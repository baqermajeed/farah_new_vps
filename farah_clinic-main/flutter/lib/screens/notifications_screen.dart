import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/patient.dart';
import '../utils/whatsapp_helper.dart';
import '../utils/number_formatter.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E5478),
        title: const Text('الإشعارات'),
        centerTitle: true,
      ),
      body: Consumer<AppProvider>(
        builder: (context, app, child) {
          final items = app.notificationPatients;
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد إشعارات حالياً',
                style: TextStyle(fontSize: 20),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final Patient p = items[index];
              final remaining = p.remainingAmount;
              final monthly = p.calculatedMonthlyAmount;
              final overdueDays = p.daysOverdue;
              final lastPay = app.lastPaymentDateFor(p.name);

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active,
                              color: Color(0xFF1E5478)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              p.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              overdueDays > 0
                                  ? 'متأخر ${overdueDays}يوم'
                                  : 'موعد اليوم',
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _chip(
                              label: 'المبلغ المستحق',
                              value: NumberFormatter.formatNumber(monthly)),
                          _chip(
                              label: 'المتبقي',
                              value: NumberFormatter.formatNumber(remaining)),
                          _chip(label: 'الهاتف', value: p.phone),
                          if (lastPay != null)
                            _chip(
                                label: 'آخر تسديد',
                                value: _formatDate(lastPay)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                            ),
                            onPressed: () async {
                              await WhatsAppHelper.sendOverduePaymentReminder(
                                patient: p,
                                remainingAmount: remaining,
                                monthlyAmount: monthly,
                                overdueDays: overdueDays,
                              );
                            },
                            icon: Icon(Icons.message),
                            label: Text('إرسال واتساب'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await context
                                  .read<AppProvider>()
                                  .markPatientNotified(p);
                            },
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('تم التبليغ'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static Widget _chip({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(value),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y/$m/$day';
  }
}
