# -*- coding: utf-8 -*-
import os, json, glob
import numpy as np
from pathlib import Path
import tensorflow as tf
from tensorflow import keras
from sklearn.model_selection import train_test_split

# ================== إعداد ==================
BASE_DIR = Path(__file__).resolve().parent
SEQ_DIR  = BASE_DIR / "sequences"   # كل كلمة مجلد
MODEL_DIR = Path("C:/ishara_Project/models")
MODEL_DIR.mkdir(parents=True, exist_ok=True)

SEQ_LEN = 60
FEAT_DIM = 376
HAND_ANGLES = 6
FEAT_DIM_TOTAL = FEAT_DIM + HAND_ANGLES
SEED = 42

np.random.seed(SEED)
tf.random.set_seed(SEED)

# ================== تحميل البيانات ==================
def load_sequences(seq_dir):
    labels = sorted([d.name for d in seq_dir.iterdir() if d.is_dir()])
    X, y = [], []

    for li, lbl in enumerate(labels):
        files = glob.glob(str(seq_dir / lbl / "*.npy"))
        for f in files:
            arr = np.load(f).astype(np.float32)

            if arr.shape[1] != FEAT_DIM:
                continue

            # قص / padding
            if arr.shape[0] >= SEQ_LEN:
                arr = arr[:SEQ_LEN]
            else:
                pad = np.zeros((SEQ_LEN - arr.shape[0], FEAT_DIM), np.float32)
                arr = np.concatenate([arr, pad], axis=0)

            # إضافة زوايا اليد
            full = np.zeros((SEQ_LEN, FEAT_DIM_TOTAL), np.float32)
            full[:, :FEAT_DIM] = arr

            for t in range(SEQ_LEN):
                x1, y1 = arr[t,0:42], arr[t,42:84]
                x2, y2 = arr[t,84:126], arr[t,126:168]

                yaw1 = np.arctan2(np.mean(y1), np.mean(x1))
                pitch1 = np.mean(y1) - 0.5
                roll1 = np.std(x1-y1)

                yaw2 = np.arctan2(np.mean(y2), np.mean(x2))
                pitch2 = np.mean(y2) - 0.5
                roll2 = np.std(x2-y2)

                full[t, -6:] = [yaw1,pitch1,roll1,yaw2,pitch2,roll2]

            X.append(full)
            y.append(li)

    return np.array(X), np.array(y), labels

# ================== Normalization ==================
def compute_norm(X):
    flat = X.reshape(-1, FEAT_DIM_TOTAL)
    mean = flat.mean(axis=0)
    std  = flat.std(axis=0) + 1e-6
    return mean.astype(np.float32), std.astype(np.float32)

# ================== النموذج ==================
def build_model(num_classes):
    inp = keras.Input((SEQ_LEN, FEAT_DIM_TOTAL))
    x = keras.layers.Masking(0.0)(inp)
    x = keras.layers.Bidirectional(
        keras.layers.LSTM(128, return_sequences=True))(x)
    x = keras.layers.Bidirectional(
        keras.layers.LSTM(64))(x)
    x = keras.layers.Dense(128, activation="relu")(x)
    x = keras.layers.Dropout(0.4)(x)
    out = keras.layers.Dense(num_classes, activation="softmax")(x)

    model = keras.Model(inp, out)
    model.compile(
        optimizer=keras.optimizers.Adam(1e-3),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"]
    )
    return model

# ================== Training ==================
def main():
    X, y, labels = load_sequences(SEQ_DIR)
    print("Data:", X.shape, "Classes:", labels)

    X_train, X_val, y_train, y_val = train_test_split(
        X, y, test_size=0.15, random_state=SEED, stratify=y
    )

    mean, std = compute_norm(X_train)
    X_train = (X_train - mean) / std
    X_val   = (X_val - mean) / std

    model = build_model(len(labels))
    model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=60,
        batch_size=32,
        verbose=2
    )

    # ================== حفظ ==================
    model.save(MODEL_DIR / "final_v3.keras")
    np.savez(MODEL_DIR / "norm_stats_v3.npz", mean=mean, std=std)
    with open(MODEL_DIR / "labels_v3.json", "w", encoding="utf-8") as f:
        json.dump({"labels": labels}, f, ensure_ascii=False, indent=2)

    print("✅ تم حفظ النموذج وكل الملفات")

if __name__ == "__main__":
    main()
