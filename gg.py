# -*- coding: utf-8 -*-
import os, json, threading, collections, numpy as np, cv2, mediapipe as mp, time
from pathlib import Path
from tensorflow import keras
from PIL import ImageFont, ImageDraw, Image
from bidi.algorithm import get_display
import pyttsx3
import arabic_reshaper

# ---------------- مسارات النماذج ----------------
BASE_DIR = Path(__file__).resolve().parent
MODEL_DIR  = Path("C:/ishara_Project/models")
MODEL_PATH = MODEL_DIR / "final_v3.keras"
NORM_PATH  = MODEL_DIR / "norm_stats_v3.npz"
LABELS_PATH= MODEL_DIR / "labels_v3.json"

# تحميل النموذج وملفات التطبيع والتسميات
model = keras.models.load_model(str(MODEL_PATH))
norm = np.load(str(NORM_PATH))
MEAN, STD = norm["mean"].astype(np.float32), norm["std"].astype(np.float32)
with open(LABELS_PATH, "r", encoding="utf-8") as f:
    LABELS = json.load(f)["labels"]

# ---------------- خريطة الكلمات العربية ----------------
TEXT_MAP = {
    "buka":"بكاء","kanon":"قانون","harekk":"حريق","esafat_awalia":"اسعافات أولية",
    "hadth":"حادث","saedni":"أريد المساعدة","shurta":"شرطة","bark_allah_fik":"بارك الله فيك",
    "saeid":"سعيد","hazin":"حزين","ghadib":"غاضب","khaeff":"خائف","mashawes":"مشوش",
    "ana omee":"أُمي","ahed_lee":"اعادة","sareqa":"سرقة","alhamdolahh":"الحمد لله",
    "salam":"السلام","alikum":"عليكم","kaifhalak":"كيف حالك","libya":"ليبيا",
    "asef":"آسف","ana asamm":"أنا أصم","anaesmii":"أنا اسمي","adrus":"أدرس",
    "fikuliyat":"في كلية","taqniat":"تقنية","ma3lomat":"المعلومات","motanaqla":"المتنقلة",
    "haysba":"الحوسبة","qesam":"قسم","naamm":"نعم","laa":"لا","amass":"منذ أمس",
    "kahaa":"وكحة","sodaa":"صداع","masjad":"مسجد","tarek":"طريق"
}

# ---------------- Mediapipe ----------------
MODEL_CACHE = Path(os.environ.get("LOCALAPPDATA", r"C:\Temp")) / "ishara_models"
MODEL_CACHE.mkdir(parents=True, exist_ok=True)
HAND_TASK = MODEL_CACHE / "hand_landmarker.task"
FACE_TASK = MODEL_CACHE / "face_landmarker.task"

def ensure_task(path, url, min_size=1_000_000):
    if not path.exists() or path.stat().st_size < min_size:
        import urllib.request
        urllib.request.urlretrieve(url, str(path))

ensure_task(HAND_TASK,
    "https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task")
ensure_task(FACE_TASK,
    "https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task")

from mediapipe.tasks import python as mp_python
from mediapipe.tasks.python import vision as mp_vision
BaseOptions = mp_python.BaseOptions
RunningMode = mp_vision.RunningMode

hand_detector = mp_vision.HandLandmarker.create_from_options(
    mp_vision.HandLandmarkerOptions(
        base_options=BaseOptions(model_asset_path=str(HAND_TASK)),
        num_hands=2, running_mode=RunningMode.IMAGE,
        min_hand_detection_confidence=0.5
    )
)
face_detector = mp_vision.FaceLandmarker.create_from_options(
    mp_vision.FaceLandmarkerOptions(
        base_options=BaseOptions(model_asset_path=str(FACE_TASK)),
        num_faces=1, running_mode=RunningMode.IMAGE,
        min_face_detection_confidence=0.5,
        output_face_blendshapes=True
    )
)

# ---------------- إعداد الثوابت ----------------
SEQ_LEN = 60
FEAT_DIM = 376
HAND_ANGLES = 6
FEAT_DIM_TOTAL = FEAT_DIM + HAND_ANGLES
CONF_THRESH = 0.98
STREAK_MIN = 22
PROB_QUEUE_LEN = 10
WORD_COOLDOWN = 2.0

SIMILAR_WORDS = [
    {"ana asamm","alhamdolahh"},
    {"kaifhalak","asef","anaesmii"},
    {"alikum","naamm"},
    {"motanaqla","libya"},
    {"adrus","hadth"},
    {"fikuliyat","naamm"}
]

# ---------------- TTS ----------------
engine = pyttsx3.init()
engine.setProperty('rate', 150)
engine.setProperty('voice','com.apple.speech.synthesis.voice.maged')
def speak_text(text):
    engine.say(text)
    engine.runAndWait()

# ---------------- استخراج الميزات ----------------
def extract_features_376(frame_bgr):
    rgb = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB)
    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
    hands_res = hand_detector.detect(mp_image)
    face_res  = face_detector.detect(mp_image)
    all_points = np.zeros((FEAT_DIM,),dtype=np.float32)
    idx = 0

    hand_list = hands_res.hand_landmarks if hands_res and hands_res.hand_landmarks else []
    hand_list = hand_list[:2]
    if hand_list:
        for hand in hand_list:
            for lm in hand: all_points[idx]=lm.x; idx+=1
        for hand in hand_list:
            for lm in hand: all_points[idx]=lm.y; idx+=1
    else: idx += 84

    face_lms = face_res.face_landmarks[0] if face_res and face_res.face_landmarks else None
    if face_lms is not None:
        face_lms = list(face_lms)[:120]
        for lm in face_lms: all_points[idx]=lm.x; idx+=1
        for lm in face_lms: all_points[idx]=lm.y; idx+=1
    else: idx += 240

    if face_res and face_res.face_blendshapes:
        items = face_res.face_blendshapes[0]
        scores = [float(cat.score) for cat in items]
        scores += [0.0]*(52-len(scores))
        all_points[idx:idx+52] = np.array(scores,dtype=np.float32); idx+=52
    else: idx += 52

    return all_points

def compute_hand_angles_from_feat(feat):
    try:
        x1,y1 = feat[0:42],feat[42:84]
        x2,y2 = feat[84:126],feat[126:168]
        def mean_safe(x): return float(np.mean(x)) if len(x)>0 else 0.0
        yaw1 = np.arctan2(mean_safe(y1),mean_safe(x1)); pitch1=mean_safe(y1)-0.5; roll1=float(np.std(x1-y1))
        yaw2 = np.arctan2(mean_safe(y2),mean_safe(x2)); pitch2=mean_safe(y2)-0.5; roll2=float(np.std(x2-y2))
        return np.array([yaw1,pitch1,roll1,yaw2,pitch2,roll2],dtype=np.float32)
    except: return np.zeros((HAND_ANGLES,),dtype=np.float32)

# ---------------- Predictor Thread ----------------
class PredictorThread(threading.Thread):
    def __init__(self, model, mean, std):
        super().__init__(daemon=True)
        self.model,self.mean,self.std = model,mean,std
        self.seq=collections.deque(maxlen=SEQ_LEN)
        self.probs=None; self.lock=threading.Lock(); self.event=threading.Event(); self.running=True
    def add_frame(self, feats):
        self.seq.append(feats)
        if len(self.seq)==SEQ_LEN: self.event.set()
    def run(self):
        while self.running:
            self.event.wait()
            if not self.running: break
            arr = np.stack(list(self.seq),axis=0)[None,:,:]
            if arr.shape[-1]!=self.mean.shape[0]:
                if self.mean.shape[0]==FEAT_DIM_TOTAL and arr.shape[-1]==FEAT_DIM:
                    frames=[]
                    for f in arr[0]:
                        angs = compute_hand_angles_from_feat(f)
                        frames.append(np.concatenate([f,angs],axis=0))
                    arr = np.stack(frames,axis=0)[None,:,:]
                else:
                    print("[error] mismatch features dim")
            arr = (arr-self.mean[None,None,:])/self.std[None,None,:]
            probs = self.model.predict(arr,verbose=0)[0]
            with self.lock: self.probs=probs
            self.event.clear()
    def get_probs(self):
        with self.lock: return self.probs

predictor = PredictorThread(model, MEAN, STD)
predictor.start()

# ---------------- واجهة العرض ----------------
cap = cv2.VideoCapture(0,cv2.CAP_DSHOW)
cv2.namedWindow("Ishara Results",cv2.WINDOW_NORMAL)
last_label = None; streak = 0
last_label_displayed = None
display_text = ""
display_until = 0
last_display_time = 0

font_path = str(BASE_DIR / "arial.ttf")
font = ImageFont.truetype(font_path, 36)
prob_queue = collections.deque(maxlen=PROB_QUEUE_LEN)

def is_similar(label1,label2):
    if not label1 or not label2: return False
    for group in SIMILAR_WORDS:
        if label1 in group and label2 in group:
            return True
    return False

while True:
    ok, frame = cap.read()
    if not ok: break
    frame = cv2.flip(frame,1)
    feats = extract_features_376(frame)
    feats_full = np.concatenate([feats,compute_hand_angles_from_feat(feats)],axis=0)
    predictor.add_frame(feats_full)
    probs = predictor.get_probs()

    H,W,_ = frame.shape
    cv2.rectangle(frame,(0,H-60),(W,H),(0,0,0),-1)

    if probs is not None:
        prob_queue.append(probs)
        avg_probs = np.mean(prob_queue, axis=0)
        top_idx = int(np.argmax(avg_probs))
        conf = float(avg_probs[top_idx])
        label = LABELS[top_idx]

        sorted_probs = np.sort(avg_probs)[::-1]
        top_prob = sorted_probs[0]
        second_prob = sorted_probs[1] if len(sorted_probs)>1 else 0

        if conf >= CONF_THRESH and (top_prob - second_prob) > 0.15:
            if label == last_label:
                streak += 1
            else:
                streak = 1
                last_label = label
        else:
            streak = 0
            last_label = None

        if streak >= STREAK_MIN and (time.time() - last_display_time) > WORD_COOLDOWN:
            if not is_similar(last_label_displayed,label):
                arabic = TEXT_MAP.get(label,label)
                reshaped_text = arabic_reshaper.reshape(arabic)
                display_text = get_display(reshaped_text)
                display_until = time.time() + 2.0
                threading.Thread(target=speak_text, args=(arabic,), daemon=True).start()
                last_label_displayed = label
                last_display_time = time.time()
            streak = 0
            last_label = None

    if display_text and time.time()<display_until:
        img_pil = Image.fromarray(frame)
        draw = ImageDraw.Draw(img_pil)
        draw.text((10,H-50), display_text, font=font, fill=(255,255,255,255))
        frame = np.array(img_pil)

    cv2.imshow("Ishara Results", frame)
    key = cv2.waitKey(1)&0xFF
    if key in [27,ord('q'),ord('Q')]: break

cap.release()
predictor.running=False
predictor.event.set()
cv2.destroyAllWindows()
print("💾 الخروج — إغلاق الموارد")
