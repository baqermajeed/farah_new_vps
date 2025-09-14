from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, EmailStr
from bson import ObjectId
from passlib.context import CryptContext

# إعداد تشفير كلمات المرور
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class User(BaseModel):
    """نموذج المستخدم"""
    id: Optional[str] = Field(default_factory=lambda: str(ObjectId()), alias="_id")
    username: str = Field(..., min_length=3, max_length=50, description="اسم المستخدم")
    email: Optional[EmailStr] = Field(None, description="البريد الإلكتروني")
    full_name: str = Field(..., min_length=2, max_length=100, description="الاسم الكامل")
    hashed_password: str = Field(..., description="كلمة المرور المشفرة")
    is_active: bool = Field(default=True, description="هل المستخدم نشط")
    is_admin: bool = Field(default=False, description="هل المستخدم مدير")
    created_at: datetime = Field(default_factory=datetime.now, description="تاريخ الإنشاء")
    last_login: Optional[datetime] = Field(None, description="آخر تسجيل دخول")

    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True
        json_encoders = {ObjectId: str}

    @staticmethod
    def hash_password(password: str) -> str:
        """تشفير كلمة المرور"""
        return pwd_context.hash(password)

    def verify_password(self, password: str) -> bool:
        """التحقق من كلمة المرور"""
        return pwd_context.verify(password, self.hashed_password)

    def to_dict(self) -> dict:
        """تحويل إلى قاموس مع استبعاد كلمة المرور"""
        user_dict = self.dict()
        user_dict.pop("hashed_password", None)
        return user_dict


class UserCreate(BaseModel):
    """نموذج إنشاء مستخدم جديد"""
    username: str = Field(..., min_length=3, max_length=50, description="اسم المستخدم")
    email: Optional[EmailStr] = Field(None, description="البريد الإلكتروني")
    full_name: str = Field(..., min_length=2, max_length=100, description="الاسم الكامل")
    password: str = Field(..., min_length=6, description="كلمة المرور")
    is_admin: bool = Field(default=False, description="هل المستخدم مدير")


class UserLogin(BaseModel):
    """نموذج تسجيل الدخول"""
    username: str = Field(..., description="اسم المستخدم")
    password: str = Field(..., description="كلمة المرور")


class UserResponse(BaseModel):
    """نموذج استجابة المستخدم"""
    id: str
    username: str
    email: Optional[str]
    full_name: str
    is_active: bool
    is_admin: bool
    created_at: datetime
    last_login: Optional[datetime]


class Token(BaseModel):
    """نموذج الرمز المميز"""
    access_token: str
    token_type: str = "bearer"
    expires_in: int  # بالثواني


class TokenData(BaseModel):
    """بيانات الرمز المميز"""
    username: Optional[str] = None
    user_id: Optional[str] = None
