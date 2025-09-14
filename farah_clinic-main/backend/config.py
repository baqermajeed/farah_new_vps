import os
from typing import Optional


class Config:
    """إعدادات التطبيق (تُحمّل من متغيرات البيئة)"""

    # قاعدة البيانات
    MONGODB_URL: str = os.getenv("MONGODB_URL", "mongodb://localhost:27017")

    # التطبيق
    APP_NAME: str = os.getenv("APP_NAME", "Farah Dental Clinic API")
    APP_VERSION: str = os.getenv("APP_VERSION", "1.0.0")
    DEBUG: bool = os.getenv("DEBUG", "True").lower() == "true"

    # إعدادات JWT
    JWT_SECRET_KEY: str = os.getenv(
        "JWT_SECRET_KEY", "your-very-secure-secret-key-here-change-in-production"
    )
    JWT_ALGORITHM: str = os.getenv("JWT_ALGORITHM", "HS256")
    # مدة صلاحية Access Token: أقصر في الإنتاج (افتراضي 15 دقيقة)
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = int(
        os.getenv("JWT_ACCESS_TOKEN_EXPIRE_MINUTES")
        or ("43200" if DEBUG else "15")
    )

    # مدة صلاحية Refresh Token: افتراضياً 30 يوم
    JWT_REFRESH_TOKEN_EXPIRE_MINUTES: int = int(
        os.getenv("JWT_REFRESH_TOKEN_EXPIRE_MINUTES")
        or ("43200")
    )

    # إعدادات الأمان الأخرى
    BCRYPT_ROUNDS: int = int(os.getenv("BCRYPT_ROUNDS", "12"))


# إنشاء نسخة من الإعدادات لاستخدامها عبر المشروع
config = Config()


