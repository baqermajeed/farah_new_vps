"""
خدمة مصادقة مبسطة للتطوير
تعمل بدون قاعدة بيانات مؤقتاً لحل مشكلة MongoDB
"""

from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext

from models.user import User, UserCreate, UserLogin, Token, TokenData

# إعدادات JWT
SECRET_KEY = "your-secret-key-here-change-in-production"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30 * 24 * 60  # 30 يوم

# إعداد تشفير كلمات المرور
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# مستخدم افتراضي في الذاكرة (للتطوير فقط)
DEFAULT_ADMIN = {
    "id": "admin_id_123",
    "username": "admin",
    "email": "admin@farahdental.com",
    "full_name": "مدير النظام",
    "hashed_password": pwd_context.hash("admin123"),
    "is_active": True,
    "is_admin": True,
    "created_at": datetime.now(),
    "last_login": None
}

# مستخدم عادي افتراضي (للتطوير فقط)
DEFAULT_USER = {
    "id": "user_id_123",
    "username": "user",
    "email": "user@farahdental.com",
    "full_name": "مستخدم عادي",
    "hashed_password": pwd_context.hash("user123"),
    "is_active": True,
    "is_admin": False,
    "created_at": datetime.now(),
    "last_login": None
}

# قائمة المستخدمين في الذاكرة (للتطوير فقط)
MEMORY_USERS = [DEFAULT_ADMIN, DEFAULT_USER]


class SimpleAuthService:
    """خدمة مصادقة مبسطة للتطوير"""

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
        # التحقق من عدم وجود اسم مستخدم مكرر
        for existing_user in MEMORY_USERS:
            if existing_user["username"] == user_data.username:
                raise ValueError("اسم المستخدم موجود بالفعل")

        # إنشاء المستخدم
        new_user = {
            "id": f"user_{len(MEMORY_USERS) + 1}",
            "username": user_data.username,
            "email": user_data.email,
            "full_name": user_data.full_name,
            "hashed_password": pwd_context.hash(user_data.password),
            "is_active": True,
            "is_admin": user_data.is_admin,
            "created_at": datetime.now(),
            "last_login": None
        }

        MEMORY_USERS.append(new_user)
        return User(**new_user)

    async def authenticate_user(self, username: str, password: str) -> Optional[User]:
        """مصادقة المستخدم"""
        for user_data in MEMORY_USERS:
            if user_data["username"] == username:
                if pwd_context.verify(password, user_data["hashed_password"]):
                    if user_data["is_active"]:
                        return User(**user_data)
        return None

    async def get_user_by_username(self, username: str) -> Optional[User]:
        """الحصول على مستخدم بالاسم"""
        for user_data in MEMORY_USERS:
            if user_data["username"] == username:
                return User(**user_data)
        return None

    async def get_user_by_id(self, user_id: str) -> Optional[User]:
        """الحصول على مستخدم بالمعرف"""
        for user_data in MEMORY_USERS:
            if user_data["id"] == user_id:
                return User(**user_data)
        return None

    async def update_last_login(self, username: str):
        """تحديث آخر تسجيل دخول"""
        for user_data in MEMORY_USERS:
            if user_data["username"] == username:
                user_data["last_login"] = datetime.now()
                break

    async def create_default_admin(self):
        """إنشاء مدير افتراضي إذا لم يكن موجوداً"""
        # المدير الافتراضي موجود بالفعل في MEMORY_USERS
        print("✅ المدير الافتراضي جاهز: admin / admin123")

    async def create_default_user(self):
        """إنشاء مستخدم افتراضي عادي إذا لم يكن موجوداً"""
        # المستخدم الافتراضي موجود بالفعل في MEMORY_USERS
        print("✅ المستخدم العادي جاهز: user / user123")

    def get_password_hash(self, password: str) -> str:
        """تشفير كلمة المرور"""
        return pwd_context.hash(password)

    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        """التحقق من كلمة المرور"""
        return pwd_context.verify(plain_password, hashed_password)


# إنشاء نسخة واحدة من خدمة المصادقة المبسطة
simple_auth_service = SimpleAuthService()
