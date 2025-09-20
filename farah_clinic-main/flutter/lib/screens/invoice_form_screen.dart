import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';
import '../models/patient.dart';
import '../models/invoice_data.dart';
import '../utils/number_formatter.dart';

class InvoiceFormScreen extends StatefulWidget {
  const InvoiceFormScreen({super.key});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  Patient? _selectedPatient;
  InvoiceData? _invoiceData;
  final List<TextEditingController> _notesControllers = [];
  final List<TextEditingController> _amountControllers = [];
  final TextEditingController _searchController = TextEditingController();
  List<Patient> _filteredPatients = [];
  bool _showDropdown = false;

  void _updateInvoiceData() {
    if (_selectedPatient != null) {
      _invoiceData = InvoiceData.fromPatient(_selectedPatient!);
      _notesControllers.clear();
      _amountControllers.clear();
      for (int i = 0; i < _invoiceData!.installments.length; i++) {
        _notesControllers.add(TextEditingController());
        // فقط الصف الأول يحتوي على قيمة افتراضية
        if (i == 0) {
          _amountControllers.add(TextEditingController(
              text: NumberFormatter.formatNumber(
                  _invoiceData!.installments[i].amount)));
        } else {
          _amountControllers.add(TextEditingController());
        }
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    for (var controller in _notesControllers) {
      controller.dispose();
    }
    for (var controller in _amountControllers) {
      controller.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('استمارة الكمبيالة'),
        backgroundColor: const Color.fromARGB(255, 30, 84, 120),
        foregroundColor: Colors.white,
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return GestureDetector(
            onTap: () {
              // إخفاء القائمة عند الضغط خارجها
              setState(() {
                _showDropdown = false;
              });
              FocusScope.of(context).unfocus();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // اختيار المريض
                  _buildPatientSelector(appProvider.patients),

                  const SizedBox(height: 20),

                  // الاستمارة
                  if (_invoiceData != null) _buildInvoiceForm(),

                  const SizedBox(height: 20),

                  // أزرار العمليات
                  if (_invoiceData != null) _buildActionButtons(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPatientSelector(List<Patient> patients) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.person,
                  color: Color.fromARGB(255, 30, 84, 120),
                ),
                const SizedBox(width: 12),
                Text(
                  'اختيار المريض',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFF649FCC),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // حقل البحث مع الأيقونة
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: const Color(0xFF649FCC).withValues(alpha: 0.3),
                ),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ابحث عن المريض أو اكتب اسماً جديداً...',
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.person_add,
                    color: Color(0xFF649FCC),
                    size: 20,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showDropdown
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFF649FCC),
                    ),
                    onPressed: () {
                      setState(() {
                        _showDropdown = !_showDropdown;
                        if (_showDropdown) {
                          _filteredPatients = patients;
                        }
                      });
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _showDropdown = true;
                    _filteredPatients = patients
                        .where((patient) => patient.name
                            .toLowerCase()
                            .contains(value.toLowerCase()))
                        .toList();
                  });
                },
                onTap: () {
                  setState(() {
                    _showDropdown = true;
                    _filteredPatients = patients;
                  });
                },
              ),
            ),
            // قائمة المرشحين
            if (_showDropdown && _filteredPatients.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFF649FCC).withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _filteredPatients.length,
                  itemBuilder: (context, index) {
                    final patient = _filteredPatients[index];
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedPatient = patient;
                          _searchController.text = patient.name;
                          _showDropdown = false;
                        });
                        _updateInvoiceData();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: index < _filteredPatients.length - 1
                              ? Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF649FCC)
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFF649FCC),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    patient.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'المبلغ: ${NumberFormatter.formatNumber(patient.totalAmount)} د.ع',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Color(0xFF649FCC),
                            ),
                          ],
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
  }

  Widget _buildInvoiceForm() {
    if (_invoiceData == null) return Container();

    return Center(
      child: Container(
        width: 700, // عرض ثابت للاستمارة
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // تصغير حجم العمود
          children: [
            // رأس الاستمارة
            _buildInvoiceHeader(),

            // الجدول الأول: معلومات المريض
            _buildPatientInfoTable(),

            // الجدول الثاني: جدول الدفعات
            _buildPaymentScheduleTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 30, 84, 120),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          // لوجو العيادة
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: Image.asset(
              'assets/new-farah.png',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Text(
              'عيادة فرح لطب الأسنان',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfoTable() {
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Container(
      margin: const EdgeInsets.all(0),
      child: Table(
        border: TableBorder.all(
          color: Colors.black,
          width: 1.2,
        ),
        children: [
          // رأس الجدول
          TableRow(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 30, 84, 120),
            ),
            children: [
              _buildTableHeaderCell('اسم المراجع'),
              _buildTableHeaderCell('المبلغ الكلي'),
              _buildTableHeaderCell('المدة'),
              _buildTableHeaderCell('تاريخ التسجيل'),
            ],
          ),
          // بيانات المريض
          TableRow(
            children: [
              _buildTableCell(_invoiceData!.patientName),
              _buildTableCell(
                  '${NumberFormatter.formatNumber(_invoiceData!.totalAmount)} دينار عراقي'),
              _buildTableCell(_getDurationText(_invoiceData!.totalMonths)),
              _buildTableCell(
                  dateFormat.format(_invoiceData!.registrationDate)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentScheduleTable() {
    const int totalRows = 10; // عرض/طباعة 10 صفوف فقط
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Container(
      margin: const EdgeInsets.only(top: 0),
      child: Table(
        border: TableBorder.all(
          color: Colors.black,
          width: 1.2,
        ),
        children: [
          // رأس جدول الدفعات
          TableRow(
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 210, 151, 0),
            ),
            children: [
              _buildTableHeaderCell('تاريخ الدفعات'),
              _buildTableHeaderCell('المبلغ المطلوب'),
              _buildTableHeaderCell('الملاحظات'),
            ],
          ),
          // 10 صفوف ثابتة (تُملأ من البيانات أو تُترك فارغة)
          ...List.generate(totalRows, (index) {
            if (index < _invoiceData!.installments.length) {
              final PaymentInstallment installment =
                  _invoiceData!.installments[index];
              return TableRow(
                children: [
                  _buildTableCell(dateFormat.format(installment.paymentDate)),
                  _buildAmountCell(index),
                  _buildNotesCell(index),
                ],
              );
            } else {
              return TableRow(
                children: [
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(''),
                ],
              );
            }
          }),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          fontSize: 20,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAmountCell(int index) {
    // الصف الأول يكون قيمة ثابتة غير قابلة للتغيير
    if (index == 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        child: Text(
          '${NumberFormatter.formatNumber(_invoiceData!.installments[index].amount)} دينار',
          style: GoogleFonts.cairo(
            fontSize: 20,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // الصفوف الباقية تكون حقول إدخال بدون حدود وبدون هنت
    return Container(
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: _amountControllers[index],
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: GoogleFonts.cairo(fontSize: 20, color: Colors.black87),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        onChanged: (value) {
          if (_invoiceData != null &&
              index < _invoiceData!.installments.length) {
            double? amount = double.tryParse(value);
            if (amount != null) {
              _invoiceData!.installments[index].amount = amount;
            }
          }
        },
      ),
    );
  }

  Widget _buildNotesCell(int index) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: _notesControllers[index],
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: GoogleFonts.cairo(fontSize: 20, color: Colors.black87),
        textAlign: TextAlign.center,
        onChanged: (value) {
          if (_invoiceData != null &&
              index < _invoiceData!.installments.length) {
            _invoiceData!.installments[index].notes = value;
          }
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.print,
                  color: Color(0xFF27AE60),
                ),
                const SizedBox(width: 12),
                Text(
                  'طباعة الاستمارة',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFF27AE60),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('طباعة الاستمارة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                ),
                onPressed: () async {
                  if (_invoiceData != null) {
                    final pdf = await _generateNewInvoicePdf();
                    await Printing.layoutPdf(
                      format: PdfPageFormat.a4,
                      onLayout: (PdfPageFormat format) async => pdf.save(),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<pw.Document> _generateNewInvoicePdf() async {
    if (_invoiceData == null) {
      throw Exception('لا توجد بيانات استمارة');
    }

    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy/MM/dd');
    final double margin = 10 * PdfPageFormat.mm; // هامش 10 مم من كل الأطراف
    final double rowHeight =
        15 * PdfPageFormat.mm; // ارتفاع ثابت لكل صف (مواءم لـ A4 مع 10 صفوف)

    // تحميل الخط العربي (محلياً إن توفر، وإلا من Google Fonts)
    late pw.Font arabicFont;
    late pw.Font arabicBoldFont;
    try {
      final regularData =
          await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
      arabicFont = pw.Font.ttf(regularData);
      final boldData = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
      arabicBoldFont = pw.Font.ttf(boldData);
    } catch (_) {
      arabicFont = await PdfGoogleFonts.amiriRegular();
      arabicBoldFont = await PdfGoogleFonts.amiriBold();
    }

    // تحميل صورة اللوغو
    final logoBytes = await rootBundle.load('assets/new-farah.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    // حدود واضحة للجدول (خطوط داخلية وخارجية أوضح للطباعة)
    final pw.TableBorder tableBorder = pw.TableBorder.symmetric(
      inside: const pw.BorderSide(color: PdfColors.black, width: 1.2),
      outside: const pw.BorderSide(color: PdfColors.black, width: 1.2),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginLeft: margin,
          marginRight: margin,
          marginTop: margin,
          marginBottom: margin,
        ),
        build: (pw.Context context) {
          // تجهيز 10 صفوف ثابتة لجدول الدفعات
          final List<pw.TableRow> fixedRows = List.generate(10, (i) {
            if (i < _invoiceData!.installments.length) {
              final inst = _invoiceData!.installments[i];
              final String dateText = dateFormat.format(inst.paymentDate);
              final String amountText =
                  '${NumberFormatter.formatNumber(inst.amount)} دينار';
              final String notesText = inst.notes.isNotEmpty ? inst.notes : '';
              return pw.TableRow(children: [
                _buildPdfTableCell(dateText, arabicFont, height: rowHeight),
                _buildPdfTableCell(amountText, arabicFont, height: rowHeight),
                _buildPdfTableCell(notesText, arabicFont, height: rowHeight),
              ]);
            } else {
              return pw.TableRow(children: [
                _buildPdfTableCell('', arabicFont, height: rowHeight),
                _buildPdfTableCell('', arabicFont, height: rowHeight),
                _buildPdfTableCell('', arabicFont, height: rowHeight),
              ]);
            }
          });

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // رأس الاستمارة
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF1E5478), // نفس لون التطبيق
                ),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 80,
                      height: 80,
                      child: pw.Image(
                        logoImage,
                        width: 80,
                        height: 80,
                        fit: pw.BoxFit.cover,
                      ),
                    ),
                    pw.SizedBox(width: 20),
                    pw.Expanded(
                      child: pw.Text(
                        'عيادة فرح لطب الأسنان',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          font: arabicBoldFont,
                        ),
                        textAlign: pw.TextAlign.center,
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ),
                  ],
                ),
              ),

              // جدول معلومات المريض
              pw.Table(
                border: tableBorder,
                children: [
                  // رأس الجدول
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF1E5478), // نفس لون التطبيق
                    ),
                    children: [
                      _buildPdfTableHeaderCell('اسم المراجع', arabicBoldFont),
                      _buildPdfTableHeaderCell('المبلغ الكلي', arabicBoldFont),
                      _buildPdfTableHeaderCell('المدة', arabicBoldFont),
                      _buildPdfTableHeaderCell('تاريخ التسجيل', arabicBoldFont),
                    ],
                  ),
                  // بيانات المريض
                  pw.TableRow(
                    children: [
                      _buildPdfTableCell(_invoiceData!.patientName, arabicFont),
                      _buildPdfTableCell(
                          '${NumberFormatter.formatNumber(_invoiceData!.totalAmount)} دينار عراقي',
                          arabicFont),
                      _buildPdfTableCell(
                          _getDurationText(_invoiceData!.totalMonths),
                          arabicFont),
                      _buildPdfTableCell(
                          dateFormat.format(_invoiceData!.registrationDate),
                          arabicFont),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 8),

              // جدول الدفعات (10 صفوف ثابتة)
              pw.Table(
                border: tableBorder,
                columnWidths: const {
                  0: pw.FlexColumnWidth(2), // التاريخ
                  1: pw.FlexColumnWidth(2), // المبلغ
                  2: pw.FlexColumnWidth(3), // الملاحظات
                },
                children: [
                  // رأس جدول الدفعات
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(
                          0xFFD29700), // نفس اللون الذهبي للتطبيق
                    ),
                    children: [
                      _buildPdfTableHeaderCell('تاريخ الدفعات', arabicBoldFont,
                          height: rowHeight),
                      _buildPdfTableHeaderCell('المبلغ المطلوب', arabicBoldFont,
                          height: rowHeight),
                      _buildPdfTableHeaderCell('الملاحظات', arabicBoldFont,
                          height: rowHeight),
                    ],
                  ),
                  // 10 صفوف دائماً
                  ...fixedRows,
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildPdfTableHeaderCell(String text, pw.Font font,
      {double? height}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      height: height,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 18,
          font: font,
        ),
        textAlign: pw.TextAlign.center,
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  pw.Widget _buildPdfTableCell(String text, pw.Font font, {double? height}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      height: height,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 16,
          color: PdfColors.black,
          font: font,
        ),
        textAlign: pw.TextAlign.center,
        textDirection: pw.TextDirection.rtl,
        maxLines: 1,
      ),
    );
  }

  // دالة لتحويل عدد الأشهر إلى نص عربي
  String _getDurationText(int months) {
    if (months == 1) {
      return 'شهر واحد';
    } else if (months == 2) {
      return 'شهران';
    } else if (months <= 10) {
      return '$months أشهر';
    } else if (months == 12) {
      return 'سنة واحدة';
    } else if (months == 24) {
      return 'سنتان';
    } else if (months % 12 == 0) {
      final years = months ~/ 12;
      return '$years ${years == 1 ? 'سنة' : 'سنوات'}';
    } else {
      final years = months ~/ 12;
      final remainingMonths = months % 12;
      String result = '';
      if (years > 0) {
        result += '$years ${years == 1 ? 'سنة' : 'سنوات'}';
      }
      if (remainingMonths > 0) {
        if (result.isNotEmpty) result += ' و ';
        result += '$remainingMonths ${remainingMonths == 1 ? 'شهر' : 'أشهر'}';
      }
      return result;
    }
  }
}
