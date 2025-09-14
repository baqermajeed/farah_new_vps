import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/patient.dart';
import '../utils/number_formatter.dart';

class AddPatientDialog extends StatefulWidget {
  const AddPatientDialog({super.key});

  @override
  State<AddPatientDialog> createState() => _AddPatientDialogState();
}

class _AddPatientDialogState extends State<AddPatientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _monthsController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _treatmentController = TextEditingController();

  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    // قراءة حالة المدير بعد بناء السياق
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<AppProvider>();
      setState(() => _isAdmin = app.isAdmin);
    });
    // إضافة listener لتحديث حقل المدة عند تغيير عدد الأشهر
    _monthsController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _monthsController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _treatmentController.dispose();
    super.dispose();
  }

  Future<void> _addPatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final patient = Patient(
      name: _nameController.text.trim(),
      totalAmount: NumberFormatter.parseFormattedNumber(_amountController.text),
      installmentsMonths: int.parse(_monthsController.text),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      treatmentType: _treatmentController.text.trim(),
      registrationDate: _selectedDate,
    );

    final success = await context.read<AppProvider>().addPatient(patient);

    if (mounted) {
      if (success) {
        _showSuccessDialog();
        _clearForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('حدث خطأ أثناء إضافة المريض'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF27AE60),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'تم إضافة الحالة بنجاح',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF27AE60),
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'تم حفظ بيانات المريض في النظام',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // غلق رسالة النجاح
                Navigator.of(context).pop(); // غلق الفورم نفسه
              },
              child: const Text('موافق'),
            ),
          ],
        );
      },
    );
  }

  void _clearForm() {
    _nameController.clear();
    _amountController.clear();
    _monthsController.clear();
    _phoneController.clear();
    setState(() {
      _selectedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // عنوان الدايلوج
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF27AE60).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_add,
                        size: 24,
                        color: Color(0xFF27AE60),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'تسجيل مريض جديد',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: const Color(0xFF27AE60),
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // التاريخ
                _buildDateField(),
                const SizedBox(height: 20),

                // اسم المريض
                _buildTextField(
                  controller: _nameController,
                  label: 'اسم المريض',
                  icon: Icons.person,
                  hint: 'أدخل اسم المريض الكامل',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال اسم المريض';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // مبلغ الكمبيالة
                _buildTextField(
                  controller: _amountController,
                  label: 'مبلغ الكمبيالة (د.ع)',
                  icon: Icons.attach_money,
                  hint: 'أدخل المبلغ الإجمالي',
                  keyboardType: TextInputType.number,
                  inputFormatters: NumberFormatter.getAmountInputFormatters(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال مبلغ الكمبيالة';
                    }
                    double amount = NumberFormatter.parseFormattedNumber(value);
                    if (amount <= 0) {
                      return 'يرجى إدخال مبلغ صحيح (أرقام فقط)';
                    }
                    if (amount < 1000) {
                      return 'المبلغ يجب أن يكون أكبر من 1000 دينار';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // عدد الأشهر
                _buildTextField(
                  controller: _monthsController,
                  label: 'عدد الأشهر',
                  icon: Icons.calendar_month,
                  hint: 'أدخل عدد أشهر التقسيط',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال عدد الأشهر';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'يرجى إدخال عدد أشهر صحيح (أرقام فقط)';
                    }
                    if (int.parse(value) > 60) {
                      return 'عدد الأشهر لا يمكن أن يزيد عن 60 شهر';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // المدة (عرض تلقائي)
                _buildDurationField(),
                const SizedBox(height: 20),

                // رقم الهاتف
                _buildTextField(
                  controller: _phoneController,
                  label: 'رقم الهاتف',
                  icon: Icons.phone,
                  hint: 'مثال: 07701234567',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'يرجى إدخال رقم الهاتف';
                    }
                    if (!value.startsWith('07')) {
                      return 'رقم الهاتف يجب أن يبدأ بـ 07';
                    }
                    if (value.length != 11) {
                      return 'رقم الهاتف يجب أن يكون 11 رقم';
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return 'رقم الهاتف يجب أن يحتوي على أرقام فقط';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // زر الإضافة
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addPatient,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add),
                              SizedBox(width: 12),
                              Text(
                                'إضافة المريض',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'التاريخ',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2C3E50),
              ),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: _isAdmin
              ? () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                }
              : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(_isAdmin ? 0.1 : 0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const Spacer(),
                if (_isAdmin)
                  Text(
                    'اضغط للتغيير',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  )
                else
                  Text(
                    'للمدير فقط',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2C3E50),
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            hintText: hint,
          ),
        ),
      ],
    );
  }

  Widget _buildDurationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.schedule,
              color: Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'المدة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[50],
          ),
          child: Text(
            _getDurationText(),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _getDurationText() {
    final monthsText = _monthsController.text.trim();
    if (monthsText.isEmpty) {
      return 'سيتم عرض المدة بعد إدخال عدد الأشهر';
    }

    final months = int.tryParse(monthsText);
    if (months == null || months <= 0) {
      return 'عدد أشهر غير صحيح';
    }

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
