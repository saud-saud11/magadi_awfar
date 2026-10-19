import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'results_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(ProductItem) onAddToBasket;
  final VoidCallback? onOpenVoiceBasket;

  const HomeScreen({
    super.key,
    required this.onAddToBasket,
    this.onOpenVoiceBasket,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedDistrict = 'سلطانة';
  String _selectedSortMode = 'cheapest_product'; // cheapest_product or cheapest_total
  final TextEditingController _searchController = TextEditingController();
  
  List<District> _districts = [];

  final List<String> _recentSearches = [
    'نوتيلا 500 جرام',
    'حليب المراعي 2 لتر',
    'أرز الشعلان 10 كجم',
  ];

  final List<String> _quickQueries = [
    'تونة قودي',
    'شاي ربيع',
    'مكرونة',
    'جبنة كيري',
    'صابون تايد',
    'حليب المراعي',
    'أرز الشعلان',
    'نوتيلا',
    'بيبسي',
    'زيت عافية',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final districts = await ApiService.getDistricts();
    if (mounted) {
      setState(() {
        _districts = districts;
      });
    }
  }

  void _performSearch(String query) {
    final q = query.trim();
    if (q.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          initialQuery: q,
          district: _selectedDistrict,
          initialSortBy: _selectedSortMode,
          onAddToBasket: widget.onAddToBasket,
        ),
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
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'اختر حيّك في المدينة المنورة',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'تُربط نتائج الأسعار والتوفر بالفروع ونطاقات التوصيل الفعلية لحيّك',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.primaryContainer,
                    child: Icon(Icons.my_location, color: AppTheme.primary),
                  ),
                  title: const Text('استخدام موقعي الحالي على الخريطة', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('طلب إذن الموقع لتحديد الفرع الأقرب تلقائيًا'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: AppTheme.primaryContainer.withOpacity(0.5),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تفعيل نطاق المدينة المنورة - حي سلطانة بناءً على الموقع')),
                    );
                  },
                ),
                const SizedBox(height: 12),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: _districts.length,
                    itemBuilder: (c, idx) {
                      final dist = _districts[idx];
                      final isSelected = dist.nameAr == _selectedDistrict;
                      return ListTile(
                        leading: Icon(
                          isSelected ? Icons.check_circle : Icons.location_on_outlined,
                          color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                        ),
                        title: Text(dist.nameAr, style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppTheme.primary : AppTheme.textDark,
                        )),
                        subtitle: Text(dist.city),
                        onTap: () {
                          setState(() {
                            _selectedDistrict = dist.nameAr;
                          });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showDistrictPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, color: AppTheme.primary, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'المدينة المنورة • $_selectedDistrict',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, color: AppTheme.primary, size: 18),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.textDark),
            tooltip: 'الإعدادات والتفضيلات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, Color(0xFF047857)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مقاضي أوفر',
                              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'مقارنة أسعار البقالة في المدينة المنورة',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Search Bar Input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _performSearch,
                      decoration: InputDecoration(
                        hintText: 'ابحث عن منتج: مثال «نوتيلا 500 جرام»',
                        hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.mic, color: AppTheme.primary),
                              tooltip: 'السلة الصوتية بالذكاء الاصطناعي',
                              onPressed: widget.onOpenVoiceBasket,
                            ),
                            IconButton(
                              icon: const Icon(Icons.qr_code_scanner, color: AppTheme.textMuted),
                              tooltip: 'مسح الباركود',
                              onPressed: () {
                                _searchController.text = '8000500193389';
                                _performSearch('8000500193389');
                              },
                            ),
                          ],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // AI Voice Basket Quick Action Banner
            GestureDetector(
              onTap: widget.onOpenVoiceBasket,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic, color: AppTheme.primary, size: 26),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'السلة الصوتية الذكية (AI)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'تحدّث بلهجتك: «أبي حليب السعودية واثنين جبن كيري»',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.primary),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Direct Price Comparison Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.insights, size: 18, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'مقارنة أسعار الرف المباشرة بين أسواق المدينة المنورة',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick search tags
            const Text(
              'عمليات بحث شائعة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickQueries.map((q) {
                return ActionChip(
                  label: Text(q),
                  backgroundColor: AppTheme.surface,
                  side: const BorderSide(color: AppTheme.border),
                  labelStyle: const TextStyle(color: AppTheme.textDark, fontSize: 13),
                  onPressed: () {
                    _searchController.text = q;
                    _performSearch(q);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            // Recent searches
            if (_recentSearches.isNotEmpty) ...[
              const Text(
                'عمليات البحث الأخيرة',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _recentSearches.map((r) {
                  return InputChip(
                    avatar: const Icon(Icons.history, size: 14, color: AppTheme.textMuted),
                    label: Text(r, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    backgroundColor: Colors.transparent,
                    side: BorderSide(color: Colors.grey.shade300),
                    onPressed: () {
                      _searchController.text = r;
                      _performSearch(r);
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
