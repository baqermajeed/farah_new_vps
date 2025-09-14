import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'providers/app_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DentalClinicApp());
}

class DentalClinicApp extends StatelessWidget {
  const DentalClinicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppProvider(),
      child: MaterialApp(
        title: 'عيادة فرح لطب الأسنان',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,

          // الألوان الجديدة البسيطة
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF649FCC),
            secondary: Color(0xFFD0EBFF),
            surface: Color(0xFFF2EDE9),
            onPrimary: Colors.white,
            onSecondary: Color(0xFF649FCC),
            onSurface: Color(0xFF2C3E50),
          ),

          // الخطوط
          fontFamily: 'Segoe UI', // استخدام Segoe UI التي تدعم العربية بشكل جيد
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
            ),
            headlineMedium: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
            titleLarge: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF34495E),
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF34495E),
            ),
          ),

          // تصميم الأزرار البسيط
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF649FCC),
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: const Color(0xFF649FCC).withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // تصميم حقول الإدخال البسيط
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFD0EBFF),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFD0EBFF),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF649FCC),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            labelStyle: const TextStyle(
              color: Color(0xFF649FCC),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            hintStyle: TextStyle(
              color: Colors.grey.withValues(alpha: 0.6),
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
            prefixIconColor: const Color(0xFF649FCC),
            suffixIconColor: const Color(0xFF649FCC),
          ),

          // تصميم البطاقات البسيط
          cardTheme: CardThemeData(
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
            margin: const EdgeInsets.all(8),
          ),

          // شريط التطبيق
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF649FCC),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: 'Cairo',
            ),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // التحقق من حالة تسجيل الدخول عند بدء التطبيق
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().checkLoginStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        // إذا كان التطبيق يتحقق من حالة تسجيل الدخول
        if (appProvider.isLoading) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF649FCC),
                    Color(0xFFD0EBFF),
                    Color(0xFFF2EDE9),
                  ],
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'جاري تحميل التطبيق...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // إذا كان المستخدم مسجل الدخول
        if (appProvider.isLoggedIn) {
          return const DashboardScreen();
        }

        // إذا لم يكن مسجل الدخول
        return const LoginScreen();
      },
    );
  }
}
