from datetime import datetime, timedelta
import pytz


class DateUtils:
    """معالجات مساعدة للتاريخ والوقت"""

    # توقيت بغداد (GMT+3)
    BAGHDAD_TZ = pytz.timezone('Asia/Baghdad')

    @staticmethod
    def get_baghdad_now() -> datetime:
        """الحصول على التاريخ والوقت الحالي في بغداد"""
        return datetime.now(DateUtils.BAGHDAD_TZ)

    @staticmethod
    def convert_to_baghdad_time(dt: datetime) -> datetime:
        """تحويل تاريخ إلى توقيت بغداد"""
        if dt.tzinfo is None:
            # إذا كان التاريخ بدون توقيت، نفترض أنه UTC
            dt = pytz.UTC.localize(dt)

        return dt.astimezone(DateUtils.BAGHDAD_TZ)

    @staticmethod
    def calculate_next_payment_date(last_payment_date: datetime, months: int = 1) -> datetime:
        """حساب تاريخ الدفعة التالية"""
        # إضافة الأشهر المطلوبة
        next_date = last_payment_date + timedelta(days=30 * months)

        # التأكد من أن التاريخ في اليوم الأول من الشهر
        next_date = next_date.replace(day=1)

        return DateUtils.convert_to_baghdad_time(next_date)

    @staticmethod
    def calculate_days_overdue(due_date: datetime) -> int:
        """حساب عدد الأيام المتأخرة"""
        baghdad_now = DateUtils.get_baghdad_now()
        if due_date.tzinfo is None:
            due_date = DateUtils.convert_to_baghdad_time(due_date)

        days_overdue = (baghdad_now - due_date).days
        return max(0, days_overdue)

    @staticmethod
    def format_date_for_display(dt: datetime) -> str:
        """تنسيق التاريخ للعرض"""
        baghdad_time = DateUtils.convert_to_baghdad_time(dt)
        return baghdad_time.strftime("%Y-%m-%d %H:%M:%S")

    @staticmethod
    def format_date_only(dt: datetime) -> str:
        """تنسيق التاريخ فقط (بدون الوقت)"""
        baghdad_time = DateUtils.convert_to_baghdad_time(dt)
        return baghdad_time.strftime("%Y-%m-%d")

    @staticmethod
    def get_month_start(dt: datetime) -> datetime:
        """الحصول على بداية الشهر"""
        return dt.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    @staticmethod
    def get_month_end(dt: datetime) -> datetime:
        """الحصول على نهاية الشهر"""
        next_month = dt.replace(day=28) + timedelta(days=4)  # الذهاب إلى الشهر التالي
        return next_month - timedelta(days=next_month.day)  # العودة إلى اليوم الأخير من الشهر الحالي
