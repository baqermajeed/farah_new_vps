from datetime import datetime
from typing import Optional, List, Union
from pydantic import BaseModel, Field
from bson import ObjectId


class PatientCreate(BaseModel):
    """سكيما إنشاء مريض جديد"""
    name: str = Field(..., min_length=1, max_length=100, description="اسم المريض")
    phone: str = Field(..., min_length=10, max_length=15, description="رقم الهاتف")
    total_amount: float = Field(..., gt=0, description="المبلغ الكلي للكمبياله")
    installments_months: int = Field(..., gt=0, le=120, description="عدد أشهر التقسيط")
    registration_date: Optional[datetime] = Field(None, description="تاريخ التسجيل")
    notes: Optional[str] = Field(None, max_length=500, description="ملاحظات")


class PatientUpdate(BaseModel):
    """سكيما تحديث مريض"""
    name: Optional[str] = Field(None, min_length=1, max_length=100, description="اسم المريض")
    phone: Optional[str] = Field(None, min_length=10, max_length=15, description="رقم الهاتف")
    total_amount: Optional[float] = Field(None, gt=0, description="المبلغ الكلي للكمبياله")
    installments_months: Optional[int] = Field(None, gt=0, le=120, description="عدد أشهر التقسيط")
    registration_date: Optional[datetime] = Field(None, description="تاريخ التسجيل")
    notes: Optional[str] = Field(None, max_length=500, description="ملاحظات")
    is_completed: Optional[bool] = Field(None, description="هل تم إكمال التقسيط")
    # للسماح للمدير بتعديل المبلغ المتبقي بشكل مباشر
    remaining_amount: Optional[float] = Field(None, ge=0, description="المبلغ المتبقي")


class PatientResponse(BaseModel):
    """سكيما عرض المريض"""
    id: Union[str, ObjectId] = Field(alias="_id")
    name: str
    phone: str
    total_amount: float
    installments_months: int
    notes: Optional[str]
    registration_date: datetime
    is_completed: bool
    total_paid: float
    remaining_amount: float
    monthly_installment: float
    next_payment_date: datetime
    payments_count: int

    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True
        json_encoders = {ObjectId: str}


class PatientList(BaseModel):
    """سكيما قائمة المرضى"""
    id: Union[str, ObjectId] = Field(alias="_id")
    name: str
    phone: str
    total_amount: float
    remaining_amount: float
    next_payment_date: datetime
    is_completed: bool

    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True
        json_encoders = {ObjectId: str}


class PaymentCreate(BaseModel):
    """سكيما إنشاء دفعة جديدة"""
    patient_id: str = Field(..., description="معرف المريض")
    amount: float = Field(..., gt=0, description="المبلغ المدفوع")
    payment_date: Optional[datetime] = Field(None, description="تاريخ الدفعة (اختياري)")
    notes: Optional[str] = Field(None, max_length=500, description="ملاحظات")


class PaymentResponse(BaseModel):
    """سكيما عرض الدفعة"""
    id: Union[str, ObjectId] = Field(alias="_id")
    patient_id: Union[str, ObjectId]
    patient_name: Optional[str] = None  # إضافة اسم المريض
    amount: float
    payment_date: datetime
    notes: Optional[str]

    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True
        json_encoders = {ObjectId: str}


class OverdueNotification(BaseModel):
    """سكيما إشعار المتأخرات"""
    patient_id: Union[str, ObjectId]
    patient_name: str
    phone: str
    registration_date: datetime
    days_overdue: int
    total_amount: float
    remaining_amount: float
    monthly_installment: float
    next_payment_date: datetime

    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True
        json_encoders = {ObjectId: str}


class PaymentUpdate(BaseModel):
    """سكيما تحديث الدفعة"""
    payment_date: Optional[datetime] = Field(None, description="تاريخ الدفعة")
    notes: Optional[str] = Field(None, max_length=500, description="ملاحظات")


class PatientFilter(BaseModel):
    """سكيما فلترة المرضى"""
    name: Optional[str] = None
    is_completed: Optional[bool] = None
    overdue_only: Optional[bool] = None
