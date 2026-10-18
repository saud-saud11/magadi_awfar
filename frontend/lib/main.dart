import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'models/models.dart';
import 'screens/home_screen.dart';
import 'screens/voice_basket_screen.dart';
import 'screens/basket_screen.dart';
import 'screens/admin_screen.dart';

void main() {
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
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: ResponsiveMobileWrapper(
          child: MainNavigationScreen(),
        ),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<BasketItem> _basket = [];

  void _addToBasket(ProductItem product) {
    setState(() {
      final existingIndex = _basket.indexWhere((b) => b.product.id == product.id);
      if (existingIndex >= 0) {
        _basket[existingIndex].quantity += 1;
      } else {
        _basket.add(BasketItem(product: product, quantity: 1));
      }
    });
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
  }

  void _removeFromBasket(int productId) {
    setState(() {
      _basket.removeWhere((b) => b.product.id == productId);
    });
  }

  void _clearBasket() {
    setState(() {
      _basket.clear();
    });
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
        onNavigateToBasketCompare: () => setState(() => _currentIndex = 2),
      ),
      BasketScreen(
        basketItems: _basket,
        onClearBasket: _clearBasket,
        onRemoveItem: _removeFromBasket,
        onUpdateQuantity: _updateBasketQuantity,
      ),
      const AdminScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: AppTheme.textMuted,
            backgroundColor: AppTheme.surface,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            onTap: (index) => setState(() => _currentIndex = index),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.search),
                activeIcon: Icon(Icons.search, color: AppTheme.primary),
                label: 'مقارنة الأسعار',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.mic),
                activeIcon: Icon(Icons.mic, color: AppTheme.primary),
                label: 'السلة الصوتية',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: _basket.isNotEmpty,
                  label: Text('${_basket.length}'),
                  backgroundColor: AppTheme.primary,
                  child: const Icon(Icons.shopping_basket_outlined),
                ),
                activeIcon: Badge(
                  isLabelVisible: _basket.isNotEmpty,
                  label: Text('${_basket.length}'),
                  backgroundColor: AppTheme.primary,
                  child: const Icon(Icons.shopping_basket, color: AppTheme.primary),
                ),
                label: 'سلة المقاضي',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.admin_panel_settings_outlined),
                activeIcon: Icon(Icons.admin_panel_settings, color: AppTheme.primary),
                label: 'إدارة المصادر',
              ),
            ],
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
            child: ClipRect(
              child: child,
            ),
          ),
        );
      },
    );
  }
}

