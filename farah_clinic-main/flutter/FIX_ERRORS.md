# إصلاحات سريعة للأخطاء

## ✅ تم إصلاحه:
- API service وmodel conversions  
- Database service (تم حذفه)
- invoice_data.dart

## ⚠️ يحتاج إصلاح:
الملفات التالية تحتاج لإصلاح DateTime null safety:

### payment_screen.dart
- أسطر 328-330: تحتاج `?.` أو `?? DateTime.now()`
- سطر 1037: تحتاج `?? DateTime.now()`  
- سطر 1214: تحتاج `?? DateTime.now()`

### overdue_payments_screen.dart  
- أسطر 54-58: تحتاج `?.` أو `?? DateTime.now()`
- أسطر 79-81: تحتاج `?.` أو `?? DateTime.now()`
- أسطر 128-130: تحتاج `?.` أو `?? DateTime.now()`
- سطر 137: تحتاج `?? DateTime.now()`
- أسطر 181-183: تحتاج `?.` أو `?? DateTime.now()` 
- سطر 201: تحتاج `?? DateTime.now()`
- سطر 459: تحتاج `?? DateTime.now()`

## الحل السريع:
استبدال كل `dateTime.property` بـ `(dateTime ?? DateTime.now()).property`
أو استبدال `payment.paymentDate` بـ `payment.paymentDate ?? DateTime.now()`

## للتشغيل فقط (تجاهل الـ warnings):
```bash
flutter build windows --release --ignore-deprecation
```

أو أفضل: إصلاح الأخطاء الحرجة فقط وتجاهل الـ info warnings
