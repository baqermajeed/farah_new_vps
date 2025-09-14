import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/patient.dart';
import '../models/payment.dart';
import '../config/api_config.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;
  static Map<String, String> get headers {
    if (_token != null) {
      return {
        ...ApiConfig.defaultHeaders,
        'Authorization': 'Bearer $_token',
      };
    }
    return ApiConfig.defaultHeaders;
  }

  static String? _token;
  static const String _tokenKey = 'auth_token';
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // حفظ/استرجاع/مسح التوكن
  static Future<void> saveToken(String token) async {
    _token = token;
    try {
      // احفظ في التخزين الآمن أولاً
      await _secureStorage.write(key: _tokenKey, value: token);
      // كنسخ احتياطي للأجهزة غير المدعومة فقط
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (_) {
      // تجاهل أخطاء التخزين المحلي
    }
  }

  static Future<void> loadToken() async {
    try {
      // حاول من التخزين الآمن أولاً
      _token = await _secureStorage.read(key: _tokenKey);
      if (_token == null || _token!.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        _token = prefs.getString(_tokenKey);
      }
    } catch (_) {
      _token = null;
    }
  }

  static Future<void> clearToken() async {
    _token = null;
    try {
      await _secureStorage.delete(key: _tokenKey);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (_) {
      // تجاهل
    }
  }

  static bool get hasToken => _token != null && _token!.isNotEmpty;

  // تسجيل الدخول وجلب التوكن
  static Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.authPrefix}/login'),
        headers: ApiConfig.defaultHeaders,
        body: json.encode({'username': username, 'password': password}),
      );
      final data = _handleResponse(response);
      if (data != null && data['access_token'] != null) {
        await saveToken(data['access_token']);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // جلب معلومات المستخدم الحالي (للتحقق من is_admin)
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${ApiConfig.authPrefix}/me'),
        headers: headers,
      );
      final data = _handleResponse(response);
      if (data is Map<String, dynamic>) return data;
      return null;
    } catch (_) {
      return null;
    }
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final bodyString = utf8.decode(response.bodyBytes);
      if (bodyString.isEmpty) return null;
      return json.decode(bodyString);
    } else {
      // التعامل الموحّد مع 401/403
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw HttpException(
          'UNAUTHORIZED: ${response.statusCode}: ${response.body}',
          uri: response.request?.url,
        );
      }
      throw HttpException(
        'HTTP ${response.statusCode}: ${response.body}',
        uri: response.request?.url,
      );
    }
  }

  // اختبار اتصال API
  static Future<bool> testConnection() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // جلب رسالة الترحيب
  static Future<String> getWelcomeMessage() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 5));

      final data = _handleResponse(response);
      if (data is Map<String, dynamic>) {
        return data['message'] ?? 'API Ready';
      }
      return 'API Ready';
    } catch (e) {
      throw Exception('فشل في الاتصال بالخادم: $e');
    }
  }

  // جلب جميع البيانات دفعة واحدة (bootstrap)
  static Future<BootstrapData> getBootstrapData() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/bootstrap'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      final data = _handleResponse(response);
      return BootstrapData.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('فشل في جلب بيانات النظام: $e');
    }
  }

  // البحث عن مريض بالاسم
  static Future<Patient?> searchPatientByName(String name) async {
    try {
      final response = await http
          .get(
            Uri.parse(
                '$baseUrl${ApiConfig.patientsPrefix}/search?query=${Uri.encodeComponent(name)}'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 404) {
        return null;
      }
      final dynamic responseData = _handleResponse(response);
      if (responseData == null || (responseData as List).isEmpty) return null;
      return Patient.fromJson(responseData.first);
    } catch (e) {
      throw Exception('فشل في البحث عن المريض: $e');
    }
  }

  // إضافة دفعة جديدة
  static Future<Map<String, dynamic>> addPayment(Payment payment) async {
    try {
      final response = await http
          .post(
            Uri.parse(
                '$baseUrl${ApiConfig.patientsPrefix}/${payment.patientId}/payments'),
            headers: headers,
            body: json.encode({
              'patient_id': payment.patientId,
              'amount': payment.amount,
              if (payment.paymentDate != null)
                'payment_date': payment.paymentDate!.toIso8601String(),
              'notes': payment.notes,
            }),
          )
          .timeout(const Duration(seconds: 10));

      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('فشل في إضافة الدفعة: $e');
    }
  }

  // جلب مدفوعات مريض معين
  static Future<List<Payment>> getPatientPayments(String patientId) async {
    try {
      final response = await http
          .get(
            Uri.parse(
                '$baseUrl${ApiConfig.patientsPrefix}/$patientId/payments'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      final data = _handleResponse(response) as List<dynamic>;
      return data
          .map((json) => Payment.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('فشل في جلب مدفوعات المريض: $e');
    }
  }

  // إضافة مريض جديد
  static Future<Patient> addPatient(Patient patient) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiConfig.patientsPrefix}/'),
            headers: headers,
            body: json.encode({
              'name': patient.name,
              'phone': patient.phone,
              'total_amount': patient.totalAmount,
              'installments_months': patient.installmentsMonths,
              if (patient.registrationDate != null)
                'registration_date':
                    patient.registrationDate!.toIso8601String(),
              'notes': patient.notes,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = _handleResponse(response);
      return Patient.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('فشل في إضافة المريض: $e');
    }
  }

  // تحديث بيانات مريض
  static Future<void> updatePatient(String patientId, Patient patient) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl${ApiConfig.patientsPrefix}/$patientId'),
            headers: headers,
            body: json.encode({
              'name': patient.name,
              'phone': patient.phone,
              'total_amount': patient.totalAmount,
              'installments_months': patient.installmentsMonths,
              if (patient.registrationDate != null)
                'registration_date':
                    patient.registrationDate!.toIso8601String(),
              'notes': patient.notes,
              'is_completed': patient.isCompleted,
              'remaining_amount': patient.remainingAmount,
            }),
          )
          .timeout(const Duration(seconds: 10));

      _handleResponse(response);
    } catch (e) {
      throw Exception('فشل في تحديث بيانات المريض: $e');
    }
  }

  // تحديث دفعة (تاريخ/ملاحظات)
  static Future<Map<String, dynamic>> updatePayment({
    required String patientId,
    required String paymentId,
    DateTime? paymentDate,
    String? notes,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (paymentDate != null)
        body['payment_date'] = paymentDate.toIso8601String();
      if (notes != null) body['notes'] = notes;
      final response = await http
          .put(
            Uri.parse(
                '$baseUrl${ApiConfig.patientsPrefix}/$patientId/payments/$paymentId'),
            headers: headers,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 10));

      return _handleResponse(response) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('فشل في تحديث الدفعة: $e');
    }
  }

  // حذف دفعة
  static Future<void> deletePayment({
    required String patientId,
    required String paymentId,
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse(
                '$baseUrl${ApiConfig.patientsPrefix}/$patientId/payments/$paymentId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      _handleResponse(response);
    } catch (e) {
      throw Exception('فشل في حذف الدفعة: $e');
    }
  }

  // حذف مريض
  static Future<void> deletePatient(String patientId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl${ApiConfig.patientsPrefix}/$patientId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      _handleResponse(response);
    } catch (e) {
      throw Exception('فشل في حذف المريض: $e');
    }
  }

  // تحميل تقرير PDF لمريض
  static Future<List<int>> getPatientReport(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/form/$patientId'),
        headers: {'Accept': 'application/pdf', ...headers},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      } else {
        throw HttpException(
          'HTTP ${response.statusCode}: ${response.body}',
          uri: response.request?.url,
        );
      }
    } catch (e) {
      throw Exception('فشل في تحميل التقرير: $e');
    }
  }

  // جلب المرضى المتأخرين
  static Future<List<Patient>> getOverduePatients() async {
    try {
      // محاولة استدعاء نقطة نهاية مخصصة إذا كانت متاحة على الخادم
      final response = await http
          .get(
            Uri.parse('$baseUrl${ApiConfig.patientsPrefix}/?overdue_only=true'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      final dynamic data = _handleResponse(response);
      if (data is List) {
        return data
            .map((e) => Patient.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      // إذا لم تكن الاستجابة بالشكل المتوقع، انتقل لحساب محلي عبر bootstrap
      throw const FormatException('Unexpected response format');
    } catch (_) {
      // فallback: استخدام bootstrap ثم التصفية محلياً
      final bootstrap = await getBootstrapData();
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      final List<Patient> overdue = bootstrap.patients.where((p) {
        if (p.remainingAmount <= 0) return false;
        final DateTime nextDate =
            p.nextPaymentDate ?? p.calculatedNextPaymentDate;
        return !nextDate.isAfter(today);
      }).toList()
        ..sort((a, b) {
          final int cmpDays = b.daysOverdue.compareTo(a.daysOverdue);
          if (cmpDays != 0) return cmpDays;
          return b.remainingAmount.compareTo(a.remainingAmount);
        });
      return overdue;
    }
  }

  // جلب المرضى الذين لديهم مبالغ متبقية للدفع
  static Future<List<Patient>> getPatientsWithPendingPayments() async {
    try {
      // إذا كانت نقطة النهاية متاحة على الخادم
      final response = await http
          .get(
            Uri.parse('$baseUrl${ApiConfig.patientsPrefix}/?completed=false'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      final dynamic data = _handleResponse(response);
      if (data is List) {
        return data
            .map((e) => Patient.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      // استمرار إلى الفallback إذا كان الشكل غير متوقع
      throw const FormatException('Unexpected response format');
    } catch (_) {
      // فallback: جلب bootstrap والتصفية محلياً
      final bootstrap = await getBootstrapData();
      final List<Patient> pending = bootstrap.patients
          .where((p) => p.remainingAmount > 0)
          .toList()
        ..sort((a, b) => b.remainingAmount.compareTo(a.remainingAmount));
      return pending;
    }
  }
}

// نموذج للإحصائيات
class Statistics {
  final int totalPatients;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final int overduePatients;
  final int completedPatients;
  final int activePatients;

  Statistics({
    required this.totalPatients,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.overduePatients,
    this.completedPatients = 0,
    this.activePatients = 0,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      totalPatients: json['total_patients'] as int,
      totalAmount: (json['total_amount'] as num).toDouble(),
      paidAmount: (json['total_paid'] as num).toDouble(),
      remainingAmount: (json['total_remaining'] as num).toDouble(),
      overduePatients: json['overdue_summary']?['total_overdue'] as int? ?? 0,
      completedPatients: json['completed_patients'] as int? ?? 0,
      activePatients: json['active_patients'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_patients': totalPatients,
        'total_amount': totalAmount,
        'paid_amount': paidAmount,
        'remaining_amount': remainingAmount,
        'overdue_patients': overduePatients,
        'completed_patients': completedPatients,
        'active_patients': activePatients,
      };

  @override
  String toString() {
    return toJson().toString();
  }
}

// نموذج بيانات bootstrap
class BootstrapData {
  final List<Patient> patients;
  final List<Payment> payments;
  final Statistics statistics;

  BootstrapData({
    required this.patients,
    required this.payments,
    required this.statistics,
  });

  factory BootstrapData.fromJson(Map<String, dynamic> json) {
    return BootstrapData(
      patients: (json['patients'] as List<dynamic>)
          .map((e) => Patient.fromJson(e as Map<String, dynamic>))
          .toList(),
      payments: (json['payments'] as List<dynamic>)
          .map((e) => Payment.fromJson(e as Map<String, dynamic>))
          .toList(),
      statistics:
          Statistics.fromJson(json['statistics'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'patients': patients.map((p) => p.toJson()).toList(),
        'payments': payments.map((p) => p.toJson()).toList(),
        'statistics': statistics.toJson(),
      };
}
