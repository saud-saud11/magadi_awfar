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

  static const _units =
      r'كيلو\s*جرام|كيلوجرام|كيلو|كجم|كغم|كغ|kg|جرام|غرام|جم|غم|grams?|gm|g|ملليلتر|مليلتر|ml|مل|لتر|liters?|litres?|ltr|l';
  static const _counts =
      r'عبوات|عبوه|علب|علبه|حبات|حبه|قطع|قطعه|حفاضات|حفاضه|حفاض|مناديل|منديل|pieces?|pcs?|counts?|ct|diapers?|sheets?|wipes?|tablets?|capsules?|bottles?|cans?|sachets?';
  static int? _arithmetic(String value) {
    final tokens = RegExp(r'\d+|[+*()]')
        .allMatches(
          value
              .replaceAll(RegExp(r'free|مجانا|مجاني'), '')
              .replaceAll(RegExp(r'[x×]'), '*'),
        )
        .map((m) => m[0]!)
        .toList();
    var i = 0;
    late int Function() sum;
    int atom() {
      if (i >= tokens.length) throw const FormatException();
      if (tokens[i] == '(') {
        i++;
        final n = sum();
        if (i >= tokens.length || tokens[i++] != ')') {
          throw const FormatException();
        }
        return n;
      }
      final n = int.parse(tokens[i++]);
      if (n < 1) throw const FormatException();
      return n;
    }

    int multiply() {
      var n = atom();
      while (i < tokens.length && tokens[i] == '*') {
        i++;
        n *= atom();
      }
      return n;
    }

    sum = () {
      var n = multiply();
      while (i < tokens.length && tokens[i] == '+') {
        i++;
        n += multiply();
      }
      return n;
    };
    try {
      final n = sum();
      return i == tokens.length && n > 0 && n <= 10000 ? n : null;
    } catch (_) {
      return null;
    }
  }

  static ({double? amount, String? unit, int? pack}) measurement(String value) {
    const unknown = (amount: null, unit: null, pack: null);
    var text = normalize(value);
    final countPattern = RegExp(
      r'(\d+)\s*(' + _counts + r')(?![a-z\u0600-\u06ff])',
    );
    if (RegExp(r'diapers?|nappies|حفاضات|حفاضه|حفاض').hasMatch(text) &&
        countPattern.hasMatch(text)) {
      text = text.replaceAll(
        RegExp(
          r'(?:\d+(?:\.\d+)?\s*[-–]\s*)?\d+(?:\.\d+)?\s*(?:kg|كيلو(?:\s*جرام)?|كجم)(?![a-z\u0600-\u06ff])',
        ),
        ' ',
      );
    }
    if (RegExp(
      r'\d+(?:\.\d+)?\s*(?:(?:' +
          _units +
          r')\s*)?(?:[-–—]|to|الي)\s*\d+(?:\.\d+)?\s*(?:' +
          _units +
          r')(?![a-z\u0600-\u06ff])',
    ).hasMatch(text)) {
      return unknown;
    }
    text = text.replaceAllMapped(
      RegExp(r'(\d+(?:\.\d+)?)\s*\+\s*(\d+(?:\.\d+)?)'),
      (m) => '${num.parse(m[1]!) + num.parse(m[2]!)} ',
    );
    final sizes = RegExp(
      r'(\d+(?:\.\d+)?)\s*(' + _units + r')(?![a-z\u0600-\u06ff])',
    ).allMatches(text).toList();
    if (sizes.length > 1 &&
        RegExp(
          r'&|\b(?:plus|with free)\b|\sو\s',
        ).hasMatch(text.substring(sizes.first.end, sizes.last.start))) {
      return unknown;
    }
    double? amount;
    String? unit;
    for (final size in sizes) {
      var n = double.parse(size[1]!);
      final raw = size[2]!.replaceAll(RegExp(r'\s'), '');
      String u;
      if (['كيلوجرام', 'كيلو', 'كجم', 'كغم', 'كغ', 'kg'].contains(raw)) {
        n *= 1000;
        u = 'g';
      } else if ([
        'لتر',
        'l',
        'ltr',
        'liter',
        'litre',
        'liters',
        'litres',
      ].contains(raw)) {
        n *= 1000;
        u = 'ml';
      } else {
        u = ['مل', 'ml', 'ملليلتر', 'مليلتر'].contains(raw) ? 'ml' : 'g';
      }
      if (amount != null && (amount != n || unit != u)) return unknown;
      amount = n;
      unit = u;
    }
    RegExpMatch? measured = sizes.isEmpty ? null : sizes.first;
    if (measured == null) {
      measured = countPattern.firstMatch(text);
      if (measured != null) {
        amount = double.parse(measured[1]!);
        unit = 'count';
      }
    }
    int? pack;
    if (measured != null) {
      final prefix = RegExp(r'(\d+(?:\s*[x×*]\s*\d+)*\s*[x×*]\s*)$').firstMatch(
        text.substring(0, measured.start).replaceAll(RegExp(r'[()]'), ' '),
      );
      if (prefix != null) {
        pack = _arithmetic(prefix[1]!.replaceAll(RegExp(r'[x×*]\s*$'), ''));
      }
      final suffix = RegExp(
        r'^\s*\)*\s*[x×*]\s*(\(?\s*\d+(?:\s*[+*x×]\s*\(?\s*\d+\s*\)?)*(?:\s*free)?\s*\)?)',
      ).firstMatch(text.substring(measured.end));
      if (suffix != null) {
        final n = _arithmetic(suffix[1]!);
        if (n != null) pack = (pack ?? 1) * n;
      }
    }
    if (unit != 'count') {
      final count =
          countPattern.firstMatch(text) ??
          RegExp(
            r'(?:^|\s)(?:حزمه|كرتون|شده|pack)\s*(?:of\s*)?\(?\s*(\d+)(?![\d.]|\s*(?:' +
                _units +
                r'))',
          ).firstMatch(text);
      if (count != null) {
        final n = int.parse(count[1]!);
        if (pack != null && pack != n) return unknown;
        pack = n;
      }
    }
    if (pack == null &&
        RegExp(
          r'multi\s*pack|multipack|عبوه متعدده|عبوات متعدده',
        ).hasMatch(text)) {
      return unknown;
    }
    return (amount: amount, unit: unit, pack: pack);
  }

  static String variantName(String name) => normalize(name)
      .replaceAll(
        RegExp(
          r'\d+(?:\.\d+)?\s*(?:كيلو\s*جرام|كيلوجرام|كيلو|كجم|كغم|كغ|kg|جرام|غرام|جم|غم|grams?|gm|g|ملليلتر|مليلتر|ml|مل|لتر|liters?|litres?|l)(?![a-z\u0600-\u06ff])',
        ),
        '',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static String? amazonAsin(String query) {
    final value = query.trim();
    if (RegExp(r'^[A-Z0-9]{10}$', caseSensitive: false).hasMatch(value)) {
      return value.toUpperCase();
    }
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'https' ||
        !['amazon.sa', 'www.amazon.sa'].contains(uri.host) ||
        uri.hasPort ||
        uri.userInfo.isNotEmpty) {
      return null;
    }
    return RegExp(
      r'/(?:dp|gp/product)/([A-Z0-9]{10})(?:/|$)',
      caseSensitive: false,
    ).firstMatch(uri.path)?.group(1)?.toUpperCase();
  }

  static bool exactSize(String query, ProductItem product) {
    if (amazonAsin(query) != null) {
      return true;
    }
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

  static bool sameProduct(ProductItem a, ProductItem b) {
    if (!a.hasExactQuantity ||
        !b.hasExactQuantity ||
        a.normalizedSizeAmount == null ||
        a.normalizedSizeAmount! <= 0 ||
        a.normalizedSizeAmount != b.normalizedSizeAmount ||
        a.normalizedSizeUnit != b.normalizedSizeUnit ||
        a.packCount != b.packCount) {
      return false;
    }
    String? barcode(ProductItem p) =>
        p.gtinBarcode != null && validBarcode(p.gtinBarcode!)
        ? p.gtinBarcode!.padLeft(14, '0')
        : null;
    final leftBarcode = barcode(a), rightBarcode = barcode(b);
    if (leftBarcode != null &&
        rightBarcode != null &&
        leftBarcode != rightBarcode) {
      return false;
    }
    // The server owns cross-store matching. Preserve its aliases when an old
    // basket item is refreshed or a retailer is temporarily unavailable.
    if (a.id > 0 && b.id > 0) {
      final leftIds = {a.id, ...a.catalogProductIds};
      final rightIds = {b.id, ...b.catalogProductIds};
      if (leftIds.intersection(rightIds).isNotEmpty) return true;
    }
    if (a.canonicalId != null && b.canonicalId != null) {
      return a.canonicalId == b.canonicalId;
    }
    if (leftBarcode != null && leftBarcode == rightBarcode) return true;
    return normalize(a.nameAr).isNotEmpty &&
        normalize(a.nameAr) == normalize(b.nameAr);
  }

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
