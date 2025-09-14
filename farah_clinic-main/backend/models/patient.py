from datetime import datetime, date
from typing import Optional, List, Union
from pydantic import BaseModel, Field, field_validator
from bson import ObjectId


class Payment(BaseModel):
    """نموذج الدفعة"""
    id: Union[str, ObjectId] = Field(default_factory=ObjectId, alias="_id")
    patient_id: Union[str, ObjectId]
    amount: float = Field(..., gt=0, description="المبلغ المدفوع")
    payment_date: datetime = Field(default_factory=datetime.now)
    notes: Optional[str] = None

    @field_validator('id', 'patient_id', mode='before')
    @classmethod
    def validate_objectid(cls, v):
        if isinstance(v, str):
            if ObjectId.is_valid(v):
                return ObjectId(v)
            else:
                raise ValueError("Invalid ObjectId string")
        return v

    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True
        json_encoders = {ObjectId: str}


class Patient(BaseModel):
    """نموذج المريض"""
    id: Union[str, ObjectId] = Field(default_factory=ObjectId, alias="_id")
    name: str = Field(..., min_length=1, max_length=100, description="اسم المريض")
    phone: str = Field(..., min_length=10, max_length=15, description="رقم الهاتف")
    total_amount: float = Field(..., gt=0, description="المبلغ الكلي للكمبياله")
    installments_months: int = Field(..., gt=0, le=120, description="عدد أشهر التقسيط")
    notes: Optional[str] = Field(None, max_length=500, description="ملاحظات")
    registration_date: datetime = Field(default_factory=datetime.now, description="تاريخ التسجيل")
    is_completed: bool = Field(default=False, description="هل تم إكمال التقسيط")

    # حساب المبالغ
    total_paid: float = Field(default=0.0, description="إجمالي المبالغ المدفوعة")
    remaining_amount: float = Field(default=0.0, description="المبلغ المتبقي")

    # قائمة المدفوعات
    payments: List[Payment] = Field(default_factory=list, description="قائمة المدفوعات")

    @field_validator('id', mode='before')
    @classmethod
    def validate_objectid(cls, v):
        if isinstance(v, str):
            if ObjectId.is_valid(v):
                return ObjectId(v)
            else:
                raise ValueError("Invalid ObjectId string")
        return v

    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True
        json_encoders = {ObjectId: str}

    def calculate_remaining_amount(self):
        """حساب المبلغ المتبقي"""
        self.remaining_amount = self.total_amount - self.total_paid
        return self.remaining_amount

    def calculate_monthly_installment(self):
        """حساب القسط الشهري"""
        return self.total_amount / self.installments_months

    def get_next_payment_date(self):
        """حساب تاريخ الدفعة التالية شهرياً من تاريخ التسجيل.

        المنطق: كل دفعة تُسجَّل تقفز تاريخ الاستحقاق شهر واحد من تاريخ التسجيل.
        أي أن الدفعة رقم N تجعل الاستحقاق عند (تاريخ التسجيل + N أشهر).
        التالي دائماً (عدد الدفعات + 1) شهر من تاريخ التسجيل.
        """
        payments_count = len(self.payments) if self.payments else 0
        base_date = self.registration_date

        def add_months(d: datetime, months: int) -> datetime:
            total_months = (d.month - 1) + months
            year = d.year + (total_months // 12)
            month = (total_months % 12) + 1

            if month == 12:
                next_month_first = datetime(year + 1, 1, 1)
            else:
                next_month_first = datetime(year, month + 1, 1)
            last_day = (next_month_first - timedelta(days=1)).day

            day = min(d.day, last_day)
            return d.replace(year=year, month=month, day=day)

        return add_months(base_date, payments_count + 1)

    def is_overdue(self, days_threshold: int = 1):
        """التحقق من وجود متأخرات"""
        next_payment_date = self.get_next_payment_date()
        days_overdue = (datetime.now() - next_payment_date).days
        return days_overdue > days_threshold and not self.is_completed


from datetime import timedelta
