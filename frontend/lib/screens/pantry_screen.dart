import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/pantry_service.dart';
import '../services/push_service.dart';
import '../widgets/pantry_alert_dialog.dart';
import '../widgets/ios_pwa_install_dialog.dart';
import '../widgets/ui/ui_kit.dart';

class PantryScreen extends StatefulWidget {
  final Function(List<PantryItemModel>) onAddPantryToBasket;
  final Function(ProductItem) onAddSingleToBasket;
  final VoidCallback onNavigateToBasket;
  final VoidCallback? onNavigateToSearch;

  const PantryScreen({
    super.key,
    required this.onAddPantryToBasket,
    required this.onAddSingleToBasket,
    required this.onNavigateToBasket,
    this.onNavigateToSearch,
  });

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final PantryService _pantryService = PantryService();
  bool _isLoading = false;
  bool _isCheckingPrices = false;
  PantrySummaryModel? _summary;
  Map<String, dynamic> _pushConfig = {};
  bool _pushBusy = false;

  @override
  void initState() {
    super.initState();
    _summary = _buildSummaryFromCache();
    _pantryService.trackedItemsNotifier.addListener(_onTrackedItemsChanged);
    _loadData();
    _pantryService.getPushConfig().then((config) {
      if (mounted) setState(() => _pushConfig = config);
    });
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
      totalPotentialSavingsSar: list.fold(
        0.0,
        (acc, it) => acc + (it.priceDropSar * it.usualQuantity),
      ),
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
            alertsCount < 0
                ? 'تعذر فحص الأسعار الآن؛ لم يتم تأكيد تحديثها'
                : alertsCount > 0
                ? 'تم فحص الأسعار بنجاح! تم إرسال $alertsCount تنبيهات جديدة.'
                : 'اكتمل طلب الفحص للمصادر المتاحة؛ راجع وقت آخر تحقق لكل صنف.',
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
    if (PushNotificationService.isIos &&
        !PushNotificationService.isStandalone) {
      if (mounted) IosPwaInstallDialog.show(context);
      return;
    }

    if (_pushBusy) return;
    if (_pushConfig['enabled'] != true ||
        _pushConfig['public_key'] is! String) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'خدمة التنبيهات لم تتصل بخادم مهيأ بعد. أصنافك محفوظة ويمكنك متابعة أسعارها هنا.',
          ),
        ),
      );
      return;
    }
    setState(() => _pushBusy = true);
    final res = await PushNotificationService.registerAndSubscribe(
      _pushConfig['public_key'] as String,
    );
    if (res['success'] == true) {
      res['success'] = await _pantryService.registerPush(res);
    }
    if (mounted) setState(() => _pushBusy = false);

    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم تسجيل جهازك للتنبيهات. ستصلك عند رصد انخفاض أثناء الفحص الدوري.',
          ),
          backgroundColor: AppTheme.primary,
        ),
      );
    } else {
      final errMsg =
          res['error']?.toString() ??
          'تعذر تفعيل الإشعارات، يمكنك متابعة الأسعار داخل التطبيق';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تنبيه: $errMsg')));
    }
    _pushConfig = await _pantryService.getPushConfig();
    if (mounted) setState(() {});
  }

  void _showNotificationHistorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const NotificationHistorySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _summary?.items ?? _pantryService.trackedItemsNotifier.value;
    final totalItems = items.length;
    final activeAlerts = items
        .where((i) => i.serverSynced && i.isAlertEnabled)
        .length;
    final itemsWithDrops = items
        .where((i) => i.hasVerifiedPrice && i.hasPriceDrop)
        .length;
    final totalSavings = items
        .where((i) => i.hasVerifiedPrice)
        .fold(0.0, (acc, i) => acc + (i.priceDropSar * i.usualQuantity));
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
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
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
                    const SizedBox(height: 8),
                    ValueListenableBuilder<String>(
                      valueListenable: _pantryService.statusNotifier,
                      builder: (context, status, _) => Text(
                        status,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
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
                        child: GradientButton(
                          onPressed: () {
                            widget.onAddPantryToBasket(items);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'تمت إضافة ${items.length} أصناف من مقاضي البيت إلى سلة المقاضي بنجاح!',
                                ),
                                backgroundColor: AppTheme.primary,
                                action: SnackBarAction(
                                  label: 'عرض السلة',
                                  textColor: Colors.white,
                                  onPressed: widget.onNavigateToBasket,
                                ),
                              ),
                            );
                          },
                          icon: Icons.shopping_basket_rounded,
                          label:
                              'أضف مقاضي البيت للسلة (${items.length} أصناف)',
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'أصنافي المحفوظة للمتابعة الدائمة',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.textDark,
                          ),
                        ),
                        if (totalItems > 0)
                          TextButton.icon(
                            onPressed: () => _toggleAllAlerts(!allAlertsActive),
                            icon: Icon(
                              allAlertsActive
                                  ? Icons.notifications_off_outlined
                                  : Icons.notifications_active_outlined,
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
                  Text(
                    'تفعيل إشعارات الآيفون (iOS)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    'أضف التطبيق للشاشة الرئيسية لتلقي تنبيهات الأسعار الفورية',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => IosPwaInstallDialog.show(context),
              child: const Text(
                'الطريقة',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    if ((perm != 'granted' || _pushConfig['registered'] != true) &&
        PushNotificationService.isSupported) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primaryContainer.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.notification_add,
              color: AppTheme.primary,
              size: 24,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تفعيل الإشعارات الفورية',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.primary,
                    ),
                  ),
                  Text(
                    'احصل على تنبيه فوري عند رصد انخفاض أسعار مقاضيك حتى عند إغلاق التطبيق',
                    style: TextStyle(fontSize: 11, color: AppTheme.textDark),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _requestWebPush,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'تفعيل',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSummaryCard({
    required int totalItems,
    required int activeAlerts,
    required int itemsWithDrops,
    required double totalSavings,
    required bool allAlertsActive,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: IslamicPatternPainter(
                  color: Colors.white.withOpacity(0.04),
                  cell: 42,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: AppTheme.goldGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.kitchen_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'مراقبة أسعار مقاضي البيت',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.cloud_sync_rounded,
                              color: AppTheme.accentGold,
                              size: 14,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'حسب آخر تحقق',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatItem(
                        'المقاضي المتابعة',
                        '$totalItems',
                        Icons.playlist_add_check_rounded,
                      ),
                      _buildStatItem(
                        'تنبيهات نشطة',
                        '$activeAlerts',
                        Icons.notifications_active_rounded,
                      ),
                      _buildStatItem(
                        'عروض وتخفيضات',
                        '$itemsWithDrops',
                        Icons.trending_down_rounded,
                      ),
                      _buildStatItem(
                        'وفر محتمل',
                        '${totalSavings.toStringAsFixed(1)} ر.س',
                        Icons.savings_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.accentGold, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SoftCard(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(26),
      child: Column(
        children: [
          const EmptyIllustration(
            icon: Icons.notifications_active_rounded,
            size: 90,
          ),
          const SizedBox(height: 18),
          const Text(
            'قائمة مقاضي البيت فارغة حالياً',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'احفظ المنتجات التي تشتريها باستمرار (مثل الحليب، الأرز، الجبن، الزيت)، وسيقوم النظام بمراقبة أسعارها عبر المتاجر وتنبيهك فوراً بأي تخفيض.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          if (widget.onNavigateToSearch != null)
            GradientButton(
              label: 'ابحث عن مقاضيك وأضفها للمتابعة',
              icon: Icons.search_rounded,
              onPressed: widget.onNavigateToSearch,
            ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_rounded,
                      color: AppTheme.accentGold,
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'طرق سهلة لإضافة الأصناف:',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  '1. انقر على أيقونة الجرس 🔔 بجانب أي منتج في نتائج البحث.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textDark,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '2. أو استخدم الأمر الصوتي: «حط حليب السعودية في قائمة المتابعة».',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textDark,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPantryItemCard(PantryItemModel item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductImage(
                  imageUrl: item.imageUrl,
                  nameAr: item.productNameAr,
                  width: 68,
                  height: 68,
                  borderRadius: 14,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productNameAr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppTheme.textDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (item.brandAr != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceAlt,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Text(
                                item.brandAr!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ),
                          if (item.packLabelAr != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.packLabelAr!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            item.hasVerifiedPrice
                                ? '${item.lastLowestPriceSar.toStringAsFixed(2)} ر.س'
                                : 'بانتظار سعر موثوق',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceAlt,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Text(
                              item.lastLowestStoreName ?? 'المتجر',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBell(
                      active: item.isAlertEnabled,
                      tooltip: item.isAlertEnabled
                          ? 'التنبيه مفعل (انقر للتعطيل)'
                          : 'التنبيه معطل (انقر للتفعيل)',
                      onTap: () async {
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
                      icon: const Icon(
                        Icons.tune_rounded,
                        color: AppTheme.textMuted,
                        size: 20,
                      ),
                      tooltip: 'تخصيص شروط التنبيه والكمية',
                      onPressed: () async {
                        final changed = await PantryAlertDialog.show(
                          context,
                          item,
                        );
                        if (changed == true) _loadData();
                      },
                    ),
                  ],
                ),
              ],
            ),
            if (item.hasVerifiedPrice && item.hasPriceDrop)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.trending_down_rounded,
                      color: Color(0xFF047857),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'وفر ${item.priceDropSar.toStringAsFixed(2)} ر.س (${item.priceDropPercentage.toStringAsFixed(0)}%) مقارنة بسعر الأساس (${item.baselinePriceSar.toStringAsFixed(2)} ر.س)',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (item.isTargetMet)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFFB45309),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'وصل السعر إلى المستهدف المطلوب (${item.targetPriceSar?.toStringAsFixed(2)} ر.س أو أقل)!',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Divider(height: 18, color: AppTheme.border.withOpacity(0.6)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'الكمية المعتادة: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    InkWell(
                      onTap: item.usualQuantity > 1
                          ? () async {
                              await _pantryService.updateItem(
                                item.id,
                                usualQuantity: item.usualQuantity - 1,
                              );
                              _loadData();
                            }
                          : null,
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: item.usualQuantity > 1
                              ? AppTheme.surfaceAlt
                              : AppTheme.border.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.remove_rounded,
                          size: 14,
                          color: item.usualQuantity > 1
                              ? AppTheme.textDark
                              : Colors.grey,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '${item.usualQuantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        await _pantryService.updateItem(
                          item.id,
                          usualQuantity: item.usualQuantity + 1,
                        );
                        _loadData();
                      },
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          gradient: AppTheme.emeraldButton,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    widget.onAddSingleToBasket(item.toProductItem());
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تمت إضافة «${item.productNameAr}» لسلة المشتريات',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                  label: const Text(
                    'أضف للسلة',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationHistorySheet extends StatefulWidget {
  const NotificationHistorySheet({super.key});

  @override
  State<NotificationHistorySheet> createState() =>
      _NotificationHistorySheetState();
}

class _NotificationHistorySheetState extends State<NotificationHistorySheet> {
  final PantryService _pantryService = PantryService();
  bool _isLoading = false;
  bool _isSendingTest = false;
  bool _isClearing = false;
  List<NotificationLogItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _notifications = _pantryService.cachedNotifications;
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final list = await _pantryService.fetchNotificationHistory();
      if (mounted) {
        setState(() {
          _notifications = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clearHistory() async {
    setState(() => _isClearing = true);
    final success = await _pantryService.clearNotificationHistory();
    if (mounted) {
      setState(() {
        _isClearing = false;
        if (success) _notifications = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'تم مسح سجل الإشعارات' : 'تعذر مسح السجل؛ حاول مجددًا',
          ),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _sendTestNotification() async {
    setState(() => _isSendingTest = true);
    final success = await _pantryService.sendTestNotification();
    if (mounted) {
      setState(() {
        _isSendingTest = false;
        _notifications = _pantryService.cachedNotifications;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'تم إرسال التنبيه إلى مزود الإشعارات'
                : 'تعذر إرسال التنبيه؛ تحقق من تفعيل الاشتراك وإعدادات الخادم',
          ),
          backgroundColor: AppTheme.primary,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.only(top: 16, bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notifications_active, color: AppTheme.primary),
                      SizedBox(width: 8),
                      Text(
                        'سجل الإشعارات والتنبيهات',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSendingTest ? null : _sendTestNotification,
                      icon: _isSendingTest
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, size: 16),
                      label: const Text(
                        'تجربة تنبيه فوري 🔔',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  if (_notifications.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _isClearing ? null : _clearHistory,
                      icon: _isClearing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_sweep_outlined, size: 16),
                      label: const Text(
                        'مسح السجل',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_isLoading && _notifications.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              )
            else if (_notifications.isEmpty)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'لا توجد تنبيهات سابقة بعد',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'ستظهر هنا التغيّرات التي رصدها الفحص الدوري للأصناف المتابعة.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 12),
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: notif.isRead
                            ? Colors.grey.shade200
                            : AppTheme.primaryContainer,
                        child: Icon(
                          Icons.notifications,
                          color: notif.isRead ? Colors.grey : AppTheme.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        notif.titleAr,
                        style: TextStyle(
                          fontWeight: notif.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            notif.bodyAr,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textDark,
                            ),
                          ),
                          if (notif.createdAt != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(notif.createdAt!),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      onTap: () {
                        if (!notif.isRead) {
                          _pantryService.markNotificationRead(notif.id);
                        }
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }
}
