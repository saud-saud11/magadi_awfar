import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/pantry_service.dart';
import '../services/push_service.dart';
import '../widgets/pantry_alert_dialog.dart';
import '../widgets/ios_pwa_install_dialog.dart';

class PantryScreen extends StatefulWidget {
  final Function(List<PantryItemModel>) onAddPantryToBasket;
  final Function(ProductItem) onAddSingleToBasket;
  final VoidCallback onNavigateToBasket;

  const PantryScreen({
    super.key,
    required this.onAddPantryToBasket,
    required this.onAddSingleToBasket,
    required this.onNavigateToBasket,
  });

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final PantryService _pantryService = PantryService();
  bool _isLoading = false;
  bool _isCheckingPrices = false;
  PantrySummaryModel? _summary;

  @override
  void initState() {
    super.initState();
    _summary = _buildSummaryFromCache();
    _pantryService.trackedItemsNotifier.addListener(_onTrackedItemsChanged);
    _loadData();
  }

  @override
  void dispose() {
    _pantryService.trackedItemsNotifier.removeListener(_onTrackedItemsChanged);
    super.dispose();
  }

  void _onTrackedItemsChanged() {
    if (mounted) {
      setState(() {
        _summary = _buildSummaryFromCache();
      });
    }
  }

  PantrySummaryModel _buildSummaryFromCache() {
    final list = _pantryService.trackedItemsNotifier.value;
    return PantrySummaryModel(
      totalItems: list.length,
      activeAlertsCount: list.where((it) => it.isAlertEnabled).length,
      itemsWithDropsCount: list.where((it) => it.hasPriceDrop).length,
      totalPotentialSavingsSar: list.fold(0.0, (acc, it) => acc + (it.priceDropSar * it.usualQuantity)),
      items: list,
    );
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final summary = await _pantryService.fetchPantrySummary();
      if (mounted && summary != null) {
        setState(() {
          _summary = summary;
        });
      }
    } catch (e) {
      debugPrint('Error loading pantry data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _triggerManualCheck() async {
    setState(() => _isCheckingPrices = true);
    final alertsCount = await _pantryService.triggerManualCheck();
    if (mounted) {
      setState(() => _isCheckingPrices = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            alertsCount > 0
                ? 'تم فحص الأسعار بنجاح! تم إرسال $alertsCount تنبيهات جديدة.'
                : 'تم فحص أحدث الأسعار لدى جميع المتاجر وتحديث المقاضي بنجاح.',
          ),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadData();
    }
  }

  Future<void> _toggleAllAlerts(bool enable) async {
    await _pantryService.toggleAllAlerts(enable);
    _loadData();
  }

  Future<void> _requestWebPush() async {
    if (PushNotificationService.isIos && !PushNotificationService.isStandalone) {
      if (mounted) IosPwaInstallDialog.show(context);
      return;
    }

    final res = await PushNotificationService.registerAndSubscribe(
      'BCa_Fake_Vapid_Public_Key_Sample_4PushNotifications_MagadiAwfar_Demo_Key'
    );

    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تفعيل التنبيهات الفورية بنجاح! ستصلك إشعارات عند نزول الأسعار.'),
          backgroundColor: AppTheme.primary,
        ),
      );
    } else {
      final errMsg = res['error']?.toString() ?? 'تعذر تفعيل الإشعارات، يمكنك متابعة الأسعار داخل التطبيق';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تنبيه: $errMsg'),
        ),
      );
    }
    setState(() {});
  }

  void _showNotificationHistorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            List<NotificationLogItem> history = List.from(_pantryService.cachedNotifications);
            bool isFetchingFresh = false;

            // Trigger background refresh if empty or on open
            if (history.isEmpty) {
              isFetchingFresh = true;
              _pantryService.fetchNotificationHistory().then((fresh) {
                if (ctx.mounted) {
                  setSheetState(() {
                    history = fresh;
                    isFetchingFresh = false;
                  });
                }
              });
            }

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.history, color: AppTheme.primary),
                            SizedBox(width: 8),
                            Text('سجل تنبيهات الأسعار', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (isFetchingFresh)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    Expanded(
                      child: history.isEmpty && !isFetchingFresh
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.notifications_none, size: 50, color: Colors.grey),
                                  SizedBox(height: 12),
                                  Text('لا توجد تنبيهات مسجلة حتى الآن', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: history.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (c, idx) {
                                final notif = history[idx];
                                final timeStr = notif.createdAt != null
                                    ? '${notif.createdAt!.hour.toString().padLeft(2, '0')}:${notif.createdAt!.minute.toString().padLeft(2, '0')} - ${notif.createdAt!.day}/${notif.createdAt!.month}'
                                    : '';
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                  leading: CircleAvatar(
                                    backgroundColor: notif.eventType == 'price_drop'
                                        ? Colors.green.shade100
                                        : AppTheme.primaryContainer,
                                    child: Icon(
                                      notif.eventType == 'price_drop' ? Icons.trending_down : Icons.notifications,
                                      color: notif.eventType == 'price_drop' ? Colors.green.shade800 : AppTheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(notif.titleAr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(notif.bodyAr, style: const TextStyle(fontSize: 12, color: AppTheme.textDark)),
                                      if (timeStr.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          timeStr,
                                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _summary?.items ?? _pantryService.trackedItemsNotifier.value;
    final totalItems = items.length;
    final activeAlerts = items.where((i) => i.isAlertEnabled).length;
    final itemsWithDrops = items.where((i) => i.hasPriceDrop).length;
    final totalSavings = items.fold(0.0, (acc, i) => acc + (i.priceDropSar * i.usualQuantity));
    final allAlertsActive = totalItems > 0 && activeAlerts == totalItems;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('مقاضي البيت — متابعة الأسعار'),
          actions: [
            IconButton(
              icon: _isCheckingPrices
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.bolt, color: Colors.amberAccent),
              tooltip: 'تحقق فوري من الأسعار الآن',
              onPressed: _isCheckingPrices ? null : _triggerManualCheck,
            ),
            ValueListenableBuilder<int>(
              valueListenable: _pantryService.unreadNotificationsCountNotifier,
              builder: (context, count, child) {
                return IconButton(
                  icon: Badge(
                    isLabelVisible: count > 0,
                    label: Text('$count'),
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.notifications_outlined),
                  ),
                  tooltip: 'سجل التنبيهات',
                  onPressed: _showNotificationHistorySheet,
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            if (_isLoading)
              const LinearProgressIndicator(
                backgroundColor: AppTheme.primaryContainer,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                minHeight: 3,
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                color: AppTheme.primary,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildPushBanner(),
                    const SizedBox(height: 12),
                    _buildSummaryCard(
                      totalItems: totalItems,
                      activeAlerts: activeAlerts,
                      itemsWithDrops: itemsWithDrops,
                      totalSavings: totalSavings,
                      allAlertsActive: allAlertsActive,
                    ),
                    const SizedBox(height: 16),
                    if (totalItems > 0)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            widget.onAddPantryToBasket(items);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تمت إضافة ${items.length} أصناف من مقاضي البيت إلى سلة المقاضي بنجاح!'),
                                backgroundColor: AppTheme.primary,
                                action: SnackBarAction(
                                  label: 'عرض السلة',
                                  textColor: Colors.white,
                                  onPressed: widget.onNavigateToBasket,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.shopping_basket, color: Colors.white),
                          label: Text(
                            'أضف مقاضي البيت للسلة (${items.length} أصناف)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 2,
                          ),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'أصنافي المحفوظة للمتابعة الدائمة',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                        ),
                        if (totalItems > 0)
                          TextButton.icon(
                            onPressed: () => _toggleAllAlerts(!allAlertsActive),
                            icon: Icon(
                              allAlertsActive ? Icons.notifications_off_outlined : Icons.notifications_active_outlined,
                              size: 16,
                            ),
                            label: Text(
                              allAlertsActive ? 'إيقاف الكل' : 'تفعيل الكل',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (totalItems == 0)
                      _buildEmptyState()
                    else
                      ...items.map((item) => _buildPantryItemCard(item)),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPushBanner() {
    final perm = PushNotificationService.getPermissionState();
    final isIos = PushNotificationService.isIos;
    final isStandalone = PushNotificationService.isStandalone;

    if (isIos && !isStandalone) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.apple, color: Colors.blue, size: 28),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تفعيل إشعارات الآيفون (iOS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('أضف التطبيق للشاشة الرئيسية لتلقي تنبيهات الأسعار الفورية', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => IosPwaInstallDialog.show(context),
              child: const Text('الطريقة', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    if (perm != 'granted' && PushNotificationService.isSupported) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primaryContainer.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.notification_add, color: AppTheme.primary, size: 24),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تفعيل الإشعارات الفورية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary)),
                  Text('احصل على تنبيه فوري فور انخفاض أسعار مقاضيك حتى عند إغلاق التطبيق', style: TextStyle(fontSize: 11, color: AppTheme.textDark)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _requestWebPush,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('تفعيل', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    return const SizedBox();
  }

  Widget _buildSummaryCard({
    required int totalItems,
    required int activeAlerts,
    required int itemsWithDrops,
    required double totalSavings,
    required bool allAlertsActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.primary,
            AppTheme.primaryDark,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.kitchen, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text('مراقبة أسعار مقاضي البيت', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_sync, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'مراقبة آلية 24/7',
                      style: TextStyle(color: Colors.white.withOpacity(0.95), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem('المقاضي المتابعة', '$totalItems', Icons.playlist_add_check),
              _buildStatItem('تنبيهات نشطة', '$activeAlerts', Icons.notifications_active),
              _buildStatItem('عروض وتخفيضات', '$itemsWithDrops', Icons.trending_down),
              _buildStatItem('وفر محتمل', '${totalSavings.toStringAsFixed(1)} ر.س', Icons.savings),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_active_outlined, size: 48, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'قائمة مقاضي البيت فارغة حالياً',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          const Text(
            'احفظ المنتجات التي تشتريها باستمرار (مثل الحليب، الأرز، الجبن، الزيت)، وسيقوم النظام بمراقبة أسعارها عبر المتاجر وتنبيهك فوراً بأي تخفيض.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('💡 طرق سهلة لإضافة الأصناف:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primary)),
                SizedBox(height: 4),
                Text('1. انقر على أيقونة الجرس 🔔 بجانب أي منتج في نتائج البحث.', style: TextStyle(fontSize: 11, color: AppTheme.textDark)),
                Text('2. أو استخدم الأمر الصوتي: «حط حليب السعودية في قائمة المتابعة».', style: TextStyle(fontSize: 11, color: AppTheme.textDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPantryItemCard(PantryItemModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 65,
                    height: 65,
                    color: Colors.grey.shade100,
                    child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                        ? Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2, color: Colors.grey),
                          )
                        : const Icon(Icons.inventory_2, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productNameAr,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (item.brandAr != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(item.brandAr!, style: const TextStyle(fontSize: 10, color: AppTheme.textDark)),
                            ),
                          if (item.packLabelAr != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.packLabelAr!,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '${item.lastLowestPriceSar.toStringAsFixed(2)} ر.س',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primary),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.lastLowestStoreName ?? 'المتجر',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        item.isAlertEnabled ? Icons.notifications_active : Icons.notifications_off_outlined,
                        color: item.isAlertEnabled ? Colors.amber.shade800 : Colors.grey,
                      ),
                      tooltip: item.isAlertEnabled ? 'التنبيه مفعل (انقر للتعطيل)' : 'التنبيه معطل (انقر للتفعيل)',
                      onPressed: () async {
                        await _pantryService.toggleAlert(item.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                !item.isAlertEnabled
                                    ? 'تم تفعيل التنبيه لـ «${item.productNameAr}» 🔔'
                                    : 'تم إيقاف التنبيه مؤقتاً لـ «${item.productNameAr}»',
                              ),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune, color: AppTheme.textMuted, size: 20),
                      tooltip: 'تخصيص شروط التنبيه والكمية',
                      onPressed: () async {
                        final changed = await PantryAlertDialog.show(context, item);
                        if (changed == true) _loadData();
                      },
                    ),
                  ],
                ),
              ],
            ),
            if (item.hasPriceDrop)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.trending_down, color: Colors.green.shade800, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'وفر ${item.priceDropSar.toStringAsFixed(2)} ر.س (${item.priceDropPercentage.toStringAsFixed(0)}%) مقارنة بسعر الأساس (${item.baselinePriceSar.toStringAsFixed(2)} ر.س)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            if (item.isTargetMet)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.amber.shade900, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'وصل السعر إلى المستهدف المطلوب (${item.targetPriceSar?.toStringAsFixed(2)} ر.س أو أقل)!',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('الكمية المعتادة: ', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    InkWell(
                      onTap: item.usualQuantity > 1
                          ? () async {
                              await _pantryService.updateItem(item.id, usualQuantity: item.usualQuantity - 1);
                              _loadData();
                            }
                          : null,
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: item.usualQuantity > 1 ? Colors.grey.shade200 : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.remove, size: 14, color: item.usualQuantity > 1 ? AppTheme.textDark : Colors.grey),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${item.usualQuantity}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        await _pantryService.updateItem(item.id, usualQuantity: item.usualQuantity + 1);
                        _loadData();
                      },
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, size: 14, color: AppTheme.textDark),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    widget.onAddSingleToBasket(item.toProductItem());
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تمت إضافة «${item.productNameAr}» لسلة المشتريات'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_shopping_cart, size: 16),
                  label: const Text('أضف للسلة', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
