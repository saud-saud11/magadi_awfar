import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

/// Public read-only source coverage. Administrative controls live behind server authorization.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late Future<List<SourceInfo>> _sources = ApiService.getSources();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('المتاجر ومصادر الأسعار'),
      actions: [
        IconButton(
          tooltip: 'تحديث حالة المصادر',
          onPressed: () => setState(() => _sources = ApiService.getSources()),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<SourceInfo>>(
      future: _sources,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final sources = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'نعرض الأسعار التي استطعنا جلبها فقط. ظهور اسم متجر هنا لا يعني أن أسعاره متاحة أو أنه يوصل لحيّك.',
              style: TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            if (sources.isEmpty)
              const ListTile(
                leading: Icon(Icons.cloud_off_outlined),
                title: Text('تعذر جلب حالة المصادر من الخادم'),
                subtitle: Text(
                  'أعد المحاولة. ستظهر حالة كل متجر بعد استجابة خادم المقارنة.',
                ),
              ),
            for (final source in sources)
              Card(
                child: ListTile(
                  leading: Icon(
                    source.isEnabled
                        ? Icons.check_circle_outline
                        : Icons.link_off,
                    color: source.isEnabled
                        ? AppTheme.primary
                        : AppTheme.textMuted,
                  ),
                  title: Text(source.nameAr),
                  subtitle: Text(source.statusText),
                ),
              ),
          ],
        );
      },
    ),
  );
}
