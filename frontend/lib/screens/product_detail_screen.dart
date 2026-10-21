import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/url_launcher_helper.dart';
import '../services/pantry_service.dart';
import '../widgets/pantry_alert_dialog.dart';
import '../widgets/ui/ui_kit.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductItem product;
  final String district;
  final Function(ProductItem) onAddToBasket;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.district,
    required this.onAddToBasket,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('تفاصيل المنتج والعروض'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ValueListenableBuilder<List<PantryItemModel>>(
                valueListenable: PantryService().trackedItemsNotifier,
                builder: (context, trackedItems, _) {
                  final isTracked = trackedItems.any((i) => i.productId == product.id);
                  final trackedItem = isTracked ? trackedItems.firstWhere((i) => i.productId == product.id) : null;
                  final isAlertActive = trackedItem?.isAlertEnabled ?? false;

                  return AnimatedBell(
                    active: isTracked && isAlertActive,
                    size: 24,
                    tooltip: isTracked
                        ? (isAlertActive ? 'التنبيه مفعل (انقر للتعطيل)' : 'التنبيه معطل (انقر للتفعيل)')
                        : 'تابع السعر في مقاضي البيت',
                    onTap: () async {
                      if (!isTracked) {
                        await PantryService().addToPantry(product);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تمت إضافة «${product.nameAr}» إلى مقاضي البيت ومتابعة الأسعار بنجاح 🔔'),
                              backgroundColor: AppTheme.primary,
                              behavior: SnackBarBehavior.floating,
                              action: SnackBarAction(
                                label: 'تخصيص',
                                textColor: Colors.white,
                                onPressed: () {
                                  final item = PantryService().getTrackedItemByProductId(product.id);
                                  if (item != null) {
                                    PantryAlertDialog.show(context, item);
                                  }
                                },
                              ),
                            ),
                          );
                        }
                      } else if (trackedItem != null) {
                        await PantryService().toggleAlert(trackedItem.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                !isAlertActive
                                    ? 'تم تفعيل التنبيه لـ «${product.nameAr}» 🔔'
                                    : 'تم إيقاف التنبيه مؤقتاً لـ «${product.nameAr}»',
                              ),
                              duration: const Duration(seconds: 3),
                              behavior: SnackBarBehavior.floating,
                              action: SnackBarAction(
                                label: 'تخصيص',
                                textColor: Colors.amberAccent,
                                onPressed: () => PantryAlertDialog.show(context, trackedItem),
                              ),
                            ),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Header Card
              SoftCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    ProductImage(
                      imageUrl: product.imageUrl,
                      nameAr: product.nameAr,
                      width: 130,
                      height: 130,
                      borderRadius: 22,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      product.nameAr,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        if (product.brandAr != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceAlt,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Text(product.brandAr!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          ),
                        if (product.normalizedSizeAmount != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${product.normalizedSizeAmount} ${product.normalizedSizeUnit ?? ''}',
                              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ),
                        if (product.gtinBarcode != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceAlt,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.qr_code_rounded, size: 14, color: AppTheme.textMuted),
                                const SizedBox(width: 4),
                                Text(product.gtinBarcode!, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Specifications
              const SectionTitle('المواصفات والبيانات الموحدة', emoji: '📋'),
              SoftCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _buildSpecRow('المدينة ونطاق التغطية', 'المدينة المنورة • $district'),
                    Divider(color: AppTheme.border.withOpacity(0.6), height: 18),
                    _buildSpecRow('الماركة التجارية', product.brandAr ?? 'غير محددة'),
                    Divider(color: AppTheme.border.withOpacity(0.6), height: 18),
                    _buildSpecRow('الوزن / الحجم الصافي', '${product.normalizedSizeAmount ?? '-'} ${product.normalizedSizeUnit ?? ''}'),
                    Divider(color: AppTheme.border.withOpacity(0.6), height: 18),
                    _buildSpecRow('الباركود الدولي (GTIN)', product.gtinBarcode ?? 'غير متوفر'),
                    Divider(color: AppTheme.border.withOpacity(0.6), height: 18),
                    _buildSpecRow('سياسة الأسعار في السعودية', 'سعر موحد لكافة فروع السوبرماركت'),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Store Offers Header
              SectionTitle(
                'عروض المتاجر المفحوصة (${product.offers.length})',
                emoji: '🏪',
                actionLabel: 'مرتبة من الأرخص',
              ),

              // Offers List
              if (product.offers.isEmpty)
                const SoftCard(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('لا توجد عروض متصلة لهذا الصنف حالياً', style: TextStyle(color: AppTheme.textMuted)),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: product.offers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final offer = product.offers[i];
                    final isCheapest = offer.isCheapestProduct || i == 0;
                    final podiumMedal = i == 0 ? '🥇' : (i == 1 ? '🥈' : (i == 2 ? '🥉' : ''));

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isCheapest ? const Color(0xFFFFFDF5) : AppTheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isCheapest ? AppTheme.accentGold : AppTheme.border,
                          width: isCheapest ? 1.5 : 1,
                        ),
                        boxShadow: isCheapest ? AppTheme.glowShadow(AppTheme.accentGold.withOpacity(0.25)) : AppTheme.softShadow,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (podiumMedal.isNotEmpty) ...[
                                      Text(podiumMedal, style: const TextStyle(fontSize: 16)),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(
                                      offer.storeNameAr,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                                    ),
                                    if (isCheapest) ...[
                                      const SizedBox(width: 8),
                                      const SavingsBadge('الأرخص 👑', gold: true),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      offer.isInStock ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                      size: 13,
                                      color: offer.isInStock ? AppTheme.success : AppTheme.danger,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'آخر تحقق: اليوم • ${offer.isInStock ? 'متوفر بالمخزون' : 'غير متوفر'}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: offer.isInStock ? AppTheme.success : AppTheme.danger,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${offer.priceSar.toStringAsFixed(2)} ر.س',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: isCheapest ? const Color(0xFFB47D1E) : AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  side: const BorderSide(color: AppTheme.primary, width: 1.2),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () async {
                                  final launched = await UrlLauncherHelper.openStoreUrl(
                                    offer.productUrl,
                                    deepLink: offer.deepLink,
                                  );
                                  if (ctx.mounted && !launched) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text('تعذر فتح الرابط تلقائيًا: ${offer.productUrl}'),
                                        backgroundColor: Colors.red.shade700,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                child: const Text('افتح بالمتجر', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // Add to Comparison Basket Button
              GradientButton(
                label: 'إضافة إلى سلة المقارنة',
                icon: Icons.add_shopping_cart_rounded,
                onPressed: () {
                  onAddToBasket(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تمت إضافة «${product.nameAr}» إلى السلة ✨'),
                      backgroundColor: AppTheme.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
      ],
    );
  }
}
