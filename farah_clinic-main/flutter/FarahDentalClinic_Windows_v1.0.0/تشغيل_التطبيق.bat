@echo off
chcp 65001 >nul
echo تشغيل نظام إدارة عيادة الأسنان - فرح...
echo Starting Farah Dental Clinic Management System...
echo.

REM التحقق من وجود الملفات المطلوبة
if not exist "farah_dental_clinic_app.exe" (
    echo خطأ: الملف التنفيذي غير موجود!
    echo Error: Executable file not found!
    pause
    exit /b 1
)

if not exist "flutter_windows.dll" (
    echo خطأ: مكتبة Flutter غير موجودة!
    echo Error: Flutter library not found!
    pause
    exit /b 1
)

if not exist "printing_plugin.dll" (
    echo خطأ: مكتبة الطباعة غير موجودة!
    echo Error: Printing plugin not found!
    pause
    exit /b 1
)

echo جميع الملفات موجودة، يتم تشغيل التطبيق...
echo All files present, starting application...
echo.

REM تشغيل التطبيق
start "" "farah_dental_clinic_app.exe"

echo تم تشغيل التطبيق بنجاح!
echo Application started successfully!
timeout /t 3 /nobreak >nul
