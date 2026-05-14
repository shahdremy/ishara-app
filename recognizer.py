# -*- coding: utf-8 -*-
# recognizer.py

import json
import cv2
import numpy as np
import mediapipe as mp
import tensorflow as tf
from pathlib import Path

# ================== Paths ==================
BASE_DIR = Path(__file__).resolve().parent
MODEL_DIR = BASE_DIR / "models"

MODEL_PATH = MODEL_DIR / "final_v3.keras"
LABELS_PATH = MODEL_DIR / "labels_v3.json"
NORM_PATH = MODEL_DIR / "norm_stats_v3.npz"

# ================== Load model ==================
model = tf.keras.models.load_model(MODEL_PATH)

with open(LABELS_PATH, "r", encoding="utf-8") as f:
    labels = json.load(f)["labels"]

norm = np.load(NORM_PATH)
mean = norm["mean"]
std = norm["std"]

SEQ_LEN = 60
FEAT_DIM_TOTAL = mean.shape[0]

# ================== MediaPipe ==================
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(
    static_image_mode=False,
    max_num_hands=2,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)

# ================== Buffer ==================
sequence = []

# ================== Feature extraction ==================
def extract_features(results):
    feat = np.zeros(376, dtype=np.float32)

    if results.multi_hand_landmarks:
        for h, hand in enumerate(results.multi_hand_landmarks[:2]):
            for i, lm in enumerate(hand.landmark):
                idx = h * 126 + i * 3
                feat[idx:idx+3] = [lm.x, lm.y, lm.z]

    return feat


# ================== Main function ==================
def process_frame(frame):
    global sequence

    img_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results = hands.process(img_rgb)

    features = extract_features(results)
    sequence.append(features)

    if len(sequence) > SEQ_LEN:
        sequence.pop(0)

    label = "..."

    if len(sequence) == SEQ_LEN:
        seq = np.array(sequence, dtype=np.float32)
        seq = (seq - mean[:376]) / std[:376]
        seq = np.expand_dims(seq, axis=0)

        preds = model.predict(seq, verbose=0)[0]
        idx = int(np.argmax(preds))
        conf = preds[idx]

        if conf > 0.6:
            label = labels[idx]

    # ===== عرض النص =====
    cv2.putText(
        frame,
        label,
        (30, 60),
        cv2.FONT_HERSHEY_SIMPLEX,
        1.5,
        (0, 255, 0),
        3
    )

    return frame, label
