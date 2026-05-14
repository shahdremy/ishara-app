# -*- coding: utf-8 -*-
# Ishara Realtime (ROBUST + FAST LAUNCH) — ثقة عالية + تثبيت زمني + بوابة حركة + دمج عبارات
# + عرض عربي صحيح (Pillow+bidi) + Edge-TTS مع اختيار تلقائي لأصوات عربية
# + عبارة الدراسة: "أدرس في كلية تقنية المعلومات" (adrus → fi_kuliyat → taqniat → ma3lomat)

import os, time, json, collections, urllib.request, asyncio, threading, queue, tempfile
import numpy as np
import cv2
from pathlib import Path

import edge_tts
import mediapipe as mp
from mediapipe.tasks import python as mp_python
from mediapipe.tasks.python import vision as mp_vision
from tensorflow import keras
from PIL import Image, ImageDraw, ImageFont
import arabic_reshaper
from bidi.algorithm import get_display

# ===== مسارات النموذج =====
BASE_DIR   = Path(__file__).resolve().parent
MODEL_DIR  = BASE_DIR / "models"
MODEL_PATH = MODEL_DIR / "ishara_376_60.keras"
NORM_PATH  = MODEL_DIR / "norm_376_60.npz"
LABELS_PATH= MODEL_DIR / "labels.json"
assert MODEL_PATH.exists() and NORM_PATH.exists() and LABELS_PATH.exists(), "درّبي أولاً (train_ishara_model.py)."

# ===== تحميل النموذج/التطبيع/الأصناف =====
model = keras.models.load_model(MODEL_PATH)
norm  = np.load(NORM_PATH)
MEAN, STD = norm["mean"].astype(np.float32), norm["std"].astype(np.float32)
with open(LABELS_PATH, "r", encoding="utf-8") as f:
    LABELS = json.load(f)["labels"]

# ===== نصوص النطق/الكتابة =====
TEXT_MAP = {
   "kanon":"قانون","harekk":"حريق","esafat_awalia":"اسعافات الاولية","hadth":"حادث","saedni":"اريد المساعدة",
    "saeid": "سعيد", "hazin": "حزين", "ghadib": "غاضب","khaeff":"خائف","mashawes":"مشوش",
    "bikhair": "بخير", "alhamdolahh": "الحمد لله", "salam": "السلام", "alikum": "عليكم", "kaifhalak": "كيف حالك","libya":"ليبيا","asef":"اسف","ana asamm":"انا اصم","ana taleba":"انا طالب","omree":"عمري",
    "anaesmii": "أنا اسمي", "shahd": "شهد",
    "adrus": "أدرس", "fikuliyat": "في كلية", "taqniat": "تقنية", "ma3lomat": "المعلومات","motanaqla":"المتنقلة", "haysba":"الحوسبة","qesam":"قسم",
    "naamm":"نعم","shokran":"شكرا","laa":"لا", "amass":"منذامس","kahaa":"وكحة","sodaa":"لذي صداع","da":"دالٌ", "ha":"هاءٌ", "sha":"شينٌ",
    "madrasa":"مدرسة","masjad":"مسجد","tarek":"طريق"
}
NAME_LABELS = {"shahd"}
EMO_LABELS  = {"saeid","hazin","ghadib"}
NON_EMO     = set(LABELS) - EMO_LABELS

# ===== إعدادات الصرامة/السرعة =====
CONF_THRESH       = 0.70
MARGIN_THRESH     = 0.25
STREAK_MIN        = 4
STREAK_CONFUSE    = 6
COOLDOWN_CLASS    = 1.10
COOLDOWN_GLOBAL   = 0.35
SEQ_LEN           = 60
FAST_MIN_FR       = 2

CONFUSING_SETS = [
    {"kaifhalak", "anaesmii", "adrus"},
]

REQUIRE_FACE_FOR_EMO = True
MAX_HAND_MOTION_FOR_EMO = 0.0016
EMO_FACE_SCORE_MIN   = 0.35

ENABLE_PHRASE_MERGE = True
PHRASE_WINDOW = 2.5

STUDY_SEQ  = ["adrus", "fi_kuliyat", "taqniat", "ma3lomat"]
STUDY_TEXT = "أدرس في كلية تقنية المعلومات"
STUDY_STEP_TIMEOUT = 2.0
STUDY_COOLDOWN = 3.0

TTS_ON = True
VOICE_CANDIDATES = [
    "ar-LY-ImanNeural", "ar-LY-OmarNeural",
    "ar-EG-SalmaNeural", "ar-EG-ShakirNeural",
    "ar-SA-ZariyahNeural", "ar-SA-HamedNeural",
    "ar-AE-FatimaNeural", "ar-AE-HamdanNeural",
    "ar-KW-NouraNeural", "ar-KW-FahedNeural",
]
def pick_edge_voice(): return VOICE_CANDIDATES[0]
EDGE_VOICE = pick_edge_voice()

# ===== TTS worker =====
_tts_q = queue.Queue()
def _tts_worker():
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)

    async def run():
        while True:
            txt = await loop.run_in_executor(None, _tts_q.get)
            if txt is None:
                break
            try:
                tts = edge_tts.Communicate(txt, voice=EDGE_VOICE)
                with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as f:
                    out = f.name
                await tts.save(out)
                try:
                    os.startfile(out)
                    # حذف الملف بعد 3 ثواني لتجنب التراكم
                    threading.Timer(3, lambda: os.remove(out) if os.path.exists(out) else None).start()
                except Exception as e_inner:
                    print("[TTS startfile error]", e_inner)
            except Exception as e:
                print("[TTS error]", e)

    loop.run_until_complete(run())

threading.Thread(target=_tts_worker, daemon=True).start()

def speak_ar(t):
    if TTS_ON:
        try:
            _tts_q.put_nowait(t)
        except:
            pass

def tts_shutdown():
    try:
        _tts_q.put_nowait(None)
    except:
        pass

# ===== MediaPipe =====
MODEL_CACHE = Path(os.environ.get("LOCALAPPDATA", r"C:\Temp")) / "ishara_models"
MODEL_CACHE.mkdir(parents=True, exist_ok=True)
HAND_TASK = MODEL_CACHE / "hand_landmarker.task"
FACE_TASK = MODEL_CACHE / "face_landmarker.task"
def ensure_task(path: Path, url: str, min_size: int = 1_000_000):
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists() or path.stat().st_size < min_size:
        print(f"[download] {path.name} ...")
        urllib.request.urlretrieve(url, str(path))
        print(f"[ok] saved → {path}")
ensure_task(HAND_TASK, "https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task")
ensure_task(FACE_TASK, "https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task")

BaseOptions = mp_python.BaseOptions
RunningMode = mp_vision.RunningMode
hand_detector = mp_vision.HandLandmarker.create_from_options(
    mp_vision.HandLandmarkerOptions(
        base_options=BaseOptions(model_asset_path=str(HAND_TASK)),
        num_hands=2, running_mode=RunningMode.IMAGE, min_hand_detection_confidence=0.5
    )
)
face_detector = mp_vision.FaceLandmarker.create_from_options(
    mp_vision.FaceLandmarkerOptions(
        base_options=BaseOptions(model_asset_path=str(FACE_TASK)),
        num_faces=1, running_mode=RunningMode.IMAGE, min_face_detection_confidence=0.5,
        output_face_blendshapes=True
    )
)

# ===== خطوط وألوان =====
WHITE=(255,255,255); ORANGE=(0,165,255); CYAN=(255,255,0)
def _pick_font(size=42):
    for p in [r"C:\Windows\Fonts\NotoNaskhArabic-Regular.ttf",
              r"C:\Windows\Fonts\trado.ttf",
              r"C:\Windows\Fonts\segoeui.ttf",
              r"C:\Windows\Fonts\arial.ttf"]:
        if os.path.exists(p):
            try: return ImageFont.truetype(p, size=size)
            except: pass
    return ImageFont.load_default()
_AR_FONT = _pick_font(42)
def draw_arabic_text(frame_bgr, text, bottom=True):
    shaped = arabic_reshaper.reshape(text)
    bidi_text = get_display(shaped)
    img = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB)
    pil = Image.fromarray(img); draw = ImageDraw.Draw(pil)
    W,H = pil.size; bar_h = 72
    if bottom:
        draw.rectangle([(0,H-bar_h),(W,H)], fill=(0,0,0)); pos=(12, H-54)
    else:
        draw.rectangle([(0,0),(W,bar_h)], fill=(0,0,0)); pos=(12, 12)
    draw.text(pos, bidi_text, font=_AR_FONT, fill=(0,255,0))
    return cv2.cvtColor(np.array(pil), cv2.COLOR_RGB2BGR)

# ===== استخراج الميزات =====
FACE_KEEP=120; BLEND_DIM=52
HAND_POINTS=42*2; FACE_POINTS=FACE_KEEP*2; FEAT_DIM=HAND_POINTS+FACE_POINTS+BLEND_DIM

def _expr_scores(face_res):
    if not (face_res and face_res.face_blendshapes): return (0.0,0.0,0.0)
    d = { (it.category_name or str(i)) : float(it.score) for i,it in enumerate(face_res.face_blendshapes[0]) }
    def g(k): return d.get(k, 0.0)
    happy = 0.75*((g("mouthSmileLeft")+g("mouthSmileRight"))/2.0) + 0.15*((g("cheekSquintLeft")+g("cheekSquintRight")+g("cheekPuff"))/3.0) + 0.10*((g("eyeSquintLeft")+g("eyeSquintRight"))/2.0)
    sad   = 0.75*((g("mouthFrownLeft")+g("mouthFrownRight"))/2.0) + 0.25*g("browInnerUp")
    angry = 0.55*((g("browDownLeft")+g("browDownRight"))/2.0) + 0.30*((g("eyeSquintLeft")+g("eyeSquintRight"))/2.0) + 0.15*((g("mouthPressLeft")+g("mouthPressRight"))/2.0)
    return float(np.clip(happy,0,1)), float(np.clip(sad,0,1)), float(np.clip(angry,0,1))

def extract_features_376(frame_bgr):
    rgb = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB)
    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
    hands_res = hand_detector.detect(mp_image)
    face_res  = face_detector.detect(mp_image)

    all_points = np.zeros((FEAT_DIM,), dtype=np.float32); idx=0
    hand_list = hands_res.hand_landmarks if (hands_res and hands_res.hand_landmarks) else []
    hand_list = hand_list[:2]
    if hand_list:
        for hand in hand_list:
            for lm in hand: all_points[idx]=lm.x; idx+=1
        for hand in hand_list:
            for lm in hand: all_points[idx]=lm.y; idx+=1
    else:
        idx += HAND_POINTS

    face_lms = face_res.face_landmarks[0] if (face_res and face_res.face_landmarks) else None
    if face_lms is not None:
        face_lms = list(face_lms)[:FACE_KEEP]
        for lm in face_lms: all_points[idx]=lm.x; idx+=1
        for lm in face_lms: all_points[idx]=lm.y; idx+=1
    else:
        idx += FACE_POINTS

    if face_res and face_res.face_blendshapes:
        items = face_res.face_blendshapes[0]
        scores = [float(cat.score) for cat in items]
        if len(scores) >= BLEND_DIM: scores = scores[:BLEND_DIM]
        else: scores += [0.0]*(BLEND_DIM-len(scores))
        all_points[idx:idx+BLEND_DIM] = np.array(scores, dtype=np.float32); idx+=BLEND_DIM
    else:
        idx += BLEND_DIM

    return all_points, hand_list, face_lms, face_res

# ===== Thread للنموذج لتسريع التنبؤ =====
class PredictorThread(threading.Thread):
    def __init__(self, model, mean, std):
        super().__init__(daemon=True)
        self.model = model
        self.mean = mean
        self.std = std
        self.seq = collections.deque(maxlen=SEQ_LEN)
        self.probs = None
        self.lock = threading.Lock()
        self.event = threading.Event()
        self.running = True

    def add_frame(self, feats):
        self.seq.append(feats)
        if len(self.seq) == SEQ_LEN:
            self.event.set()

    def run(self):
        while self.running:
            self.event.wait()
            if not self.running: break
            arr = np.stack(list(self.seq), axis=0)[None, :, :]
            arr = (arr - self.mean[None,None,:]) / self.std[None,None,:]
            probs = self.model.predict(arr, verbose=0)[0]
            with self.lock:
                self.probs = probs
            self.event.clear()

    def get_probs(self):
        with self.lock:
            return self.probs

predictor = PredictorThread(model, MEAN, STD)
predictor.start()

# ===== نوافذ وتتبع =====
seq = collections.deque(maxlen=SEQ_LEN)
streak = 0
last_label = None
last_said_per_class = {lbl: 0.0 for lbl in LABELS}
last_global_fire = 0.0

pending = {"label": None, "ts": 0.0}
def maybe_merge_and_say(voted_label, now):
    global pending
    txt = TEXT_MAP.get(voted_label, voted_label)
    if not ENABLE_PHRASE_MERGE:
        speak_ar(txt); return True
    if pending["label"]:
        first = pending["label"]
        if first=="salam" and voted_label=="alikum" and (now-pending["ts"]<=PHRASE_WINDOW):
            speak_ar("السلام عليكم"); pending={"label":None,"ts":0.0}; return True
        if first=="anaesmii" and voted_label in NAME_LABELS and (now-pending["ts"]<=PHRASE_WINDOW):
            if voted_label=="shahd": speak_ar("أنا اسمي شهد")
            else: speak_ar(f"{TEXT_MAP.get('anaesmii','أنا اسمي')} {TEXT_MAP.get(voted_label, voted_label)}")
            pending={"label":None,"ts":0.0}; return True
        speak_ar(TEXT_MAP.get(first, first)); pending={"label":None,"ts":0.0}
        speak_ar(txt); return True
    if voted_label in ("salam","anaesmii"):
        pending={"label":voted_label,"ts":now}
        return False
    else:
        speak_ar(txt); return True

study_idx = 0
study_ts0 = 0.0
last_study_done = 0.0
def reset_study_seq():
    global study_idx, study_ts0
    study_idx = 0; study_ts0 = 0.0
def feed_study_seq(label, now):
    global study_idx, study_ts0, last_study_done
    if now - last_study_done < STUDY_COOLDOWN:
        reset_study_seq(); return False
    if study_idx == 0:
        if label == STUDY_SEQ[0]:
            study_idx = 1; study_ts0 = now
        else:
            reset_study_seq()
        return False
    if now - study_ts0 > STUDY_STEP_TIMEOUT * len(STUDY_SEQ):
        reset_study_seq()
        if label == STUDY_SEQ[0]:
            study_idx = 1; study_ts0 = now
        return False
    expected = STUDY_SEQ[study_idx]
    if label == expected:
        study_idx += 1
        if study_idx == len(STUDY_SEQ):
            speak_ar(STUDY_TEXT)
            last_study_done = now
            reset_study_seq()
            return True
        return False
    else:
        if label == STUDY_SEQ[0]:
            study_idx = 1; study_ts0 = now
        return False

class HandGate:
    def __init__(self):
        self.prev = None
        self.state = "IDLE"
        self.ts = time.time()
        self.MOVE_ON  = 0.0022
        self.MOVE_OFF = 0.0010
    def energy(self, feat_now):
        if self.prev is None:
            self.prev = feat_now.copy(); return 0.0
        d = np.abs(feat_now - self.prev); self.prev = feat_now.copy()
        return float(np.mean(d))
    def update(self, has_hands, e):
        now = time.time()
        if self.state == "IDLE":
            if has_hands and e > self.MOVE_ON:
                self.state = "MOVING"; self.ts = now
        elif self.state == "MOVING":
            if e < self.MOVE_OFF and has_hands:
                self.state = "STABLE"; self.ts = now
            if not has_hands and (now - self.ts > 1.2):
                self.state = "IDLE"; self.ts = now
        elif self.state == "STABLE":
            if e > self.MOVE_ON:
                self.state = "MOVING"; self.ts = now
            if not has_hands:
                self.state = "IDLE"; self.ts = now

gate = HandGate()

# ===== كاميرا =====
cap = cv2.VideoCapture(0, cv2.CAP_DSHOW)
if not cap.isOpened(): raise RuntimeError("تعذّر فتح الكاميرا")
cv2.namedWindow("Ishara Realtime (ROBUST)", cv2.WINDOW_NORMAL)

last_text = ""
last_text_ts = 0.0
def show_text(frame, text, bottom=True):
    global last_text, last_text_ts
    frame[:] = draw_arabic_text(frame, text, bottom=bottom)
    last_text = text; last_text_ts = time.time()

print("ROBUST mode: ثقة≥0.70، هامش≥0.25، 4 فريمات (6 لو ملتبسة)، بوابة حركة يد، ودمج عبارات + دراسة.")
frame_i = 0
while True:
    ok, frame = cap.read()
    if not ok: break
    frame = cv2.flip(frame, 1)

    feats, hands, face_lms, face_res = extract_features_376(frame)
    predictor.add_frame(feats)
    probs = predictor.get_probs()

    has_hands = bool(hands and len(hands)>0)
    face_ok   = face_lms is not None

    e = gate.energy(feats)
    gate.update(has_hands, e)

    if probs is not None:
        order = np.argsort(probs)[::-1]
        top = int(order[0]); second = int(order[1]) if len(order)>1 else top
        label = LABELS[top]
        conf  = float(probs[top])
        margin= float(probs[top] - probs[second])

        actor_ok = True
        if label in NON_EMO:
            actor_ok = has_hands and (gate.state == "STABLE")
        elif label in EMO_LABELS:
            hpy,sad,ang = _expr_scores(face_res)
            emo_score = {"saeid":hpy, "hazin":sad, "ghadib":ang}.get(label, 0.0)
            actor_ok = (not has_hands or e <= MAX_HAND_MOTION_FOR_EMO) and face_ok and (emo_score >= EMO_FACE_SCORE_MIN)

        if actor_ok and conf >= CONF_THRESH and margin >= MARGIN_THRESH:
            if label == last_label: streak += 1
            else: streak = 1; last_label = label
        else: streak = 0; last_label = None

        required_streak = STREAK_MIN
        for s in CONFUSING_SETS:
            if label in s:
                required_streak = max(required_streak, STREAK_CONFUSE)

        now = time.time()
        class_cool_ok = (now - last_said_per_class[label] >= COOLDOWN_CLASS)
        global_cool_ok= (now - last_global_fire >= COOLDOWN_GLOBAL)

        if streak >= required_streak and class_cool_ok and global_cool_ok:
            text_to_show = TEXT_MAP.get(label, label)
            if label in STUDY_SEQ:
                show_text(frame, text_to_show)
                full_done = feed_study_seq(label, now)
                if full_done: show_text(frame, STUDY_TEXT)
                last_said_per_class[label] = now
                last_global_fire = now
                streak = 0; last_label = None
            else:
                said = False
                if ENABLE_PHRASE_MERGE:
                    said = maybe_merge_and_say(label, now)
                    if not said: text_to_show = TEXT_MAP.get(label, label)
                if not ENABLE_PHRASE_MERGE or said: show_text(frame, text_to_show)
                last_said_per_class[label] = now
                last_global_fire = now
                streak = 0; last_label = None

        H, W, _ = frame.shape
        top3 = " | ".join([f"{LABELS[i]}:{probs[i]:.2f}" for i in order[:3]])
        cv2.rectangle(frame,(0,0),(W,86),(0,0,0),-1)
        cv2.putText(frame,f"Top3: {top3}", (10,34), cv2.FONT_HERSHEY_SIMPLEX,0.7,ORANGE,2)
        cv2.putText(frame,f"Gate:{gate.state}  Motion:{e:.4f}  Streak:{streak}/{required_streak}",
                    (10,68), cv2.FONT_HERSHEY_SIMPLEX,0.6,CYAN,2)

    if last_text and (time.time()-last_text_ts)<1.0:
        frame[:] = draw_arabic_text(frame, last_text, bottom=True)

    cv2.imshow("Ishara Realtime (ROBUST)", frame)
    frame_i += 1
    if (cv2.waitKey(1) & 0xFF) in [27, ord('q'), ord('Q')]: break

cap.release(); tts_shutdown(); predictor.running=False; predictor.event.set(); cv2.destroyAllWindows()
