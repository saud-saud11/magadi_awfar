import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/pantry_service.dart';
import '../services/api_service.dart';

class PantryAlertDialog extends StatefulWidget {
  final PantryItemModel item;

  const PantryAlertDialog({super.key, required this.item});

  static Future<bool?> show(BuildContext context, PantryItemModel item) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => PantryAlertDialog(item: item),
    );
  }

  @override
  State<PantryAlertDialog> createState() => _PantryAlertDialogState();
}

class _PantryAlertDialogState extends State<PantryAlertDialog> {
  late TextEditingController _targetPriceController;
  late int _quantity;
  late bool _isAlertEnabled;
  late double? _selectedDropPercentage;
  late Set<String> _selectedStores;

  List<SourceInfo> _availableStores = [];
  bool _loadingStores = true;

  Future<void> _loadStores() async {
    final stores = await ApiService.getSources();
    if (!mounted) return;
    setState(() {
      _availableStores = stores
          .where((s) => s.isEnabled || _selectedStores.contains(s.code))
          .toList();
      _loadingStores = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _targetPriceController = TextEditingController(
      text: widget.item.targetPriceSar != null
          ? widget.item.targetPriceSar!.toStringAsFixed(2)
          : '',
    );
    _quantity = widget.item.usualQuantity;
    _isAlertEnabled = widget.item.isAlertEnabled;
    _selectedDropPercentage = widget.item.dropPercentageThreshold;
    _selectedStores = widget.item.storeCodes != null
        ? widget.item.storeCodes!.toSet()
        : <String>{};
    _loadStores();
  }

  @override
  void dispose() {
    _targetPriceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final targetPrice = double.tryParse(_targetPriceController.text.trim());
    final saved = await PantryService().updateItem(
      widget.item.id,
      usualQuantity: _quantity,
      targetPriceSar: targetPrice,
      dropPercentageThreshold: _selectedDropPercentage,
      storeCodes: _selectedStores.isNotEmpty ? _selectedStores.toList() : null,
      isAlertEnabled: _isAlertEnabled,
    );
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(PantryService().statusNotifier.value)),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'إزالة من مقاضي البيت؟',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            'هل تود إزالة «${widget.item.productNameAr}» من قائمة المتابعة وتنبيهات الأسعار؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'إزالة',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      final removed = await PantryService().removeItem(widget.item.id);
      if (mounted && removed) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22),
        actionsPadding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.glowShadow(
                  AppTheme.primary.withOpacity(0.25),
                ),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إعدادات تنبيه السعر',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.item.productNameAr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Alert Switch
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _isAlertEnabled
                        ? AppTheme.primaryContainer.withOpacity(0.45)
                        : AppTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isAlertEnabled
                          ? AppTheme.primary.withOpacity(0.35)
                          : AppTheme.border,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isAlertEnabled
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_off_rounded,
                            color: _isAlertEnabled
                                ? AppTheme.primary
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isAlertEnabled
                                ? 'التنبيهات مفعلة للصنف'
                                : 'التنبيهات متوقفة مؤقتاً',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: _isAlertEnabled
                                  ? AppTheme.primary
                                  : AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isAlertEnabled,
                        activeColor: AppTheme.primary,
                        onChanged: (v) => setState(() => _isAlertEnabled = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Usual Quantity
                const Text(
                  'الكمية المعتادة للمنزل:',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton.filledTonal(
                      icon: const Icon(Icons.remove, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.surfaceAlt,
                        foregroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        '$_quantity حبات',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.add, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => setState(() => _quantity++),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Target Price
                const Text(
                  'السعر المستهدف للتنبيه (اختياري):',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.item.hasVerifiedPrice
                      ? 'سعر الأساس الموثق: ${widget.item.baselinePriceSar.toStringAsFixed(2)} ر.س'
                      : 'بانتظار سعر أساس موثوق',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _targetPriceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.item.hasVerifiedPrice
                        ? 'مثال: ${(widget.item.baselinePriceSar * 0.9).toStringAsFixed(2)}'
                        : 'أدخل السعر الذي تريده',
                    suffixText: 'ر.س',
                    filled: true,
                    fillColor: AppTheme.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppTheme.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Percentage Drop
                const Text(
                  'نسبة التخفيض المطلوبة للتنبيه:',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPercentChip('أي انخفاض', null),
                    _buildPercentChip('5% فأكثر', 5.0),
                    _buildPercentChip('10% فأكثر', 10.0),
                    _buildPercentChip('20% فأكثر', 20.0),
                  ],
                ),
                const SizedBox(height: 18),

                // Specific Stores Filter
                const Text(
                  'المتاجر المشمولة بالتنبيه (الكل افتراضياً):',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 8),
                if (_loadingStores)
                  const LinearProgressIndicator()
                else if (_availableStores.isEmpty)
                  const Text(
                    'تعذر تحميل قائمة المتاجر؛ إعدادك الحالي محفوظ.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _availableStores.map((st) {
                    final isChecked = _selectedStores.contains(st.code);
                    return FilterChip(
                      label: Text(
                        st.isEnabled ? st.nameAr : '${st.nameAr} (غير مرتبط)',
                      ),
                      selected: isChecked,
                      selectedColor: AppTheme.primaryContainer,
                      checkmarkColor: AppTheme.primary,
                      backgroundColor: AppTheme.surfaceAlt,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isChecked ? AppTheme.primary : AppTheme.border,
                        ),
                      ),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: isChecked
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isChecked ? AppTheme.primary : AppTheme.textDark,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedStores.add(st.code);
                          } else {
                            _selectedStores.remove(st.code);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        actions: [
          Row(
            children: [
              TextButton.icon(
                onPressed: _confirmDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 18,
                ),
                label: const Text(
                  'إزالة',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'حفظ التعديلات',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPercentChip(String label, double? percent) {
    final isSelected = _selectedDropPercentage == percent;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primary,
      backgroundColor: AppTheme.surfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.border,
        ),
      ),
      labelStyle: TextStyle(
        fontSize: 11,
        color: isSelected ? Colors.white : AppTheme.textDark,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
      ),
      onSelected: (_) {
        setState(() => _selectedDropPercentage = percent);
      },
    );
  }
}
