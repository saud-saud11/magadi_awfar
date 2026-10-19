import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/pantry_service.dart';
import '../widgets/ui/ui_kit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PantryService _pantryService = PantryService();

  String _selectedDistrict = 'سلطانة';
  String _defaultMilkSize = '1 لتر';
  String _defaultMilkType = 'كامل الدسم';
  String _defaultBreadType = 'أبيض فاخر';
  bool _enableAudioFeedback = true;
  bool _enablePriceAlertNotifications = true;

  // Quiet hours & Daily digest preferences
  bool _enableQuietHours = true;
  String _quietHoursStart = '23:00';
  String _quietHoursEnd = '07:00';
  bool _dailyDigestEnabled = false;

  List<District> _districts = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final list = await ApiService.getDistricts();
    final prefs = await _pantryService.fetchAlertPreferences();
    if (mounted) {
      setState(() {
        _districts = list;
        _enableQuietHours = prefs.enableQuietHours;
        _quietHoursStart = prefs.quietHoursStart;
        _quietHoursEnd = prefs.quietHoursEnd;
        _dailyDigestEnabled = prefs.dailyDigestEnabled;
      });
    }
  }

  Future<void> _saveAllPreferences() async {
    final alertPrefs = AlertPreferencesModel(
      enableQuietHours: _enableQuietHours,
      quietHoursStart: _quietHoursStart,
      quietHoursEnd: _quietHoursEnd,
      dailyDigestEnabled: _dailyDigestEnabled,
    );
    await _pantryService.updateAlertPreferences(alertPrefs);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ الإعدادات والتفضيلات وساعات الهدوء بنجاح ✨'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final currentStr = isStart ? _quietHoursStart : _quietHoursEnd;
    final parts = currentStr.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? (isStart ? 23 : 7),
      minute: int.tryParse(parts.last) ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox(),
        );
      },
    );

    if (picked != null) {
      final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _quietHoursStart = formatted;
        } else {
          _quietHoursEnd = formatted;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('الإعدادات والتفضيلات'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            // ── Location Section ────────────────────────────────
            const SectionTitle('الموقع والتوصيل (المدينة المنورة)', emoji: '📍'),
            SoftCard(
              onTap: _showDistrictPicker,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('الحي المختار بالمدينة المنورة', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textMuted)),
                        const SizedBox(height: 2),
                        Text(_selectedDistrict, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 16)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.textMuted),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Quiet Hours & Alerts Section ───────────────────
            const SectionTitle('تنبيهات الأسعار وساعات الهدوء', emoji: '🌙'),
            SoftCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('تنبيهات انخفاض الأسعار', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    subtitle: const Text('إشعار فوري عند هبوط أسعار مقاضيك المتابعة لموقعك', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    value: _enablePriceAlertNotifications,
                    activeColor: AppTheme.primary,
                    onChanged: (val) => setState(() => _enablePriceAlertNotifications = val),
                  ),
                  const Divider(height: 18),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('تفعيل ساعات الهدوء (عدم الإزعاج ليلاً)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    subtitle: const Text('كتم إشعارات النظام أثناء وقت النوم وحفظها بالسجل الداخلي', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    value: _enableQuietHours,
                    activeColor: AppTheme.primary,
                    onChanged: (val) => setState(() => _enableQuietHours = val),
                  ),
                  if (_enableQuietHours) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickTime(isStart: true),
                              borderRadius: BorderRadius.circular(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('من الساعة (بداية الهدوء)', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.bedtime_outlined, size: 16, color: AppTheme.primary),
                                      const SizedBox(width: 6),
                                      Text(_quietHoursStart, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.textDark)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(width: 1, height: 36, color: AppTheme.border),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickTime(isStart: false),
                              borderRadius: BorderRadius.circular(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('حتى الساعة (نهاية الهدوء)', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.wb_sunny_outlined, size: 16, color: AppTheme.accentGold),
                                      const SizedBox(width: 6),
                                      Text(_quietHoursEnd, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.textDark)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Divider(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('الملخص اليومي الموحد (صباحاً)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    subtitle: const Text('تجميع أفضل العروض في ملخص صباحي واحد الساعة 9:00 ص', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    value: _dailyDigestEnabled,
                    activeColor: AppTheme.primary,
                    onChanged: (val) => setState(() => _dailyDigestEnabled = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Voice & AI Defaults ─────────────────────────────
            const SectionTitle('الافتراضات التلقائية للسلة الصوتية', emoji: '🎙️'),
            SoftCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('الحجم الافتراضي للحليب', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: const Text('يُضاف تلقائياً عند عدم تحديد الحجم بالصوت', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    trailing: DropdownButton<String>(
                      value: _defaultMilkSize,
                      underline: const SizedBox(),
                      borderRadius: BorderRadius.circular(16),
                      items: const [
                        DropdownMenuItem(value: '1 لتر', child: Text('1 لتر (عبوة فردية)')),
                        DropdownMenuItem(value: '2 لتر', child: Text('2 لتر (عائلي كبير)')),
                        DropdownMenuItem(value: '200 مل', child: Text('200 مل (صغير)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _defaultMilkSize = val);
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('نوع الحليب الافتراضي', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: const Text('كامل الدسم أو قليل الدسم', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    trailing: DropdownButton<String>(
                      value: _defaultMilkType,
                      underline: const SizedBox(),
                      borderRadius: BorderRadius.circular(16),
                      items: const [
                        DropdownMenuItem(value: 'كامل الدسم', child: Text('كامل الدسم')),
                        DropdownMenuItem(value: 'قليل الدسم', child: Text('قليل الدسم')),
                        DropdownMenuItem(value: 'خالي اللاكتوز', child: Text('خالي اللاكتوز')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _defaultMilkType = val);
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('نوع التوست والخبز الافتراضي', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: const Text('أبيض أو بر أسمر', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    trailing: DropdownButton<String>(
                      value: _defaultBreadType,
                      underline: const SizedBox(),
                      borderRadius: BorderRadius.circular(16),
                      items: const [
                        DropdownMenuItem(value: 'أبيض فاخر', child: Text('أبيض فاخر (لوزين)')),
                        DropdownMenuItem(value: 'بر أسمر', child: Text('بر أسمر صحي')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _defaultBreadType = val);
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('الرد الصوتي التفاعلي', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: const Text('تأكيد الإضافة والتعديل صوتياً بعد كل أمر', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    value: _enableAudioFeedback,
                    activeColor: AppTheme.primary,
                    onChanged: (val) => setState(() => _enableAudioFeedback = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Live Server Status ──────────────────────────────
            const SectionTitle('حالة الاتصال والربط المباشر', emoji: '⚡'),
            SoftCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppTheme.success,
                          shape: BoxShape.circle,
                          boxShadow: AppTheme.glowShadow(AppTheme.success),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'مراقبة الأسعار اللحظية (Real-Time)',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      const Spacer(),
                      const SavingsBadge('نشط 24/7', gold: true),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'التطبيق متصل بمحركات البحث اللحظية لمتاجر المدينة المنورة (العثيم، بنده، التميمي، كارفور، الدانوب، أمازون).',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'الخادم: ${ApiService.baseUrl}',
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppTheme.textDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Save Button ────────────────────────────────────
            GradientButton(
              label: 'حفظ كافة التفضيلات ✨',
              icon: Icons.check_circle_outline_rounded,
              onPressed: _saveAllPreferences,
            ),
          ],
        ),
      ),
    );
  }

  void _showDistrictPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'اختر حيّك في المدينة المنورة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.builder(
                    itemCount: _districts.length,
                    itemBuilder: (_, i) {
                      final d = _districts[i];
                      final isSelected = d.nameAr == _selectedDistrict;
                      return ListTile(
                        title: Text(
                          d.nameAr,
                          style: TextStyle(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500),
                        ),
                        trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary) : null,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onTap: () {
                          setState(() => _selectedDistrict = d.nameAr);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
