import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/url_launcher_helper.dart';
import '../services/pantry_service.dart';
import '../widgets/pantry_alert_dialog.dart';

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
            ValueListenableBuilder<List<PantryItemModel>>(
              valueListenable: PantryService().trackedItemsNotifier,
              builder: (context, trackedItems, _) {
                final isTracked = trackedItems.any((i) => i.productId == product.id);
                final trackedItem = isTracked ? trackedItems.firstWhere((i) => i.productId == product.id) : null;
                final isAlertActive = trackedItem?.isAlertEnabled ?? false;

                return IconButton(
                  icon: Icon(
                    isTracked
                        ? (isAlertActive ? Icons.notifications_active : Icons.notifications_off_outlined)
                        : Icons.notifications_none_outlined,
                    color: isTracked
                        ? (isAlertActive ? Colors.amber.shade800 : Colors.grey)
                        : AppTheme.textDark,
                  ),
                  tooltip: isTracked ? 'متابع في مقاضي البيت (انقر للتعديل)' : 'تابع السعر في مقاضي البيت',
                  onPressed: () async {
                    if (!isTracked) {
                      await PantryService().addToPantry(product);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تمت إضافة «${product.nameAr}» إلى مقاضي البيت ومتابعة الأسعار بنجاح 🔔'),
                            backgroundColor: AppTheme.primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } else if (trackedItem != null) {
                      PantryAlertDialog.show(context, trackedItem);
                    }
                  },
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
              // Product Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: product.imageUrl != null
                          ? Image.network(
                              product.imageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2, size: 50, color: AppTheme.primary),
                            )
                          : const Icon(Icons.inventory_2, size: 50, color: AppTheme.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      product.nameAr,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (product.brandAr != null)
                          Chip(
                            label: Text(product.brandAr!),
                            backgroundColor: Colors.grey.shade100,
                          ),
                        if (product.normalizedSizeAmount != null)
                          Chip(
                            label: Text('${product.normalizedSizeAmount} ${product.normalizedSizeUnit ?? ''}'),
                            backgroundColor: AppTheme.primaryContainer,
                            labelStyle: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                          ),
                        if (product.gtinBarcode != null)
                          Chip(
                            avatar: const Icon(Icons.qr_code, size: 16),
                            label: Text(product.gtinBarcode!),
                            backgroundColor: Colors.grey.shade100,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Specifications
              const Text(
                'المواصفات والبيانات الموحدة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSpecRow('المدينة ونطاق التغطية', 'المدينة المنورة • $district'),
                      const Divider(),
                      _buildSpecRow('الماركة التجارية', product.brandAr ?? 'غير محددة'),
                      const Divider(),
                      _buildSpecRow('الوزن / الحجم الصافي', '${product.normalizedSizeAmount ?? '-'} ${product.normalizedSizeUnit ?? ''}'),
                      const Divider(),
                      _buildSpecRow('الباركود الدولي (GTIN)', product.gtinBarcode ?? 'غير متوفر'),
                      const Divider(),
                      _buildSpecRow('سياسة الأسعار في السعودية', 'سعر موحد لكافة فروع السوبرماركت'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Store Offers Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'عروض المتاجر المفحوصة (${product.offers.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  const Text('مرتبة من الأرخص', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
              const SizedBox(height: 8),

              // Offers List
              if (product.offers.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('لا توجد عروض متصلة لهذا الصنف حالياً'),
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
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: offer.isCheapestProduct
                            ? Border.all(color: AppTheme.primary, width: 1.5)
                            : Border.all(color: Colors.grey.shade200),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      offer.storeNameAr,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                    ),
                                    if (offer.isCheapestProduct) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text('أرخص سعر', style: TextStyle(color: Colors.white, fontSize: 10)),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'آخر تحقق: اليوم • ${offer.isInStock ? 'متوفر بالمخزون' : 'غير متوفر'}',
                                  style: TextStyle(fontSize: 11, color: offer.isInStock ? Colors.green.shade700 : Colors.red),
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
                                  fontWeight: FontWeight.bold,
                                  color: offer.isCheapestProduct ? AppTheme.primary : AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                                child: const Text('افتح بالمتجر', style: TextStyle(fontSize: 11)),
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
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('إضافة إلى سلة المقارنة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    onAddToBasket(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تمت إضافة «${product.nameAr}» إلى السلة'),
                        backgroundColor: AppTheme.primary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
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
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
      ],
    );
  }
}
