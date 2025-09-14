class ApiConfig {
  // إعدادات الخادم
  static const String localhost = 'http://127.0.0.1:8000';
  static const String androidEmulator = 'http://10.0.2.2:8000';
  static const String networkIP =
      'http://192.168.1.100:8000'; // غير هذا حسب IP جهازك

  // استخدم baseUrl المناسب حسب البيئة
  static String get baseUrl {
    // يمكن تمريره عند البناء: --dart-define=API_BASE_URL=https://your-domain.com
    const String envUrl =
        String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl;
    return localhost;
  }

  // مسارات API الجديدة
  static const String authPrefix = '/auth';
  static const String patientsPrefix = '/patients';
  static const String paymentsPrefix = '/payments';

  // إعدادات الاتصال
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // رسائل الخطأ
  static const Map<String, String> errorMessages = {
    'no_internet': 'لا يوجد اتصال بالإنترنت',
    'server_error': 'خطأ في الخادم',
    'timeout': 'انتهت مهلة الاتصال',
    'not_found': 'المورد غير موجود',
    'unauthorized': 'غير مصرح لك بالوصول',
    'validation_error': 'خطأ في البيانات المدخلة',
  };

  // headers افتراضية
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  // رسائل النجاح
  static const Map<String, String> successMessages = {
    'patient_added': 'تم إضافة المريض بنجاح',
    'patient_updated': 'تم تحديث بيانات المريض بنجاح',
    'patient_deleted': 'تم حذف المريض بنجاح',
    'payment_added': 'تم إضافة الدفعة بنجاح',
    'data_loaded': 'تم تحميل البيانات بنجاح',
  };
}
