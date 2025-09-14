import os
import datetime
import schedule
import time
import subprocess
import zipfile
from telegram import Bot

# ===== إعدادات =====
MONGO_USER = "farah"
MONGO_PASS = "Farah435"
DB_NAME = "farah_dental_clinic"
BACKUP_DIR = r"C:\backup"
BOT_TOKEN = "8382161247:AAEk-nNlC0kHkD2t-qqmWPL6fGJQZJ8K0Yw"
CHAT_ID = "1515241653"
MAX_SIZE_MB = 50  # الحد الأقصى لكل ملف عند الإرسال
RETENTION_HOURS = 24  # حذف النسخ القديمة بعد 24 ساعة

bot = Bot(token=BOT_TOKEN)

# ===== دالة لتقسيم الملفات الكبيرة =====
def split_file(file_path, max_size_mb=50):
    parts = []
    max_size = max_size_mb * 1024 * 1024
    with open(file_path, "rb") as f:
        index = 1
        while True:
            chunk = f.read(max_size)
            if not chunk:
                break
            part_file = f"{file_path}.part{index}"
            with open(part_file, "wb") as pf:
                pf.write(chunk)
            parts.append(part_file)
            index += 1
    return parts

# ===== دالة لحذف النسخ القديمة =====
def clean_old_backups():
    now = time.time()
    for folder in os.listdir(BACKUP_DIR):
        folder_path = os.path.join(BACKUP_DIR, folder)
        if os.path.isdir(folder_path):
            if now - os.path.getmtime(folder_path) > RETENTION_HOURS * 3600:
                try:
                    # حذف المجلد والملفات بداخله
                    for root, dirs, files in os.walk(folder_path, topdown=False):
                        for name in files:
                            os.remove(os.path.join(root, name))
                        for name in dirs:
                            os.rmdir(os.path.join(root, name))
                    os.rmdir(folder_path)
                    print(f"🗑️ تم حذف النسخة القديمة: {folder_path}")
                except Exception as e:
                    print(f"❌ فشل حذف النسخة القديمة {folder_path}: {e}")

# ===== دالة عمل النسخة وإرسالها =====
def backup_and_send():
    clean_old_backups()  # تنظيف النسخ القديمة أولًا

    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = os.path.join(BACKUP_DIR, f"{DB_NAME}_backup_{timestamp}")
    os.makedirs(backup_path, exist_ok=True)
    
    # عمل النسخة باستخدام mongodump
    subprocess.run([
        r"C:\Program Files\MongoDB\Tools\100\bin\mongodump.exe",
        f"--db={DB_NAME}",
        f"-u={MONGO_USER}",
        f"-p={MONGO_PASS}",
        f"--authenticationDatabase={DB_NAME}",
        f"--out={backup_path}"
    ])

    # ضغط النسخة
    zip_file = f"{backup_path}.zip"
    with zipfile.ZipFile(zip_file, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(backup_path):
            for file in files:
                file_path = os.path.join(root, file)
                zipf.write(file_path, os.path.relpath(file_path, backup_path))
    
    file_size_mb = os.path.getsize(zip_file) / (1024*1024)
    print(f"📦 حجم النسخة المضغوطة: {file_size_mb:.2f} MB")

    # تقسيم الملفات إذا أكبر من MAX_SIZE_MB
    if file_size_mb > MAX_SIZE_MB:
        parts = split_file(zip_file, MAX_SIZE_MB)
    else:
        parts = [zip_file]
    
    # إرسال كل جزء على Telegram مع try/except
    for part in parts:
        try:
            with open(part, "rb") as f:
                bot.send_document(chat_id=CHAT_ID, document=f)
            print(f"✅ تم إرسال: {part}")
        except Exception as e:
            print(f"❌ فشل إرسال {part}: {e}")
            try:
                bot.send_message(chat_id=CHAT_ID, text=f"❌ فشل إرسال النسخة: {part}\nالخطأ: {e}")
            except:
                pass

# ===== جدولة كل 30 دقيقة =====
schedule.every(30).minutes.do(backup_and_send)

print("🕒 بدأ جدولة النسخ الاحتياطية كل نصف ساعة...")
while True:
    schedule.run_pending()
    time.sleep(5)
