from typing import List, Dict, Any
from datetime import datetime, timedelta
from models.patient import Patient
from schemas.patient import OverdueNotification
from utils.date_utils import DateUtils


class NotificationUtils:
    """معالجات مساعدة للإشعارات"""

    @staticmethod
    def create_overdue_notification(patient: Patient) -> OverdueNotification:
        """إنشاء إشعار متأخر لمريض"""
        next_payment_date = patient.get_next_payment_date()
        days_overdue = DateUtils.calculate_days_overdue(next_payment_date)

        return OverdueNotification(
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

    @staticmethod
    def format_notification_message(notification: OverdueNotification) -> str:
        """تنسيق رسالة الإشعار"""
        return f"""
تذكير بدفعة متأخرة:

المريض: {notification.patient_name}
رقم الهاتف: {notification.phone}
تاريخ التسجيل: {DateUtils.format_date_only(notification.registration_date)}
عدد الأيام المتأخرة: {notification.days_overdue} يوم
المبلغ الكلي: {notification.total_amount:.2f} دينار
المبلغ المتبقي: {notification.remaining_amount:.2f} دينار
القسط الشهري: {notification.monthly_installment:.2f} دينار
تاريخ الدفعة التالية: {DateUtils.format_date_only(notification.next_payment_date)}

يرجى تسوية الدفعة في أقرب وقت ممكن.
"""

    @staticmethod
    def get_overdue_summary(notifications: List[OverdueNotification]) -> Dict[str, Any]:
        """الحصول على ملخص المتأخرات"""
        if not notifications:
            return {
                "total_overdue_patients": 0,
                "total_overdue_amount": 0.0,
                "average_days_overdue": 0,
                "critical_cases": 0  # متأخرات أكثر من 30 يوم
            }

        total_amount = sum(n.remaining_amount for n in notifications)
        total_days = sum(n.days_overdue for n in notifications)
        critical_cases = len([n for n in notifications if n.days_overdue > 30])

        return {
            "total_overdue_patients": len(notifications),
            "total_overdue_amount": round(total_amount, 2),
            "average_days_overdue": round(total_days / len(notifications), 1),
            "critical_cases": critical_cases
        }

    @staticmethod
    def filter_notifications_by_severity(
        notifications: List[OverdueNotification],
        max_days: int = None
    ) -> List[OverdueNotification]:
        """فلترة الإشعارات حسب الخطورة"""
        if max_days is None:
            return notifications

        return [n for n in notifications if n.days_overdue <= max_days]

    @staticmethod
    def group_notifications_by_month(
        notifications: List[OverdueNotification]
    ) -> Dict[str, List[OverdueNotification]]:
        """تجميع الإشعارات حسب الشهر"""
        grouped = {}

        for notification in notifications:
            month_key = DateUtils.format_date_only(notification.next_payment_date)[:7]  # YYYY-MM

            if month_key not in grouped:
                grouped[month_key] = []

            grouped[month_key].append(notification)

        return grouped

    @staticmethod
    def get_upcoming_payments(patients: List[Patient], days_ahead: int = 7) -> List[Dict[str, Any]]:
        """الحصول على الدفعات القادمة خلال فترة محددة"""
        upcoming = []
        baghdad_now = DateUtils.get_baghdad_now()

        for patient in patients:
            if patient.is_completed:
                continue

            next_payment = patient.get_next_payment_date()
            days_until_payment = (next_payment - baghdad_now).days

            if 0 <= days_until_payment <= days_ahead:
                upcoming.append({
                    "patient_id": patient.id,
                    "patient_name": patient.name,
                    "phone": patient.phone,
                    "next_payment_date": next_payment,
                    "days_until_payment": days_until_payment,
                    "amount_due": patient.calculate_monthly_installment(),
                    "remaining_amount": patient.remaining_amount
                })

        # ترتيب حسب تاريخ الدفعة
        upcoming.sort(key=lambda x: x["next_payment_date"])

        return upcoming
