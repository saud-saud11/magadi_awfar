import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'services/product_matching.dart';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'models/models.dart';
import 'screens/home_screen.dart';
import 'screens/voice_basket_screen.dart';
import 'screens/basket_screen.dart';
import 'screens/pantry_screen.dart';
import 'screens/admin_screen.dart';
import 'services/pantry_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PantryService().initialize();
  runApp(const MagadiAwfarApp());
}

class MagadiAwfarApp extends StatelessWidget {
  const MagadiAwfarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مقاضي أوفر - المدينة المنورة',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) => ResponsiveMobileWrapper(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox(),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = Uri.base.queryParameters['view'] == 'pantry' ? 2 : 0;
  bool _refreshing = false;
  final List<BasketItem> _basket = [];

  @override
  void initState() {
    super.initState();
    _restoreBasket();
  }

  Future<void> _restoreBasket() async {
    final prefs = await SharedPreferences.getInstance();
    ApiService.selectedDistrict =
        prefs.getString('magadi_district') ?? 'سلطانة';
    try {
      final saved =
          jsonDecode(prefs.getString('magadi_basket_v2') ?? '[]') as List;
      if (mounted) {
        setState(() {
          _basket.addAll(
            saved.map(
              (i) => BasketItem(
                product: ProductItem.fromJson(i['product']),
                quantity: i['quantity'] as int,
              ),
            ),
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _saveBasket() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'magadi_basket_v2',
      jsonEncode(
        _basket
            .map((i) => {'product': i.product.toJson(), 'quantity': i.quantity})
            .toList(),
      ),
    );
  }

  Future<void> _refreshPrices() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    final items = List<BasketItem>.from(_basket);
    for (var offset = 0; offset < items.length; offset += 3) {
      await Future.wait(
        items.skip(offset).take(3).map((item) async {
          final result = await ApiService.search(
            query: item.product.nameAr,
            district: ApiService.selectedDistrict,
          );
          final exact = (result?.matchedProducts ?? [])
              .where(
                (p) =>
                    ProductMatching.sameProduct(p, item.product) &&
                    p.lowestOffer != null,
              )
              .toList();
          if (exact.isNotEmpty && mounted && _basket.contains(item)) {
            // Keep the basket identity stable while refreshing its observed offers.
            item.product = ProductItem.fromJson({
              ...exact.first.toJson(),
              'id': item.product.id,
            });
          }
        }),
      );
    }
    if (mounted) {
      setState(() => _refreshing = false);
      await _saveBasket();
    }
  }

  void _addToBasket(ProductItem product) {
    setState(() {
      final existingIndex = _basket.indexWhere(
        (b) =>
            b.product.id == product.id ||
            ProductMatching.sameProduct(b.product, product),
      );
      if (existingIndex >= 0) {
        _basket[existingIndex].quantity = (_basket[existingIndex].quantity + 1)
            .clamp(1, 100);
      } else {
        _basket.add(BasketItem(product: product, quantity: 1));
      }
    });
    _saveBasket();
  }

  void _addPantryToBasket(List<PantryItemModel> pantryItems) {
    setState(() {
      for (final item in pantryItems) {
        final existingIndex = _basket.indexWhere(
          (b) => b.product.id == item.productId,
        );
        if (existingIndex >= 0) {
          _basket[existingIndex].quantity =
              (_basket[existingIndex].quantity + item.usualQuantity).clamp(
                1,
                100,
              );
        } else {
          _basket.add(
            BasketItem(
              product: item.toProductItem(),
              quantity: item.usualQuantity,
            ),
          );
        }
      }
      _currentIndex = 3; // Switch to BasketScreen
    });
    _saveBasket();
    _refreshPrices();
  }

  void _updateBasketQuantity(int productId, int delta) {
    setState(() {
      final idx = _basket.indexWhere((b) => b.product.id == productId);
      if (idx >= 0) {
        _basket[idx].quantity += delta;
        if (_basket[idx].quantity <= 0) {
          _basket.removeAt(idx);
        }
      }
    });
    _saveBasket();
  }

  void _removeFromBasket(int productId) {
    setState(() {
      _basket.removeWhere((b) => b.product.id == productId);
    });
    _saveBasket();
  }

  void _clearBasket() {
    setState(() {
      _basket.clear();
    });
    _saveBasket();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onAddToBasket: _addToBasket,
        onOpenVoiceBasket: () => setState(() => _currentIndex = 1),
      ),
      VoiceBasketScreen(
        onAddToBasket: _addToBasket,
        onNavigateToBasketCompare: () {
          setState(() => _currentIndex = 3);
          _refreshPrices();
        },
      ),
      PantryScreen(
        onAddPantryToBasket: _addPantryToBasket,
        onAddSingleToBasket: _addToBasket,
        onNavigateToBasket: () {
          setState(() => _currentIndex = 3);
          _refreshPrices();
        },
        onNavigateToSearch: () => setState(() => _currentIndex = 0),
      ),
      BasketScreen(
        basketItems: _basket,
        onClearBasket: _clearBasket,
        onRemoveItem: _removeFromBasket,
        onUpdateQuantity: _updateBasketQuantity,
        onNavigateToSearch: () => setState(() => _currentIndex = 0),
        onRefresh: _refreshPrices,
        refreshing: _refreshing,
      ),
      const AdminScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppTheme.border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0E3B33).withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              selectedItemColor: AppTheme.primary,
              unselectedItemColor: AppTheme.textMuted,
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w600,
                fontSize: 10.5,
              ),
              onTap: (index) => setState(() => _currentIndex = index),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.search_rounded),
                  activeIcon: Icon(
                    Icons.search_rounded,
                    color: AppTheme.primary,
                  ),
                  label: 'الرئيسية',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.mic_none_rounded),
                  activeIcon: Icon(Icons.mic_rounded, color: AppTheme.primary),
                  label: 'بالصوت',
                ),
                BottomNavigationBarItem(
                  icon: ValueListenableBuilder<List<PantryItemModel>>(
                    valueListenable: PantryService().trackedItemsNotifier,
                    builder: (context, items, _) {
                      return Badge(
                        isLabelVisible: items.isNotEmpty,
                        label: Text(
                          '${items.length}',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: AppTheme.accentGold,
                        child: const Icon(Icons.kitchen_outlined),
                      );
                    },
                  ),
                  activeIcon: ValueListenableBuilder<List<PantryItemModel>>(
                    valueListenable: PantryService().trackedItemsNotifier,
                    builder: (context, items, _) {
                      return Badge(
                        isLabelVisible: items.isNotEmpty,
                        label: Text(
                          '${items.length}',
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: AppTheme.accentGold,
                        child: const Icon(
                          Icons.kitchen_rounded,
                          color: AppTheme.primary,
                        ),
                      );
                    },
                  ),
                  label: 'مقاضي البيت',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: _basket.isNotEmpty,
                    label: Text(
                      '${_basket.length}',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: AppTheme.primary,
                    child: const Icon(Icons.shopping_basket_outlined),
                  ),
                  activeIcon: Badge(
                    isLabelVisible: _basket.isNotEmpty,
                    label: Text(
                      '${_basket.length}',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: AppTheme.primary,
                    child: const Icon(
                      Icons.shopping_basket_rounded,
                      color: AppTheme.primary,
                    ),
                  ),
                  label: 'السلة',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.admin_panel_settings_outlined),
                  activeIcon: Icon(
                    Icons.admin_panel_settings_rounded,
                    color: AppTheme.primary,
                  ),
                  label: 'المتاجر',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Adaptive wrapper ensuring sleek mobile phone layout on large screens
/// and full-bleed native experience on iOS & Android phones
class ResponsiveMobileWrapper extends StatelessWidget {
  final Widget child;

  const ResponsiveMobileWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 520) {
          return child;
        }

        return Container(
          color: const Color(0xFF0F172A), // Luxury dark slate backdrop
          alignment: Alignment.center,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            decoration: BoxDecoration(
              color: AppTheme.background,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 36,
                  spreadRadius: 2,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRect(child: child),
          ),
        );
      },
    );
  }
}
