import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/pantry_service.dart';

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

  final List<Map<String, String>> _availableStores = [
    {'code': 'danube', 'name': 'الدانوب'},
    {'code': 'panda', 'name': 'بنده'},
    {'code': 'othaim', 'name': 'أسواق العثيم'},
    {'code': 'tamimi', 'name': 'أسواق التميمي'},
    {'code': 'carrefour', 'name': 'كارفور'},
    {'code': 'nahdi', 'name': 'صيدلية النهدي'},
    {'code': 'dawaa', 'name': 'صيدلية الدواء'},
  ];

  @override
  void initState() {
    super.initState();
    _targetPriceController = TextEditingController(
      text: widget.item.targetPriceSar != null ? widget.item.targetPriceSar!.toStringAsFixed(2) : '',
    );
    _quantity = widget.item.usualQuantity;
    _isAlertEnabled = widget.item.isAlertEnabled;
    _selectedDropPercentage = widget.item.dropPercentageThreshold;
    _selectedStores = widget.item.storeCodes != null ? widget.item.storeCodes!.toSet() : <String>{};
  }

  @override
  void dispose() {
    _targetPriceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final targetPrice = double.tryParse(_targetPriceController.text.trim());
    await PantryService().updateItem(
      widget.item.id,
      usualQuantity: _quantity,
      targetPriceSar: targetPrice,
      dropPercentageThreshold: _selectedDropPercentage,
      storeCodes: _selectedStores.isNotEmpty ? _selectedStores.toList() : null,
      isAlertEnabled: _isAlertEnabled,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إزالة من مقاضي البيت؟'),
          content: Text('هل تود إزالة «${widget.item.productNameAr}» من قائمة المتابعة وتنبيهات الأسعار؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('إزالة', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await PantryService().removeItem(widget.item.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune, color: AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('إعدادات تنبيه السعر', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    widget.item.productNameAr,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
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
                const SizedBox(height: 10),
                // Alert Switch
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isAlertEnabled ? AppTheme.primaryContainer.withOpacity(0.3) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isAlertEnabled ? Icons.notifications_active : Icons.notifications_off,
                            color: _isAlertEnabled ? AppTheme.primary : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isAlertEnabled ? 'التنبيهات مفعلة للصنف' : 'التنبيهات متوقفة مؤقتاً',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _isAlertEnabled ? AppTheme.primary : AppTheme.textDark,
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
                const SizedBox(height: 16),

                // Usual Quantity
                const Text('الكمية المعتادة للمنزل:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton.filledTonal(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '$_quantity حبات',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    const SizedBox(width: 16),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () => setState(() => _quantity++),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Target Price
                const Text('السعر المستهدف للتنبيه (اختياري):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  'سعر الأساس الحالي: ${widget.item.baselinePriceSar.toStringAsFixed(2)} ر.س',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _targetPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'مثال: ${(widget.item.baselinePriceSar * 0.9).toStringAsFixed(2)}',
                    suffixText: 'ر.س',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),

                // Percentage Drop
                const Text('نسبة التخفيض المطلوبة للتنبيه:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildPercentChip('أي انخفاض', null),
                    _buildPercentChip('5% فأكثر', 5.0),
                    _buildPercentChip('10% فأكثر', 10.0),
                    _buildPercentChip('20% فأكثر', 20.0),
                  ],
                ),
                const SizedBox(height: 16),

                // Specific Stores Filter
                const Text('المتاجر المشمولة بالتنبيه (الكل افتراضياً):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _availableStores.map((st) {
                    final isChecked = _selectedStores.contains(st['code']);
                    return FilterChip(
                      label: Text(st['name']!),
                      selected: isChecked,
                      selectedColor: AppTheme.primaryContainer,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                        color: isChecked ? AppTheme.primary : AppTheme.textDark,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedStores.add(st['code']!);
                          } else {
                            _selectedStores.remove(st['code']!);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
            label: const Text('إزالة الصنف', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('حفظ التعديلات'),
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
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        fontSize: 11,
        color: isSelected ? Colors.white : AppTheme.textDark,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) {
        setState(() => _selectedDropPercentage = percent);
      },
    );
  }
}
