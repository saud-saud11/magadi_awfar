import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<SourceInfo> _sources = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSources();
  }

  Future<void> _loadSources() async {
    setState(() => _isLoading = true);
    final sources = await ApiService.getSources();
    if (mounted) {
      setState(() {
        _sources = sources;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSource(String code) async {
    final success = await ApiService.toggleSource(code);
    if (success) {
      _loadSources();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث حالة الموصل بنجاح')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة إدارة المصادر والموثوقية'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadSources,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Overview Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shield_outlined, color: AppTheme.primary, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'مبادئ الموثوقية والشفافية التقنية',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'ظهور اسم المصدر في التطبيق لا يعني اكتمال ربطه دون التحقق. لكل مصدر حالة واضحة (متصل، يحتاج إعداد، غير مدعوم). لا نخترع مفاتيح ولا نتجاوز شروط الاستخدام.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textDark, height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildStatChip('المصادر النشطة', '${_sources.where((s) => s.status == 'connected').length}'),
                            const SizedBox(width: 10),
                            _buildStatChip('تحتاج إعدادات', '${_sources.where((s) => s.status == 'requires_setup').length}'),
                            const SizedBox(width: 10),
                            _buildStatChip('غير مدعومة', '${_sources.where((s) => s.status == 'unsupported').length}'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'تفاصيل الموصلات ومحركات البحث المربوطة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 12),

                  // Sources List
                  ..._sources.map((source) {
                    final isConnected = source.status == 'connected';
                    final isSetup = source.status == 'requires_setup';
                    final color = isConnected
                        ? AppTheme.success
                        : isSetup
                            ? AppTheme.accentGold
                            : AppTheme.danger;

                    final statusLabel = isConnected
                        ? 'متصل'
                        : isSetup
                            ? 'يحتاج إعداد'
                            : 'غير مدعوم حاليًا';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      source.nameAr,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: source.isEnabled,
                                  activeColor: AppTheme.primary,
                                  onChanged: (v) => _toggleSource(source.code),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              source.statusText,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
        ],
      ),
    );
  }
}
