from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any
from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorCollection

from models.patient import Patient, Payment
from schemas.patient import (
    PatientCreate, PatientUpdate, PatientResponse,
    PatientList, PaymentCreate, OverdueNotification, PaymentUpdate
)
from services.database import db_service


class PatientService:
    """خدمة إدارة المرضى"""

    def __init__(self):
        self.patients_collection: AsyncIOMotorCollection = None
        self.payments_collection: AsyncIOMotorCollection = None

    async def initialize_collections(self):
        """تهيئة المجموعات"""
        if self.patients_collection is None:
            self.patients_collection = db_service.get_collection("patients")
        if self.payments_collection is None:
            self.payments_collection = db_service.get_collection("payments")

    async def create_patient(self, patient_data: PatientCreate) -> Patient:
        """إنشاء مريض جديد"""
        await self.initialize_collections()

        patient = Patient(
            name=patient_data.name,
            phone=patient_data.phone,
            total_amount=patient_data.total_amount,
            installments_months=patient_data.installments_months,
            notes=patient_data.notes,
            registration_date=patient_data.registration_date or datetime.now(),
            remaining_amount=patient_data.total_amount  # في البداية المبلغ المتبقي = المبلغ الكلي
        )

        # إدراج في قاعدة البيانات
        result = await self.patients_collection.insert_one(patient.dict(by_alias=True))

        # استرجاع المريض المُدرج
        created_patient = await self.patients_collection.find_one({"_id": result.inserted_id})
        return Patient(**created_patient)

    async def get_patient_by_id(self, patient_id: str) -> Optional[Patient]:
        """الحصول على مريض بالمعرف"""
        await self.initialize_collections()

        try:
            patient_data = await self.patients_collection.find_one({"_id": ObjectId(patient_id)})
            if patient_data:
                # الحصول على المدفوعات الخاصة بالمريض
                payments_data = await self.payments_collection.find({"patient_id": ObjectId(patient_id)}).to_list(length=None)
                patient_data["payments"] = [Payment(**payment) for payment in payments_data]

                patient = Patient(**patient_data)
                patient.calculate_remaining_amount()
                return patient
        except Exception as e:
            print(f"خطأ في الحصول على المريض: {e}")
        return None

    async def get_patient_by_name_or_phone(self, search_term: str) -> List[Patient]:
        """البحث عن مريض بالاسم أو رقم الهاتف"""
        await self.initialize_collections()

        # البحث بالاسم أو رقم الهاتف
        query = {
            "$or": [
                {"name": {"$regex": search_term, "$options": "i"}},
                {"phone": {"$regex": search_term, "$options": "i"}}
            ]
        }

        patients_data = await self.patients_collection.find(query).to_list(length=None)
        patients = []

        for patient_data in patients_data:
            # الحصول على المدفوعات
            payments_data = await self.payments_collection.find({"patient_id": patient_data["_id"]}).to_list(length=None)
            patient_data["payments"] = [Payment(**payment) for payment in payments_data]

            patient = Patient(**patient_data)
            patient.calculate_remaining_amount()
            patients.append(patient)

        return patients

    async def get_all_patients(
        self,
        name_filter: Optional[str] = None,
        completed_filter: Optional[bool] = None,
        overdue_only: Optional[bool] = None
    ) -> List[PatientList]:
        """الحصول على جميع المرضى مع فلترة"""
        await self.initialize_collections()

        query = {}

        # فلترة بالاسم
        if name_filter:
            query["name"] = {"$regex": name_filter, "$options": "i"}

        # فلترة بالحالة (مكتمل/غير مكتمل)
        if completed_filter is not None:
            query["is_completed"] = completed_filter

        patients_data = await self.patients_collection.find(query).to_list(length=None)
        patients = []

        for patient_data in patients_data:
            # الحصول على المدفوعات
            payments_data = await self.payments_collection.find({"patient_id": patient_data["_id"]}).to_list(length=None)
            patient_data["payments"] = [Payment(**payment) for payment in payments_data]

            patient = Patient(**patient_data)
            patient.calculate_remaining_amount()

            # فلترة المتأخرات إذا طُلب ذلك
            if overdue_only and not patient.is_overdue():
                continue

            patients.append(self._convert_to_patient_list(patient))

        return patients

    async def update_patient(self, patient_id: str, update_data: PatientUpdate) -> Optional[Patient]:
        """تحديث بيانات المريض"""
        await self.initialize_collections()

        try:
            # تحضير البيانات للتحديث
            update_dict = {k: v for k, v in update_data.dict(exclude_unset=True).items() if v is not None}

            if update_dict:
                result = await self.patients_collection.update_one(
                    {"_id": ObjectId(patient_id)},
                    {"$set": update_dict}
                )

                if result.modified_count > 0:
                    return await self.get_patient_by_id(patient_id)
        except Exception as e:
            print(f"خطأ في تحديث المريض: {e}")
        return None

    async def delete_patient(self, patient_id: str) -> bool:
        """حذف مريض"""
        await self.initialize_collections()

        try:
            # حذف المدفوعات أولاً
            await self.payments_collection.delete_many({"patient_id": ObjectId(patient_id)})

            # حذف المريض
            result = await self.patients_collection.delete_one({"_id": ObjectId(patient_id)})
            return result.deleted_count > 0
        except Exception as e:
            print(f"خطأ في حذف المريض: {e}")
        return False

    async def create_payment(self, payment_data: PaymentCreate) -> Optional[Payment]:
        """إنشاء دفعة جديدة"""
        await self.initialize_collections()

        try:
            patient_id = ObjectId(payment_data.patient_id)

            # التحقق من وجود المريض
            patient = await self.get_patient_by_id(payment_data.patient_id)
            if not patient:
                return None

            # إنشاء الدفعة
            payment = Payment(
                patient_id=patient_id,
                amount=payment_data.amount,
                payment_date=payment_data.payment_date or datetime.now(),
                notes=payment_data.notes
            )

            # إدراج الدفعة
            result = await self.payments_collection.insert_one(payment.dict(by_alias=True))

            # تحديث إجمالي المدفوعات للمريض
            await self.patients_collection.update_one(
                {"_id": patient_id},
                {"$inc": {"total_paid": payment_data.amount}}
            )

            # التحقق من اكتمال التقسيط
            updated_patient = await self.get_patient_by_id(payment_data.patient_id)
            if updated_patient and updated_patient.remaining_amount <= 0:
                await self.patients_collection.update_one(
                    {"_id": patient_id},
                    {"$set": {"is_completed": True}}
                )

            return payment

        except Exception as e:
            print(f"خطأ في إنشاء الدفعة: {e}")
        return None

    async def update_payment(self, payment_id: str, update_data: PaymentUpdate) -> Optional[Payment]:
        """تحديث دفعة"""
        await self.initialize_collections()
        try:
            update_dict = {k: v for k, v in update_data.dict(exclude_unset=True).items() if v is not None}
            if not update_dict:
                # لا يوجد شيء للتحديث
                payment = await self.payments_collection.find_one({"_id": ObjectId(payment_id)})
                return Payment(**payment) if payment else None

            result = await self.payments_collection.update_one(
                {"_id": ObjectId(payment_id)},
                {"$set": update_dict}
            )

            if result.modified_count > 0:
                updated = await self.payments_collection.find_one({"_id": ObjectId(payment_id)})
                return Payment(**updated) if updated else None
        except Exception as e:
            print(f"خطأ في تحديث الدفعة: {e}")
        return None

    async def delete_payment(self, payment_id: str) -> bool:
        """حذف دفعة"""
        await self.initialize_collections()
        try:
            # عند حذف الدفعة، يُفضّل خصمها من total_paid للمريض المرتبط
            payment_doc = await self.payments_collection.find_one({"_id": ObjectId(payment_id)})
            if not payment_doc:
                return False

            result = await self.payments_collection.delete_one({"_id": ObjectId(payment_id)})
            if result.deleted_count > 0:
                # خصم المبلغ من إجمالي المدفوعات
                await self.patients_collection.update_one(
                    {"_id": payment_doc["patient_id"]},
                    {"$inc": {"total_paid": -float(payment_doc.get("amount", 0))}}
                )
                return True
        except Exception as e:
            print(f"خطأ في حذف الدفعة: {e}")
        return False

    async def get_overdue_notifications(self) -> List[OverdueNotification]:
        """الحصول على إشعارات المتأخرات"""
        await self.initialize_collections()

        # الحصول على جميع المرضى غير المكتملين
        patients_data = await self.patients_collection.find({"is_completed": False}).to_list(length=None)
        notifications = []

        for patient_data in patients_data:
            # الحصول على المدفوعات
            payments_data = await self.payments_collection.find({"patient_id": patient_data["_id"]}).to_list(length=None)
            patient_data["payments"] = [Payment(**payment) for payment in payments_data]

            patient = Patient(**patient_data)
            patient.calculate_remaining_amount()

            if patient.is_overdue():
                next_payment_date = patient.get_next_payment_date()
                days_overdue = (datetime.now() - next_payment_date).days

                notification = OverdueNotification(
                    patient_id=patient.id,
                    patient_name=patient.name,
                    phone=patient.phone,
                    registration_date=patient.registration_date,
                    days_overdue=days_overdue,
                    total_amount=patient.total_amount,
                    remaining_amount=patient.remaining_amount,
                    monthly_installment=patient.calculate_monthly_installment(),
                    next_payment_date=next_payment_date
                )
                notifications.append(notification)

        return notifications

    def _convert_to_patient_list(self, patient: Patient) -> PatientList:
        """تحويل مريض إلى تنسيق القائمة"""
        return PatientList(
            id=patient.id,
            name=patient.name,
            phone=patient.phone,
            total_amount=patient.total_amount,
            remaining_amount=patient.remaining_amount,
            next_payment_date=patient.get_next_payment_date(),
            is_completed=patient.is_completed
        )


# إنشاء نسخة واحدة من خدمة المريض
patient_service = PatientService()
