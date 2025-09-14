import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  String? _loginError;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loginError = null;
    });

    final success = await context.read<AppProvider>().login(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );

    if (mounted) {
      if (success) {
        setState(() {
          _loginError = null;
        });
        // اترك التوجيه لـ AuthWrapper
      } else {
        // تسجيل دخول فاشل
        setState(() {
          _loginError = 'اسم المستخدم أو كلمة المرور غير صحيحة';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('اسم المستخدم أو كلمة المرور غير صحيحة'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF2EDE9),
              Color(0xFFD0EBFF),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shadowColor: const Color(0xFF649FCC).withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(40.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // شعار وعنوان العيادة
                      _buildHeader(),
                      const SizedBox(height: 40),
                      // حقول الإدخال
                      _buildUsernameField(),
                      const SizedBox(height: 20),
                      _buildPasswordField(),
                      _buildErrorAlert(),
                      const SizedBox(height: 32),
                      // زر تسجيل الدخول
                      _buildLoginButton(),
                      const SizedBox(height: 24),
                      // معلومات تسجيل الدخول
                      _buildLoginInfo(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // الشعار الأنيق
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF649FCC),
                Color(0xFFD0EBFF),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF649FCC).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_hospital,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        // عنوان العيادة
        Text(
          'عيادة فرح لطب الأسنان',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: const Color(0xFF649FCC),
                fontWeight: FontWeight.w700,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'نظام إدارة الكمبيالات',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      decoration: const InputDecoration(
        labelText: 'اسم المستخدم',
        prefixIcon: Icon(Icons.person),
        hintText: 'أدخل اسم المستخدم',
        border: OutlineInputBorder(),
      ),
      onChanged: (_) {
        if (_loginError != null) {
          setState(() {
            _loginError = null;
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'يرجى إدخال اسم المستخدم';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: 'كلمة المرور',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        hintText: 'أدخل كلمة المرور',
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) {
        if (_loginError != null) {
          setState(() {
            _loginError = null;
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'يرجى إدخال كلمة المرور';
        }
        return null;
      },
    );
  }

  Widget _buildErrorAlert() {
    if (_loginError == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _loginError!,
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: appProvider.isLoading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF649FCC),
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: const Color(0xFF649FCC).withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: appProvider.isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'جاري تسجيل الدخول...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'تسجيل الدخول',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildLoginInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EDE9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD0EBFF),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: Color(0xFF649FCC),
              ),
              SizedBox(width: 8),
              Text(
                'بيانات تسجيل الدخول',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF649FCC),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'يرجى إدخال بيانات تسجيل الدخول الخاصة بك.',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
