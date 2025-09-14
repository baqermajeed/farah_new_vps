from fastapi import APIRouter, HTTPException, Query, Depends
from typing import List, Optional
from bson import ObjectId

from models.patient import Patient
from models.user import User
from schemas.patient import (
    PatientCreate, PatientUpdate, PatientResponse,
    PatientList, PaymentCreate, PaymentResponse,
    OverdueNotification, PatientFilter, PaymentUpdate
)
from services.patient_service import patient_service
from utils.date_utils import DateUtils
from utils.notification_utils import NotificationUtils
from router.auth_router import get_current_user_dependency, get_admin_user
 

router = APIRouter(prefix="/patients", tags=["patients"])


@router.post("/", response_model=PatientResponse)
async def create_patient(patient: PatientCreate, current_user: User = Depends(get_current_user_dependency)):
    """إنشاء مريض جديد"""
    try:
        created_patient = await patient_service.create_patient(patient)

        # تحويل إلى PatientResponse
        response = PatientResponse(
            id=created_patient.id,
            name=created_patient.name,
            phone=created_patient.phone,
            total_amount=created_patient.total_amount,
            installments_months=created_patient.installments_months,
            notes=created_patient.notes,
            registration_date=created_patient.registration_date,
            is_completed=created_patient.is_completed,
            total_paid=created_patient.total_paid,
            remaining_amount=created_patient.remaining_amount,
            monthly_installment=created_patient.calculate_monthly_installment(),
            next_payment_date=created_patient.get_next_payment_date(),
            payments_count=len(created_patient.payments)
        )

        return response

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"خطأ في إنشاء المريض: {str(e)}")


@router.get("/", response_model=List[PatientList])
async def get_patients(
    name: Optional[str] = Query(None, description="فلترة بالاسم"),
    completed: Optional[bool] = Query(None, description="فلترة بالحالة (مكتمل/غير مكتمل)"),
    overdue_only: Optional[bool] = Query(False, description="عرض المتأخرات فقط"),
    current_user: User = Depends(get_current_user_dependency)
):
    """الحصول على جميع المرضى مع فلترة"""
    try:
        patients = await patient_service.get_all_patients(
            name_filter=name,
            completed_filter=completed,
            overdue_only=overdue_only
        )
        return patients

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"خطأ في استرجاع المرضى: {str(e)}")


@router.get("/search", response_model=List[PatientResponse])
async def search_patients(
    query: str = Query(..., description="البحث بالاسم أو رقم الهاتف"),
    current_user: User = Depends(get_current_user_dependency)
):
    """البحث عن مريض بالاسم أو رقم الهاتف"""
    try:
        patients = await patient_service.get_patient_by_name_or_phone(query)

        # تحويل إلى PatientResponse
        responses = []
        for patient in patients:
            response = PatientResponse(
                id=patient.id,
                name=patient.name,
                phone=patient.phone,
                total_amount=patient.total_amount,
                installments_months=patient.installments_months,
                notes=patient.notes,
                registration_date=patient.registration_date,
                is_completed=patient.is_completed,
                total_paid=patient.total_paid,
                remaining_amount=patient.remaining_amount,
                monthly_installment=patient.calculate_monthly_installment(),
                next_payment_date=patient.get_next_payment_date(),
                payments_count=len(patient.payments)
            )
            responses.append(response)

        return responses

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"خطأ في البحث عن المرضى: {str(e)}")


@router.get("/{patient_id}", response_model=PatientResponse)
async def get_patient(patient_id: str, current_user: User = Depends(get_current_user_dependency)):
    """الحصول على تفاصيل مريض معين"""
    try:
        patient = await patient_service.get_patient_by_id(patient_id)

        if not patient:
            raise HTTPException(status_code=404, detail="المريض غير موجود")

        # تحويل إلى PatientResponse
        response = PatientResponse(
            id=patient.id,
            name=patient.name,
            phone=patient.phone,
            total_amount=patient.total_amount,
            installments_months=patient.installments_months,
            notes=patient.notes,
            registration_date=patient.registration_date,
            is_completed=patient.is_completed,
            total_paid=patient.total_paid,
            remaining_amount=patient.remaining_amount,
            monthly_installment=patient.calculate_monthly_installment(),
            next_payment_date=patient.get_next_payment_date(),
            payments_count=len(patient.payments)
        )

        return response

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"خطأ في استرجاع المريض: {str(e)}")


@router.put("/{patient_id}", response_model=PatientResponse)
async def update_patient(patient_id: str, patient_update: PatientUpdate, current_user: User = Depends(get_admin_user)):
    """تحديث بيانات المريض"""
    try:
        updated_patient = await patient_service.update_patient(patient_id, patient_update)

        if not updated_patient:
            raise HTTPException(status_code=404, detail="المريض غير موجود أو لم يتم تحديث أي بيانات")

        # تحويل إلى PatientResponse
        response = PatientResponse(
            id=updated_patient.id,
            name=updated_patient.name,
            phone=updated_patient.phone,
            total_amount=updated_patient.total_amount,
            installments_months=updated_patient.installments_months,
            notes=updated_patient.notes,
            registration_date=updated_patient.registration_date,
            is_completed=updated_patient.is_completed,
            total_paid=updated_patient.total_paid,
            remaining_amount=updated_patient.remaining_amount,
            monthly_installment=updated_patient.calculate_monthly_installment(),
            next_payment_date=updated_patient.get_next_payment_date(),
            payments_count=len(updated_patient.payments)
        )

        return response

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"خطأ في تحديث المريض: {str(e)}")


@router.delete("/{patient_id}")
async def delete_patient(patient_id: str, current_user: User = Depends(get_admin_user)):
    """حذف مريض"""
    try:
        success = await patient_service.delete_patient(patient_id)

        if not success:
            raise HTTPException(status_code=404, detail="المريض غير موجود")

        return {"message": "تم حذف المريض بنجاح"}

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"خطأ في حذف المريض: {str(e)}")


@router.post("/{patient_id}/payments", response_model=PaymentResponse)
async def create_payment(patient_id: str, payment: PaymentCreate, current_user: User = Depends(get_current_user_dependency)):
    """إنشاء دفعة جديدة لمريض"""
    try:
        # التأكد من أن معرف المريض صحيح
        payment.patient_id = patient_id

        created_payment = await patient_service.create_payment(payment)

        if not created_payment:
            raise HTTPException(status_code=404, detail="المريض غير موجود")

        # جلب اسم المريض
        patient = await patient_service.get_patient_by_id(patient_id)
        patient_name = patient.name if patient else None

        # تحويل إلى PaymentResponse
        response = PaymentResponse(
            id=created_payment.id,
            patient_id=created_payment.patient_id,
            patient_name=patient_name,
            amount=created_payment.amount,
            payment_date=created_payment.payment_date,
            notes=created_payment.notes
        )

        return response

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"خطأ في إنشاء الدفعة: {str(e)}")


@router.get("/{patient_id}/payments", response_model=List[PaymentResponse])
async def get_patient_payments(patient_id: str, current_user: User = Depends(get_current_user_dependency)):
    """جلب جميع مدفوعات مريض معين"""
    try:
        # التحقق من وجود المريض
        patient = await patient_service.get_patient_by_id(patient_id)
        if not patient:
            raise HTTPException(status_code=404, detail="المريض غير موجود")

        # جلب المدفوعات
        payments = []
        for payment in patient.payments:
            payments.append(PaymentResponse(
                id=payment.id,
                patient_id=payment.patient_id,
                patient_name=patient.name,
                amount=payment.amount,
                payment_date=payment.payment_date,
                notes=payment.notes
            ))

        # ترتيب المدفوعات حسب التاريخ (الأحدث أولاً)
        payments.sort(key=lambda x: x.payment_date, reverse=True)

        return payments

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"خطأ في جلب مدفوعات المريض: {str(e)}")


@router.put("/{patient_id}/payments/{payment_id}", response_model=PaymentResponse)
async def update_payment(
    patient_id: str,
    payment_id: str,
    update: PaymentUpdate,
    current_user: User = Depends(get_admin_user)
):
    """تحديث دفعة (للمدير فقط)"""
    try:
        # التحقق من وجود المريض
        patient = await patient_service.get_patient_by_id(patient_id)
        if not patient:
            raise HTTPException(status_code=404, detail="المريض غير موجود")

        updated_payment = await patient_service.update_payment(payment_id, update)
        if not updated_payment:
            raise HTTPException(status_code=404, detail="الدفعة غير موجودة أو لم يتم تحديث أي بيانات")

        # إرجاع استجابة منسقة
        response = PaymentResponse(
            id=updated_payment.id,
            patient_id=updated_payment.patient_id,
            patient_name=patient.name,
            amount=updated_payment.amount,
            payment_date=updated_payment.payment_date,
            notes=updated_payment.notes
        )
        return response
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"خطأ في تحديث الدفعة: {str(e)}")


@router.delete("/{patient_id}/payments/{payment_id}")
async def delete_payment(patient_id: str, payment_id: str, current_user: User = Depends(get_admin_user)):
    """حذف دفعة (للمدير فقط)"""
    try:
        # التحقق من وجود المريض
        patient = await patient_service.get_patient_by_id(patient_id)
        if not patient:
            raise HTTPException(status_code=404, detail="المريض غير موجود")

        success = await patient_service.delete_payment(payment_id)
        if not success:
            raise HTTPException(status_code=404, detail="الدفعة غير موجودة")

        return {"message": "تم حذف الدفعة بنجاح"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"خطأ في حذف الدفعة: {str(e)}")


@router.get("/notifications/overdue", response_model=List[OverdueNotification])
async def get_overdue_notifications(current_user: User = Depends(get_current_user_dependency)):
    """الحصول على إشعارات المتأخرات"""
    try:
        notifications = await patient_service.get_overdue_notifications()
        return notifications

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"خطأ في استرجاع الإشعارات: {str(e)}")


 


@router.get("/upcoming-payments")
async def get_upcoming_payments(days_ahead: int = Query(7, description="عدد الأيام المقبلة"), current_user: User = Depends(get_current_user_dependency)):
    """الحصول على الدفعات القادمة"""
    try:
        # الحصول على جميع المرضى
        patients_data = await patient_service.get_all_patients()

        # تحويل إلى كائنات Patient
        patients = []
        for patient_data in patients_data:
            patient = await patient_service.get_patient_by_id(str(patient_data.id))
            if patient:
                patients.append(patient)

        # الحصول على الدفعات القادمة
        upcoming = NotificationUtils.get_upcoming_payments(patients, days_ahead)

        return {
            "upcoming_payments": upcoming,
            "total_count": len(upcoming),
            "date_range": f"خلال {days_ahead} أيام قادمة"
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"خطأ في استرجاع الدفعات القادمة: {str(e)}")


@router.get("/statistics/summary")
async def get_patients_statistics(current_user: User = Depends(get_current_user_dependency)):
    """الحصول على إحصائيات المرضى"""
    try:
        # الحصول على جميع المرضى
        all_patients = await patient_service.get_all_patients()

        # إحصائيات عامة
        total_patients = len(all_patients)
        completed_patients = len([p for p in all_patients if p.is_completed])
        active_patients = total_patients - completed_patients

        # إجمالي المبالغ
        total_amount = sum(p.total_amount for p in all_patients)
        total_paid = sum(p.total_amount - p.remaining_amount for p in all_patients)
        total_remaining = sum(p.remaining_amount for p in all_patients)

        # إشعارات المتأخرات
        overdue_notifications = await patient_service.get_overdue_notifications()
        overdue_summary = NotificationUtils.get_overdue_summary(overdue_notifications)

        return {
            "total_patients": total_patients,
            "completed_patients": completed_patients,
            "active_patients": active_patients,
            "total_amount": round(total_amount, 2),
            "total_paid": round(total_paid, 2),
            "total_remaining": round(total_remaining, 2),
            "overdue_summary": overdue_summary,
            "current_datetime": DateUtils.get_baghdad_now().isoformat()
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"خطأ في استرجاع الإحصائيات: {str(e)}")
