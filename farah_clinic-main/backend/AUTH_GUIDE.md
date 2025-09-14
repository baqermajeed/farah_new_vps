# دليل نظام المصادقة - عيادة الدكتورة فرح الأسنان

## نظرة عامة

تم إضافة نظام مصادقة شامل للتطبيق باستخدام Bearer Token و JWT. النظام يحمي جميع endpoints المتعلقة بالمرضى ويتطلب تسجيل دخول للوصول إليها.

## الميزات المضافة

### 1. نماذج المستخدمين
- **User**: نموذج المستخدم الأساسي
- **UserCreate**: نموذج إنشاء مستخدم جديد
- **UserLogin**: نموذج تسجيل الدخول
- **UserResponse**: نموذج استجابة المستخدم
- **Token**: نموذج الرمز المميز

### 2. خدمة المصادقة (AuthService)
- تشفير كلمات المرور باستخدام bcrypt
- إنشاء وتحقق من JWT tokens
- إدارة المستخدمين
- إنشاء مدير افتراضي

### 3. Router المصادقة
- `POST /auth/register` - تسجيل مستخدم جديد
- `POST /auth/login` - تسجيل الدخول
- `GET /auth/me` - الحصول على بيانات المستخدم الحالي
- `POST /auth/refresh` - تجديد الرمز المميز
- `POST /auth/logout` - تسجيل الخروج

### 4. Middleware الحماية
- **AuthMiddleware**: يتحقق من صحة Bearer Token
- **AdminMiddleware**: يتحقق من صلاحيات المدير

## كيفية الاستخدام

### 1. تسجيل الدخول

```bash
curl -X POST "http://localhost:8000/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "admin123"
  }'
```

**الاستجابة:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 2592000
}
```

### 2. استخدام الرمز المميز

```bash
curl -X GET "http://localhost:8000/patients" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

### 3. الحصول على بيانات المستخدم الحالي

```bash
curl -X GET "http://localhost:8000/auth/me" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

### 4. تسجيل مستخدم جديد

```bash
curl -X POST "http://localhost:8000/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "newuser",
    "email": "user@example.com",
    "full_name": "اسم المستخدم",
    "password": "password123",
    "is_admin": false
  }'
```

## المدير الافتراضي

عند بدء تشغيل التطبيق لأول مرة، يتم إنشاء مدير افتراضي:

- **اسم المستخدم**: `admin`
- **كلمة المرور**: `admin123`
- **الصلاحيات**: مدير

⚠️ **تحذير**: يجب تغيير كلمة مرور المدير الافتراضي في الإنتاج!

## المسارات المحمية

جميع المسارات التالية تتطلب Bearer Token:

- `GET /patients` - قائمة المرضى
- `POST /patients` - إنشاء مريض جديد
- `GET /patients/{id}` - تفاصيل مريض
- `PUT /patients/{id}` - تحديث مريض
- `DELETE /patients/{id}` - حذف مريض
- `POST /patients/{id}/payments` - إضافة دفعة
- `GET /patients/notifications/overdue` - إشعارات المتأخرات
- `GET /patients/upcoming-payments` - الدفعات القادمة
- `GET /patients/statistics/summary` - الإحصائيات

## المسارات العامة

هذه المسارات لا تتطلب مصادقة:

- `GET /` - صفحة الترحيب
- `GET /health` - فحص حالة التطبيق
- `GET /docs` - وثائق API
- `POST /auth/login` - تسجيل الدخول
- `POST /auth/register` - تسجيل مستخدم جديد

## إعدادات الأمان

### JWT Settings
- **الخوارزمية**: HS256
- **مدة الصلاحية**: 30 يوم
- **المفتاح السري**: يجب تغييره في الإنتاج

### كلمات المرور
- **الحد الأدنى**: 6 أحرف
- **التشفير**: bcrypt
- **الملح**: تلقائي

## تحديث التطبيق Flutter

لتحديث تطبيق Flutter للعمل مع نظام المصادقة الجديد:

1. **إضافة Bearer Token للطلبات**:
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

2. **تخزين الرمز المميز**:
```dart
// بعد تسجيل الدخول الناجح
await storage.write(key: 'auth_token', value: response['access_token']);
```

3. **إدارة انتهاء صلاحية الرمز**:
```dart
// التحقق من انتهاء الصلاحية وإعادة تسجيل الدخول
if (isTokenExpired(token)) {
  await refreshToken();
}
```

## استكشاف الأخطاء

### خطأ 401 - Unauthorized
- تحقق من وجود Authorization header
- تأكد من صحة تنسيق Bearer Token
- تحقق من انتهاء صلاحية الرمز

### خطأ 403 - Forbidden
- تحقق من صلاحيات المستخدم
- تأكد من أن المستخدم نشط

### خطأ 500 - Internal Server Error
- تحقق من اتصال قاعدة البيانات
- راجع سجلات الخادم

## الأمان في الإنتاج

1. **تغيير المفتاح السري**:
```python
SECRET_KEY = "your-very-secure-secret-key-here"
```

2. **تحديد النطاقات المسموحة**:
```python
allow_origins=["https://yourdomain.com"]
```

3. **استخدام HTTPS**:
```python
# في الإنتاج، استخدم HTTPS فقط
```

4. **تغيير كلمة مرور المدير الافتراضي**

5. **تفعيل سجلات الأمان**

## الدعم

للمساعدة أو الاستفسارات، يرجى مراجعة الوثائق أو التواصل مع فريق التطوير.
