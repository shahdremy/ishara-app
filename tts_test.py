import pyttsx3
print("init...")
engine = pyttsx3.init(driverName='sapi5')  # مهم في ويندوز
print("voices:")
for i, v in enumerate(engine.getProperty("voices")):
    print(i, v.id, v.name)
engine.setProperty("rate", 165)
engine.setProperty("volume", 1.0)

chosen = None
for v in engine.getProperty("voices"):
    name = (v.name or "").lower()
    if any(k in name for k in ["arab", "hoda", "naayf", "mizrah", "leila", "salma"]):
        engine.setProperty("voice", v.id)
        chosen = v.name
        break

print("chosen:", chosen or "default voice")
engine.say("اختبار صوت عربي. إن سمعتي هذا فالصوت يعمل.")
engine.runAndWait()
print("DONE.")
