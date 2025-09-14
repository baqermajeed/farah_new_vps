class Patient {
  int get installmentMonths => installmentsMonths;
  final String? id; // تغيير من int إلى String لـ MongoDB ObjectId
  final String name;
  final double totalAmount;
  final int installmentsMonths;
  final String phone;
  final String address;
  final String treatmentType;
  final DateTime? registrationDate;
  final double totalPaid;
  final int paymentDayOfMonth;
  final String notes;
  final double? monthlyInstallment; // إضافة للتوافق مع API
  final DateTime? nextPaymentDate; // إضافة للتوافق مع API
  final bool isCompleted;
  final double remainingAmount;
  final int paymentsCount;

  Patient({
    this.id,
    required this.name,
    required this.totalAmount,
    required this.installmentsMonths,
    required this.phone,
    this.address = '',
    this.treatmentType = '',
    this.registrationDate,
    this.totalPaid = 0.0,
    this.paymentDayOfMonth = 1,
    this.notes = '',
    this.monthlyInstallment,
    this.nextPaymentDate,
    this.isCompleted = false,
    this.remainingAmount = 0.0,
    this.paymentsCount = 0,
  });

  // حساب الدفعة الشهرية
  double get calculatedMonthlyAmount => 
      monthlyInstallment ?? (installmentsMonths > 0 ? totalAmount / installmentsMonths : 0);

  int get remainingMonths {
    if (calculatedMonthlyAmount == 0) return 0;
    final paidMonths = (totalPaid / calculatedMonthlyAmount).floor();
    return installmentsMonths - paidMonths;
  }

  // حساب تاريخ الدفعة القادمة
  DateTime get calculatedNextPaymentDate {
    if (nextPaymentDate != null) return nextPaymentDate!;
    
    if (calculatedMonthlyAmount == 0 || registrationDate == null) {
      return registrationDate ?? DateTime.now();
    }
    
    final paidMonths = (totalPaid / calculatedMonthlyAmount).floor();
    return DateTime(
      registrationDate!.year,
      registrationDate!.month + paidMonths + 1,
      paymentDayOfMonth,
    );
  }

  // التحقق من التأخير في الدفع
  bool get isOverdue {
    if (remainingAmount <= 0) return false;
    final nextDate = nextPaymentDate ?? calculatedNextPaymentDate;
    return DateTime.now().isAfter(nextDate);
  }

  // عدد الأيام المتأخرة
  int get daysOverdue {
    if (!isOverdue) return 0;
    final nextDate = nextPaymentDate ?? calculatedNextPaymentDate;
    return DateTime.now().difference(nextDate).inDays;
  }

  // تحويل إلى JSON للإرسال إلى API
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'total_amount': totalAmount,
      'installments_months': installmentsMonths,
      'address': address,
      'treatment_type': treatmentType,
      'registration_date': registrationDate?.toIso8601String().split('T')[0],
      'total_paid': totalPaid,
      'payment_day_of_month': paymentDayOfMonth,
      'notes': notes,
    };
  }

  // إنشاء من JSON response من API
  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String? ?? json['_id'] as String?,
      name: json['name'] as String,
      phone: json['phone'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      installmentsMonths: json['installments_months'] as int,
      address: json['address'] as String? ?? '',
      treatmentType: json['treatment_type'] as String? ?? '',
      registrationDate: json['registration_date'] != null 
          ? DateTime.parse(json['registration_date']) 
          : null,
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0.0,
      paymentDayOfMonth: json['payment_day_of_month'] as int? ?? 1,
      notes: json['notes'] as String? ?? '',
      monthlyInstallment: (json['monthly_installment'] as num?)?.toDouble(),
      nextPaymentDate: json['next_payment_date'] != null 
          ? DateTime.parse(json['next_payment_date']) 
          : null,
      isCompleted: json['is_completed'] as bool? ?? false,
      remainingAmount: (json['remaining_amount'] as num?)?.toDouble() ?? 0.0,
      paymentsCount: json['payments_count'] as int? ?? 0,
    );
  }

  // الطرق القديمة للتوافق مع الكود الموجود
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'totalAmount': totalAmount,
      'totalMonths': installmentsMonths,
      'phoneNumber': phone,
      'address': address,
      'treatmentType': treatmentType,
      'registrationDate': registrationDate?.millisecondsSinceEpoch,
      'paidAmount': totalPaid,
      'paymentDayOfMonth': paymentDayOfMonth,
      'notes': notes,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id']?.toString(),
      name: map['name'],
      totalAmount: map['totalAmount'],
      installmentsMonths: map['totalMonths'],
      phone: map['phoneNumber'],
      address: map['address'] ?? '',
      treatmentType: map['treatmentType'] ?? '',
      registrationDate: map['registrationDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['registrationDate'])
          : null,
      totalPaid: map['paidAmount'] ?? 0.0,
      paymentDayOfMonth: map['paymentDayOfMonth'] ?? 1,
      notes: map['notes'] ?? '',
    );
  }

  Patient copyWith({
    String? id,
    String? name,
    double? totalAmount,
    int? installmentsMonths,
    String? phone,
    String? address,
    String? treatmentType,
    DateTime? registrationDate,
    double? totalPaid,
    int? paymentDayOfMonth,
    String? notes,
    double? monthlyInstallment,
    DateTime? nextPaymentDate,
    bool? isCompleted,
    double? remainingAmount,
    int? paymentsCount,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      totalAmount: totalAmount ?? this.totalAmount,
      installmentsMonths: installmentsMonths ?? this.installmentsMonths,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      treatmentType: treatmentType ?? this.treatmentType,
      registrationDate: registrationDate ?? this.registrationDate,
      totalPaid: totalPaid ?? this.totalPaid,
      paymentDayOfMonth: paymentDayOfMonth ?? this.paymentDayOfMonth,
      notes: notes ?? this.notes,
      monthlyInstallment: monthlyInstallment ?? this.monthlyInstallment,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      isCompleted: isCompleted ?? this.isCompleted,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      paymentsCount: paymentsCount ?? this.paymentsCount,
    );
  }
}
