import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/verified_product_card.dart';

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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('تفاصيل المنتج والعروض')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'المدينة المنورة • $district',
          style: const TextStyle(color: AppTheme.textMuted),
        ),
        const SizedBox(height: 12),
        VerifiedProductCard(
          product: product,
          expanded: true,
          onAdd: () {
            onAddToBasket(product);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('تمت الإضافة للسلة')));
          },
        ),
        if (product.gtinBarcode != null)
          Text(
            'الباركود: ${product.gtinBarcode}',
            style: const TextStyle(color: AppTheme.textMuted),
          ),
      ],
    ),
  );
}
