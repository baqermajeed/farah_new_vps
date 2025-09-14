from datetime import timedelta
from fastapi import APIRouter, HTTPException, Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Optional

from models.user import UserCreate, UserLogin, UserResponse, Token
from services.simple_auth_service import simple_auth_service

router = APIRouter(prefix="/auth", tags=["authentication"])

# إعداد Bearer Token
security = HTTPBearer()


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(user_data: UserCreate):
    """تسجيل مستخدم جديد"""
    try:
        user = await simple_auth_service.create_user(user_data)
        return UserResponse(**user.to_dict())
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"خطأ في إنشاء المستخدم: {str(e)}"
        )


@router.post("/login", response_model=Token)
async def login(user_credentials: UserLogin):
    """تسجيل الدخول"""
    user = await simple_auth_service.authenticate_user(
        user_credentials.username, 
        user_credentials.password
    )
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="اسم المستخدم أو كلمة المرور غير صحيحة",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # إنشاء الرمز المميز
    access_token_expires = timedelta(minutes=30 * 24 * 60)  # 30 يوم
    access_token = simple_auth_service.create_access_token(
        data={"sub": user.username, "user_id": str(user.id)},
        expires_delta=access_token_expires
    )
    
    # تحديث آخر تسجيل دخول
    await simple_auth_service.update_last_login(user.username)
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "expires_in": int(access_token_expires.total_seconds())
    }


@router.get("/me", response_model=UserResponse)
async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """الحصول على بيانات المستخدم الحالي"""
    token_data = simple_auth_service.verify_token(credentials.credentials)
    
    if not token_data:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="رمز مميز غير صحيح أو منتهي الصلاحية",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    user = await simple_auth_service.get_user_by_username(token_data.username)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="المستخدم غير موجود",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    return UserResponse(**user.to_dict())


@router.post("/refresh", response_model=Token)
async def refresh_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """تجديد الرمز المميز"""
    token_data = simple_auth_service.verify_token(credentials.credentials)
    
    if not token_data:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="رمز مميز غير صحيح أو منتهي الصلاحية",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    user = await simple_auth_service.get_user_by_username(token_data.username)
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="المستخدم غير موجود أو غير نشط",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # إنشاء رمز مميز جديد
    access_token_expires = timedelta(minutes=30 * 24 * 60)  # 30 يوم
    access_token = simple_auth_service.create_access_token(
        data={"sub": user.username, "user_id": str(user.id)},
        expires_delta=access_token_expires
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "expires_in": int(access_token_expires.total_seconds())
    }


@router.post("/logout")
async def logout():
    """تسجيل الخروج (على العميل حذف الرمز المميز)"""
    return {"message": "تم تسجيل الخروج بنجاح"}


# دالة للحصول على المستخدم الحالي (للاستخدام في endpoints أخرى)
async def get_current_user_dependency(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """اعتماد للحصول على المستخدم الحالي"""
    token_data = simple_auth_service.verify_token(credentials.credentials)
    
    if not token_data:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="رمز مميز غير صحيح أو منتهي الصلاحية",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    user = await simple_auth_service.get_user_by_username(token_data.username)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="المستخدم غير موجود",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    return user


# دالة للتحقق من صلاحيات المدير
async def get_admin_user(current_user = Depends(get_current_user_dependency)):
    """اعتماد للتحقق من صلاحيات المدير"""
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="ليس لديك صلاحية للوصول إلى هذا المورد"
        )
    return current_user
