#!/usr/bin/env python3
"""
ملف تشغيل سريع لنظام عيادة الدكتورة فرح الأسنان
"""

import os
import sys
import subprocess
from pathlib import Path


def check_requirements():
    """فحص المتطلبات"""
    print("🔍 فحص المتطلبات...")

    # فحص Python
    if sys.version_info < (3, 8):
        print("❌ يتطلب Python 3.8 أو أحدث")
        return False

    print(f"✅ Python {sys.version.split()[0]}")

    # فحص MongoDB (محاولة الاتصال)
    try:
        import pymongo
        from pymongo.errors import ConnectionFailure

        client = pymongo.MongoClient("mongodb://localhost:27017", serverSelectionTimeoutMS=3000)
        client.admin.command('ping')
        print("✅ MongoDB متصل")
        client.close()
    except ConnectionFailure:
        print("❌ MongoDB غير متصل. تأكد من تشغيل MongoDB")
        print("   لتثبيت MongoDB على Windows: https://docs.mongodb.com/manual/tutorial/install-mongodb-on-windows/")
        return False
    except ImportError:
        print("❌ مكتبة pymongo غير مثبتة")
        return False

    return True


def install_dependencies():
    """تثبيت المتطلبات"""
    print("📦 تثبيت المتطلبات...")

    requirements_file = Path(__file__).parent / "requirements.txt"
    if not requirements_file.exists():
        print("❌ ملف requirements.txt غير موجود")
        return False

    try:
        subprocess.check_call([
            sys.executable, "-m", "pip", "install", "-r", str(requirements_file)
        ])
        print("✅ تم تثبيت المتطلبات")
        return True
    except subprocess.CalledProcessError:
        print("❌ فشل في تثبيت المتطلبات")
        return False


def start_server():
    """تشغيل الخادم"""
    print("🚀 تشغيل الخادم...")

    try:
        import uvicorn
        from main import app

        print("✅ بدء تشغيل الخادم على http://localhost:8000")
        print("📖 وثائق API: http://localhost:8000/docs")
        print("🛑 لإيقاف الخادم اضغط Ctrl+C")

        uvicorn.run(
            "main:app",
            host="0.0.0.0",
            port=8000,
            reload=True,
            log_level="info"
        )

    except ImportError:
        print("❌ فشل في استيراد uvicorn")
        return False
    except KeyboardInterrupt:
        print("\n🛑 تم إيقاف الخادم")
        return True
    except Exception as e:
        print(f"❌ خطأ في تشغيل الخادم: {e}")
        return False


def main():
    """الدالة الرئيسية"""
    print("🏥 نظام عيادة الدكتورة فرح الأسنان")
    print("=" * 50)

    # فحص المتطلبات
    if not check_requirements():
        print("\n🔧 يرجى حل المشاكل أعلاه ثم تشغيل الملف مرة أخرى")
        input("اضغط Enter للخروج...")
        return

    # تثبيت المتطلبات إذا لم تكن مثبتة
    try:
        import fastapi
        import motor
        import pymongo
        print("✅ جميع المكتبات المطلوبة مثبتة")
    except ImportError:
        if not install_dependencies():
            print("\n🔧 يرجى تثبيت المتطلبات يدوياً:")
            print("   pip install -r requirements.txt")
            input("اضغط Enter للخروج...")
            return

    print("\n" + "=" * 50)

    # تشغيل الخادم
    start_server()


if __name__ == "__main__":
    main()
