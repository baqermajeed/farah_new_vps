from datetime import timedelta
from fastapi import APIRouter, HTTPException, Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Optional

from models.user import UserCreate, UserLogin, UserResponse, Token, TokenPair, RefreshRequest
from config import config
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


@router.post("/login", response_model=TokenPair)
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
    access_token_expires = timedelta(minutes=config.JWT_ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = simple_auth_service.create_access_token(
        data={"sub": user.username, "user_id": str(user.id)},
        expires_delta=access_token_expires
    )
    refresh_token, _ = simple_auth_service.create_refresh_token(
        username=user.username,
        user_id=str(user.id),
    )
    
    # تحديث آخر تسجيل دخول
    await simple_auth_service.update_last_login(user.username)
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "expires_in": int(access_token_expires.total_seconds()),
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


@router.post("/refresh", response_model=TokenPair)
async def refresh_token(body: RefreshRequest):
    """تجديد الرمز المميز باستخدام refresh token (مع تدوير)."""
    verified = simple_auth_service.verify_refresh_token(body.refresh_token)
    if not verified:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token غير صحيح أو مُبطل أو منتهي",
        )

    token_data, jti = verified

    user = await simple_auth_service.get_user_by_username(token_data.username)
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="المستخدم غير موجود أو غير نشط",
        )

    # إنشاء access جديد وتدوير refresh
    access_token_expires = timedelta(minutes=config.JWT_ACCESS_TOKEN_EXPIRE_MINUTES)
    new_access_token = simple_auth_service.create_access_token(
        data={"sub": user.username, "user_id": str(user.id)},
        expires_delta=access_token_expires,
    )
    new_refresh_token = simple_auth_service.rotate_refresh_token(jti, user.username, str(user.id))

    return {
        "access_token": new_access_token,
        "refresh_token": new_refresh_token,
        "token_type": "bearer",
        "expires_in": int(access_token_expires.total_seconds()),
    }


@router.post("/logout")
async def logout(body: Optional[RefreshRequest] = None):
    """تسجيل الخروج: إبطال refresh token إن تم تمريره، وعلى العميل حذف access."""
    if body and body.refresh_token:
        simple_auth_service.revoke_refresh_token(body.refresh_token)
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
