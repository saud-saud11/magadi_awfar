import '../widgets/verified_product_card.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/ui/ui_kit.dart';
import 'product_detail_screen.dart';

class ResultsScreen extends StatefulWidget {
  final String initialQuery;
  final String district;
  final String initialSortBy;
  final Function(ProductItem) onAddToBasket;

  const ResultsScreen({
    super.key,
    required this.initialQuery,
    required this.district,
    required this.initialSortBy,
    required this.onAddToBasket,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late String _currentSortBy;
  String _selectedStoreFilter = 'all'; // all, danube, panda, othaim, carrefour
  String _selectedCategoryFilter = 'all'; // all, or specific subCategory
  String _selectedPackagingFilter = 'all'; // all, single, bundle
  bool _onlyInStock = false;

  SearchResult? _result;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentSortBy = widget.initialSortBy;
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService.search(
        query: widget.initialQuery,
        district: widget.district,
        sortBy: _currentSortBy,
      );

      if (mounted) {
        setState(() {
          _result = res;
          if (res == null ||
              (res.matchedProducts.isEmpty && res.alternativeSizes.isEmpty)) {
            _errorMessage =
                'لم نتمكن من العثور على عروض لبحث «${widget.initialQuery}». يرجى تجربة كلمات أخرى مثل: أرز الشعلان، نوتيلا، حليب السعودية.';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ أثناء جلب النتائج. يرجى إعادة المحاولة.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.initialQuery),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث الآن',
              onPressed: _fetchResults,
            ),
          ],
        ),
        body: Column(
          children: [
            // Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppTheme.surface,
              child: Column(
                children: [
                  // Location and Sort bar
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: AppTheme.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'المدينة المنورة • ${widget.district}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.arrow_downward,
                              size: 13,
                              color: AppTheme.primary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'المتاجر حسب السعر',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Store Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('الكل', 'all'),
                        _buildFilterChip('الدانوب', 'danube'),
                        _buildFilterChip('بنده', 'panda'),
                        _buildFilterChip('العثيم', 'othaim'),
                        _buildFilterChip('التميمي', 'tamimi'),
                        _buildFilterChip('نون منتس', 'noon_minutes'),
                        _buildFilterChip('أمازون', 'amazon_sa'),
                        _buildFilterChip('صيدلية النهدي', 'nahdi'),
                        _buildFilterChip('صيدلية الدواء', 'dawaa'),
                        _buildFilterChip('كارفور', 'carrefour'),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('المتوفر فقط'),
                          selected: _onlyInStock,
                          selectedColor: AppTheme.primaryContainer,
                          onSelected: (v) => setState(() => _onlyInStock = v),
                        ),
                      ],
                    ),
                  ),

                  // Packaging Format Quick Filter (بالحبة vs بالحزمة / الكرتون)
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildPackagingChip('كافة الأشكال', 'all'),
                        _buildPackagingChip(
                          '🥫 عبوات فردية (بالحبّة)',
                          'single',
                        ),
                        _buildPackagingChip('📦 حزم وكراتين (شدّات)', 'bundle'),
                      ],
                    ),
                  ),

                  // Sub-category Filter Chips (e.g. حليب طازج، حليب طويل الأجل، حليب مبخر...)
                  if (_result != null && _result!.subCategories.length > 1) ...[
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryChip('كافة الأقسام', 'all'),
                          ..._result!.subCategories.map(
                            (cat) => _buildCategoryChip(cat, cat),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),

            // Main Body
            Expanded(
              child: _isLoading
                  ? const SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: ProductSkeletonList(count: 4),
                    )
                  : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const EmptyIllustration(
                              icon: Icons.wifi_off_rounded,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 18),
                            GradientButton(
                              label: 'إعادة المحاولة',
                              icon: Icons.refresh_rounded,
                              onPressed: _fetchResults,
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildResultsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String code) {
    final isSelected = _selectedStoreFilter == code;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppTheme.primary,
        backgroundColor: AppTheme.surface,
        elevation: isSelected ? 2 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textDark,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          fontSize: 12,
        ),
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.border,
        ),
        onSelected: (_) {
          setState(() => _selectedStoreFilter = code);
        },
      ),
    );
  }

  Widget _buildCategoryChip(String label, String code) {
    final isSelected = _selectedCategoryFilter == code;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppTheme.primary,
        backgroundColor: AppTheme.surface,
        elevation: isSelected ? 2 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textDark,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          fontSize: 12,
        ),
        checkmarkColor: Colors.white,
        showCheckmark: isSelected,
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.border,
        ),
        onSelected: (_) {
          setState(() => _selectedCategoryFilter = code);
        },
      ),
    );
  }

  Widget _buildPackagingChip(String label, String code) {
    final isSelected = _selectedPackagingFilter == code;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppTheme.primary,
        backgroundColor: AppTheme.surface,
        elevation: isSelected ? 2 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textDark,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          fontSize: 12,
        ),
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.border,
        ),
        onSelected: (_) {
          setState(() => _selectedPackagingFilter = code);
        },
      ),
    );
  }

  IconData _getCategoryIcon(String cat) {
    if (cat.contains('طازج')) return Icons.local_drink;
    if (cat.contains('طويل الأجل') || cat.contains('طويل الاجل')) {
      return Icons.inventory_2_outlined;
    }
    if (cat.contains('مبخر') || cat.contains('مكثف')) {
      return Icons.coffee_outlined;
    }
    if (cat.contains('نكهات')) return Icons.icecream_outlined;
    if (cat.contains('مجفف') || cat.contains('بودرة')) return Icons.grain;
    if (cat.contains('ألبان') || cat.contains('زبادي')) {
      return Icons.breakfast_dining_outlined;
    }
    if (cat.contains('شوكولاتة') || cat.contains('نوتيلا')) {
      return Icons.cake_outlined;
    }
    if (cat.contains('أرز') || cat.contains('ارز')) return Icons.rice_bowl;
    if (cat.contains('زيت')) return Icons.opacity;
    if (cat.contains('أطفال')) return Icons.child_care;
    if (cat.contains('حزم') || cat.contains('كراتين')) return Icons.inventory_2;
    if (cat.contains('فردية') || cat.contains('بالحبّة')) {
      return Icons.sports_bar_outlined;
    }
    return Icons.category_outlined;
  }

  Widget _buildResultsList() {
    if (_result == null) return const SizedBox();

    final allMatched = _result!.matchedProducts;
    final alternatives = _result!.alternativeSizes;
    final exactMatched = _result!.exactSizeMatched;

    var matched = _selectedCategoryFilter == 'all'
        ? allMatched
        : allMatched
              .where(
                (p) =>
                    (p.subCategory ?? 'عروض مطابقة') == _selectedCategoryFilter,
              )
              .toList();

    if (_selectedPackagingFilter == 'single') {
      matched = matched.where((p) => !p.isBundle).toList();
    } else if (_selectedPackagingFilter == 'bundle') {
      matched = matched.where((p) => p.isBundle).toList();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            _result!.disclaimer,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ),
        // Strict matching Warning banner if requested size was not found
        if (!exactMatched)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB), // Warm amber tint
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info, color: AppTheme.warning, size: 22),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'لم نجد هذا الحجم في المصادر المفحوصة',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'بحثت عن «${widget.initialQuery}». لم نجد عبوة مطابقة تمامًا لهذا الحجم في المصادر التي استجابت. لا نخلط بين الأحجام، وعرضنا لك أدناه الأحجام البديلة مع سعر كل 100 جرام لسهولة المقارنة.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF78350F),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

        // Matched Products (Grouped by Category with headers)
        if (matched.isNotEmpty) ...[
          Row(
            children: [
              Text(
                _selectedCategoryFilter == 'all'
                    ? 'المنتجات المطابقة'
                    : _selectedCategoryFilter,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const Spacer(),
              Text(
                '${matched.length} منتجات',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._buildGroupedProductList(matched),
          const SizedBox(height: 20),
        ],

        // Alternative Sizes Section
        if (alternatives.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.swap_horiz, color: AppTheme.primary, size: 20),
              const SizedBox(width: 6),
              const Text(
                'أحجام بديلة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const Spacer(),
              Text(
                '${alternatives.length} أحجام',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...alternatives.map((p) => _buildProductCard(p, isAlternative: true)),
        ],

        // Empty State if no matched and no alternatives
        if (matched.isEmpty && alternatives.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            child: Column(
              children: [
                const EmptyIllustration(
                  icon: Icons.search_off_rounded,
                  size: 90,
                ),
                const SizedBox(height: 18),
                Text(
                  _result!.statusMessage.isNotEmpty
                      ? _result!.statusMessage
                      : 'لم يتم العثور على منتجات مطابقة لبحثك.',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'جرّب البحث باسم المنتج أو الماركة الأساسية مثل: «نوتيلا»، «حليب المراعي»، «أرز الشعلان»، «زيت عافية»، «سكر الأسرة».',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Bottom Disclaimer
        Center(
          child: Text(
            '«${_result!.disclaimer}»',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  List<Widget> _buildGroupedProductList(List<ProductItem> products) {
    List<Widget> widgets = [];
    String? currentCategory;

    for (var p in products) {
      final cat = p.subCategory ?? 'عروض مطابقة';

      // Insert section divider when a new sub-category starts
      if (_selectedCategoryFilter == 'all' && cat != currentCategory) {
        currentCategory = cat;
        final count = products
            .where((item) => (item.subCategory ?? 'عروض مطابقة') == cat)
            .length;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(cat),
                    size: 16,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  cat,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Divider(color: Colors.grey.shade300, thickness: 1),
                ),
              ],
            ),
          ),
        );
      }
      widgets.add(_buildProductCard(p, isAlternative: false));
    }

    return widgets;
  }

  Widget _buildProductCard(ProductItem product, {required bool isAlternative}) {
    final offers = product.offers
        .where(
          (o) =>
              o.isFresh &&
              (_selectedStoreFilter == 'all' ||
                  o.storeCode == _selectedStoreFilter) &&
              (!_onlyInStock || (o.stockKnown && o.isInStock)),
        )
        .toList();
    if (offers.isEmpty && (_selectedStoreFilter != 'all' || _onlyInStock)) {
      return const SizedBox();
    }
    return VerifiedProductCard(
      product: product,
      offers: offers,
      onAdd: () {
        widget.onAddToBasket(product);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تمت الإضافة للسلة')));
      },
      onDetails: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(
            product: product,
            district: widget.district,
            onAddToBasket: widget.onAddToBasket,
          ),
        ),
      ),
    );
  }
}
