# -*- coding: utf-8 -*-
# collector_376_tasks.py — تجميع 376 ميزة (أيدي + وجه + Blendshapes) مع مؤشّرات تعابير صحيحة ودعم 1..9
import os, cv2, time, numpy as np
from pathlib import Path
import urllib.request
import mediapipe as mp
from mediapipe.tasks import python as mp_python
from mediapipe.tasks.python import vision as mp_vision

# ===== مسارات الحفظ =====
BASE_DIR = Path(__file__).resolve().parent
SEQ_DIR = BASE_DIR / "sequences"
SEQ_DIR.mkdir(exist_ok=True)

# ✨ الأصناف (حتى 9 أزرار: 1..9) — رتّبي زي ما تبّي
LABELS = [
       # تحيات/سؤال
"kanon","tarek","madrasa","ana taleba","ana asamm","asef","masjad","harekk","esafat_awalia","libya","hadth","saedni","omree","mashawes","khaeff","motanaqla", "haysba","qesam","naamm","shokran", "amass","kahaa", "sodaa","ma3lomat","taqniat","fikuliyat",
    "salam", "alikum", "kaifhalak", "saeid", "hazin", "ghadib"
          ,"alhamdolahh","anaesmii" , "adrus"     # ردود/تعريف
]
for lbl in LABELS: 
    (SEQ_DIR / lbl).mkdir(exist_ok=True)

# ===== نماذج .task في مسار آمن =====
MODEL_DIR = Path(os.environ.get("LOCALAPPDATA", r"C:\Temp")) / "ishara_models"
MODEL_DIR.mkdir(parents=True, exist_ok=True)
HAND_TASK = MODEL_DIR / "hand_landmarker.task"
FACE_TASK = MODEL_DIR / "face_landmarker.task"

def ensure_task(path: Path, url: str, min_size: int = 1_000_000):
    if not path.exists() or path.stat().st_size < min_size:
        print(f"[download] {path.name} ...")
        urllib.request.urlretrieve(url, str(path))
        print(f"[ok] saved → {path}")

ensure_task(HAND_TASK, "https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task")
ensure_task(FACE_TASK, "https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task")
print("[models] HAND_TASK =", HAND_TASK)
print("[models] FACE_TASK =", FACE_TASK)

# ===== إعداد MediaPipe =====
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
        output_face_blendshapes=True  # مهم لقراءة تعابير الوجه
    )
)

# للرسم فقط
mp_face_mesh = mp.solutions.face_mesh

# ===== كاميرا =====
cap = cv2.VideoCapture(0, cv2.CAP_DSHOW)
if not cap.isOpened():
    raise RuntimeError("تعذّر فتح الكاميرا")

# ===== ثوابت الميزات =====
GREEN=(0,255,0); WHITE=(255,255,255); YELLOW=(0,255,255); CYAN=(255,255,0)
MAX_FRAMES = 60      # لازم يطابق التدريب
FACE_KEEP  = 120
HAND_POINTS = 42 * 2            # 84
FACE_POINTS = FACE_KEEP * 2     # 240
BLEND_DIM  = 52                 # عدد الـ blendshapes
TOTAL_POINTS = HAND_POINTS + FACE_POINTS + BLEND_DIM  # = 376

frames = []; recording = False

def draw_progress_bar(frame, x, y, w, h, progress, color=(0,255,0)):
    cv2.rectangle(frame, (x,y), (x+w,y+h), (80,80,80), 1)
    inner_w = int(w * max(0.0, min(1.0, progress)))
    cv2.rectangle(frame, (x,y), (x+inner_w,y+h), color, -1)

def extract_features_376(frame_bgr):
    """(أيدي x ثم y) + (وجه x ثم y) + (52 Blendshapes) = 376 + قاموس أسماء للتغذية البصرية"""
    rgb = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB)
    mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)

    hands_res = hand_detector.detect(mp_image)
    face_res  = face_detector.detect(mp_image)

    all_points = np.zeros((TOTAL_POINTS,), dtype=np.float32)
    idx = 0

    # --- الأيدي (حد أقصى يدين) ---
    hand_list = hands_res.hand_landmarks if (hands_res and hands_res.hand_landmarks) else []
    hand_list = hand_list[:2]
    if hand_list:
        for hand in hand_list:         # x
            for lm in hand: all_points[idx]=lm.x; idx+=1
        for hand in hand_list:         # y
            for lm in hand: all_points[idx]=lm.y; idx+=1
    else:
        idx += HAND_POINTS

    # --- الوجه: 120 نقطة x ثم y ---
    face_lms = face_res.face_landmarks[0] if (face_res and face_res.face_landmarks) else None
    if face_lms is not None:
        face_lms = list(face_lms)[:FACE_KEEP]
        for lm in face_lms: all_points[idx]=lm.x; idx+=1
        for lm in face_lms: all_points[idx]=lm.y; idx+=1
    else:
        idx += FACE_POINTS

    # --- Blendshapes (تعابير الوجه) 52 قيمة + قاموس بالأسماء ---
    bs_dict = {}
    if face_res and face_res.face_blendshapes:
        items = face_res.face_blendshapes[0]
        scores = []
        for i, cat in enumerate(items):
            name = (cat.category_name or f"idx_{i}")
            val  = float(cat.score)
            bs_dict[name] = val
            scores.append(val)
        # ثبّت الطول 52: قص/صفّر
        if len(scores) >= BLEND_DIM:
            scores = scores[:BLEND_DIM]
        else:
            scores = scores + [0.0]*(BLEND_DIM - len(scores))
        all_points[idx:idx+BLEND_DIM] = np.array(scores, dtype=np.float32); idx += BLEND_DIM
    else:
        idx += BLEND_DIM

    return all_points, hand_list, face_lms, bs_dict

# ===== مؤشّرات تعابير الوجه (عَ الشاشة فقط — لا تؤثر على الحفظ) =====
def rough_expression_scores(bs_dict):
    """
    مؤشرات تقريبية مبنية على أسماء معروفة من MediaPipe:
      - سعيد: mouthSmileLeft/Right (+ cheek/eyeSquint خفيف)
      - حزين: mouthFrownLeft/Right + browInnerUp
      - غاضب: browDownLeft/Right + eyeSquint + mouthPress
    نرجّع قيم بين 0..1 لعرضها فقط.
    """
    if not bs_dict:
        return 0.0, 0.0, 0.0

    def g(name):  # get value by name
        return float(bs_dict.get(name, 0.0))

    # Happy
    smile = (g("mouthSmileLeft") + g("mouthSmileRight")) / 2.0
    cheek = (g("cheekSquintLeft") + g("cheekSquintRight") + g("cheekPuff")) / 3.0
    eye_sq = (g("eyeSquintLeft") + g("eyeSquintRight")) / 2.0
    happy = 0.75*smile + 0.15*cheek + 0.10*eye_sq

    # Sad
    frown = (g("mouthFrownLeft") + g("mouthFrownRight")) / 2.0
    brow_in_up = g("browInnerUp")
    sad = 0.75*frown + 0.25*brow_in_up

    # Angry
    brow_down = (g("browDownLeft") + g("browDownRight")) / 2.0
    eye_squint = (g("eyeSquintLeft") + g("eyeSquintRight")) / 2.0
    mouth_press = (g("mouthPressLeft") + g("mouthPressRight")) / 2.0
    angry = 0.55*brow_down + 0.30*eye_squint + 0.15*mouth_press

    # حدّ القيم لـ [0..1]
    happy = float(np.clip(happy, 0.0, 1.0))
    sad   = float(np.clip(sad,   0.0, 1.0))
    angry = float(np.clip(angry, 0.0, 1.0))
    return happy, sad, angry

print("R: تسجيل/إيقاف  |  1–9: حفظ حسب الليبل  |  S/Esc: خروج")
while True:
    ok, frame = cap.read()
    if not ok: break
    frame = cv2.flip(frame, 1)

    feats, hand_list, face_lms, bs_dict = extract_features_376(frame)
    H, W, _ = frame.shape

    # رسم اليدين (نقاط بسيطة)
    if hand_list:
        for hand in hand_list:
            for lm in hand:
                cx, cy = int(lm.x * W), int(lm.y * H)
                cv2.circle(frame, (cx, cy), 2, GREEN, -1)

    # رسم الوجه (كونتور + نقاط خفيفة)
    face_ok = face_lms is not None
    if face_ok:
        pts = [(int(lm.x*W), int(lm.y*H)) for lm in face_lms[:FACE_KEEP]]
        for s, e in mp_face_mesh.FACEMESH_CONTOURS:
            if s < len(pts) and e < len(pts):
                cv2.line(frame, pts[s], pts[e], (0,255,0), 1)
        for i,(x,y) in enumerate(pts):
            if i%2==0: cv2.circle(frame,(x,y),1,(0,0,0),-1)

    # شريط حالة أعلى
    hands_cnt = len(hand_list) if hand_list else 0
    cv2.rectangle(frame,(0,0),(W,96),(0,0,0),-1)
    cv2.putText(frame,f"Hands: {hands_cnt}/2  |  Face: {'Yes' if face_ok else 'No'}",
                (10,32), cv2.FONT_HERSHEY_SIMPLEX,0.8,WHITE,2,cv2.LINE_AA)

    # مؤشرات التعابير (مساعدة للمشاعر أثناء التسجيل)
    hpy, sad, ang = rough_expression_scores(bs_dict)
    cv2.putText(frame, f"FaceExpr ~ Happy:{hpy:.2f}  Sad:{sad:.2f}  Angry:{ang:.2f}",
                (10,60), cv2.FONT_HERSHEY_SIMPLEX,0.6,YELLOW,2,cv2.LINE_AA)

    # التسجيل
    if recording:
        frames.append(feats)
        cv2.putText(frame, f"Recording... {len(frames)}/{MAX_FRAMES}", (10, 92),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.8, CYAN, 2)
        draw_progress_bar(frame, 10, 112, 300, 12, len(frames)/float(MAX_FRAMES))
        if len(frames) >= MAX_FRAMES:
            recording = False
            print("⏹️ تم الإيقاف التلقائي — اضغطي رقم الإشارة (1–9) للحفظ")

    # تعليمات ديناميكية للأزرار 1..9
    labels_help = " | ".join([f"{i+1}:{LABELS[i]}" for i in range(min(9,len(LABELS)))])
    cv2.putText(frame, f"R: تسجيل | {labels_help} | S/Esc: خروج", (10, 150),
                cv2.FONT_HERSHEY_SIMPLEX, 0.6, GREEN, 2)

    cv2.imshow("Ishara Collector (376: hands+face+blendshapes)", frame)

    key = cv2.waitKey(1) & 0xFF
    if key in [ord('s'), ord('S'), 27]:
        break
    elif key in [ord('r'), ord('R')]:
        recording = not recording
        if recording:
            frames = []; print(f"🎬 بدء التسجيل... (الهدف: {MAX_FRAMES} فريم)")
        else:
            print("⏹️ توقّف التسجيل، اختاري رقم الإشارة للحفظ")
    elif ord('1') <= key <= ord('9'):
        idx = key - ord('1')
        if idx < len(LABELS):
            if len(frames) > 5:
                label = LABELS[idx]
                file_path = (SEQ_DIR/label/f"{int(time.time())}.npy")
                np.save(file_path, np.array(frames, dtype=np.float32))
                print(f"✅ حفظ: {label} ({len(frames)} فريم) → {file_path.name}")
                frames = []
            else:
                print("⚠️ تسلسل قصير — سجّلي R ثم أعيدي المحاولة")

cap.release(); cv2.destroyAllWindows()
print("💾 تم الحفظ في:", SEQ_DIR)
