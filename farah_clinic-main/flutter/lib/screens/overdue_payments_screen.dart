import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/patient.dart';
import '../models/payment.dart';
import '../utils/whatsapp_helper.dart';
import '../utils/number_formatter.dart';

class OverduePaymentsScreen extends StatefulWidget {
  const OverduePaymentsScreen({super.key});

  @override
  State<OverduePaymentsScreen> createState() => _OverduePaymentsScreenState();
}

class _OverduePaymentsScreenState extends State<OverduePaymentsScreen> {
  Future<List<Patient>>? _overdueFuture; // منع تكرار الطلبات
  final Map<String, TextEditingController> _notesControllers = {};
  final Map<String, String> _savedNotes = {}; // لحفظ الملاحظات

  @override
  void dispose() {
    for (var controller in _notesControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // استخدم Future واحد
    _overdueFuture = context.read<AppProvider>().getOverduePatients();
  }

  // حساب عدد الأيام المتأخرة
  int _calculateOverdueDays(Patient patient, List<Payment> payments) {
    final patientPayments =
        payments.where((p) => p.patientName == patient.name).toList();

    // حساب إجمالي المبلغ المدفوع
    final totalPaid =
        patientPayments.fold<double>(0, (sum, payment) => sum + payment.amount);

    // إذا سدد كامل المبلغ، فلا يوجد تأخير
    if (totalPaid >= patient.totalAmount) {
      return 0;
    }

    // حساب عدد الأشهر المنقضية منذ التسجيل بطريقة أكثر دقة
    final now = DateTime.now();
    final registrationDate = patient.registrationDate ?? DateTime.now();

    int monthsPassed = (now.year - registrationDate.year) * 12 +
        (now.month - registrationDate.month);

    // إذا لم يكمل الشهر الحالي بعد، نقلل شهر واحد
    if (now.day < registrationDate.day) {
      monthsPassed--;
    }

    // إذا لم يمر شهر كامل بعد، لا يوجد تأخير
    if (monthsPassed <= 0) {
      return 0;
    }

    // حساب المبلغ المطلوب دفعه حتى الآن
    final monthlyAmount = patient.totalAmount / patient.installmentsMonths;
    final expectedAmountTillNow = monthlyAmount * monthsPassed;

    // إذا كان المبلغ المدفوع أقل من المطلوب
    if (totalPaid < expectedAmountTillNow) {
      // حساب عدد الأشهر المتأخرة
      final shortfall = expectedAmountTillNow - totalPaid;
      final monthsOverdue = (shortfall / monthlyAmount).ceil();

      // حساب تاريخ الدفعة المتأخرة الأولى
      final firstOverdueDate = DateTime(
        registrationDate.year,
        registrationDate.month + (monthsPassed - monthsOverdue + 1),
        registrationDate.day,
      );

      return now.difference(firstOverdueDate).inDays;
    }

    return 0;
  }

  // الحصول على المرضى المتأخرين
  List<Patient> _getOverduePatients(
      List<Patient> patients, List<Payment> payments) {
    return patients.where((patient) {
      final overdueDays = _calculateOverdueDays(patient, payments);
      return overdueDays > 0;
    }).toList();
  }

  // حساب المبلغ المتبقي للمريض
  double _getRemainingAmount(Patient patient, List<Payment> payments) {
    final patientPayments =
        payments.where((p) => p.patientName == patient.name).toList();
    final totalPaid =
        patientPayments.fold<double>(0, (sum, payment) => sum + payment.amount);
    return patient.totalAmount - totalPaid;
  }

  // حساب المبلغ الشهري
  double _getMonthlyAmount(Patient patient) {
    return patient.totalAmount / patient.installmentsMonths;
  }

  // طباعة معلومات التشخيص
  void _printDebugInfo(List<Patient> patients, List<Payment> payments) {
    print('=== معلومات تشخيص التسديدات المتأخرة ===');
    print('عدد المرضى: ${patients.length}');
    print('عدد الدفعات: ${payments.length}');

    for (var patient in patients) {
      final patientPayments =
          payments.where((p) => p.patientName == patient.name).toList();
      final totalPaid = patientPayments.fold<double>(
          0, (sum, payment) => sum + payment.amount);
      final overdueDays = _calculateOverdueDays(patient, payments);
      final monthlyAmount = _getMonthlyAmount(patient);

      final now = DateTime.now();
      final registrationDate = patient.registrationDate ?? DateTime.now();
      int monthsPassed = (now.year - registrationDate.year) * 12 +
          (now.month - registrationDate.month);
      if (now.day < registrationDate.day) {
        monthsPassed--;
      }
      final expectedAmount = monthlyAmount * monthsPassed;

      print('\\n--- المريض: ${patient.name} ---');
      print(
          'تاريخ التسجيل: ${DateFormat('yyyy-MM-dd').format(patient.registrationDate ?? DateTime.now())}');
      print('المبلغ الإجمالي: ${patient.totalAmount}');
      print('عدد الأشهر الإجمالي: ${patient.installmentsMonths}');
      print('المبلغ الشهري: ${NumberFormatter.formatNumber(monthlyAmount)}');
      print('الأشهر المنقضية: $monthsPassed');
      print('المبلغ المطلوب حتى الآن: ${NumberFormatter.formatNumber(expectedAmount)}');
      print('المبلغ المدفوع: ${NumberFormatter.formatNumber(totalPaid)}');
      print('عدد الدفعات: ${patientPayments.length}');
      print('عدد الأيام المتأخرة: $overdueDays');
      print('هل متأخر؟ ${overdueDays > 0 ? 'نعم' : 'لا'}');
    }
    print('===============================');
  }

  // عرض معلومات التشخيص في نافذة
  void _showDebugInfo(BuildContext context) {
    final appProvider = context.read<AppProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('معلومات التشخيص'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('عدد المرضى: ${appProvider.patients.length}'),
                Text('عدد الدفعات: ${appProvider.payments.length}'),
                const Divider(),
                ...appProvider.patients.map((patient) {
                  final patientPayments = appProvider.payments
                      .where((p) => p.patientName == patient.name)
                      .toList();
                  final totalPaid = patientPayments.fold<double>(
                      0, (sum, payment) => sum + payment.amount);
                  final overdueDays =
                      _calculateOverdueDays(patient, appProvider.payments);
                  final monthlyAmount = _getMonthlyAmount(patient);

                  final now = DateTime.now();
                  final registrationDate =
                      patient.registrationDate ?? DateTime.now();
                  int monthsPassed = (now.year - registrationDate.year) * 12 +
                      (now.month - registrationDate.month);
                  if (now.day < registrationDate.day) {
                    monthsPassed--;
                  }
                  final expectedAmount = monthlyAmount * monthsPassed;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                          Text(
                              'تاريخ التسجيل: ${DateFormat('yyyy-MM-dd').format(patient.registrationDate ?? DateTime.now())}'),
                          Text('المبلغ الإجمالي: ${patient.totalAmount} دينار'),
                          Text('عدد الأشهر: ${patient.installmentsMonths}'),
                          Text(
                              'المبلغ الشهري: ${NumberFormatter.formatNumber(monthlyAmount)} دينار'),
                          Text('الأشهر المنقضية: $monthsPassed'),
                          Text(
                              'المبلغ المطلوب: ${NumberFormatter.formatNumber(expectedAmount)} دينار'),
                          Text(
                              'المبلغ المدفوع: ${NumberFormatter.formatNumber(totalPaid)} دينار'),
                          Text('عدد الدفعات: ${patientPayments.length}'),
                          Text(
                            'عدد الأيام المتأخرة: $overdueDays',
                            style: TextStyle(
                              color:
                                  overdueDays > 0 ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EDE9),
      appBar: AppBar(
        toolbarHeight: 80, // ارتفاع AppBar
        backgroundColor: const Color.fromARGB(255, 30, 84, 120),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Center(
          child: Text(
            'التسديدات المتأخرة للمراجعين',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Cairo',
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white, size: 30),
            onPressed: () => _showDebugInfo(context),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return FutureBuilder<List<Patient>>(
            future: _overdueFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color.fromARGB(255, 30, 84, 120),
                  ),
                );
              }

              final overduePatients = snapshot.data ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // الجدول الرئيسي
                    _buildOverdueTable(overduePatients, appProvider.payments),

                    const SizedBox(height: 24),

                    // كارتات الإحصائيات
                    _buildStatisticsCards(
                        overduePatients, appProvider.payments),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOverdueTable(
      List<Patient> overduePatients, List<Payment> payments) {
    if (overduePatients.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // عنوان الجدول
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 30, 84, 120),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning,
                  color: Colors.white,
                  size: 30,
                ),
                const SizedBox(width: 8),
                const Text(
                  'المراجعين المتأخرين في التسديد',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${overduePatients.length} مريض',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // رؤوس الأعمدة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFD0EBFF),
            ),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2.5), // اسم المراجع
                1: FlexColumnWidth(2), // تاريخ التسجيل
                2: FlexColumnWidth(1.5), // عدد الأيام المتأخرة
                3: FlexColumnWidth(2), // المبلغ المتبقي
                4: FlexColumnWidth(2), // القسط المستحق
                5: FlexColumnWidth(2), // رقم الهاتف
                6: FlexColumnWidth(3), // الملاحظات
              },
              children: [
                TableRow(
                  children: [
                    _buildTableHeader('اسم المراجع'),
                    _buildTableHeader('تاريخ تسجيل\nالاستمارة'),
                    _buildTableHeader('عدد الأيام\nالمتأخرة'),
                    _buildTableHeader('المبلغ المتبقي'),
                    _buildTableHeader('القسط المستحق'),
                    _buildTableHeader('رقم الهاتف'),
                    _buildTableHeader('تواصل واتساب'),
                  ],
                ),
              ],
            ),
          ),

          // بيانات الجدول
          ...overduePatients.asMap().entries.map((entry) {
            final index = entry.key;
            final patient = entry.value;
            return _buildTableRow(patient, payments, index);
          }),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF649FCC),
          fontFamily: 'Cairo',
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableRow(Patient patient, List<Payment> payments, int index) {
    final overdueDays = _calculateOverdueDays(patient, payments);
    final remainingAmount = _getRemainingAmount(patient, payments);
    final monthlyAmount = _getMonthlyAmount(patient);

    // إنشاء controller للملاحظات إذا لم يكن موجوداً
    if (!_notesControllers.containsKey(patient.name)) {
      _notesControllers[patient.name] = TextEditingController();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.5),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(1.5),
          3: FlexColumnWidth(2),
          4: FlexColumnWidth(2),
          5: FlexColumnWidth(2),
          6: FlexColumnWidth(3),
        },
        children: [
          TableRow(
            children: [
              _buildTableCell(patient.name, isName: true),
              _buildTableCell(DateFormat('yyyy/MM/dd')
                  .format(patient.registrationDate ?? DateTime.now())),
              _buildOverdueDaysCell(overdueDays),
              _buildAmountCell(remainingAmount, isRemaining: true),
              _buildAmountCell(monthlyAmount),
              _buildTableCell(patient.phone),
              _buildWhatsAppCell(
                  patient, remainingAmount, monthlyAmount, overdueDays),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isName = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 20,
          fontFamily: 'Cairo',
          fontWeight: isName ? FontWeight.w600 : FontWeight.normal,
          color: isName ? const Color(0xFF649FCC) : Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildOverdueDaysCell(int days) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Text(
          '$days يوم',
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAmountCell(double amount, {bool isRemaining = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Text(
        '${NumberFormatter.formatNumber(amount)} دينار',
        style: TextStyle(
          fontSize: 20,
          fontFamily: 'cairo',
          fontWeight: FontWeight.w600,
          color: isRemaining ? Colors.red : const Color(0xFF649FCC),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // إرسال رسالة واتساب للتذكير بالتسديد
  Future<void> _sendWhatsAppReminder(Patient patient, double remainingAmount,
      double monthlyAmount, int overdueDays) async {
    try {
      final success = await WhatsAppHelper.sendOverduePaymentReminder(
        patient: patient,
        remainingAmount: remainingAmount,
        monthlyAmount: monthlyAmount,
        overdueDays: overdueDays,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم فتح الواتساب لإرسال رسالة للمريض ${patient.name}',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                ),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'حدث خطأ في فتح الواتساب. تأكد من أن الواتساب مثبت على الجهاز',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                ),
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ: $e',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // زر الواتساب للتواصل مع المريض
  Widget _buildWhatsAppCell(Patient patient, double remainingAmount,
      double monthlyAmount, int overdueDays) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF25D366), // لون الواتساب الأخضر
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF25D366).withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.chat,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () => _sendWhatsAppReminder(
                patient, remainingAmount, monthlyAmount, overdueDays),
            tooltip: 'إرسال رسالة تذكير عبر الواتساب',
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد تسديدات متأخرة',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'جميع المرضى ملتزمون بمواعيد التسديد',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(
      List<Patient> overduePatients, List<Payment> payments) {
    double totalRemainingAmount = 0;
    double totalMonthlyAmount = 0;

    for (var patient in overduePatients) {
      totalRemainingAmount += _getRemainingAmount(patient, payments);
      totalMonthlyAmount += _getMonthlyAmount(patient);
    }

    return Row(
      children: [
        // كارت المبلغ المتبقي الكلي
        Expanded(
          child: _buildStatisticsCard(
            title: 'المبلغ المتبقي الكلي',
            amount: totalRemainingAmount,
            icon: Icons.warning,
            color: Colors.red,
            backgroundColor: Colors.red.withOpacity(0.1),
          ),
        ),

        const SizedBox(width: 16),

        // كارت مجموع التسديد الشهري
        Expanded(
          child: _buildStatisticsCard(
            title: 'مجموع التسديد الشهري',
            amount: totalMonthlyAmount,
            icon: Icons.attach_money,
            color: const Color(0xFF649FCC),
            backgroundColor: const Color(0xFF649FCC).withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${NumberFormatter.formatNumber(amount)} دينار',
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
