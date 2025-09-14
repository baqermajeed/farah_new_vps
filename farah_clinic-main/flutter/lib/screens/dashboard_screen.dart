import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/add_patient_dialog.dart';
import 'overdue_payments_screen.dart';
import 'invoice_form_screen.dart';
import 'notifications_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/payment.dart';
import '../models/patient.dart';
import '../utils/number_formatter.dart';

/// نوع الكارد - دائري أو شريطي
enum CardType { circular, bar }

class PatientColumnConfig {
  final String title;
  final int? flex;
  final double? width;
  final TextAlign headerAlign;
  final TextAlign cellAlign;
  final EdgeInsets? headerPadding;
  final EdgeInsets? cellPadding;
  final double headerGapAfter;
  final double cellGapAfter;
  final Widget Function(dynamic patient) cellBuilder;
  final TextStyle? headerStyle;

  const PatientColumnConfig({
    required this.title,
    this.flex,
    this.width,
    this.headerAlign = TextAlign.right,
    this.cellAlign = TextAlign.right,
    this.headerPadding,
    this.cellPadding,
    this.headerGapAfter = 0,
    this.cellGapAfter = 0,
    required this.cellBuilder,
    this.headerStyle,
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _searchQuery = '';
  @override
  void initState() {
    super.initState();
    // تحميل البيانات عند بدء الشاشة ثم إضافة مريض تجريبي متأخر إن لم يوجد
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initApp();
    });
  }

  Future<void> _initApp() async {
    final app = context.read<AppProvider>();
    await app.loadData();
    await _addTestOverduePatient(app);
  }

  Future<void> _addTestOverduePatient(AppProvider app) async {
    const String testName = 'مراجع متأخر (تجربة)';
    final bool exists = app.patients.any((p) => p.name == testName);
    if (exists) return;
    final Patient demo = Patient(
      name: testName,
      phone: '0780000000',
      totalAmount: 1000000,
      installmentsMonths: 10,
      registrationDate: DateTime.now().subtract(const Duration(days: 120)),
      totalPaid: 100000,
      remainingAmount: 900000,
      nextPaymentDate: DateTime.now().subtract(const Duration(days: 10)),
      paymentsCount: 10,
      isCompleted: false,
    );
    try {
      await app.addPatient(demo);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          if (appProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF5BA0D4),
              ),
            );
          }

          return Stack(
            children: [
              // صف علوي يحتوي الأزرار الثلاثة بشكل أفقي
              Positioned(
                left: 350,
                top: 20,
                right: 180, // اترك مساحة للعمود الأيمن بعد تصغيره
                child: SizedBox(
                  height: 70,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      textDirection:
                          TextDirection.rtl, // 🔹 ترتيب من اليمين لليسار
                      children: [
                        SizedBox(
                          width: 320,
                          height: 60,
                          child: _buildTopButton(
                            'تسجيل مريض جديد',
                            Icons.person_add_outlined,
                            () => showDialog(
                              context: context,
                              builder: (context) => const AddPatientDialog(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 320,
                          height: 60,
                          child: _buildTopButton(
                            'تسديد كمبيالة',
                            Icons.payment,
                            () => showPaymentDialog(context),
                          ),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 320,
                          height: 60,
                          child: _buildTopButton(
                            'التسديدات المتأخرة',
                            Icons.refresh_outlined,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const OverduePaymentsScreen()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // شريط البحث أسفل الأزرار بمسافة 70، يبعد 170 عن الحافة اليمنى
              Positioned(
                top: 30 + 70 + 30,
                right: 185,
                child: SizedBox(
                  width: 600,
                  height: 50,
                  child: _buildSearchBar(),
                ),
              ),

              // نص عنوان التنبيهات
              Positioned(
                top: 30 + 70 + 50 + 50, // فوق كونتينر الإشعارات بمسافة 20
                right: 185, // نفس مسافة شريط البحث من الحافة اليمنى
                child: SizedBox(
                  width: 970,
                  child: Text(
                    'التنبيــهـــات الهـامـة و الفــوريـة',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Color.fromARGB(255, 30, 84, 120),
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ),

              // كونتينر الإشعارات أسفل شريط البحث بمسافة 50
              Positioned(
                top: 30 + 70 + 50 + 50 + 60, // أسفل شريط البحث بمسافة 50
                right: 185, // نفس مسافة شريط البحث من الحافة اليمنى
                child: SizedBox(
                  width: 1000,
                  height: 85,
                  child: _buildNotificationsContainer(),
                ),
              ),

              // جدول المرضى أسفل شريط الإشعارات بمسافة 20، وعلى بعد 20 من الأعمدة الجانبية وقاع الشاشة
              Positioned(
                top: 30 + 70 + 50 + 50 + 60 + 85 + 30, // أسفل الإشعارات بـ 20
                right: 185, // 20 من العمود الأيمن (right:30 + عرض 130 + ~25)
                left: 350, // 20 من العمود الأيسر (left:30 + عرض 300 + 20)
                bottom: 20, // 20 من القاع
                child: _buildPatientsTable(),
              ),

              // زر طباعة استمارة بمحاذاة شريط البحث مع مسافة 20 بينهما
              Positioned(
                top: 30 + 70 + 30,
                right: 170 + 600 + 40, // 170 + عرض شريط البحث + 20 مسافة
                child: SizedBox(
                  width: 290,
                  height: 50,
                  child: _buildSlimButton(
                    'طباعة استمارة',
                    Icons.print_outlined,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const InvoiceFormScreen()),
                    ),
                  ),
                ),
              ),

              // العمود الأيمن - الملف الشخصي
              Positioned(
                top: 10,
                right: 30,
                bottom: 10,
                child: Container(
                  width: 130,
                  height: 986,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromARGB(255, 30, 84, 120),
                        Color.fromARGB(255, 30, 84, 120),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50),
                      // صورة الملف الشخصي
                      Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: ClipOval(
                          child: Image.asset(
                            "assets/new-farah.png",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      // النص
                      Consumer<AppProvider>(
                        builder: (context, appProvider, child) {
                          return Column(
                            children: [
                              Text(
                                'عيادة فرح',
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const Spacer(),
                      // زر تسجيل الخروج
                      Consumer<AppProvider>(
                        builder: (context, appProvider, child) {
                          return PopupMenuButton<String>(
                            child: const Icon(
                              Icons.logout,
                              color: Colors.white,
                              size: 20, // حجم الأيقونة
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (value) async {
                              if (value == 'logout') {
                                await appProvider.logout();
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem<String>(
                                value: 'user_info',
                                enabled: false,
                                child: Text(
                                    'مرحباً ${appProvider.currentUser ?? 'المستخدم'}'),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem<String>(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(Icons.logout, size: 18),
                                    SizedBox(width: 8),
                                    Text('تسجيل الخروج'),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 30), // المسافة من القاع
                    ],
                  ),
                ),
              ),

              // زر الإشعارات في العمود الأيمن يبعد 350 عن الحافة السفلية
              Positioned(
                right: 65,
                bottom: 350,
                child: Consumer<AppProvider>(
                  builder: (context, appProvider, child) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Stack(
                          children: [
                            const Center(
                              child: Icon(
                                Icons.notifications,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            // الشارة بعدد الإشعارات
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Consumer<AppProvider>(
                                builder: (context, app, _) {
                                  final count = app.notificationPatients.length;
                                  if (count == 0)
                                    return const SizedBox.shrink();
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      count.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // العمود الأيسر - كروت الإحصائيات المحدثة
              Positioned(
                top: 10,
                left: 30,
                bottom: 10,
                child: Container(
                  width: 300,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromARGB(255, 30, 84, 120),
                        Color.fromARGB(255, 0, 0, 0)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment
                          .start, // أبقي باقي المحتويات كما هي
                      children: [
                        SizedBox(
                          height: 15,
                        ),
                        // العنوان فقط بمحاذاة اليمين
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'إحصائيات العيادة',
                            style: GoogleFonts.cairo(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: const Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                        ),
                        const SizedBox(height: 60),

                        // الإحصائيات الدائرية العلوية
                        _buildStatCardForColumn(
                          'إجمالي الكمبيالات',
                          NumberFormatter.formatNumber(appProvider.totalAmount),
                          Icons.account_balance_wallet,
                          Color.fromARGB(255, 30, 84, 120),
                          cardType: CardType.circular,
                          subtitle: 'المبلغ الكلي للكمبيالات',
                        ),
                        const SizedBox(height: 26),

                        _buildStatCardForColumn(
                          'المبالغ المسددة',
                          NumberFormatter.formatNumber(appProvider.paidAmount),
                          Icons.savings,
                          const Color(0xFF0E9EC8),
                          cardType: CardType.circular,
                          subtitle: 'المبالغ المسددة من الكمبيالات',
                        ),

                        SizedBox(
                          height: 40,
                        ), // الإحصائيات الشريطية السفلية
                        _buildStatCardForColumn(
                          'المبالغ المتبقية',
                          NumberFormatter.formatNumber(
                              appProvider.remainingAmount),
                          Icons.water_drop,
                          const Color.fromARGB(255, 95, 101, 113),
                          cardType: CardType.bar,
                        ),
                        SizedBox(
                          height: 16,
                        ),
                        _buildStatCardForColumn(
                          'الكمبيالات المتبقية',
                          '${appProvider.remainingBillsCount}',
                          Icons.receipt_long,
                          const Color.fromARGB(255, 108, 42, 42),
                          cardType: CardType.bar,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// ويدجت مخصص لعرض إحصائيات بتصميمات مختلفة مطابقة للتصميم المرفق
  Widget _buildStatCardForColumn(
    String title,
    String value,
    IconData icon,
    Color color, {
    CardType cardType = CardType.circular,
    String? subtitle,
  }) {
    if (cardType == CardType.circular) {
      return _buildCircularCard(title, value, icon, color, subtitle);
    } else {
      return _buildBarCard(title, value, icon, color);
    }
  }

  /// كارد دائري مع دائرة كبيرة في المنتصف (للإحصائيات الرئيسية)
  Widget _buildCircularCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String? subtitle,
  ) {
    return Container(
      width: 260,
      height: 120,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF236B8C).withOpacity(0.66), // اللون الجديد للمربع
        borderRadius: BorderRadius.circular(12),
        // ✅ تمت إزالة الـ Border (stroke)
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // الدائرة الكبيرة في أعلى المربع
          Positioned(
            top: -35,
            left: (200 / 2) - 10,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF14A3C9), // اللون الأول
                    Color(0xFF145566), // اللون الثاني
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF14A3C9).withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _formatValue(value),
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          // النصوص في منتصف المربع
          Positioned.fill(
            top: 40,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // العنوان الرئيسي
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color.fromARGB(255, 170, 205, 228),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // العنوان الفرعي
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// كارد شريطي أفقي (للإحصائيات الثانوية)
  Widget _buildBarCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // الشريط الأساسي
        Container(
          width: 260, // ✅ نفس عرض الكارد الدائري حتى يصيروا بمحاذاة واحدة
          height: 50,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerRight,
              colors: [
                Color(0xFF0E9EC8),
                Color(0xFF0E9EC8),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF26C6DA).withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 40),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!_shouldShowValueInCircle(value))
                  Text(
                    _formatValue(value),
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // الدائرة خارج الشريط من الجهة اليسرى
        Positioned(
          left: -15,
          top: -5,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: _shouldShowValueInCircle(value)
                  ? Text(
                      value,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      icon,
                      color: Colors.white,
                      size: 26,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  /// دالة مساعدة لتحديد ما إذا كانت القيمة يجب أن تظهر في الدائرة الصغيرة
  bool _shouldShowValueInCircle(String value) {
    // إذا كانت القيمة رقم صغير (أقل من 100) أو نص قصير
    final numValue = double.tryParse(value);
    return (numValue != null && numValue < 100) || value.length <= 3;
  }

  /// دالة مساعدة لتنسيق القيم الكبيرة
  String _formatValue(String value) {
    final numValue = double.tryParse(value);
    if (numValue != null && numValue >= 1000000) {
      return '${(numValue / 1000000).toStringAsFixed(1)}M';
    } else if (numValue != null && numValue >= 1000) {
      return '${(numValue / 1000).toStringAsFixed(1)}K';
    }
    return value;
  }

  // زر علوي مدمج للاستخدام ضمن صف الأزرار
  Widget _buildTopButton(String title, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 75,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 30, 84, 120), // لون الزر أزرق غامق
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 196, 9, 9).withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color:
                      const Color.fromARGB(255, 255, 255, 255), // أيقونة بيضاء
                  size: 24,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      color:
                          const Color.fromARGB(255, 255, 255, 255), // أزرق فاتح
                      fontWeight: FontWeight.w700, // يمكن تعديل الوزن إذا تريد
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // زر رفيع للطباعة
  Widget _buildSlimButton(String title, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 30, 84, 120),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 196, 9, 9).withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: const Color.fromARGB(255, 255, 255, 255),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      color: const Color.fromARGB(255, 255, 255, 255),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // شريط البحث عن المرضى مع أيقونة وظل ونص Cairo Bold أسود
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12), // زوايا الشريط
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 45, 44, 44)
                .withOpacity(0.1), // ظل خفيف
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        textDirection: TextDirection.rtl,
        textAlignVertical: TextAlignVertical.center, // النص بالسنتر عمودياً
        style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold, // Bold
            color: Colors.black, // لون النص أسود
            fontSize: 14),
        decoration: InputDecoration(
          hintText: 'ابحث عن مريض',
          hintTextDirection: TextDirection.rtl,
          hintStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.black54, // لون النص المساعد شوي فاتح
            fontSize: 14,
          ),
          filled: true,
          fillColor: Colors.white, // خلفية الشريط
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 0),

          // الأيقونة داخل كونتينر أزرق 50x50 مع بوردر ريديوس
          prefixIcon: Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 59, 155, 157),
              borderRadius: BorderRadius.circular(12), // زوايا الأيقونة
            ),
            child: const Icon(
              Icons.search,
              color: Colors.white,
              size: 24,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 50,
            minHeight: 50,
          ),

          // إزالة الحدود
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (query) {
          // يمكن لاحقاً ربطه ببحث فعلي من المزود
          setState(() => _searchQuery = query.trim());
        },
        onChanged: (value) {
          setState(() => _searchQuery = value.trim());
        },
      ),
    );
  }

  // كونتينر الإشعارات
  Widget _buildNotificationsContainer() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final hasNotifications = appProvider.notificationPatients.isNotEmpty;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          },
          child: Container(
            width: 910,
            height: 75,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(255, 45, 44, 44)
                      .withOpacity(0.1), // ظل خفيف
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
              color: const Color(0xFFFEFEEA), // لون كريمي فاتح
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                children: [
                  // سهم التنقل
                  const Icon(
                    Icons.arrow_back_ios,
                    color: Color(0xFF5BA0D4),
                    size: 16,
                  ),
                  const SizedBox(width: 15),
                  // النص
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          hasNotifications
                              ? 'لديك إشعارات جديدة اضغط لعرضها'
                              : 'لا توجد إشعارات',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.w800, // نفس الوزن السابق
                            color: const Color.fromARGB(
                                255, 30, 84, 120), // أزرق داكن
                          ),
                        ),
                        if (!hasNotifications) ...[
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'سيتم اعلامك بالجديد',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  color: const Color.fromARGB(
                                      255, 30, 31, 31), // أزرق فاتح
                                  fontWeight: FontWeight
                                      .normal, // يمكن تعديل الوزن إذا تريد
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.bolt,
                                color: Color(0xFFFF9800),
                                size: 16,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // جدول عرض المرضى
  Widget _buildPatientsTable() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        final patients = appProvider.patients;
        final List<dynamic> sortedPatients = List<dynamic>.from(patients)
          ..sort((a, b) {
            final da = _safeRegistrationDate(a);
            final db = _safeRegistrationDate(b);
            if (da == null && db == null) return 0;
            if (da == null) return 1; // null considered older
            if (db == null) return -1;
            return db.compareTo(da); // newest first
          });
        final filteredPatients = sortedPatients.where((p) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          final name = (p.name ?? '').toString().toLowerCase();
          final phone = (p.phone ?? '').toString().toLowerCase();
          return name.contains(q) || phone.contains(q);
        }).toList();
        final textStyle = GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2C3E50));
        final headerStyle = GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color.fromARGB(255, 59, 155, 157));

        final columns = <PatientColumnConfig>[
          PatientColumnConfig(
            title: 'تاريخ التسجيل',
            flex: 1,
            headerAlign: TextAlign.right,
            cellAlign: TextAlign.right,
            headerGapAfter: 30,
            cellGapAfter: 30,
            cellBuilder: (p) => Text(
              _formatDate(_safeRegistrationDate(p)),
              textAlign: TextAlign.right,
              style:
                  textStyle.copyWith(color: Color.fromARGB(255, 128, 155, 173)),
            ),
          ),
          PatientColumnConfig(
            title: 'اسم المريض',
            flex: 1,
            headerAlign: TextAlign.right,
            cellAlign: TextAlign.right,
            headerGapAfter: 30,
            cellGapAfter: 30,
            cellBuilder: (p) => Text(
              p.name,
              textAlign: TextAlign.right,
              style:
                  textStyle.copyWith(color: Color.fromARGB(255, 30, 84, 120)),
            ),
          ),
          PatientColumnConfig(
            title: 'رقم الهاتف',
            flex: 1,
            headerAlign: TextAlign.right,
            cellAlign: TextAlign.right,
            headerGapAfter: 30,
            cellGapAfter: 30,
            cellBuilder: (p) => Text(
              p.phone,
              textAlign: TextAlign.right,
              style:
                  textStyle.copyWith(color: Color.fromARGB(255, 128, 155, 173)),
            ),
          ),
          PatientColumnConfig(
            title: 'مبلغ الكمبيالة',
            flex: 1,
            headerAlign: TextAlign.right,
            cellAlign: TextAlign.right,
            headerGapAfter: 30,
            cellGapAfter: 30,
            cellBuilder: (p) => Text(
              NumberFormatter.formatNumber(p.totalAmount),
              textAlign: TextAlign.right,
              style:
                  textStyle.copyWith(color: Color.fromARGB(255, 128, 155, 173)),
            ),
          ),
          PatientColumnConfig(
            title: 'الإجراء',
            width: 150,
            headerAlign: TextAlign.center,
            cellAlign: TextAlign.center,
            headerGapAfter: 0,
            cellGapAfter: 0,
            cellPadding: const EdgeInsets.only(right: 40),
            cellBuilder: (p) => SizedBox(
              width: 90,
              child: ElevatedButton(
                onPressed: () => _showPatientInfo(p),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 59, 155, 157),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                ),
                child: Text('عرض',
                    style: GoogleFonts.cairo(
                        fontSize: 18, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              top: 15,
              bottom: 30,
              left: 40,
              right: 10,
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'جـــدول عـــرض المـــرضى',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        color: Color.fromARGB(255, 30, 84, 120),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  // رأس الجدول
                  Padding(
                    padding: const EdgeInsets.only(right: 30),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ...() {
                          final widgets = <Widget>[];
                          for (var i = 0; i < columns.length; i++) {
                            final col = columns[i];
                            final headerText = Padding(
                              padding: col.headerPadding ?? EdgeInsets.zero,
                              child: Text(
                                col.title,
                                textAlign: col.headerAlign,
                                style: col.headerStyle ?? headerStyle,
                              ),
                            );
                            if (col.width != null) {
                              widgets.add(SizedBox(
                                  width: col.width!, child: headerText));
                            } else {
                              widgets.add(Expanded(
                                  flex: col.flex ?? 1, child: headerText));
                            }
                            if (i < columns.length - 1 &&
                                col.headerGapAfter > 0) {
                              widgets.add(SizedBox(width: col.headerGapAfter));
                            }
                          }
                          return widgets;
                        }(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // صفوف البيانات
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 30),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            for (final p in filteredPatients) ...[
                              Row(
                                textDirection: TextDirection.rtl,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ...() {
                                    final widgets = <Widget>[];
                                    for (var i = 0; i < columns.length; i++) {
                                      final col = columns[i];
                                      Widget cell = col.cellBuilder(p);
                                      if (col.cellPadding != null) {
                                        cell = Padding(
                                            padding: col.cellPadding!,
                                            child: cell);
                                      }
                                      if (col.width != null) {
                                        widgets.add(SizedBox(
                                            width: col.width!, child: cell));
                                      } else {
                                        widgets.add(Expanded(
                                            flex: col.flex ?? 1, child: cell));
                                      }
                                      if (i < columns.length - 1 &&
                                          col.cellGapAfter > 0) {
                                        widgets.add(
                                            SizedBox(width: col.cellGapAfter));
                                      }
                                    }
                                    return widgets;
                                  }(),
                                ],
                              ),
                              const SizedBox(height: 30),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  DateTime? _safeRegistrationDate(dynamic p) {
    try {
      final date = (p.registrationDate as DateTime?);
      return date;
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    final d = DateTime(dt.year, dt.month, dt.day);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void _showPatientInfo(dynamic p) async {
    final app = context.read<AppProvider>();

    // جلب مدفوعات المريض من API
    final payments = await app.getPatientPaymentsFromAPI(p.id);

    final Color primary = const Color.fromARGB(255, 30, 84, 120);
    final Color accent = const Color.fromARGB(255, 59, 155, 157);

    final DateTime? registration = _safeRegistrationDate(p);
    final DateTime nextPay = p.nextPaymentDate ?? p.calculatedNextPaymentDate;
    final double dialogMaxHeight = MediaQuery.of(context).size.height * 0.8;

    showDialog(
      context: context,
      builder: (context) {
        final bool isAdmin = context.read<AppProvider>().isAdmin;
        // int editableMonths = p.installmentsMonths; // لم يعد مستخدماً
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          titlePadding: EdgeInsets.zero,
          contentPadding: EdgeInsets.zero,
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              width: 720,
              height: dialogMaxHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary, accent],
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                      ),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Row(
                      textDirection: TextDirection.ltr,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    p.name,
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.cairo(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    p.phone,
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Info chips
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final double gap = 12;
                              final double threeColWidth =
                                  (constraints.maxWidth - (gap * 2)) / 3;
                              final double twoColWidth =
                                  (constraints.maxWidth - gap) / 2;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    textDirection: TextDirection.rtl,
                                    children: [
                                      SizedBox(
                                        width: threeColWidth,
                                        child: _infoChip(
                                            'المبلغ الكلي',
                                            NumberFormatter.formatNumber(
                                                p.totalAmount),
                                            accent),
                                      ),
                                      SizedBox(width: gap),
                                      SizedBox(
                                        width: threeColWidth,
                                        child: _infoChip(
                                            'المبلغ المتبقي',
                                            NumberFormatter.formatNumber(
                                                p.remainingAmount),
                                            const Color(0xFFEF5350)),
                                      ),
                                      SizedBox(width: gap),
                                      SizedBox(
                                        width: threeColWidth,
                                        child: _infoChip(
                                            'المبلغ المسدد',
                                            NumberFormatter.formatNumber(
                                                p.totalPaid),
                                            const Color(0xFF66BB6A)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    alignment: WrapAlignment.end,
                                    spacing: gap,
                                    runSpacing: gap,
                                    children: [
                                      SizedBox(
                                        width: twoColWidth,
                                        child: isAdmin
                                            ? _EditableInfoChip(
                                                title: 'تاريخ التسجيل',
                                                value:
                                                    _formatDate(registration),
                                                color: primary,
                                                onTap: () async {
                                                  final picked =
                                                      await showDatePicker(
                                                    context: context,
                                                    initialDate: registration ??
                                                        DateTime.now(),
                                                    firstDate: DateTime(2000),
                                                    lastDate: DateTime(2100),
                                                  );
                                                  if (picked != null) {
                                                    await app.updatePatient(
                                                      (p as Patient).copyWith(
                                                          registrationDate:
                                                              picked),
                                                    );
                                                  }
                                                },
                                              )
                                            : _infoChip(
                                                'تاريخ التسجيل',
                                                _formatDate(registration),
                                                primary),
                                      ),
                                      SizedBox(
                                        width: twoColWidth,
                                        child: _infoChip('تاريخ التسديد القادم',
                                            _formatDate(nextPay), primary),
                                      ),
                                      SizedBox(
                                        width: twoColWidth,
                                        child: isAdmin
                                            ? _EditableNumberChip(
                                                title: 'عدد الأشهر',
                                                initialValue:
                                                    p.installmentsMonths,
                                                color: accent,
                                                onChanged: (val) async {
                                                  await app.updatePatient(
                                                    (p as Patient).copyWith(
                                                        installmentsMonths:
                                                            val),
                                                  );
                                                },
                                              )
                                            : _infoChip(
                                                'عدد الأشهر',
                                                p.installmentsMonths.toString(),
                                                accent),
                                      ),
                                      SizedBox(
                                        width: twoColWidth,
                                        child: _infoChip(
                                            'القسط الشهري',
                                            NumberFormatter.formatNumber(
                                                p.calculatedMonthlyAmount),
                                            primary),
                                      ),
                                      SizedBox(
                                        width: twoColWidth,
                                        child: isAdmin
                                            ? _EditableNumberChip(
                                                title: 'المبلغ الكلي',
                                                initialValue:
                                                    (p.totalAmount as num)
                                                        .toInt(),
                                                color: accent,
                                                onChanged: (val) async {
                                                  await app.updatePatient(
                                                    (p as Patient).copyWith(
                                                        totalAmount:
                                                            val.toDouble()),
                                                  );
                                                },
                                              )
                                            : _infoChip(
                                                'المبلغ الكلي',
                                                NumberFormatter.formatNumber(
                                                    p.totalAmount),
                                                accent),
                                      ),
                                      SizedBox(
                                        width: twoColWidth,
                                        child: isAdmin
                                            ? _EditableNumberChip(
                                                title: 'المبلغ المتبقي',
                                                initialValue:
                                                    (p.remainingAmount as num)
                                                        .toInt(),
                                                color: primary,
                                                onChanged: (val) async {
                                                  await app.updatePatient(
                                                    (p as Patient).copyWith(
                                                        remainingAmount:
                                                            val.toDouble()),
                                                  );
                                                },
                                              )
                                            : _infoChip(
                                                'المبلغ المتبقي',
                                                NumberFormatter.formatNumber(
                                                    p.remainingAmount),
                                                primary),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 20),
                          // Payments history title
                          Text(
                            'سجل التسديدات',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: primary,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Payments list (as Column, not ListView)
                          if (payments.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              alignment: Alignment.center,
                              child: Text(
                                'لا توجد تسديدات',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                            )
                          else
                            Column(
                              children: [
                                for (final pm in payments)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFB),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: accent.withOpacity(0.15)),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      child: Row(
                                        textDirection: TextDirection.rtl,
                                        children: [
                                          // الاسم (يميني ومتمدّد)
                                          Expanded(
                                            child: Text(
                                              pm.patientName,
                                              textAlign: TextAlign.right,
                                              style: GoogleFonts.cairo(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // التاريخ
                                          Text(
                                            _formatDate(pm.paymentDate),
                                            textAlign: TextAlign.right,
                                            style: GoogleFonts.cairo(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // المبلغ (أيسر كشيب)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: accent.withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              NumberFormatter.formatNumber(
                                                  pm.amount),
                                              textAlign: TextAlign.right,
                                              style: GoogleFonts.cairo(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: accent,
                                              ),
                                            ),
                                          ),
                                          if (isAdmin) ...[
                                            const SizedBox(width: 8),
                                            IconButton(
                                              tooltip: 'تعديل التاريخ',
                                              icon: const Icon(
                                                  Icons.edit_calendar,
                                                  size: 20),
                                              onPressed: () async {
                                                if (pm.id == null ||
                                                    (p as Patient).id == null)
                                                  return;
                                                final picked =
                                                    await showDatePicker(
                                                  context: context,
                                                  initialDate: pm.paymentDate ??
                                                      DateTime.now(),
                                                  firstDate: DateTime(2000),
                                                  lastDate: DateTime(2100),
                                                );
                                                if (picked != null) {
                                                  await app.updatePayment(
                                                    patientId: p.id!,
                                                    paymentId: pm.id!,
                                                    paymentDate: picked,
                                                  );
                                                }
                                              },
                                            ),
                                            IconButton(
                                              tooltip: 'حذف الدفعة',
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red, size: 20),
                                              onPressed: () async {
                                                if (pm.id == null ||
                                                    (p as Patient).id == null)
                                                  return;
                                                final confirm =
                                                    await showDialog<bool>(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: const Text(
                                                        'تأكيد الحذف'),
                                                    content: const Text(
                                                        'هل أنت متأكد من حذف هذه الدفعة؟'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                ctx, false),
                                                        child:
                                                            const Text('إلغاء'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                ctx, true),
                                                        child:
                                                            const Text('حذف'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  await app.deletePayment(
                                                      patientId: p.id!,
                                                      paymentId: pm.id!);
                                                }
                                              },
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          actionsAlignment: MainAxisAlignment.end,
          actions: [
            if (isAdmin)
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    // إعادة تحميل البيانات للتأكد من مزامنة التعديلات عبر التطبيق
                    await app.loadData(force: true);
                    if (context.mounted) Navigator.pop(context);
                    if (context.mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم حفظ التغييرات')),
                      );
                  } catch (_) {}
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B9B9D),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.save),
                label: Text('حفظ',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'إغلاق',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _infoChip(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ويدجت قابل للنقر لتعديل قيمة نصية مثل تاريخ
  Widget _EditableInfoChip({
    required String title,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit, size: 18),
          ],
        ),
      ),
    );
  }

  // ويدجت لتعديل عدد صحيح (عدد الأشهر)
  Widget _EditableNumberChip({
    required String title,
    required int initialValue,
    required Color color,
    required ValueChanged<int> onChanged,
  }) {
    final TextEditingController controller =
        TextEditingController(text: initialValue.toString());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 40,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8EC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8EC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF3B9B9D), width: 1.5),
                ),
              ),
              onChanged: (v) {
                final parsed = int.tryParse(v);
                if (parsed != null && parsed > 0) {
                  onChanged(parsed);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // (محذوف) _buildSidebarButton - لم يعد مستخدماً
}

Future<void> showPaymentDialog(BuildContext context) async {
  final app = context.read<AppProvider>();
  final List<String> patientNames = app.patients.map((p) => p.name).toList();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final DateTime today = DateTime.now();
  bool submitting = false;
  DateTime selectedDate = today;

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final Color primary = const Color.fromARGB(255, 30, 84, 120);
      final Color accent = const Color.fromARGB(255, 59, 155, 157);
      return StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          contentPadding: EdgeInsets.zero,
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: SizedBox(
              width: 640,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary, accent],
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                      ),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'تسديد كمبيالة',
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.payment, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      children: [
                        // Date fixed
                        _LabeledField(
                          label: 'تاريخ التسديد',
                          child: GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => selectedDate = picked);
                              }
                            },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F5F7),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFFE2E8EC)),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 18, color: Colors.black54),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      DateFormat('yyyy/MM/dd')
                                          .format(selectedDate),
                                      textAlign: TextAlign.right,
                                      style: GoogleFonts.cairo(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'اضغط للتغيير',
                                    style: GoogleFonts.cairo(
                                        fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Patient name with autocomplete
                        _LabeledField(
                          label: 'اسم المريض',
                          child: Autocomplete<String>(
                            optionsBuilder: (TextEditingValue value) {
                              final q = value.text.trim().toLowerCase();
                              if (q.isEmpty)
                                return const Iterable<String>.empty();
                              return patientNames
                                  .where((n) => n.toLowerCase().contains(q))
                                  .take(10);
                            },
                            onSelected: (sel) {
                              nameController.text = sel;
                              setState(() {});
                            },
                            fieldViewBuilder: (context, textController,
                                focusNode, onFieldSubmitted) {
                              textController.text = nameController.text;
                              textController.selection =
                                  TextSelection.fromPosition(TextPosition(
                                      offset: textController.text.length));
                              return TextField(
                                controller: textController,
                                focusNode: focusNode,
                                textDirection: TextDirection.rtl,
                                decoration: InputDecoration(
                                  hintText: 'اكتب اسم المريض...',
                                  hintStyle:
                                      GoogleFonts.cairo(color: Colors.black45),
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: const Icon(Icons.person,
                                      color: Color(0xFF3B9B9D)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE2E8EC)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF3B9B9D), width: 1.5),
                                  ),
                                ),
                                onChanged: (v) => nameController.text = v,
                              );
                            },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topRight,
                                child: Material(
                                  elevation: 6,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 600,
                                    constraints:
                                        const BoxConstraints(maxHeight: 220),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      itemCount: options.length,
                                      itemBuilder: (context, index) {
                                        final option = options.elementAt(index);
                                        return ListTile(
                                          dense: true,
                                          leading: const Icon(Icons.person,
                                              color: Color(0xFF3B9B9D)),
                                          title: Text(option,
                                              textAlign: TextAlign.right,
                                              style: GoogleFonts.cairo(
                                                  fontWeight: FontWeight.w700)),
                                          onTap: () => onSelected(option),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Amount
                        _LabeledField(
                          label: 'مبلغ التسديد',
                          child: TextField(
                            controller: amountController,
                            textDirection: TextDirection.rtl,
                            keyboardType: TextInputType.number,
                            inputFormatters:
                                NumberFormatter.getAmountInputFormatters(),
                            decoration: InputDecoration(
                              hintText: 'ادخل مبلغ التسديد',
                              hintStyle:
                                  GoogleFonts.cairo(color: Colors.black45),
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.attach_money,
                                  color: Color(0xFF3B9B9D)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE2E8EC)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF3B9B9D), width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Actions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                submitting ? null : () => Navigator.pop(ctx),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade200,
                              foregroundColor: Colors.black87,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text('إلغاء',
                                style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: submitting
                                ? null
                                : () async {
                                    final name = nameController.text.trim();
                                    final amount =
                                        NumberFormatter.parseFormattedNumber(
                                            amountController.text.trim());
                                    if (name.isEmpty || amount <= 0) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'يرجى إدخال اسم صحيح ومبلغ صحيح')),
                                      );
                                      return;
                                    }
                                    // تحقق من أن المبلغ لا يتجاوز الكلي أو المتبقي
                                    final matching = app.patients.where((p) =>
                                        p.name.trim().toLowerCase() ==
                                        name.toLowerCase());
                                    if (matching.isEmpty) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                            content: Text('المريض غير موجود')),
                                      );
                                      return;
                                    }
                                    final patient = matching.first;
                                    final double total = patient.totalAmount;
                                    final double remaining =
                                        patient.remainingAmount;
                                    if (amount > total || amount > remaining) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'مبلغ التسديد أكبر من المبلغ الكلي أو المتبقي')),
                                      );
                                      return;
                                    }
                                    setState(() => submitting = true);
                                    try {
                                      final payment = Payment(
                                        patientId: patient.id ?? '',
                                        patientName: name,
                                        amount: amount,
                                        paymentDate: selectedDate,
                                        notes:
                                            'تسديد كمبيالة - ${DateFormat('yyyy/MM/dd').format(today)}',
                                      );
                                      final ok = await app.addPayment(payment);
                                      if (!ctx.mounted) return;
                                      if (ok) {
                                        Navigator.pop(ctx);
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'تم تسجيل الدفعة بنجاح')),
                                        );
                                      } else {
                                        setState(() => submitting = false);
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          const SnackBar(
                                              content:
                                                  Text('فشل تسجيل الدفعة')),
                                        );
                                      }
                                    } catch (_) {
                                      if (!ctx.mounted) return;
                                      setState(() => submitting = false);
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                            content: Text('حدث خطأ غير متوقع')),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B9B9D),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : Text('تسديد',
                                    style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            label,
            style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3B9B9D)),
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
