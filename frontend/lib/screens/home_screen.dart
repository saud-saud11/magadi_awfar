import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/offline_catalog.dart';
import '../services/pantry_service.dart';
import '../widgets/ui/ui_kit.dart';
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
  String _selectedSortMode = 'cheapest_product';
  final TextEditingController _searchController = TextEditingController();
  final PantryService _pantryService = PantryService();

  List<District> _districts = [];
  List<ProductItem> _featuredDeals = [];

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

  final List<Map<String, String>> _categories = [
    {'title': 'حليب وألبان', 'emoji': '🥛', 'query': 'حليب'},
    {'title': 'أرز وحبوب', 'emoji': '🍚', 'query': 'أرز'},
    {'title': 'مشروبات', 'emoji': '🧃', 'query': 'عصير'},
    {'title': 'شعير وموسي', 'emoji': '🌾', 'query': 'شراب شعير'},
    {'title': 'منظفات', 'emoji': '🧼', 'query': 'صابون'},
    {'title': 'صيدلية', 'emoji': '💊', 'query': 'بنادول'},
    {'title': 'شوكولاتة', 'emoji': '🍫', 'query': 'نوتيلا'},
    {'title': 'زيوت ومعلبات', 'emoji': '🥫', 'query': 'تونة'},
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final districts = await ApiService.getDistricts();
    // Load real staple products from catalog for featured deals
    final staples = OfflineCatalog.search(query: '').matchedProducts;
    final deals = staples.isNotEmpty
        ? staples.take(6).toList()
        : [
            ...OfflineCatalog.search(query: 'حليب').matchedProducts.take(2),
            ...OfflineCatalog.search(query: 'أرز').matchedProducts.take(2),
            ...OfflineCatalog.search(query: 'نوتيلا').matchedProducts.take(2),
          ];

    if (mounted) {
      setState(() {
        _districts = districts;
        _featuredDeals = deals;
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on, color: AppTheme.primary, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'اختر حيّك في المدينة المنورة',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'تُربط نتائج الأسعار والتوفر بالفروع ونطاقات التوصيل الفعلية لحيّك',
                  style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),
                SoftCard(
                  color: AppTheme.primaryContainer.withOpacity(0.6),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تفعيل نطاق المدينة المنورة - حي سلطانة بناءً على الموقع')),
                    );
                  },
                  child: const Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primary,
                        radius: 18,
                        child: Icon(Icons.my_location, color: Colors.white, size: 20),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('استخدام موقعي الحالي على الخريطة', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                            Text('تحديد الفرع الأقرب تلقائيًا لموقعك في المدينة', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: _districts.length,
                    itemBuilder: (c, idx) {
                      final dist = _districts[idx];
                      final isSelected = dist.nameAr == _selectedDistrict;
                      return ListTile(
                        leading: Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.location_on_outlined,
                          color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                        ),
                        title: Text(
                          dist.nameAr,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            color: isSelected ? AppTheme.primary : AppTheme.textDark,
                          ),
                        ),
                        subtitle: Text(dist.city, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onTap: () {
                          setState(() => _selectedDistrict = dist.nameAr);
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: CustomScrollView(
          slivers: [
            // ── Hero Header ─────────────────────────────────────
            SliverToBoxAdapter(
              child: GradientHeader(
                bottomRadius: 36,
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar: Location Pill & Settings
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: InkWell(
                            onTap: _showDistrictPicker,
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on_rounded, color: AppTheme.accentGold, size: 17),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'المدينة المنورة • $_selectedDistrict',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
                          ),
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
                    const SizedBox(height: 20),

                    // Brand Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppTheme.goldGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AppTheme.glowShadow(AppTheme.accentGold),
                          ),
                          child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'مقاضي أوفر',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'مقارنة أسعار البقالة الذكية في المدينة المنورة',
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Floating Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
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
                          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary, size: 24),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.mic_rounded, color: AppTheme.primary),
                                tooltip: 'السلة الصوتية بالذكاء الاصطناعي',
                                onPressed: widget.onOpenVoiceBasket,
                              ),
                              IconButton(
                                icon: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.textMuted),
                                tooltip: 'مسح الباركود',
                                onPressed: () {
                                  _searchController.text = '8000500193389';
                                  _performSearch('8000500193389');
                                },
                              ),
                              const SizedBox(width: 4),
                            ],
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Body Content ────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Smart Voice Basket Hero Card
                  SoftCard(
                    padding: const EdgeInsets.all(18),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFFFFF), Color(0xFFF3F8F5)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.2), width: 1.2),
                    onTap: widget.onOpenVoiceBasket,
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.emeraldButton,
                            boxShadow: AppTheme.glowShadow(AppTheme.primary),
                          ),
                          child: const Icon(Icons.mic_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'سلة صوتية ذكية',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  SavingsBadge('AI ذكي', gold: true),
                                ],
                              ),
                              SizedBox(height: 3),
                              Text(
                                'تحدّث بلهجتك: «حليب السعودية واثنين جبن كيري»',
                                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.primary),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Category Quick Tiles
                  const SectionTitle('تصفح حسب الفئة', emoji: '✨'),
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final cat = _categories[i];
                        return FadeSlideIn(
                          index: i,
                          child: InkWell(
                            onTap: () => _performSearch(cat['query']!),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 86,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.border),
                                boxShadow: AppTheme.softShadow,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(cat['emoji']!, style: const TextStyle(fontSize: 28)),
                                  const SizedBox(height: 6),
                                  Text(
                                    cat['title']!,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Featured Deals (from verified catalog)
                  if (_featuredDeals.isNotEmpty) ...[
                    SectionTitle(
                      'عروض اليوم المؤكدة',
                      emoji: '🔥',
                      actionLabel: 'عرض الكل',
                      onAction: () => _performSearch(''),
                    ),
                    SizedBox(
                      height: 228,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _featuredDeals.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final item = _featuredDeals[i];
                          final bestOffer = item.lowestOffer;
                          final price = bestOffer?.priceSar ?? 0.0;
                          final storeName = bestOffer?.storeNameAr ?? 'أرخص متجر';
                          return FadeSlideIn(
                            index: i,
                            child: Container(
                              width: 168,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: AppTheme.border),
                                boxShadow: AppTheme.softShadow,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product Image + Bell
                                  Stack(
                                    children: [
                                      Container(
                                        height: 96,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: AppTheme.background,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(16),
                                                child: Image.network(
                                                  item.imageUrl!,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag_outlined, color: AppTheme.textMuted),
                                                ),
                                              )
                                            : const Icon(Icons.shopping_bag_outlined, color: AppTheme.textMuted),
                                      ),
                                      Positioned(
                                        top: 6,
                                        left: 6,
                                        child: ValueListenableBuilder<List<PantryItemModel>>(
                                          valueListenable: _pantryService.trackedItemsNotifier,
                                          builder: (context, _, __) {
                                            final isTracked = _pantryService.isProductTracked(item.id);
                                            return AnimatedBell(
                                              active: isTracked,
                                              size: 18,
                                              tooltip: isTracked ? 'متابع في مقاضي البيت' : 'تابع السعر',
                                              onTap: () async {
                                                if (!isTracked) {
                                                  await _pantryService.addToPantry(item);
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('تمت إضافة «${item.nameAr}» لمقاضي البيت 🔔'),
                                                        duration: const Duration(seconds: 2),
                                                      ),
                                                    );
                                                  }
                                                } else {
                                                  await _pantryService.toggleAlert(0, productId: item.id);
                                                }
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Name
                                  Text(
                                    item.nameAr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textDark),
                                  ),
                                  const SizedBox(height: 2),

                                  // Store label
                                  Text(
                                    storeName,
                                    style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),

                                  // Price + Add
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${price.toStringAsFixed(2)} ر.س',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w900,
                                              color: AppTheme.textDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                      InkWell(
                                        onTap: () {
                                          widget.onAddToBasket(item);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('تمت إضافة «${item.nameAr}» للسلة'),
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                            gradient: AppTheme.emeraldButton,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 26),
                  ],

                  // Popular search tags
                  const SectionTitle('عمليات بحث شائعة', emoji: '🔍'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickQueries.map((q) {
                      return ActionChip(
                        label: Text(q),
                        backgroundColor: AppTheme.surface,
                        elevation: 0,
                        side: const BorderSide(color: AppTheme.border),
                        labelStyle: const TextStyle(color: AppTheme.textDark, fontSize: 13, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onPressed: () {
                          _searchController.text = q;
                          _performSearch(q);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Recent searches
                  if (_recentSearches.isNotEmpty) ...[
                    const SectionTitle('عمليات البحث الأخيرة', emoji: '⏱️'),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _recentSearches.map((r) {
                        return InputChip(
                          avatar: const Icon(Icons.history_rounded, size: 16, color: AppTheme.textMuted),
                          label: Text(r, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                          backgroundColor: Colors.transparent,
                          side: const BorderSide(color: AppTheme.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          onPressed: () {
                            _searchController.text = r;
                            _performSearch(r);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
