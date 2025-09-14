# ملف إعدادات مثالي
# انسخ هذا الملف إلى config.py وعدّل القيم حسب الحاجة

import os
from typing import Optional

class Config:
    """إعدادات التطبيق"""

    # قاعدة البيانات
    MONGODB_URL: str = os.getenv("MONGODB_URL", "mongodb://localhost:27017")

    # التطبيق
    APP_NAME: str = os.getenv("APP_NAME", "Farah Dental Clinic API")
    APP_VERSION: str = os.getenv("APP_VERSION", "1.0.0")
    DEBUG: bool = os.getenv("DEBUG", "True").lower() == "true"

    # الأمان
    SECRET_KEY: str = os.getenv("SECRET_KEY", "your-secret-key-change-this-in-production")
    JWT_SECRET_KEY: str = os.getenv("JWT_SECRET_KEY", "your-jwt-secret-change-this-in-production")

    # الإشعارات
    NOTIFICATION_DAYS_THRESHOLD: int = int(os.getenv("NOTIFICATION_DAYS_THRESHOLD", "1"))
    CRITICAL_OVERDUE_DAYS: int = int(os.getenv("CRITICAL_OVERDUE_DAYS", "30"))

# إنشاء نسخة من الإعدادات
config = Config()
