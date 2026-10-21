import '../models/models.dart';

/// Identity and measurement rules shared by search, voice and saved baskets.
class ProductMatching {
  static String normalize(String value) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    for (var i = 0; i < 10; i++) {
      value = value.replaceAll(arabic[i], '$i').replaceAll(persian[i], '$i');
    }
    return value
        .toLowerCase()
        .replaceAll('٫', '.')
        .replaceAll(RegExp('[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'[\u064B-\u065Fـ]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static ({double? amount, String? unit, int? pack}) measurement(String value) {
    final text = normalize(value);
    final size = RegExp(
      r'(\d+(?:\.\d+)?)\s*(كيلوجرام|كيلو|كجم|كغم|kg|جرام|غرام|جم|غم|g|ملليلتر|مليلتر|ml|مل|لتر|liters?|litres?|l)(?![a-z\u0600-\u06ff])',
      caseSensitive: false,
    ).firstMatch(text);
    double? amount;
    String? unit;
    if (size != null) {
      amount = double.parse(size[1]!);
      final rawUnit = size[2]!;
      if (['كيلوجرام', 'كيلو', 'كجم', 'كغم', 'kg'].contains(rawUnit)) {
        amount *= 1000;
        unit = 'g';
      } else if ([
        'لتر',
        'l',
        'liter',
        'litre',
        'liters',
        'litres',
      ].contains(rawUnit)) {
        amount *= 1000;
        unit = 'ml';
      } else {
        unit = ['مل', 'ml', 'ملليلتر', 'مليلتر'].contains(rawUnit) ? 'ml' : 'g';
      }
    }
    final pack =
        RegExp(r'(\d+)\s*[x×*]\s*\d', caseSensitive: false).firstMatch(text) ??
        RegExp(
          r'(?:جرام|غرام|جم|kg|g|ml|مل|لتر|l)\s*[x×*]\s*(\d+)',
        ).firstMatch(text) ??
        RegExp(
          r'(\d+)\s*(?:عبوات|عبوه|علب|علبه|حبات|قطع)(?![a-z\u0600-\u06ff])',
        ).firstMatch(text) ??
        RegExp(r'(?:حزمه|كرتون|شده|pack)\s*\(?\s*(\d+)').firstMatch(text);
    return (
      amount: amount,
      unit: unit,
      pack: pack == null ? null : int.tryParse(pack[1]!),
    );
  }

  static String variantName(String name) => normalize(name)
      .replaceAll(
        RegExp(
          r'\d+(?:\.\d+)?\s*(?:كيلوجرام|كيلو|كجم|كغم|kg|جرام|غرام|جم|غم|g|ملليلتر|مليلتر|ml|مل|لتر|liters?|litres?|l)(?![a-z\u0600-\u06ff])',
        ),
        '',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static bool exactSize(String query, ProductItem product) {
    final target = measurement(query);
    if (target.amount != null &&
        (product.normalizedSizeAmount != target.amount ||
            product.normalizedSizeUnit != target.unit)) {
      return false;
    }
    if ((target.pack != null || target.amount != null) &&
        product.packCount != (target.pack ?? 1)) {
      return false;
    }
    return true;
  }

  static bool sameProduct(ProductItem a, ProductItem b) =>
      a.normalizedSizeAmount == b.normalizedSizeAmount &&
      a.normalizedSizeUnit == b.normalizedSizeUnit &&
      a.packCount == b.packCount &&
      ((a.gtinBarcode != null && a.gtinBarcode == b.gtinBarcode) ||
          normalize(a.nameAr) == normalize(b.nameAr));

  /// Stable negative IDs keep local/search-provider products separate from database IDs.
  static int localId(String identity) {
    var hash = 2166136261;
    for (final code in identity.codeUnits) {
      hash = ((hash ^ code) * 16777619) & 0x7fffffff;
    }
    return -(hash == 0 ? 1 : hash);
  }

  static bool validBarcode(String value) {
    if (!RegExp(r'^(?:\d{8}|\d{12,14})$').hasMatch(value)) return false;
    var total = 0;
    for (
      var i = value.length - 2, weight = 3;
      i >= 0;
      i--, weight = 4 - weight
    ) {
      total += int.parse(value[i]) * weight;
    }
    return (10 - total % 10) % 10 == int.parse(value[value.length - 1]);
  }
}
