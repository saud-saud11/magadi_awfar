import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class IosPwaInstallDialog extends StatelessWidget {
  const IosPwaInstallDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const IosPwaInstallDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.apple, color: AppTheme.primary, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'تفعيل إشعارات الأسعار على iOS',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'لإرسال إشعارات وتنبيهات فورية عند انخفاض الأسعار على هواتف الآيفون (iOS Safari)، يتطلب نظام أبل إضافة التطبيق إلى الشاشة الرئيسية:',
              style: TextStyle(fontSize: 13, height: 1.5, color: AppTheme.textDark),
            ),
            const SizedBox(height: 16),
            _buildStep(
              number: '1',
              title: 'اضغط على زر المشاركة (Share)',
              subtitle: 'أيقونة المربع مع السهم للأعلى [⎋] أسفل شاشة Safari',
              icon: Icons.ios_share,
            ),
            const SizedBox(height: 10),
            _buildStep(
              number: '2',
              title: 'اختر «إضافة إلى الشاشة الرئيسية»',
              subtitle: 'Add to Home Screen من قائمة الخيارات',
              icon: Icons.add_to_home_screen,
            ),
            const SizedBox(height: 10),
            _buildStep(
              number: '3',
              title: 'افتح التطبيق وفعّل الإشعارات',
              subtitle: 'ستصلك التنبيهات المباشرة حتى بعد إغلاق التطبيق تماماً',
              icon: Icons.notifications_active,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade900, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سجل التنبيهات متاح أيضاً داخل التطبيق في أي وقت حتى بدون إذن الإشعارات.',
                      style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('حسناً، فهمت ذلك'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppTheme.primary,
          child: Text(number, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                  const SizedBox(width: 6),
                  Icon(icon, size: 16, color: AppTheme.primary),
                ],
              ),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}
