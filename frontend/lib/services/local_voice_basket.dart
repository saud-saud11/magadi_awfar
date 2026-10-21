import '../models/models.dart';
import 'offline_catalog.dart';
import 'product_matching.dart';

/// Device-local command handling when the optional server is unavailable.
/// Prices always come from a separate search, never from language interpretation.
class LocalVoiceBasket {
  static List<VoiceBasketItem> _items = [];
  static final List<List<VoiceBasketItem>> _history = [];
  static List<VoiceBasketItem> _clone(List<VoiceBasketItem> items) => items
      .map(
        (i) => VoiceBasketItem(
          productId: i.productId,
          packCount: i.packCount,
          nameAr: i.nameAr,
          brandAr: i.brandAr,
          quantity: i.quantity,
          sizeAmount: i.sizeAmount,
          sizeUnit: i.sizeUnit,
          imageUrl: i.imageUrl,
        ),
      )
      .toList();

  static int _quantity(String text) {
    final number = RegExp(
      r'^\s*(\d+)\s+(?!جرام|جم|كجم|مل|لتر)',
    ).firstMatch(text);
    if (number != null) return int.parse(number[1]!).clamp(1, 100);
    if (RegExp(r'اثنين|اثنتين|حبتين|علبتين').hasMatch(text)) return 2;
    if (text.contains('ثلاث')) return 3;
    return 1;
  }

  static VoiceBasketResult execute(String query) {
    final text = ProductMatching.normalize(query);
    var message = 'الأوامر تُعالج على جهازك. الأسعار تُجلب عند المقارنة.';
    final before = _clone(_items);
    var changed = false;
    if (text.isEmpty) {
      // Read only: do not mutate the current basket when reopening the screen.
    } else if (RegExp(r'تراجع|رجع').hasMatch(text)) {
      if (_history.isNotEmpty) {
        _items = _history.removeLast();
        message = 'تم التراجع عن آخر تعديل';
      } else {
        message = 'لا يوجد تعديل للتراجع عنه';
      }
    } else if (text.contains('لا تضيف') || text.contains('ما ابي')) {
      message = 'لن نضيف الصنف إلى السلة';
    } else if (text.startsWith('شيل') || text.startsWith('احذف')) {
      final name = text.replaceFirst(RegExp(r'^(شيل|احذف)\s*'), '');
      if (name.isNotEmpty) {
        _items.removeWhere(
          (i) => ProductMatching.normalize(i.nameAr).contains(name),
        );
      }
      changed = _items.length != before.length;
      message = changed ? 'تم حذف الصنف' : 'لم أجد الصنف في سلتك';
    } else if (text.contains('زيد') ||
        text.startsWith('خله') ||
        text.startsWith('لا خله')) {
      if (_items.isEmpty) {
        message = 'أضف صنفًا أولًا حتى أعدّله';
      } else if (text.contains('كبير') || text.contains('صغير')) {
        final previous = _items.last;
        final choices =
            OfflineCatalog.search(query: previous.brandAr ?? previous.nameAr)
                .matchedProducts
                .where(
                  (p) =>
                      p.normalizedSizeUnit == previous.sizeUnit &&
                      p.brandAr == previous.brandAr &&
                      ProductMatching.variantName(p.nameAr) ==
                          ProductMatching.variantName(previous.nameAr),
                )
                .toList()
              ..sort(
                (a, b) => (a.normalizedSizeAmount ?? 0).compareTo(
                  b.normalizedSizeAmount ?? 0,
                ),
              );
        if (choices.isNotEmpty) {
          final p = text.contains('كبير') ? choices.last : choices.first;
          _items[_items.length - 1] = VoiceBasketItem(
            productId: p.id,
            packCount: p.packCount,
            nameAr: p.nameAr,
            brandAr: p.brandAr,
            quantity: previous.quantity,
            sizeAmount: p.normalizedSizeAmount,
            sizeUnit: p.normalizedSizeUnit,
            imageUrl: p.imageUrl,
          );
          changed = true;
          message = 'تم اختيار ${p.nameAr} من الكتالوج';
        } else {
          message = 'لم أجد حجمًا بديلًا مطابقًا';
        }
      } else {
        _items.last.quantity =
            (text.contains('زيد')
                    ? _items.last.quantity + 1
                    : _quantity(text.replaceFirst('خله', '').trim()))
                .clamp(1, 100);
        changed = true;
        message = 'تم تعديل الكمية إلى ${_items.last.quantity}';
      }
    } else {
      final unknown = <String>[];
      for (final part in text.split(RegExp(r'\s+و|[،,]'))) {
        final cleaned = part
            .replaceAll(RegExp(r'^(ابي|ابغى|اضف|حط)\s+'), '')
            .replaceAll(
              RegExp(r'^(اثنين|اثنتين|حبتين|علبتين|ثلاثه|ثلاث|\d+)\s+'),
              '',
            )
            .trim();
        if (cleaned.isEmpty) continue;
        final choices =
            OfflineCatalog.search(query: cleaned).matchedProducts.toList()
              ..sort(
                (a, b) => (a.normalizedSizeAmount ?? double.infinity).compareTo(
                  b.normalizedSizeAmount ?? double.infinity,
                ),
              );
        if (choices.isEmpty) {
          unknown.add(cleaned);
          continue;
        }
        final p = choices.first;
        final qty = _quantity(part);
        final index = _items.indexWhere((i) => i.productId == p.id);
        if (index >= 0) {
          _items[index].quantity = (_items[index].quantity + qty).clamp(1, 100);
        } else {
          _items.add(
            VoiceBasketItem(
              productId: p.id,
              packCount: p.packCount,
              nameAr: p.nameAr,
              brandAr: p.brandAr,
              quantity: qty,
              sizeAmount: p.normalizedSizeAmount,
              sizeUnit: p.normalizedSizeUnit,
              imageUrl: p.imageUrl,
            ),
          );
        }
        changed = true;
      }
      message = changed
          ? 'تم تحديث السلة. اخترنا أصغر عبوة من الكتالوج عندما لم تحدد الحجم؛ راجع الأصناف أدناه.'
          : 'لم أجد صنفًا مطابقًا في الكتالوج المحلي';
      if (unknown.isNotEmpty) {
        message += ' لم تتم إضافة: ${unknown.join('، ')}.';
      }
    }
    if (changed) {
      _history.add(before);
      if (_history.length > 30) _history.removeAt(0);
    }
    return VoiceBasketResult(
      status: 'local',
      recognizedText: query,
      intent: 'local_command',
      messageAr: message,
      itemsAdded: const [],
      itemsModified: const [],
      itemsRemoved: const [],
      currentBasket: _clone(_items),
      clarificationOptions: const [],
      canUndo: _history.isNotEmpty,
      sessionId: 'device_local',
    );
  }
}
