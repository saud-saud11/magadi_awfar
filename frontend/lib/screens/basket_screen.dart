import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/ui/ui_kit.dart';

class BasketItem {
  ProductItem product;
  int quantity;
  BasketItem({required this.product, this.quantity = 1});
}

class BasketQuote {
  final String storeName;
  final String scope;
  final int subtotalHalalas;
  final int matchedCount;
  final List<String> missing;
  final bool indicative;
  BasketQuote(
    this.storeName,
    this.scope,
    this.subtotalHalalas,
    this.matchedCount,
    this.missing, {
    this.indicative = false,
  });
  bool get complete => missing.isEmpty;
}

List<BasketQuote> compareKnownBasket(List<BasketItem> items) {
  final scopes = <String, StoreOffer>{};
  for (final item in items) {
    for (final offer in item.product.offers.where((o) => o.canCompare)) {
      scopes['${offer.storeCode}|${offer.branchNameAr ?? 'online_catalog'}'] =
          offer;
    }
  }
  final quotes = <BasketQuote>[];
  for (final entry in scopes.entries) {
    var subtotal = 0, matched = 0;
    var indicative = false;
    final missing = <String>[];
    for (final item in items) {
      final offers =
          item.product.offers
              .where(
                (o) =>
                    o.canCompare &&
                    '${o.storeCode}|${o.branchNameAr ?? 'online_catalog'}' ==
                        entry.key,
              )
              .toList()
            ..sort((a, b) => a.priceHalalas.compareTo(b.priceHalalas));
      if (offers.isEmpty) {
        missing.add(item.product.nameAr);
      } else {
        subtotal += offers.first.priceHalalas * item.quantity;
        indicative = indicative || offers.first.isIndicative;
        matched++;
      }
    }
    if (matched > 0) {
      quotes.add(
        BasketQuote(
          entry.value.storeNameAr,
          entry.value.branchNameAr ?? 'كتالوج المتجر',
          subtotal,
          matched,
          missing,
          indicative: indicative,
        ),
      );
    }
  }
  quotes.sort(
    (a, b) => a.complete != b.complete
        ? (a.complete ? -1 : 1)
        : a.subtotalHalalas.compareTo(b.subtotalHalalas),
  );
  return quotes;
}

class BasketScreen extends StatelessWidget {
  final List<BasketItem> basketItems;
  final VoidCallback onClearBasket;
  final Function(int productId) onRemoveItem;
  final Function(int productId, int delta) onUpdateQuantity;
  final VoidCallback? onNavigateToSearch;
  final Future<void> Function()? onRefresh;
  final bool refreshing;
  const BasketScreen({
    super.key,
    required this.basketItems,
    required this.onClearBasket,
    required this.onRemoveItem,
    required this.onUpdateQuantity,
    this.onNavigateToSearch,
    this.onRefresh,
    this.refreshing = false,
  });
  @override
  Widget build(BuildContext context) {
    final quotes = compareKnownBasket(basketItems);
    return Scaffold(
      appBar: AppBar(
        title: const Text('سلة المقاضي'),
        actions: [
          if (basketItems.isNotEmpty)
            IconButton(
              tooltip: 'تحديث الأسعار',
              onPressed: refreshing ? null : onRefresh,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: basketItems.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const EmptyIllustration(
                      icon: Icons.shopping_basket_outlined,
                      size: 90,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'وش ناقص البيت؟',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'اجمع مقاضيك، ثم قارن أسعار أصناف السلة بين المصادر المتاحة.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: onNavigateToSearch,
                      child: const Text('ابدأ بإضافة المقاضي'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (refreshing) const LinearProgressIndicator(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${basketItems.length} أصناف',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: onNavigateToSearch,
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة صنف'),
                    ),
                  ],
                ),
                for (final item in basketItems)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SoftCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ProductImage(
                                imageUrl: item.product.imageUrl,
                                nameAr: item.product.nameAr,
                                width: 56,
                                height: 64,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.product.nameAr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'إزالة الصنف',
                                onPressed: () => onRemoveItem(item.product.id),
                                icon: const Icon(Icons.close, size: 18),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                item.product.lowestOffer == null
                                    ? 'السعر يحتاج تحديثًا'
                                    : 'من ${item.product.lowestOffer!.priceSar.toStringAsFixed(2)} ر.س للحبة',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: 'تقليل الكمية',
                                onPressed: () =>
                                    onUpdateQuantity(item.product.id, -1),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              IconButton(
                                tooltip: 'زيادة الكمية',
                                onPressed: item.quantity >= 100
                                    ? null
                                    : () =>
                                          onUpdateQuantity(item.product.id, 1),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                const Text(
                  'مقارنة أسعار السلة',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'المبالغ أدناه مجموع أسعار المنتجات فقط. رسوم التوصيل والخدمة وتوفر الأصناف لحيّك تُؤكّد لدى المتجر.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ),
                if (quotes.isEmpty)
                  const SoftCard(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'لا توجد أسعار حديثة تكفي للمقارنة. حدّث الأسعار أو حاول لاحقًا.',
                    ),
                  ),
                for (final quote in quotes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SoftCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            quote.storeName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                          Text(
                            quote.scope,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${quote.indicative ? 'ابتداءً من ' : ''}${(quote.subtotalHalalas / 100).toStringAsFixed(2)} ر.س',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 26,
                              color: AppTheme.primary,
                            ),
                          ),
                          Text(
                            quote.complete
                                ? 'أسعار جميع الأصناف • قبل الرسوم'
                                : 'مجموع جزئي • ${quote.matchedCount} من ${basketItems.length} أصناف',
                          ),
                          if (quote.indicative)
                            const Text(
                              'مجموع استرشادي يتضمن أسعار أمازون الظاهرة؛ يُؤكد الإجمالي لدى المتجر.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          if (!quote.complete)
                            Text(
                              'بلا سعر مطابق: ${quote.missing.join('، ')}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 30),
              ],
            ),
    );
  }
}
