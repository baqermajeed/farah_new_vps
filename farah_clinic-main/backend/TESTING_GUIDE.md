# دليل اختبار نظام المصادقة - عيادة الدكتورة فرح الأسنان

## ✅ النظام جاهز للاختبار!

تم حل مشكلة MongoDB باستخدام خدمة مصادقة مبسطة تعمل في الذاكرة للتطوير.

## 🔐 بيانات تسجيل الدخول الافتراضية

```
اسم المستخدم: admin
كلمة المرور: admin123
```

## 🚀 كيفية اختبار النظام

### 1. تشغيل التطبيق
```bash
cd backend
python -m uvicorn main:app --reload
```

### 2. اختبار تسجيل الدخول

**استخدام curl:**
```bash
curl -X POST "http://localhost:8000/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123"}'
```

**الاستجابة المتوقعة:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 2592000
}
```

### 3. اختبار الوصول للمرضى

```bash
curl -X GET "http://localhost:8000/patients" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### 4. اختبار إنشاء مريض جديد

```bash
curl -X POST "http://localhost:8000/patients" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "أحمد محمد",
    "phone": "07901234567",
    "total_amount": 1000,
    "installments_months": 12,
    "notes": "مريض جديد"
  }'
```

### 5. اختبار إنشاء مستخدم جديد

```bash
curl -X POST "http://localhost:8000/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "newuser",
    "email": "user@example.com",
    "full_name": "مستخدم جديد",
    "password": "password123",
    "is_admin": false
  }'
```

## 🌐 اختبار عبر المتصفح

1. **فتح وثائق API**: http://localhost:8000/docs
2. **تسجيل الدخول**: استخدم `/auth/login`
3. **نسخ الرمز المميز** من الاستجابة
4. **النقر على "Authorize"** في أعلى الصفحة
5. **إدخال**: `Bearer YOUR_TOKEN_HERE`
6. **اختبار endpoints** المختلفة

## 📱 اختبار تطبيق Flutter

لتحديث تطبيق Flutter:

### 1. إضافة Bearer Token للطلبات
```dart
final token = await getStoredToken();
final response = await http.get(
  Uri.parse('$baseUrl/patients'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
);
```

### 2. تسجيل الدخول
```dart
final loginResponse = await http.post(
  Uri.parse('$baseUrl/auth/login'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'username': 'admin',
    'password': 'admin123',
  }),
);

if (loginResponse.statusCode == 200) {
  final data = jsonDecode(loginResponse.body);
  final token = data['access_token'];
  await storage.write(key: 'auth_token', value: token);
}
```

## 🔍 اختبارات إضافية

### اختبار الحماية
```bash
# هذا يجب أن يعطي خطأ 401
curl -X GET "http://localhost:8000/patients"
```

### اختبار الرمز المميز غير الصحيح
```bash
curl -X GET "http://localhost:8000/patients" \
  -H "Authorization: Bearer invalid_token"
```

### اختبار انتهاء صلاحية الرمز
```bash
# استخدم رمز منتهي الصلاحية
curl -X GET "http://localhost:8000/patients" \
  -H "Authorization: Bearer expired_token"
```

## 📊 المسارات المتاحة

### مسارات المصادقة (عامة)
- `POST /auth/login` - تسجيل الدخول
- `POST /auth/register` - تسجيل مستخدم جديد
- `GET /auth/me` - بيانات المستخدم الحالي
- `POST /auth/refresh` - تجديد الرمز المميز
- `POST /auth/logout` - تسجيل الخروج

### مسارات المرضى (محمية)
- `GET /patients` - قائمة المرضى
- `POST /patients` - إنشاء مريض جديد
- `GET /patients/{id}` - تفاصيل مريض
- `PUT /patients/{id}` - تحديث مريض
- `DELETE /patients/{id}` - حذف مريض
- `POST /patients/{id}/payments` - إضافة دفعة
- `GET /patients/notifications/overdue` - إشعارات المتأخرات
- `GET /patients/upcoming-payments` - الدفعات القادمة
- `GET /patients/statistics/summary` - الإحصائيات

### مسارات عامة
- `GET /` - صفحة الترحيب
- `GET /health` - فحص حالة التطبيق
- `GET /docs` - وثائق API

## ⚠️ ملاحظات مهمة

1. **للتطوير فقط**: النظام الحالي يستخدم مصادقة في الذاكرة
2. **للاستخدام الحقيقي**: يجب إعداد MongoDB بشكل صحيح
3. **الأمان**: غير كلمة مرور المدير الافتراضي في الإنتاج
4. **النسخ الاحتياطي**: البيانات في الذاكرة تختفي عند إعادة التشغيل

## 🛠️ حل المشاكل

### خطأ 401 - Unauthorized
- تحقق من صحة الرمز المميز
- تأكد من إضافة "Bearer " قبل الرمز
- تحقق من انتهاء صلاحية الرمز

### خطأ 500 - Internal Server Error
- تحقق من سجلات الخادم
- تأكد من تشغيل MongoDB
- راجع إعدادات الاتصال

### خطأ في الاتصال
- تأكد من تشغيل الخادم على المنفذ 8000
- تحقق من إعدادات الشبكة
- راجع سجلات التطبيق

## 🎯 الخطوات التالية

1. **اختبار جميع الوظائف**
2. **تحديث تطبيق Flutter**
3. **إعداد MongoDB للإنتاج**
4. **تطبيق الأمان الكامل**
5. **اختبار الأداء**

## 📞 الدعم

إذا واجهت أي مشاكل:
1. راجع سجلات الخادم
2. تحقق من إعدادات MongoDB
3. تأكد من صحة البيانات المرسلة
4. راجع وثائق FastAPI
