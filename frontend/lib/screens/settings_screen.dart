import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final _pantry = PantryService();
  String _district = ApiService.selectedDistrict;
  List<District> _districts = [];
  bool _quiet = true;
  bool _busy = false;
  String _start = '23:00', _end = '07:00';
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final districts = await ApiService.getDistricts();
    final prefs = await _pantry.fetchAlertPreferences();
    if (!mounted) return;
    setState(() {
      _districts = districts;
      _quiet = prefs.enableQuietHours;
      _start = prefs.quietHoursStart;
      _end = prefs.quietHoursEnd;
    });
  }

  Future<void> _pick(bool start) async {
    final parts = (start ? _start : _end).split(':');
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
    );
    if (selected == null || !mounted) return;
    final value =
        '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (start) {
        _start = value;
      } else {
        _end = value;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('magadi_district', _district);
    ApiService.selectedDistrict = _district;
    final synced = await _pantry.updateAlertPreferences(
      AlertPreferencesModel(
        enableQuietHours: _quiet,
        quietHoursStart: _start,
        quietHoursEnd: _end,
        dailyDigestEnabled: false,
      ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          synced
              ? 'تم حفظ الحي وتفضيلات التنبيهات'
              : 'تم حفظ الحي؛ تعذر حفظ ساعات الهدوء على الخادم. حاول مجددًا',
        ),
      ),
    );
    if (synced) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('الإعدادات')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle('المدينة المنورة', emoji: '📍'),
        SoftCard(
          child: DropdownButtonFormField<String>(
            initialValue: _district,
            decoration: const InputDecoration(labelText: 'الحي'),
            items: {
              _district,
              ..._districts.map((d) => d.nameAr),
            }.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (d) {
              if (d != null) setState(() => _district = d);
            },
          ),
        ),
        const SizedBox(height: 20),
        const SectionTitle('ساعات الهدوء', emoji: '🌙'),
        SoftCard(
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('تأجيل التنبيهات أثناء الهدوء'),
                value: _quiet,
                onChanged: (v) => setState(() => _quiet = v),
              ),
              const Text(
                'بتوقيت السعودية. تُرسل التنبيهات المؤجلة بعد إعادة التحقق من السعر في الفحص التالي.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              ListTile(
                title: const Text('من'),
                trailing: Text(_start),
                onTap: () => _pick(true),
              ),
              ListTile(
                title: const Text('إلى'),
                trailing: Text(_end),
                onTap: () => _pick(false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionTitle('حالة الخدمة', emoji: '🔎'),
        SoftCard(
          child: Text(
            ApiService.baseUrl.isEmpty
                ? 'السلة والأصناف محفوظة على جهازك. المتابعة والتنبيهات تحتاج ربط خادم الخدمة. أسعار البحث تعرض فقط عند نجاح التحقق من مصدرها.'
                : 'تظهر حالة كل مصدر في تبويب المتاجر. التغطية والتوفر ورسوم التوصيل تُؤكد لدى المتجر؛ المتابعة على الخادم تعمل بفحص دوري.',
            style: const TextStyle(height: 1.6, color: AppTheme.textMuted),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _busy ? null : _save,
          icon: const Icon(Icons.save_outlined),
          label: Text(_busy ? 'جارٍ الحفظ…' : 'حفظ الإعدادات'),
        ),
      ],
    ),
  );
}
