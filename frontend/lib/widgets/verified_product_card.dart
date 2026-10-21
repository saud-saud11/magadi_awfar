import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../services/pantry_service.dart';
import '../services/url_launcher_helper.dart';
import 'ui/ui_kit.dart';

class VerifiedProductCard extends StatefulWidget {
  final ProductItem product;
  final List<StoreOffer>? offers;
  final VoidCallback onAdd;
  final VoidCallback? onDetails;
  final bool expanded;
  const VerifiedProductCard({
    super.key,
    required this.product,
    this.offers,
    required this.onAdd,
    this.onDetails,
    this.expanded = false,
  });
  @override
  State<VerifiedProductCard> createState() => _VerifiedProductCardState();
}

class _VerifiedProductCardState extends State<VerifiedProductCard> {
  bool _showAll = false;
  bool _saving = false;
  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final offers = (widget.offers ?? p.offers).where((o) => o.isFresh).toList()
      ..sort((a, b) {
        final stockA = a.stockKnown && !a.isInStock ? 1 : 0,
            stockB = b.stockKnown && !b.isInStock ? 1 : 0;
        return stockA != stockB
            ? stockA.compareTo(stockB)
            : a.priceHalalas.compareTo(b.priceHalalas);
      });
    final visible = widget.expanded || _showAll
        ? offers
        : offers.take(3).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SoftCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: widget.onDetails,
              borderRadius: BorderRadius.circular(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductImage(
                    imageUrl: p.imageUrl,
                    nameAr: p.nameAr,
                    width: 78,
                    height: 90,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.nameAr,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${p.displayPackBadge}${p.normalizedSizeAmount == null ? '' : ' • ${p.normalizedSizeAmount!.toStringAsFixed(0)} ${p.normalizedSizeUnit == 'ml' ? 'مل' : 'جرام'}'}',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        if (p.lowestOffer != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'من ${p.lowestOffer!.priceSar.toStringAsFixed(2)} ر.س',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: widget.onAdd,
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text('أضف للسلة'),
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<List<PantryItemModel>>(
                  valueListenable: PantryService().trackedItemsNotifier,
                  builder: (context, items, _) {
                    final tracked = PantryService().isProductTracked(p.id);
                    return IconButton.filledTonal(
                      tooltip: tracked ? 'محفوظ في مقاضي البيت' : 'تابع السعر',
                      onPressed: _saving
                          ? null
                          : () async {
                              setState(() => _saving = true);
                              if (!tracked) {
                                await PantryService().addToPantry(p);
                              }
                              if (mounted && context.mounted) {
                                setState(() => _saving = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      PantryService().statusNotifier.value,
                                    ),
                                  ),
                                );
                              }
                            },
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              tracked
                                  ? Icons.bookmark_added
                                  : Icons.notifications_none,
                            ),
                    );
                  },
                ),
              ],
            ),
            if (offers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'لا يتوفر سعر موثوق الآن. يمكنك حفظ الصنف والمحاولة لاحقًا.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
              ),
            for (final offer in visible)
              Container(
                margin: const EdgeInsets.only(top: 9),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: offer == offers.first
                      ? AppTheme.primaryContainer
                      : AppTheme.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            offer.storeNameAr,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          '${offer.priceSar.toStringAsFixed(2)} ر.س',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      offer.verificationText,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    if (offer.originalPriceSar != null && offer.isOnSale)
                      Text(
                        'قبل العرض ${offer.originalPriceSar!.toStringAsFixed(2)} ر.س',
                        style: const TextStyle(
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    if (offer.unitPricePer100gSar != null)
                      Text(
                        'لكل 100 ${p.normalizedSizeUnit == 'ml' ? 'مل' : 'جرام'}: ${offer.unitPricePer100gSar!.toStringAsFixed(2)} ر.س',
                        style: const TextStyle(fontSize: 11),
                      ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton.icon(
                        onPressed: () async {
                          final ok = await UrlLauncherHelper.openStoreUrl(
                            offer.productUrl,
                          );
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تعذر فتح رابط المتجر'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.open_in_new, size: 14),
                        label: const Text('تحقق لدى المتجر'),
                      ),
                    ),
                  ],
                ),
              ),
            if (!widget.expanded && offers.length > 3)
              TextButton(
                onPressed: () => setState(() => _showAll = !_showAll),
                child: Text(
                  _showAll
                      ? 'إظهار أقل'
                      : 'عرض بقية المتاجر (${offers.length - 3})',
                ),
              ),
            if (offers.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'السعر قبل الرسوم • التوفر والتوصيل لحيّك يُؤكّدان لدى المتجر',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
