#!/usr/bin/env python3
"""
ملف اختبار نظام عيادة الدكتورة فرح الأسنان
يحتوي على بيانات تجريبية واختبارات للوظائف الأساسية
"""

import asyncio
import json
from datetime import datetime, timedelta
from services.patient_service import patient_service
from services.database import db_service
from schemas.patient import PatientCreate, PaymentCreate
from utils.date_utils import DateUtils


async def create_sample_patients():
    """إنشاء مرضى تجريبيين"""
    print("🧪 إنشاء بيانات تجريبية...")

    sample_patients = [
        {
            "name": "أحمد محمد علي",
            "phone": "07701234567",
            "total_amount": 3000000,  # 3 مليون دينار
            "installments_months": 24,  # 24 شهر
            "notes": "علاج أسنان شامل"
        },
        {
            "name": "فاطمة حسن",
            "phone": "07709876543",
            "total_amount": 1500000,  # 1.5 مليون دينار
            "installments_months": 12,  # 12 شهر
            "notes": "تبييض أسنان"
        },
        {
            "name": "علي عبدالله",
            "phone": "07705556677",
            "total_amount": 5000000,  # 5 مليون دينار
            "installments_months": 36,  # 36 شهر
            "notes": "زراعة أسنان"
        },
        {
            "name": "سارة محمود",
            "phone": "07704443322",
            "total_amount": 800000,  # 800 ألف دينار
            "installments_months": 8,  # 8 أشهر
            "notes": "حشوات"
        }
    ]

    created_patients = []

    for patient_data in sample_patients:
        try:
            patient = PatientCreate(**patient_data)
            created = await patient_service.create_patient(patient)
            created_patients.append(created)
            print(f"✅ تم إنشاء المريض: {created.name}")
        except Exception as e:
            print(f"❌ خطأ في إنشاء المريض {patient_data['name']}: {e}")

    return created_patients


async def create_sample_payments(patients):
    """إنشاء مدفوعات تجريبية"""
    print("\n💰 إنشاء مدفوعات تجريبية...")

    baghdad_now = DateUtils.get_baghdad_now()

    for patient in patients:
        try:
            # حساب القسط الشهري
            monthly_installment = patient.total_amount / patient.installments_months

            # إنشاء بعض المدفوعات
            payments_count = min(3, patient.installments_months)  # 3 مدفوعات كحد أقصى للاختبار

            for i in range(payments_count):
                # تاريخ الدفعة (من شهرين مضت)
                payment_date = baghdad_now - timedelta(days=30 * (payments_count - i))

                payment_data = PaymentCreate(
                    patient_id=str(patient.id),
                    amount=monthly_installment,
                    notes=f"القسط رقم {i+1}"
                )

                created_payment = await patient_service.create_payment(payment_data)
                if created_payment:
                    print(f"✅ تم إنشاء دفعة للمريض {patient.name}: {created_payment.amount:.2f} دينار")
                else:
                    print(f"❌ فشل في إنشاء دفعة للمريض {patient.name}")

        except Exception as e:
            print(f"❌ خطأ في إنشاء مدفوعات للمريض {patient.name}: {e}")


async def test_system_features():
    """اختبار ميزات النظام"""
    print("\n🧪 اختبار ميزات النظام...")

    try:
        # اختبار الحصول على جميع المرضى
        all_patients = await patient_service.get_all_patients()
        print(f"✅ عدد المرضى في النظام: {len(all_patients)}")

        # اختبار البحث
        search_results = await patient_service.get_patient_by_name_or_phone("أحمد")
        print(f"✅ نتائج البحث عن 'أحمد': {len(search_results)} مريض")

        # اختبار الإشعارات المتأخرة
        overdue_notifications = await patient_service.get_overdue_notifications()
        print(f"✅ عدد الإشعارات المتأخرة: {len(overdue_notifications)}")

        # اختبار الإحصائيات
        stats = await patient_service.get_all_patients()
        total_amount = sum(p.total_amount for p in stats)
        total_paid = sum(p.total_amount - p.remaining_amount for p in stats)
        print(f"✅ إجمالي المبالغ: {total_amount:.2f} دينار")
        print(f"✅ إجمالي المدفوعات: {total_paid:.2f} دينار")
        print(f"✅ إجمالي المتبقي: {(total_amount - total_paid):.2f} دينار")

    except Exception as e:
        print(f"❌ خطأ في اختبار الميزات: {e}")


async def display_system_info():
    """عرض معلومات النظام"""
    print("\n📊 معلومات النظام:")
    print(f"   التاريخ والوقت الحالي في بغداد: {DateUtils.get_baghdad_now()}")
    print("   العملة: دينار عراقي")
    print("   توقيت النظام: GMT+3 (بغداد)")


async def main():
    """الدالة الرئيسية للاختبار"""
    print("🧪 اختبار نظام عيادة الدكتورة فرح الأسنان")
    print("=" * 60)

    try:
        # الاتصال بقاعدة البيانات
        await db_service.connect()

        # عرض معلومات النظام
        await display_system_info()

        # إنشاء بيانات تجريبية
        patients = await create_sample_patients()

        # إنشاء مدفوعات تجريبية
        if patients:
            await create_sample_payments(patients)

        # اختبار الميزات
        await test_system_features()

        print("\n✅ تم الانتهاء من الاختبار بنجاح!")
        print("\n📖 يمكنك الآن:")
        print("   • زيارة http://localhost:8000/docs لعرض وثائق API")
        print("   • استخدام أي أداة لاختبار API مثل Postman أو curl")
        print("   • تشغيل التطبيق الرئيسي بالأمر: python main.py")

    except Exception as e:
        print(f"❌ خطأ في الاختبار: {e}")
    finally:
        # قطع الاتصال
        await db_service.disconnect()


if __name__ == "__main__":
    asyncio.run(main())
