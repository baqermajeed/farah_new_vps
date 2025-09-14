import os
from motor.motor_asyncio import AsyncIOMotorClient
from pymongo.errors import ConnectionFailure
from datetime import datetime, timedelta


class DatabaseService:
    """خدمة قاعدة البيانات"""

    def __init__(self):
        self.client = None
        self.database = None

    async def connect(self):
        """الاتصال بقاعدة البيانات"""
        try:
            # استخدام MongoDB المحلي أو من متغير البيئة
            mongo_url = os.getenv("MONGODB_URL", "mongodb://farah:Farah435@localhost:27017/farah_dental_clinic")

            
            # إنشاء الاتصال
            self.client = AsyncIOMotorClient(mongo_url)
            self.database = self.client["farah_dental_clinic"]
            
            # اختبار الاتصال
            await self.client.admin.command('ping')
            print("✅ تم الاتصال بقاعدة البيانات MongoDB بنجاح")
            
            # التحقق من إعدادات المصادقة
            try:
                # محاولة قراءة من قاعدة البيانات لاختبار الصلاحيات
                test_collection = self.database["test_auth"]
                await test_collection.find_one()
                print("✅ تم التحقق من صلاحيات القراءة والكتابة")
            except Exception as perm_error:
                print(f"⚠️ تحذير: مشكلة في الصلاحيات - {perm_error}")
                print("💡 قد تحتاج إلى إعداد مصادقة MongoDB أو تشغيله بدون مصادقة")

        except ConnectionFailure as e:
            print(f"❌ فشل في الاتصال بقاعدة البيانات: {e}")
            print("💡 تأكد من أن MongoDB يعمل وأن بيانات المصادقة صحيحة")
            raise
        except Exception as e:
            print(f"❌ خطأ غير متوقع في الاتصال بقاعدة البيانات: {e}")
            raise

    async def disconnect(self):
        """قطع الاتصال بقاعدة البيانات"""
        if self.client:
            self.client.close()
            print("🔌 تم قطع الاتصال بقاعدة البيانات")

    def get_collection(self, collection_name: str):
        """الحصول على مجموعة من قاعدة البيانات"""
        return self.database[collection_name]


# إنشاء نسخة واحدة من خدمة قاعدة البيانات
db_service = DatabaseService()
