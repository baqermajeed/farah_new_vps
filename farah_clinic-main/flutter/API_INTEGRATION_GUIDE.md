# دليل ربط Flutter مع MongoDB API

## التغييرات المطلوبة

### 1. إعدادات المشروع

#### تحديث pubspec.yaml
تم إضافة مكتبة `http` وإزالة مكتبات SQLite:

```yaml
dependencies:
  # HTTP requests for API
  http: ^1.1.0
  
  # تم إزالة هذه المكتبات:
  # sqflite: ^2.3.3+1
  # sqflite_common_ffi: ^2.3.0
```

### 2. النماذج (Models)

#### Patient Model
- تغيير `id` من `int?` إلى `String?` للتوافق مع MongoDB ObjectId
- إضافة `monthlyAmount` و `nextPaymentDate` 
- إضافة methods: `fromJson()`, `toJson()`, `isOverdue`, `daysOverdue`

#### Payment Model  
- تغيير `id` من `int?` إلى `String?`
- تغيير `paymentDate` إلى optional (`DateTime?`)
- إضافة methods: `fromJson()`, `toJson()`

### 3. خدمات API

#### ApiService
خدمة جديدة للتعامل مع MongoDB backend:
- جميع عمليات CRUD للمرضى والدفعات
- جلب الإحصائيات من الخادم
- تحميل تقارير PDF
- اختبار الاتصال بالخادم

#### ApiConfig
ملف إعدادات مركزي للـ API:
- عناوين مختلفة للخادم (localhost, emulator, network)
- timeouts ورسائل الخطأ
- إعدادات headers

### 4. AppProvider

تم تحديث AppProvider ليعمل مع API:
- استبدال SQLite بـ API calls
- إضافة error handling محسن
- إضافة اختبار اتصال API
- fallback للبيانات المحلية في حالة فشل API

## كيفية الاستخدام

### 1. تشغيل Backend
```bash
# في مجلد farah_backend
python -m uvicorn main:app --reload --port 8000
```

### 2. تشغيل Flutter App
```bash
# في مجلد farah_dental_clinic_app
flutter pub get
flutter run -d windows  # أو أي platform آخر
```

### 3. تغيير عنوان API

في ملف `lib/config/api_config.dart`:

```dart
static String get baseUrl {
  // للاستخدام المحلي
  return localhost; // http://127.0.0.1:8000
  
  // للـ Android Emulator  
  // return androidEmulator; // http://10.0.2.2:8000
  
  // للجهاز الفعلي (غير IP حسب شبكتك)
  // return networkIP; // http://192.168.1.100:8000
}
```

## مميزات الدمج

### 1. البيانات المتزامنة
- جميع التغييرات تتم على الخادم مباشرة
- البيانات متوفرة على جميع الأجهزة

### 2. الأداء المحسن
- استخدام MongoDB indexes للبحث السريع
- Aggregation pipelines للإحصائيات المعقدة

### 3. المرونة
- إمكانية إضافة حقول جديدة بسهولة
- دعم للـ backup والـ restoration

### 4. التوسع
- يمكن إضافة المزيد من المستخدمين
- دعم للـ authentication المتقدم

## نصائح التطوير

### 1. معالجة الأخطاء
```dart
try {
  final patients = await ApiService.getAllPatients();
  // استخدام البيانات
} catch (e) {
  // عرض رسالة خطأ للمستخدم
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('خطأ: $e')),
  );
}
```

### 2. Loading States
```dart
Consumer<AppProvider>(
  builder: (context, appProvider, child) {
    if (appProvider.isLoading) {
      return CircularProgressIndicator();
    }
    
    if (appProvider.errorMessage != null) {
      return Text('خطأ: ${appProvider.errorMessage}');
    }
    
    return YourDataWidget();
  },
)
```

### 3. اختبار الاتصال
```dart
final isConnected = await ApiService.testConnection();
if (!isConnected) {
  // عرض رسالة عدم الاتصال
}
```

## استكشاف الأخطاء

### 1. خطأ في الاتصال
- تأكد من أن Backend يعمل على المنفذ 8000
- تأكد من أن MongoDB يعمل
- تحقق من firewall settings

### 2. مشاكل في البيانات
- تحقق من format التواريخ
- تأكد من أن JSON structure صحيح
- راجع server logs للتفاصيل

### 3. مشاكل الشبكة
- للـ Android Emulator استخدم `10.0.2.2:8000`
- للجهاز الفعلي استخدم IP الجهاز الحقيقي
- تأكد من أن الجهازين على نفس الشبكة
