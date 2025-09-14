import 'patient.dart';

class InvoiceData {
  final String patientName;
  final double totalAmount;
  final int totalMonths;
  final DateTime registrationDate;
  final List<PaymentInstallment> installments;

  InvoiceData({
    required this.patientName,
    required this.totalAmount,
    required this.totalMonths,
    required this.registrationDate,
    required this.installments,
  });

  factory InvoiceData.fromPatient(Patient patient) {
    List<PaymentInstallment> installments = [];
    double monthlyAmount = patient.totalAmount / patient.installmentsMonths;
    final regDate = patient.registrationDate ?? DateTime.now();

    for (int i = 0; i < patient.installmentsMonths; i++) {
      DateTime paymentDate = DateTime(
        regDate.year,
        regDate.month + i,
        regDate.day,
      );

      installments.add(PaymentInstallment(
        paymentDate: paymentDate,
        amount: monthlyAmount,
        notes: '', // يمكن للمستخدم إضافة الملاحظات لاحقاً
      ));
    }

    return InvoiceData(
      patientName: patient.name,
      totalAmount: patient.totalAmount,
      totalMonths: patient.installmentsMonths,
      registrationDate: regDate,
      installments: installments,
    );
  }
}

class PaymentInstallment {
  final DateTime paymentDate;
  double amount; // إزالة final ليصبح قابل للتعديل
  String notes;

  PaymentInstallment({
    required this.paymentDate,
    required this.amount,
    this.notes = '',
  });
}
