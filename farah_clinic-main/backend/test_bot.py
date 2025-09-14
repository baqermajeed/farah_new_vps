from telegram import Bot

BOT_TOKEN = "8382161247:AAEk-nNlC0kHkD2t-qqmWPL6fGJQZJ8K0Yw"
CHAT_ID = "1515241653"

bot = Bot(token=BOT_TOKEN)

# إنشاء ملف اختبار
with open(r"C:\backup\test.txt", "w", encoding="utf-8") as f:
    f.write("اختبار البوت")

# إرسال الملف على Telegram
with open(r"C:\backup\test.txt", "rb") as f:
    bot.send_document(chat_id=CHAT_ID, document=f)

print("✅ السكربت بدأ العمل")

# بعد إرسال الملف
print("✅ تم إرسال نسخة الاختبار على Telegram")
