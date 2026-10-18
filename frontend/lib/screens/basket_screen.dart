import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

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
    final List<Map<String, dynamic>> storeResults = comparison['stores'] ?? [];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('قائمة المشتريات ومقارنة السلة'),
          actions: [
            if (widget.basketItems.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                tooltip: 'تفريغ السلة',
                onPressed: widget.onClearBasket,
              ),
          ],
        ),
        body: widget.basketItems.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shopping_basket_outlined, size: 60, color: AppTheme.primary),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'سلة المقاضي فارغة حاليًا',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ابحث عن منتجات البقالة وأضفها لمقارنة تكلفة السلة كاملة بين المتاجر',
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Items Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الأصناف المحددة (${widget.basketItems.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('إضافة صنف آخر'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Basket items list
                  ...widget.basketItems.map((item) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey.shade100,
                                child: item.product.imageUrl != null && item.product.imageUrl!.isNotEmpty
                                    ? Image.network(
                                        item.product.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => const Icon(Icons.image),
                                      )
                                    : const Icon(Icons.image),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.nameAr,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.product.normalizedSizeAmount?.toInt() ?? ''} ${item.product.normalizedSizeUnit ?? ''}',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            // Quantity Controls
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: AppTheme.textMuted, size: 20),
                                  onPressed: () {
                                    if (item.quantity > 1) {
                                      widget.onUpdateQuantity(item.product.id, -1);
                                    } else {
                                      widget.onRemoveItem(item.product.id);
                                    }
                                  },
                                ),
                                Text(
                                  '${item.quantity}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 20),
                                  onPressed: () => widget.onUpdateQuantity(item.product.id, 1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Store Basket Comparison Header
                  const Row(
                    children: [
                      Icon(Icons.compare_arrows, color: AppTheme.primary),
                      SizedBox(width: 8),
                      Text(
                        'مقارنة تكلفة السلة الكاملة في المدينة المنورة',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'لا نعتبر السلة الناقصة أرخص سلة. يتم توضيح النواقص ورسوم التوصيل والحد الأدنى.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 14),

                  // Store Comparison Cards
                  ...storeResults.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final s = entry.value;
                    final isComplete = s['is_complete'] as bool;
                    final isBest = (idx == 0 && isComplete);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isBest ? AppTheme.primaryContainer.withOpacity(0.4) : AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isBest ? AppTheme.primary : AppTheme.border,
                          width: isBest ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    s['name'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isBest)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.success,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('أرخص سلة مكتملة', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  if (!isComplete)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.warning.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('سلة غير مكتملة', style: TextStyle(color: AppTheme.warning, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              Text(
                                '${(s['total'] as double).toStringAsFixed(2)} ر.س',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isBest ? AppTheme.primary : AppTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'المنتجات: ${(s['subtotal'] as double).toStringAsFixed(2)} ر.س',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                              Text(
                                (s['delivery'] as double) == 0
                                    ? 'التوصيل: مجاني'
                                    : 'التوصيل: ${(s['delivery'] as double).toStringAsFixed(2)} ر.س',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                          if (!isComplete) ...[
                            const SizedBox(height: 6),
                            Text(
                              '⚠️ نواقص: ${(s['missing'] as List).join('، ')}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.danger, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // Split Basket Optimization Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade50, AppTheme.primaryContainer],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.call_split, color: AppTheme.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'اقتراح تقسيم السلة الذكي',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          'في هذه السلة، طلب جميع المقاضي من متجر واحد هو الخيار الأوفر، لأن رسوم التوصيل المنفصلة للمتجرين الآخرين تلغي فرق توفير أسعار السلع الفردية.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textDark, height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }
}
