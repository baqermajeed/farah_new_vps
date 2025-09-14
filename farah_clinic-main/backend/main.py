from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from services.database import db_service
from services.simple_auth_service import simple_auth_service
 
from router.patient_router import router as patient_router
from router.auth_router import router as auth_router
from middleware.auth_middleware import AuthMiddleware


@asynccontextmanager
async def lifespan(app: FastAPI):
    """إدارة عمر التطبيق"""
    # بداية التطبيق
    print("🚀 بدء تشغيل تطبيق عيادة الدكتورة فرح الأسنان...")
    await db_service.connect()
    
    # إنشاء المدير الافتراضي
    await simple_auth_service.create_default_admin()
    # إنشاء مستخدم عادي افتراضي
    await simple_auth_service.create_default_user()

    yield

    # نهاية التطبيق
    print("🛑 إيقاف التطبيق...")
    await db_service.disconnect()


# إنشاء تطبيق FastAPI
app = FastAPI(
    title="نظام عيادة الدكتورة فرح الأسنان",
    description="نظام إدارة المرضى والتقسيط لعيادة الأسنان",
    version="1.0.0",
    lifespan=lifespan
)

# إعداد CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # في الإنتاج، حدد النطاقات المسموحة
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# إضافة middleware للمصادقة
app.add_middleware(AuthMiddleware)

# تضمين المعالجات
app.include_router(auth_router)
app.include_router(patient_router)

 


@app.get("/")
async def root():
    """صفحة الترحيب"""
    return {
        "message": "مرحباً بك في نظام عيادة الدكتورة فرح الأسنان",
        "version": "1.0.0",
        "description": "نظام إدارة المرضى والتقسيط",
        "endpoints": {
            "authentication": "/auth",
            "patients": "/patients",
            "documentation": "/docs",
            "statistics": "/patients/statistics/summary"
        }
    }


@app.get("/health")
async def health_check():
    """فحص حالة التطبيق"""
    try:
        # اختبار الاتصال بقاعدة البيانات
        db_service.client.admin.command('ping')
        return {
            "status": "healthy",
            "database": "connected",
            "timestamp": "2025-01-10T12:00:00Z"  # سيتم تحديثه تلقائياً
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "database": "disconnected",
            "error": str(e)
        }


@app.get("/bootstrap")
async def bootstrap_data():
    """جلب جميع البيانات المطلوبة للتطبيق دفعة واحدة"""
    try:
        from services.patient_service import patient_service
        
        # جلب جميع المرضى
        patients_data = await patient_service.get_all_patients()
        
        # جلب الإحصائيات
        from router.patient_router import get_patients_statistics
        from models.user import User
        from router.auth_router import get_current_user_dependency
        
        # إنشاء مستخدم مؤقت للحصول على الإحصائيات
        class MockUser:
            def __init__(self):
                self.id = "bootstrap_user"
                self.username = "bootstrap"
                self.is_admin = True
        
        # جلب الإحصائيات
        stats_response = await get_patients_statistics(MockUser())
        
        # تحويل المرضى إلى تنسيق مناسب
        patients = []
        payments = []
        
        for patient_data in patients_data:
            # جلب المريض الكامل مع المدفوعات
            full_patient = await patient_service.get_patient_by_id(str(patient_data.id))
            if full_patient:
                patients.append({
                    "id": str(full_patient.id),
                    "name": full_patient.name,
                    "phone": full_patient.phone,
                    "total_amount": full_patient.total_amount,
                    "installments_months": full_patient.installments_months,
                    "notes": full_patient.notes,
                    "registration_date": full_patient.registration_date.isoformat(),
                    "is_completed": full_patient.is_completed,
                    "total_paid": full_patient.total_paid,
                    "remaining_amount": full_patient.remaining_amount,
                    "monthly_installment": full_patient.calculate_monthly_installment(),
                    "next_payment_date": full_patient.get_next_payment_date().isoformat(),
                    "payments_count": len(full_patient.payments)
                })
                
                # إضافة المدفوعات
                for payment in full_patient.payments:
                    payments.append({
                        "id": str(payment.id),
                        "patient_id": str(payment.patient_id),
                        "patient_name": full_patient.name,  # إضافة اسم المريض
                        "amount": payment.amount,
                        "payment_date": payment.payment_date.isoformat(),
                        "notes": payment.notes
                    })
        
        return {
            "patients": patients,
            "payments": payments,
            "statistics": stats_response
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"خطأ في جلب بيانات النظام: {str(e)}")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
