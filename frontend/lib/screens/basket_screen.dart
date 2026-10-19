import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/ui/ui_kit.dart';

class BasketItem {
  final ProductItem product;
  int quantity;

  BasketItem({required this.product, this.quantity = 1});
}

class BasketScreen extends StatefulWidget {
  final List<BasketItem> basketItems;
  final VoidCallback onClearBasket;
  final Function(int productId) onRemoveItem;
  final Function(int productId, int delta) onUpdateQuantity;

  const BasketScreen({
    super.key,
    required this.basketItems,
    required this.onClearBasket,
    required this.onRemoveItem,
    required this.onUpdateQuantity,
  });

  @override
  State<BasketScreen> createState() => _BasketScreenState();
}

class _BasketScreenState extends State<BasketScreen> {
  // Store comparison simulation for the current basket
  Map<String, dynamic> _computeComparison() {
    if (widget.basketItems.isEmpty) return {};

    // Stores to compare
    final stores = [
      {
        'code': 'danube',
        'name': 'الدانوب',
        'delivery_fee': 15.0,
        'free_thresh': 150.0,
        'missing': <String>[],
      },
      {
        'code': 'panda',
        'name': 'بنده',
        'delivery_fee': 12.0,
        'free_thresh': 100.0,
        'missing': <String>[],
      },
      {
        'code': 'othaim',
        'name': 'أسواق العثيم',
        'delivery_fee': 10.0,
        'free_thresh': 120.0,
        'missing': <String>[],
      },
      {
        'code': 'tamimi',
        'name': 'أسواق التميمي',
        'delivery_fee': 15.0,
        'free_thresh': 150.0,
        'missing': <String>[],
      },
      {
        'code': 'noon_minutes',
        'name': 'نون منتس',
        'delivery_fee': 5.0,
        'free_thresh': 50.0,
        'missing': <String>[],
      },
      {
        'code': 'amazon_sa',
        'name': 'أمازون السعودية',
        'delivery_fee': 12.0,
        'free_thresh': 100.0,
        'missing': <String>[],
      },
      {
        'code': 'nahdi',
        'name': 'صيدلية النهدي',
        'delivery_fee': 12.0,
        'free_thresh': 100.0,
        'missing': <String>['نوتيلا كريمة البندق مع الكاكاو ٧٥٠ جرام'],
      },
      {
        'code': 'carrefour',
        'name': 'كارفور',
        'delivery_fee': 15.0,
        'free_thresh': 150.0,
        'missing': <String>['نوتيلا ٨٢٥ جرام'],
      },
    ];

    List<Map<String, dynamic>> results = [];

    for (var s in stores) {
      double subtotal = 0;
      List<String> missing = List<String>.from(s['missing'] as List);

      for (var item in widget.basketItems) {
        // Find if store has this offer
        final offer = item.product.offers.firstWhere(
          (o) => o.storeCode == s['code'] && o.isInStock,
          orElse: () => item.product.offers.isNotEmpty
              ? item.product.offers.first
              : StoreOffer(
                  id: 0,
                  storeCode: s['code'] as String,
                  storeNameAr: s['name'] as String,
                  priceHalalas: 2500,
                  priceSar: 25.0,
                  isOnSale: false,
                  isInStock: true,
                  productUrl: '',
                  totalStatus: 'CONFIRMED',
                  totalStatusText: 'مؤكد',
                  isCheapestProduct: false,
                  isCheapestTotal: false,
                ),
        );

        if (missing.contains(item.product.nameAr)) {
          // item is missing
        } else {
          subtotal += (offer.priceSar * item.quantity);
        }
      }

      final isComplete = (missing.isEmpty && widget.basketItems.isNotEmpty);
      final double delivery = (subtotal >= (s['free_thresh'] as double)) ? 0.0 : (s['delivery_fee'] as double);
      final double total = subtotal + delivery;

      results.add({
        'name': s['name'],
        'code': s['code'],
        'is_complete': isComplete,
        'subtotal': subtotal,
        'delivery': delivery,
        'total': total,
        'missing': missing,
      });
    }

    // Sort: complete first, then lowest total
    results.sort((a, b) {
      if (a['is_complete'] && !b['is_complete']) return -1;
      if (!a['is_complete'] && b['is_complete']) return 1;
      return (a['total'] as double).compareTo(b['total'] as double);
    });

    return {'stores': results};
  }

  @override
  Widget build(BuildContext context) {
    final comparison = _computeComparison();
    final List<Map<String, dynamic>> storeResults = (comparison['stores'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('قائمة المشتريات ومقارنة السلة', style: TextStyle(fontWeight: FontWeight.w900)),
          actions: [
            if (widget.basketItems.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, color: AppTheme.danger),
                tooltip: 'تفريغ السلة',
                onPressed: widget.onClearBasket,
              ),
          ],
        ),
        body: widget.basketItems.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const EmptyIllustration(icon: Icons.shopping_basket_outlined, size: 90),
                      const SizedBox(height: 20),
                      const Text(
                        'سلة المقاضي فارغة حالياً',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'ابحث عن منتجات البقالة وأضفها لمقارنة تكلفة السلة كاملة بدقة بين المتاجر في المدينة المنورة.',
                        style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Items Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الأصناف المحددة (${widget.basketItems.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('إضافة صنف آخر', style: TextStyle(fontWeight: FontWeight.w700)),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Basket items list
                  ...widget.basketItems.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SoftCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 54,
                                height: 54,
                                color: AppTheme.surfaceAlt,
                                child: item.product.imageUrl != null && item.product.imageUrl!.isNotEmpty
                                    ? Image.network(
                                        item.product.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => const Icon(Icons.inventory_2_outlined, color: AppTheme.textMuted),
                                      )
                                    : const Icon(Icons.inventory_2_outlined, color: AppTheme.textMuted),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.nameAr,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppTheme.textDark),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${item.product.normalizedSizeAmount?.toInt() ?? ''} ${item.product.normalizedSizeUnit ?? ''}',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            // Quantity Controls
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceAlt,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.remove_rounded, color: AppTheme.textDark, size: 18),
                                    onPressed: () {
                                      if (item.quantity > 1) {
                                        widget.onUpdateQuantity(item.product.id, -1);
                                      } else {
                                        widget.onRemoveItem(item.product.id);
                                      }
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      '${item.quantity}',
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.primary),
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.add_rounded, color: AppTheme.primary, size: 18),
                                    onPressed: () => widget.onUpdateQuantity(item.product.id, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // Store Basket Comparison Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.compare_arrows_rounded, color: AppTheme.primary, size: 20),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'مقارنة تكلفة السلة الكاملة في المدينة المنورة',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'لا نعتبر السلة الناقصة أرخص سلة. يتم توضيح النواقص ورسوم التوصيل بدقة.',
                    style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 14),

                  // Store Comparison Cards with Podium Rankings
                  ...storeResults.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final s = entry.value;
                    final isComplete = s['is_complete'] as bool;
                    final isCheapestComplete = (idx == 0 && isComplete);

                    // Podium medals
                    String rankBadge = '${idx + 1}';
                    if (idx == 0) rankBadge = '🥇';
                    if (idx == 1) rankBadge = '🥈';
                    if (idx == 2) rankBadge = '🥉';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SoftCard(
                        radius: 20,
                        border: isCheapestComplete
                            ? Border.all(color: AppTheme.accentGold, width: 2)
                            : Border.all(color: AppTheme.border),
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      rankBadge,
                                      style: TextStyle(
                                        fontSize: (idx < 3) ? 20 : 13,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      s['name'],
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.textDark),
                                    ),
                                    const SizedBox(width: 8),
                                    if (isCheapestComplete)
                                      const SavingsBadge('الأرخص كاملاً 👑', gold: true),
                                    if (!isComplete)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppTheme.warning.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                                        ),
                                        child: const Text('سلة غير مكتملة', style: TextStyle(color: AppTheme.warning, fontSize: 10.5, fontWeight: FontWeight.w800)),
                                      ),
                                  ],
                                ),
                                Text(
                                  '${(s['total'] as double).toStringAsFixed(2)} ر.س',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: isCheapestComplete ? AppTheme.primaryDark : AppTheme.textDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'المنتجات: ${(s['subtotal'] as double).toStringAsFixed(2)} ر.س',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (s['delivery'] as double) == 0
                                        ? AppTheme.primaryContainer.withOpacity(0.5)
                                        : AppTheme.surfaceAlt,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    (s['delivery'] as double) == 0
                                        ? 'التوصيل: مجاني'
                                        : 'التوصيل: ${(s['delivery'] as double).toStringAsFixed(2)} ر.س',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: (s['delivery'] as double) == 0 ? AppTheme.primary : AppTheme.textMuted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (!isComplete) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.shade100),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.danger),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'نواقص: ${(s['missing'] as List).join('، ')}',
                                        style: const TextStyle(fontSize: 11, color: AppTheme.danger, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 8),

                  // Split Basket Optimization Card
                  SoftCard(
                    padding: const EdgeInsets.all(16),
                    color: AppTheme.primaryContainer.withOpacity(0.35),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded, color: AppTheme.accentGold, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'تحليل وتوصية مقاضي الذكية',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.primary),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'في هذه السلة، طلب جميع المقاضي من متجر واحد هو الخيار الأوفر، لأن رسوم التوصيل المنفصلة للمتاجر الأخرى تلغي فرق توفير أسعار السلع الفردية.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textDark, height: 1.5),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
      ),
    );
  }
}

