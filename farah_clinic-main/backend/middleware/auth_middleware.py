from fastapi import Request, HTTPException, status
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.types import ASGIApp

from services.simple_auth_service import simple_auth_service


class AuthMiddleware(BaseHTTPMiddleware):
    """Middleware للتحقق من المصادقة"""

    def __init__(self, app: ASGIApp, protected_paths: list = None):
        super().__init__(app)
        # المسارات المحمية (تتطلب مصادقة)
        self.protected_paths = protected_paths or [
            "/patients",
            "/auth/me"
        ]
        # المسارات المستثناة من المصادقة
        self.excluded_paths = [
            "/",
            "/health",
            "/docs",
            "/redoc",
            "/openapi.json",
            "/auth/login",
            "/auth/register",
            "/auth/refresh"
        ]

    async def dispatch(self, request: Request, call_next):
        """معالجة الطلب والتحقق من المصادقة"""
        
        # التحقق من المسار
        if self._is_excluded_path(request.url.path):
            return await call_next(request)
        
        # التحقق من المسارات المحمية
        if self._is_protected_path(request.url.path):
            # التحقق من وجود Authorization header
            authorization = request.headers.get("Authorization")
            
            if not authorization:
                return JSONResponse(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    content={
                        "detail": "مطلوب رمز مصادقة",
                        "error_code": "MISSING_TOKEN"
                    },
                    headers={"WWW-Authenticate": "Bearer"}
                )
            
            # التحقق من تنسيق Bearer Token
            if not authorization.startswith("Bearer "):
                return JSONResponse(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    content={
                        "detail": "تنسيق رمز المصادقة غير صحيح",
                        "error_code": "INVALID_TOKEN_FORMAT"
                    },
                    headers={"WWW-Authenticate": "Bearer"}
                )
            
            # استخراج الرمز المميز
            token = authorization.split(" ")[1]
            
            # التحقق من صحة الرمز المميز
            token_data = simple_auth_service.verify_token(token)
            
            if not token_data:
                return JSONResponse(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    content={
                        "detail": "رمز مميز غير صحيح أو منتهي الصلاحية",
                        "error_code": "INVALID_TOKEN"
                    },
                    headers={"WWW-Authenticate": "Bearer"}
                )
            
            # إضافة بيانات المستخدم إلى الطلب
            request.state.user_id = token_data.user_id
            request.state.username = token_data.username
        
        return await call_next(request)

    def _is_excluded_path(self, path: str) -> bool:
        """التحقق من أن المسار مستثنى من المصادقة"""
        return any(path.startswith(excluded) for excluded in self.excluded_paths)

    def _is_protected_path(self, path: str) -> bool:
        """التحقق من أن المسار محمي ويتطلب مصادقة"""
        return any(path.startswith(protected) for protected in self.protected_paths)


class AdminMiddleware(BaseHTTPMiddleware):
    """Middleware للتحقق من صلاحيات المدير"""

    def __init__(self, app: ASGIApp, admin_paths: list = None):
        super().__init__(app)
        # المسارات التي تتطلب صلاحيات مدير
        self.admin_paths = admin_paths or [
            "/admin",
            "/users"
        ]

    async def dispatch(self, request: Request, call_next):
        """معالجة الطلب والتحقق من صلاحيات المدير"""
        
        # التحقق من المسار
        if not self._is_admin_path(request.url.path):
            return await call_next(request)
        
        # التحقق من وجود بيانات المستخدم
        if not hasattr(request.state, 'username'):
            return JSONResponse(
                status_code=status.HTTP_401_UNAUTHORIZED,
                content={
                    "detail": "مطلوب تسجيل دخول",
                    "error_code": "AUTHENTICATION_REQUIRED"
                }
            )
        
        # التحقق من صلاحيات المدير
        try:
            user = await simple_auth_service.get_user_by_username(request.state.username)
            if not user or not user.is_admin:
                return JSONResponse(
                    status_code=status.HTTP_403_FORBIDDEN,
                    content={
                        "detail": "ليس لديك صلاحية للوصول إلى هذا المورد",
                        "error_code": "INSUFFICIENT_PERMISSIONS"
                    }
                )
        except Exception as e:
            return JSONResponse(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                content={
                    "detail": "خطأ في التحقق من الصلاحيات",
                    "error_code": "PERMISSION_CHECK_ERROR"
                }
            )
        
        return await call_next(request)

    def _is_admin_path(self, path: str) -> bool:
        """التحقق من أن المسار يتطلب صلاحيات مدير"""
        return any(path.startswith(admin_path) for admin_path in self.admin_paths)
