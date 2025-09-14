import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/patient.dart';
import '../models/payment.dart';
import '../services/api_service.dart';

class AppProvider with ChangeNotifier {
  // حالة تسجيل الدخول
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _currentUser;
  String? _errorMessage;
  bool _isApiConnected = false;
  bool _isFetching = false; // قفل لمنع تكرار التحميل
  bool _isAdmin = false;

  List<Patient> _patients = [];
  List<Payment> _payments = [];
  Statistics? _statistics;

  // تتبع الإشعارات التي تم التبليغ عنها لإخفائها لاحقاً
  final Set<String> _dismissedNotifications = <String>{};

  // Getters
  List<Patient> get patients => _patients;
  List<Payment> get payments => _payments;
  Statistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isApiConnected => _isApiConnected;
  bool get isAdmin => _isAdmin;

  // مفتاح فريد للمريض للاستخدام في الإشعارات
  String _notifKey(Patient p) => p.id ?? '${p.name}|${p.phone}';

  // إحصائيات محلية (كبديل إذا فشل API)
  double get totalAmount {
    return _statistics?.totalAmount ??
        _patients.fold(0.0, (sum, patient) => sum + patient.totalAmount);
  }

  double get paidAmount {
    return _statistics?.paidAmount ??
        _patients.fold(0.0, (sum, patient) => sum + patient.totalPaid);
  }

  double get remainingAmount {
    return _statistics?.remainingAmount ?? (totalAmount - paidAmount);
  }

  int get remainingBillsCount {
    return _patients.where((patient) => patient.remainingAmount > 0).length;
  }

  int get overdueCount {
    return _statistics?.overduePatients ??
        _patients.where((patient) => patient.isOverdue).length;
  }

  // تسجيل الدخول
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // تحقق من بيانات تسجيل الدخول عبر API
      final success = await ApiService.login(username, password);
      if (success) {
        _isLoggedIn = true;
        _currentUser = username;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('currentUser', username);
        await _fetchUserRole();
        // حمّل البيانات مباشرة بعد تسجيل الدخول بنجاح
        try {
          await loadData(force: true);
        } catch (_) {}
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('خطأ في تسجيل الدخول: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // تسجيل الخروج
  Future<void> logout() async {
    _isLoggedIn = false;
    _currentUser = null;
    _patients.clear();
    _payments.clear();

    // حذف حالة تسجيل الدخول
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('currentUser');
    await ApiService.clearToken();

    notifyListeners();
  }

  // التحقق من حالة تسجيل الدخول المحفوظة
  Future<void> checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      // حمّل التوكن أولاً
      await ApiService.loadToken();

      if (ApiService.hasToken) {
        // تحقق من صحة التوكن عبر API
        try {
          final isConnected = await ApiService.testConnection();
          if (isConnected) {
            final prefs = await SharedPreferences.getInstance();
            final currentUser = prefs.getString('currentUser');
            _isLoggedIn = true;
            _currentUser = currentUser;
            await _fetchUserRole();
            await _loadDismissed();
          } else {
            // التوكن غير صالح
            await logout();
          }
        } catch (e) {
          // خطأ في الاتصال، اعتبر المستخدم غير مسجل الدخول
          await logout();
        }
      } else {
        // لا يوجد توكن
        _isLoggedIn = false;
        _currentUser = null;
      }
    } catch (e) {
      debugPrint('خطأ في التحقق من حالة تسجيل الدخول: $e');
      _isLoggedIn = false;
      _currentUser = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchUserRole() async {
    try {
      final me = await ApiService.getCurrentUser();
      _isAdmin = (me?['is_admin'] as bool?) ?? false;
    } catch (_) {
      _isAdmin = false;
    }
  }

  // اختبار الاتصال بـ API
  Future<void> checkApiConnection() async {
    try {
      final connected = await ApiService.testConnection();
      if (connected != _isApiConnected) {
        _isApiConnected = connected;
        notifyListeners();
      } else {
        _isApiConnected = connected;
      }
    } catch (e) {
      _isApiConnected = false;
      debugPrint('خطأ في اختبار API: $e');
    }
  }

  // تحميل البيانات من API
  Future<void> loadData({bool force = false}) async {
    if (_isFetching) return;
    // إذا كانت البيانات محملة مسبقاً ولا يوجد طلب تحديث قسري، تجنب الاتصال بالشبكة
    if (!force && _patients.isNotEmpty && _statistics != null) {
      _isLoading = false;
      _isFetching = false;
      notifyListeners();
      return;
    }
    _isFetching = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // تأكد من وجود التوكن قبل أي اتصال محمي
      if (!ApiService.hasToken) {
        await ApiService.loadToken();
      }

      // لا تقم بمحاولات شبكة إذا لم يوجد توكن
      if (!ApiService.hasToken) {
        throw Exception('غير مصرح: لا يوجد توكن');
      }

      await checkApiConnection();

      if (_isApiConnected) {
        // جلب جميع البيانات دفعة واحدة فقط
        final bootstrap = await ApiService.getBootstrapData();
        _patients = bootstrap.patients;
        _payments = bootstrap.payments;
        _statistics = bootstrap.statistics;
        await _loadDismissed();
      } else {
        throw Exception('لا يمكن الاتصال بالخادم');
      }
    } catch (e) {
      _errorMessage = e.toString();
      // إذا كانت المشكلة مصادقة، امسح التوكن واعتبر المستخدم غير مسجل
      final String msg = e.toString();
      if (msg.contains('UNAUTHORIZED') || msg.contains('401')) {
        _isLoggedIn = false;
        _currentUser = null;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('isLoggedIn');
          await prefs.remove('currentUser');
        } catch (_) {}
        await ApiService.clearToken();
      }
      debugPrint('Error loading data: $e');
    }

    _isLoading = false;
    _isFetching = false;
    notifyListeners();
  }

  // تحميل/حفظ حالة الإشعارات المبلّغ عنها
  Future<void> _loadDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('dismissed_notifications') ?? <String>[];
    _dismissedNotifications
      ..clear()
      ..addAll(list);
  }

  Future<void> _saveDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'dismissed_notifications', _dismissedNotifications.toList());
  }

  // آخر تاريخ دفع لمريض
  DateTime? lastPaymentDateFor(String patientName) {
    final related = _payments
        .where((p) => p.patientName == patientName && p.paymentDate != null)
        .map((p) => p.paymentDate!)
        .toList();
    if (related.isEmpty) return null;
    related.sort((a, b) => b.compareTo(a));
    return related.first;
  }

  // المرضى المطلوب تذكيرهم (مستحق اليوم أو متأخر) ولم يتم تعليمهم كمبلّغين
  List<Patient> get notificationPatients {
    final now = DateTime.now();
    return _patients.where((p) {
      if (p.remainingAmount <= 0) return false;
      final nextDate = p.nextPaymentDate ?? p.calculatedNextPaymentDate;
      final today = DateTime(now.year, now.month, now.day);
      final dueOrOverdue = !nextDate.isAfter(today);
      if (!dueOrOverdue) return false;
      final key = _notifKey(p);
      return !_dismissedNotifications.contains(key);
    }).toList()
      ..sort((a, b) {
        final cmpDays = b.daysOverdue.compareTo(a.daysOverdue);
        if (cmpDays != 0) return cmpDays;
        return b.remainingAmount.compareTo(a.remainingAmount);
      });
  }

  // تعليم المريض كمبلّغ عنه
  Future<void> markPatientNotified(Patient patient) async {
    _dismissedNotifications.add(_notifKey(patient));
    await _saveDismissed();
    notifyListeners();
  }

  // إضافة مريض جديد
  Future<bool> addPatient(Patient patient) async {
    try {
      if (_isApiConnected && _isLoggedIn && ApiService.hasToken) {
        final ok = await ApiService.addPatient(patient);
        // تحديث متفائل: أضف محلياً ليظهر فوراً
        _patients = List<Patient>.from(_patients)..add(ok);
        notifyListeners();
      } else {
        // إضافة محلية إذا لم يكن هناك اتصال
        _patients.add(patient);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = 'خطأ في إضافة المريض: ${e.toString()}';
      debugPrint('Error adding patient: $e');
      notifyListeners();
      return false;
    }
  }

  // تحديث بيانات مريض
  Future<bool> updatePatient(Patient patient) async {
    if (patient.id == null) return false;

    try {
      if (!_isApiConnected || !_isLoggedIn || !ApiService.hasToken) {
        // لا يمكن التحديث على الخادم بدون مصادقة
        throw Exception('غير مصرح: لا يوجد اتصال أو توكن');
      }
      await ApiService.updatePatient(patient.id!, patient);
      await loadData(); // إعادة تحميل البيانات
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error updating patient: $e');
      notifyListeners();
      return false;
    }
  }

  // حذف مريض
  Future<bool> deletePatient(String patientId) async {
    try {
      if (!_isApiConnected || !_isLoggedIn || !ApiService.hasToken) {
        throw Exception('غير مصرح: لا يوجد اتصال أو توكن');
      }
      await ApiService.deletePatient(patientId);
      await loadData(); // إعادة تحميل البيانات
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error deleting patient: $e');
      notifyListeners();
      return false;
    }
  }

  // تحديث تاريخ الدفعة/ملاحظات (للمدير)
  Future<bool> updatePayment({
    required String patientId,
    required String paymentId,
    DateTime? paymentDate,
    String? notes,
  }) async {
    try {
      if (!_isApiConnected ||
          !_isLoggedIn ||
          !ApiService.hasToken ||
          !_isAdmin) {
        throw Exception('غير مصرح: يتطلب صلاحيات مدير');
      }
      await ApiService.updatePayment(
        patientId: patientId,
        paymentId: paymentId,
        paymentDate: paymentDate,
        notes: notes,
      );
      await loadData(force: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error updating payment: $e');
      notifyListeners();
      return false;
    }
  }

  // حذف دفعة (للمدير)
  Future<bool> deletePayment({
    required String patientId,
    required String paymentId,
  }) async {
    try {
      if (!_isApiConnected ||
          !_isLoggedIn ||
          !ApiService.hasToken ||
          !_isAdmin) {
        throw Exception('غير مصرح: يتطلب صلاحيات مدير');
      }
      await ApiService.deletePayment(
          patientId: patientId, paymentId: paymentId);
      await loadData(force: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error deleting payment: $e');
      notifyListeners();
      return false;
    }
  }

  // إضافة دفعة جديدة
  Future<bool> addPayment(Payment payment) async {
    try {
      if (!_isApiConnected || !_isLoggedIn || !ApiService.hasToken) {
        throw Exception('غير مصرح: لا يوجد اتصال أو توكن');
      }
      await ApiService.addPayment(payment);
      await loadData(force: true); // إعادة تحميل البيانات
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error adding payment: $e');
      notifyListeners();
      return false;
    }
  }

  // الحصول على المرضى المتأخرين
  Future<List<Patient>> getOverduePatients() async {
    // إذا لم يكن هناك مصادقة أو لم يتم تسجيل الدخول، استخدم البيانات المحلية مباشرة
    if (!_isLoggedIn || !ApiService.hasToken) {
      return _patients.where((patient) => patient.isOverdue).toList();
    }
    try {
      return await ApiService.getOverduePatients();
    } catch (e) {
      debugPrint('Error getting overdue patients: $e');
      // استخدام البيانات المحلية كبديل
      return _patients.where((patient) => patient.isOverdue).toList();
    }
  }

  // الحصول على المرضى الذين لديهم مبالغ متبقية للدفع
  Future<List<Patient>> getPatientsWithPendingPayments() async {
    // إذا لم يكن هناك مصادقة أو لم يتم تسجيل الدخول، استخدم البيانات المحلية مباشرة
    if (!_isLoggedIn || !ApiService.hasToken) {
      return _patients.where((patient) => patient.remainingAmount > 0).toList();
    }
    try {
      return await ApiService.getPatientsWithPendingPayments();
    } catch (e) {
      debugPrint('Error getting patients with pending payments: $e');
      // استخدام البيانات المحلية كبديل
      return _patients.where((patient) => patient.remainingAmount > 0).toList();
    }
  }

  // البحث عن مريض بالاسم
  Future<Patient?> searchPatientByName(String name) async {
    try {
      return await ApiService.searchPatientByName(name);
    } catch (e) {
      debugPrint('Error searching for patient: $e');
      // استخدام البيانات المحلية كبديل
      try {
        return _patients.firstWhere(
          (patient) => patient.name.toLowerCase().contains(name.toLowerCase()),
        );
      } catch (e) {
        return null;
      }
    }
  }

  // الحصول على مدفوعات مريض معين (من البيانات المحلية)
  List<Payment> getPatientPayments(String patientName) {
    return _payments
        .where((payment) => payment.patientName == patientName)
        .toList();
  }

  // جلب مدفوعات مريض معين من API
  Future<List<Payment>> getPatientPaymentsFromAPI(String patientId) async {
    try {
      if (!_isApiConnected || !_isLoggedIn || !ApiService.hasToken) {
        throw Exception('غير مصرح: لا يوجد اتصال أو توكن');
      }
      return await ApiService.getPatientPayments(patientId);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Error getting patient payments: $e');
      notifyListeners();
      return [];
    }
  }

  // تحديث البيانات
  Future<void> refreshData() async {
    if (_isLoggedIn) {
      await loadData(force: true);
    }
  }
}
