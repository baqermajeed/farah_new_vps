import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class NumberFormatter {
  // دالة لتنسيق الأرقام مع إضافة فاصلة بعد كل ثلاثة أرقام
  static String formatNumber(double number, {int decimalPlaces = 0}) {
    final formatter = NumberFormat('#,##0${decimalPlaces > 0 ? '.' + '0' * decimalPlaces : ''}');
    return formatter.format(number);
  }

  // دالة لتنسيق المبالغ مع إضافة "دينار" أو "د.ع"
  static String formatAmount(double amount, {String currency = 'دينار', int decimalPlaces = 0}) {
    return '${formatNumber(amount, decimalPlaces: decimalPlaces)} $currency';
  }

  // دالة لتنسيق المبالغ العراقية
  static String formatIraqiAmount(double amount, {int decimalPlaces = 0}) {
    return formatAmount(amount, currency: 'د.ع', decimalPlaces: decimalPlaces);
  }

  // دالة لتنسيق المبالغ مع "دينار عراقي"
  static String formatIraqiDinar(double amount, {int decimalPlaces = 0}) {
    return formatAmount(amount, currency: 'دينار عراقي', decimalPlaces: decimalPlaces);
  }

  // دالة لتنسيق النص أثناء الكتابة (إزالة الفواصل وتحويل إلى رقم)
  static String formatInputText(String text) {
    // إزالة الفواصل والمسافات
    String cleanText = text.replaceAll(',', '').replaceAll(' ', '');
    
    // التحقق من أن النص يحتوي على أرقام فقط
    if (cleanText.isEmpty) return '';
    
    // تحويل إلى رقم وإعادة تنسيق
    double? number = double.tryParse(cleanText);
    if (number == null) return cleanText;
    
    return formatNumber(number);
  }

  // دالة لاستخراج الرقم من النص المنسق
  static double parseFormattedNumber(String formattedText) {
    String cleanText = formattedText.replaceAll(',', '').replaceAll(' ', '');
    return double.tryParse(cleanText) ?? 0.0;
  }

  // InputFormatter لتنسيق المبالغ أثناء الكتابة
  static List<TextInputFormatter> getAmountInputFormatters() {
    return [
      FilteringTextInputFormatter.digitsOnly,
      TextInputFormatter.withFunction((oldValue, newValue) {
        if (newValue.text.isEmpty) return newValue;
        
        String formatted = formatInputText(newValue.text);
        return TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }),
    ];
  }
}
