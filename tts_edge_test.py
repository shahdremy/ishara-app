import asyncio, edge_tts, os, tempfile
async def main():
    tts = edge_tts.Communicate("اختبار صوت عربي من نايف.", voice="ar-SA-NaayfNeural")
    with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as f:
        out = f.name
    await tts.save(out)
    os.startfile(out)  # يشغل الملف على مشغل الصوت الافتراضي
asyncio.run(main())
