import 'package:url_launcher/url_launcher.dart';
import 'number_formatter.dart';
import '../models/patient.dart';
import 'package:intl/intl.dart';

class WhatsAppHelper {
  // إرسال رسالة تذكير بالتسديد المتأخر
  static Future<bool> sendOverduePaymentReminder({
    required Patient patient,
    required double remainingAmount,
    required double monthlyAmount,
    required int overdueDays,
  }) async {
    final message = _createOverduePaymentMessage(
      patientName: patient.name,
      remainingAmount: remainingAmount,
      monthlyAmount: monthlyAmount,
      overdueDays: overdueDays,
    );

    return await _sendWhatsAppMessage(patient.phone, message);
  }

  // إرسال رسالة تذكير بموعد
  static Future<bool> sendAppointmentReminder({
    required Patient patient,
    required DateTime appointmentDate,
    String? additionalNotes,
  }) async {
    final message = _createAppointmentMessage(
      patientName: patient.name,
      appointmentDate: appointmentDate,
      additionalNotes: additionalNotes,
    );

    return await _sendWhatsAppMessage(patient.phone, message);
  }

  // إرسال رسالة عامة للمريض
  static Future<bool> sendGeneralMessage({
    required Patient patient,
    required String message,
  }) async {
    return await _sendWhatsAppMessage(patient.phone, message);
  }

  // إنشاء رسالة التذكير بالتسديد المتأخر
  static String _createOverduePaymentMessage({
    required String patientName,
    required double remainingAmount,
    required double monthlyAmount,
    required int overdueDays,
  }) {
    return '''
السلام عليكم ورحمة الله وبركاته

الأستاذ/ة المحترم/ة $patientName

نحيطكم علماً بأن لديكم تأخير في التسديد الشهري لعيادة فرح لطب الأسنان.

📅 عدد الأيام المتأخرة: $overdueDays يوم
💰 القسط الشهري المستحق: ${NumberFormatter.formatNumber(monthlyAmount)} دينار
💳 المبلغ المتبقي الإجمالي: ${NumberFormatter.formatNumber(remainingAmount)} دينار

نرجو منكم التواصل معنا لتسوية المبلغ المستحق في أقرب وقت ممكن.

شكراً لتفهمكم وتعاونكم
عيادة فرح لطب الأسنان
    '''
        .trim();
  }

  // إنشاء رسالة تذكير بالموعد
  static String _createAppointmentMessage({
    required String patientName,
    required DateTime appointmentDate,
    String? additionalNotes,
  }) {
    final formattedDate = DateFormat('yyyy/MM/dd').format(appointmentDate);
    final formattedTime = DateFormat('HH:mm').format(appointmentDate);

    String message = '''
السلام عليكم ورحمة الله وبركاته

الأستاذ/ة المحترم/ة $patientName

نذكركم بموعدكم في عيادة فرح لطب الأسنان:

📅 التاريخ: $formattedDate
🕐 الوقت: $formattedTime

نرجو الحضور في الوقت المحدد، وفي حالة عدم التمكن من الحضور يرجى إبلاغنا مسبقاً.
    '''
        .trim();

    if (additionalNotes != null && additionalNotes.isNotEmpty) {
      message += '\n\n📝 ملاحظات إضافية:\n$additionalNotes';
    }

    message += '\n\nشكراً لتفهمكم\nعيادة فرح لطب الأسنان';

    return message;
  }

  // إرسال رسالة الواتساب عبر WhatsApp Web في المتصفح
  static Future<bool> _sendWhatsAppMessage(
      String phoneNumber, String message) async {
    try {
      // نظّف الرقم إلى أرقام فقط
      String digits = phoneNumber.replaceAll(RegExp(r'\D'), '');

      // حوله إلى صيغة دولية عراقية (بدون +) إذا احتاج
      if (digits.startsWith('0')) {
        digits = '964${digits.substring(1)}';
      } else if (!digits.startsWith('964')) {
        digits = '964$digits';
      }

      // ترميز الرسالة
      final encodedMessage = Uri.encodeComponent(message);

      // افتح WhatsApp Web في المتصفح مباشرة
      final Uri webUrl =
          Uri.parse('https://wa.me/$digits?text=$encodedMessage');

      if (await canLaunchUrl(webUrl)) {
        final ok =
            await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        if (ok) return true;
      }

      print('لا يمكن فتح WhatsApp Web للرقم: $phoneNumber');
      return false;
    } catch (e) {
      print('خطأ في إرسال رسالة الواتساب: $e');
      return false;
    }
  }

  // التحقق من صحة رقم الهاتف
  static bool isValidPhoneNumber(String phoneNumber) {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    return cleanPhone.length >= 10 && cleanPhone.length <= 15;
  }

  // تنسيق رقم الهاتف للعرض
  static String formatPhoneNumber(String phoneNumber) {
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleanPhone.startsWith('+964')) {
      final number = cleanPhone.substring(4);
      if (number.length == 10) {
        return '+964 ${number.substring(0, 3)} ${number.substring(3, 6)} ${number.substring(6)}';
      }
    }

    return phoneNumber;
  }
}
