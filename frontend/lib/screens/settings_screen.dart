import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedDistrict = 'سلطانة';
  String _defaultMilkSize = '1 لتر';
  String _defaultMilkType = 'كامل الدسم';
  String _defaultBreadType = 'أبيض فاخر';
  bool _enableAudioFeedback = true;
  bool _enablePriceAlertNotifications = true;
  List<District> _districts = [];

  @override
  void initState() {
    super.initState();
    _loadDistricts();
  }

  Future<void> _loadDistricts() async {
    final list = await ApiService.getDistricts();
    if (mounted) {
      setState(() => _districts = list);
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
          padding: const EdgeInsets.all(16),
          children: [
            // Location Section
            _buildSectionHeader('الموقع والتوصيل (المدينة المنورة)', Icons.location_on),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                title: const Text('الحي المختار بالمدينة المنورة'),
                subtitle: Text(_selectedDistrict, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showDistrictPicker,
              ),
            ),

            const SizedBox(height: 20),

            // Voice & AI Defaults (Section 6: الافتراضات المنطقية)
            _buildSectionHeader('الافتراضات التلقائية للسلة الصوتية', Icons.auto_awesome),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('الحجم الافتراضي للحليب'),
                    subtitle: const Text('يُضاف تلقائياً عند عدم تحديد الحجم بالصوت'),
                    trailing: DropdownButton<String>(
                      value: _defaultMilkSize,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: '1 لتر', child: Text('1 لتر (عبوة فردية)')),
                        DropdownMenuItem(value: '2 لتر', child: Text('2 لتر (عائلي كبير)')),
                        DropdownMenuItem(value: '200 مل', child: Text('200 مل (صغير جداً)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _defaultMilkSize = val);
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('نوع الحليب الافتراضي'),
                    subtitle: const Text('كامل الدسم أو قليل الدسم'),
                    trailing: DropdownButton<String>(
                      value: _defaultMilkType,
                      underline: const SizedBox(),
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
                    title: const Text('نوع التوست والخبز الافتراضي'),
                    subtitle: const Text('أبيض أو بر أسمر'),
                    trailing: DropdownButton<String>(
                      value: _defaultBreadType,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'أبيض فاخر', child: Text('أبيض فاخر (لوزين)')),
                        DropdownMenuItem(value: 'بر أسمر', child: Text('بر أسمر صحي')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _defaultBreadType = val);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Voice & Notification Toggles
            _buildSectionHeader('الصوت والإشعارات', Icons.notifications_active),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('الرد الصوتي التفاعلي'),
                    subtitle: const Text('تأكيد الإضافة والتعديل صوتياً بعد كل أمر'),
                    value: _enableAudioFeedback,
                    activeColor: AppTheme.primary,
                    onChanged: (val) => setState(() => _enableAudioFeedback = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('تنبيهات انخفاض الأسعار'),
                    subtitle: const Text('إشعار فوري عند هبوط سعر السلع المراقبة لموقعك'),
                    value: _enablePriceAlertNotifications,
                    activeColor: AppTheme.primary,
                    onChanged: (val) => setState(() => _enablePriceAlertNotifications = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Live Server Status
            _buildSectionHeader('خادم التحديث المباشر والربط السحابي', Icons.cloud_done),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'تحديث الأسعار بالوقت الفعلي (Real-Time)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'التطبيق متصل الآن بمحركات البحث اللحظية لمتاجر المدينة المنورة (العثيم، بنده، التميمي، كارفور، الدانوب، أمازون).',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(8),
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
            ),

            const SizedBox(height: 30),

            // Save Preferences Button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حفظ الإعدادات والتفضيلات بنجاح'),
                      backgroundColor: AppTheme.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.pop(context);
                },
                child: const Text('حفظ التفضيلات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
        ],
      ),
    );
  }

  void _showDistrictPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'اختر حيّك في المدينة المنورة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: _districts.length,
                    itemBuilder: (_, i) {
                      final d = _districts[i];
                      return ListTile(
                        title: Text(d.nameAr),
                        trailing: d.nameAr == _selectedDistrict ? const Icon(Icons.check, color: AppTheme.primary) : null,
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
