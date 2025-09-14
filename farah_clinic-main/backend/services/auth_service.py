from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from config import config
from motor.motor_asyncio import AsyncIOMotorCollection
from bson import ObjectId

from models.user import User, UserCreate, UserLogin, Token, TokenData
from services.database import db_service

# إعدادات JWT من متغيرات البيئة
SECRET_KEY = config.JWT_SECRET_KEY
ALGORITHM = config.JWT_ALGORITHM
ACCESS_TOKEN_EXPIRE_MINUTES = config.JWT_ACCESS_TOKEN_EXPIRE_MINUTES

# إعداد تشفير كلمات المرور
pwd_context = CryptContext(
    schemes=["bcrypt"],
    deprecated="auto",
    bcrypt__rounds=config.BCRYPT_ROUNDS,
)


class AuthService:
    """خدمة المصادقة"""

    def __init__(self):
        self.users_collection: AsyncIOMotorCollection = None

    async def initialize_collection(self):
        """تهيئة مجموعة المستخدمين"""
        if self.users_collection is None:
            self.users_collection = db_service.get_collection("users")

    def create_access_token(self, data: dict, expires_delta: Optional[timedelta] = None):
        """إنشاء رمز مميز للوصول"""
        to_encode = data.copy()
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        
        to_encode.update({"exp": expire})
        encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
        return encoded_jwt

    def verify_token(self, token: str) -> Optional[TokenData]:
        """التحقق من صحة الرمز المميز"""
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            username: str = payload.get("sub")
            user_id: str = payload.get("user_id")
            
            if username is None or user_id is None:
                return None
                
            return TokenData(username=username, user_id=user_id)
        except JWTError:
            return None

    async def create_user(self, user_data: UserCreate) -> User:
        """إنشاء مستخدم جديد"""
        await self.initialize_collection()

        # التحقق من عدم وجود اسم مستخدم مكرر
        existing_user = await self.users_collection.find_one({"username": user_data.username})
        if existing_user:
            raise ValueError("اسم المستخدم موجود بالفعل")

        # إنشاء المستخدم
        user = User(
            username=user_data.username,
            email=user_data.email,
            full_name=user_data.full_name,
            hashed_password=User.hash_password(user_data.password),
            is_admin=user_data.is_admin
        )

        # إدراج في قاعدة البيانات
        result = await self.users_collection.insert_one(user.dict(by_alias=True))
        
        # استرجاع المستخدم المُدرج
        created_user = await self.users_collection.find_one({"_id": result.inserted_id})
        return User(**created_user)

    async def authenticate_user(self, username: str, password: str) -> Optional[User]:
        """مصادقة المستخدم"""
        await self.initialize_collection()

        user_data = await self.users_collection.find_one({"username": username})
        if not user_data:
            return None

        user = User(**user_data)
        if not user.verify_password(password):
            return None

        if not user.is_active:
            return None

        return user

    async def get_user_by_username(self, username: str) -> Optional[User]:
        """الحصول على مستخدم بالاسم"""
        await self.initialize_collection()

        user_data = await self.users_collection.find_one({"username": username})
        if user_data:
            return User(**user_data)
        return None

    async def get_user_by_id(self, user_id: str) -> Optional[User]:
        """الحصول على مستخدم بالمعرف"""
        await self.initialize_collection()

        try:
            user_data = await self.users_collection.find_one({"_id": ObjectId(user_id)})
            if user_data:
                return User(**user_data)
        except Exception:
            pass
        return None

    async def update_last_login(self, username: str):
        """تحديث آخر تسجيل دخول"""
        await self.initialize_collection()

        await self.users_collection.update_one(
            {"username": username},
            {"$set": {"last_login": datetime.now()}}
        )

    async def create_default_admin(self):
        """إنشاء مدير افتراضي إذا لم يكن موجوداً"""
        try:
            await self.initialize_collection()

            # التحقق من وجود مدير
            admin_exists = await self.users_collection.find_one({"is_admin": True})
            if admin_exists:
                print("✅ المدير موجود بالفعل")
                return

            # إنشاء مدير افتراضي
            admin_user = UserCreate(
                username="admin",
                email="admin@farahdental.com",
                full_name="مدير النظام",
                password="admin123",  # يجب تغييرها في الإنتاج
                is_admin=True
            )

            await self.create_user(admin_user)
            print("✅ تم إنشاء المدير الافتراضي: admin / admin123")
            
        except Exception as e:
            print(f"⚠️ خطأ في إنشاء المدير الافتراضي: {e}")
            print("💡 يمكنك إنشاء المدير يدوياً عبر API")

    def get_password_hash(self, password: str) -> str:
        """تشفير كلمة المرور"""
        return pwd_context.hash(password)

    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        """التحقق من كلمة المرور"""
        return pwd_context.verify(plain_password, hashed_password)


# إنشاء نسخة واحدة من خدمة المصادقة
auth_service = AuthService()
