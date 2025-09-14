@echo off
chcp 65001 >nul
title نظام عيادة الدكتورة فرح الأسنان

echo.
echo ========================================
echo    نظام عيادة الدكتورة فرح الأسنان
echo ========================================
echo.

echo فحص المتطلبات...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python غير مثبت أو غير متوفر في PATH
    echo يرجى تثبيت Python 3.8 أو أحدث من https://python.org
    pause
    exit /b 1
)

echo ✅ Python متوفر
echo.

echo تثبيت المتطلبات...
pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo ❌ فشل في تثبيت المتطلبات
    pause
    exit /b 1
)

echo ✅ تم تثبيت المتطلبات
echo.

echo فحص الاتصال بقاعدة البيانات...
python -c "import pymongo; client = pymongo.MongoClient('mongodb://localhost:27017', serverSelectionTimeoutMS=3000); client.admin.command('ping'); client.close(); print('✅ MongoDB متصل')" 2>nul
if %errorlevel% neq 0 (
    echo ❌ MongoDB غير متصل
    echo تأكد من تشغيل MongoDB على المنفذ 27017
    echo للمساعدة في تثبيت MongoDB: https://docs.mongodb.com/manual/tutorial/install-mongodb-on-windows/
    pause
    exit /b 1
)

echo.
echo ========================================
echo          بدء تشغيل الخادم
echo ========================================
echo.
echo سيتم تشغيل الخادم على: http://localhost:8000
echo وثائق API: http://localhost:8000/docs
echo.
echo لإيقاف الخادم اضغط Ctrl+C
echo.

python main.py

echo.
echo تم إيقاف الخادم
pause
