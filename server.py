# -*- coding: utf-8 -*-
# server.py

import cv2
import json
import time
import base64
import numpy as np
from flask import Flask, Response

# ===== استيراد كود التعرف =====
from recognizer import process_frame

# ===== إعداد Flask =====
app = Flask(__name__)

# ===== فتح الكاميرا =====
cap = cv2.VideoCapture(0, cv2.CAP_DSHOW)
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

if not cap.isOpened():
    raise RuntimeError("❌ لم يتم فتح الكاميرا")

# ===== بث الفيديو + النص =====
@app.route("/stream")
def stream():
    def generate():
        while True:
            success, frame = cap.read()
            if not success:
                continue

            # 🔍 التعرف على الإشارة
            frame, label = process_frame(frame)

            # 🔁 تحويل الصورة إلى Base64
            _, buffer = cv2.imencode(".jpg", frame, [int(cv2.IMWRITE_JPEG_QUALITY), 80])
            frame_base64 = base64.b64encode(buffer).decode("utf-8")

            # 📦 البيانات المرسلة
            payload = {
                "frame": frame_base64,
                "label": label
            }

            yield f"data:{json.dumps(payload, ensure_ascii=False)}\n\n"
            time.sleep(0.03)  # ~30 FPS

    return Response(generate(), mimetype="text/event-stream")


# ===== تشغيل السيرفر =====
if __name__ == "__main__":
    print("🚀 Server running...")
    print("📡 Open: http://172.20.10.8:5000/stream")
    app.run(host="0.0.0.0", port=5000, debug=False)
