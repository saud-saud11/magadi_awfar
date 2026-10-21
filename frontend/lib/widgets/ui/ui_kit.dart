import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Paints a subtle Islamic 8-point star lattice — no image assets needed.
class IslamicPatternPainter extends CustomPainter {
  final Color color;
  final double cell;
  IslamicPatternPainter({this.color = Colors.white, this.cell = 46});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (double y = -cell; y < size.height + cell; y += cell) {
      for (double x = -cell; x < size.width + cell; x += cell) {
        final c = Offset(x + cell / 2, y + cell / 2);
        final r = cell * 0.38;
        _star(canvas, c, r, paint);
      }
    }
  }

  void _star(Canvas canvas, Offset c, double r, Paint p) {
    // Two overlapping squares => 8-point star (Rub el Hizb)
    for (final rot in [0.0, math.pi / 4]) {
      final path = Path();
      for (int i = 0; i < 4; i++) {
        final a = rot + i * math.pi / 2;
        final pt = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      canvas.drawPath(path, p);
    }
    canvas.drawCircle(c, r * 0.32, p);
  }

  @override
  bool shouldRepaint(covariant IslamicPatternPainter old) => old.color != color || old.cell != cell;
}

/// Hero header: emerald gradient + pattern + glow orb.
class GradientHeader extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double bottomRadius;

  const GradientHeader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 28),
    this.bottomRadius = 32,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(bottomRadius)),
      child: Container(
        decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: IslamicPatternPainter(color: Colors.white.withOpacity(0.07))),
            ),
            Positioned(
              top: -60,
              left: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppTheme.primaryLight.withOpacity(0.45),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Positioned(
              bottom: -70,
              right: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppTheme.accentGold.withOpacity(0.22),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// Frosted glass card.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final bool dark;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppTheme.radius,
    this.onTap,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: dark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.82),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: Colors.white.withOpacity(dark ? 0.22 : 0.9), width: 1.2),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Elevated surface card with soft shadow.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final double radius;
  final BoxBorder? border;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.color,
    this.gradient,
    this.radius = AppTheme.radius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppTheme.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppTheme.softShadow,
        border: border,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Section title with optional trailing action.
class SectionTitle extends StatelessWidget {
  final String title;
  final String? emoji;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionTitle(this.title, {super.key, this.emoji, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              gradient: AppTheme.goldGradient,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          if (emoji != null) ...[
            Text(emoji!, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textDark),
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// Pill-shaped gradient primary button.
class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final EdgeInsetsGeometry padding;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.gradient = AppTheme.emeraldButton,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: enabled ? AppTheme.glowShadow(AppTheme.primary) : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: padding,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small savings badge (green pill).
class SavingsBadge extends StatelessWidget {
  final String text;
  final bool gold;
  const SavingsBadge(this.text, {super.key, this.gold = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: gold ? AppTheme.goldGradient : const LinearGradient(colors: [Color(0xFF16C784), Color(0xFF0E9F6E)]),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// Bell that wiggles and turns gold when activated.
class AnimatedBell extends StatefulWidget {
  final bool active;
  final VoidCallback? onTap;
  final double size;
  final String? tooltip;

  const AnimatedBell({super.key, required this.active, this.onTap, this.size = 22, this.tooltip});

  @override
  State<AnimatedBell> createState() => _AnimatedBellState();
}

class _AnimatedBellState extends State<AnimatedBell> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

  @override
  void didUpdateWidget(covariant AnimatedBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          _c.forward(from: 0);
          widget.onTap?.call();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: widget.active ? AppTheme.goldGradient : null,
            color: widget.active ? null : AppTheme.surfaceAlt,
            boxShadow: widget.active ? AppTheme.glowShadow(AppTheme.accentGold) : null,
          ),
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, child) {
              final t = _c.value;
              final angle = math.sin(t * math.pi * 6) * (1 - t) * 0.5;
              return Transform.rotate(angle: angle, alignment: Alignment.topCenter, child: child);
            },
            child: Icon(
              widget.active ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
              size: widget.size,
              color: widget.active ? Colors.white : AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
    return widget.tooltip != null ? Tooltip(message: widget.tooltip!, child: btn) : btn;
  }
}

/// Shimmer skeleton block.
class ShimmerBox extends StatefulWidget {
  final double height;
  final double? width;
  final double radius;
  const ShimmerBox({super.key, required this.height, this.width, this.radius = 16});

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final v = _c.value * 3 - 1;
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(v - 1, 0),
              end: Alignment(v + 1, 0),
              colors: const [Color(0xFFEFECE4), Color(0xFFF9F7F2), Color(0xFFEFECE4)],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton list of product cards for loading states.
class ProductSkeletonList extends StatelessWidget {
  final int count;
  const ProductSkeletonList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: SoftCard(
            child: Row(
              children: const [
                ShimmerBox(height: 72, width: 72, radius: 16),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(height: 14, radius: 6),
                      SizedBox(height: 10),
                      ShimmerBox(height: 12, width: 120, radius: 6),
                      SizedBox(height: 10),
                      ShimmerBox(height: 18, width: 80, radius: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fade + slide-up entrance animation, staggered by [index].
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final delayMs = 50 * widget.index.clamp(0, 10);
    if (delayMs == 0) {
      _c.forward();
    } else {
      _timer = Timer(Duration(milliseconds: delayMs), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(curve),
        child: widget.child,
      ),
    );
  }
}

/// Friendly empty-state illustration built from layered circles + icon.
class EmptyIllustration extends StatelessWidget {
  final IconData icon;
  final double size;
  const EmptyIllustration({super.key, required this.icon, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryContainer.withOpacity(0.7)),
          ),
          Container(
            width: size * 0.72,
            height: size * 0.72,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryContainer),
          ),
          Container(
            width: size * 0.48,
            height: size * 0.48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.emeraldButton,
              boxShadow: AppTheme.glowShadow(AppTheme.primary),
            ),
            child: Icon(icon, color: Colors.white, size: size * 0.24),
          ),
          Positioned(
            top: size * 0.12,
            left: size * 0.14,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppTheme.goldGradient),
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays product image with smooth loading shimmer, error handling, and smart category fallbacks.
class ProductImage extends StatelessWidget {
  final String? imageUrl;
  final String? nameAr;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;

  const ProductImage({
    super.key,
    required this.imageUrl,
    this.nameAr,
    this.width = 70,
    this.height = 70,
    this.borderRadius = 16,
    this.fit = BoxFit.contain,
  });

  IconData _getFallbackIcon() {
    final n = (nameAr ?? '').toLowerCase();
    if (n.contains('حليب') || n.contains('لبن') || n.contains('عصير') || n.contains('مياه') || n.contains('ماء')) {
      return Icons.local_drink_rounded;
    }
    if (n.contains('أرز') || n.contains('ارز') || n.contains('شعلان') || n.contains('حبوب')) {
      return Icons.rice_bowl_rounded;
    }
    if (n.contains('شوكولاتة') || n.contains('شوكولاته') || n.contains('نوتيلا') || n.contains('سكر')) {
      return Icons.cake_rounded;
    }
    if (n.contains('زيت') || n.contains('عافية') || n.contains('نور') || n.contains('سمن')) {
      return Icons.opacity_rounded;
    }
    if (n.contains('شاي') || n.contains('قهوة') || n.contains('كوفيه')) {
      return Icons.coffee_rounded;
    }
    if (n.contains('جبن') || n.contains('جبنة') || n.contains('كيري') || n.contains('بوك') || n.contains('قشطة')) {
      return Icons.breakfast_dining_rounded;
    }
    if (n.contains('تونة') || n.contains('دجاج') || n.contains('لحم') || n.contains('سمك')) {
      return Icons.set_meal_rounded;
    }
    if (n.contains('خبز') || n.contains('توست') || n.contains('لوزين') || n.contains('كرواسون')) {
      return Icons.bakery_dining_rounded;
    }
    if (n.contains('صابون') || n.contains('تايد') || n.contains('فيري') || n.contains('غسيل') || n.contains('منظف')) {
      return Icons.cleaning_services_rounded;
    }
    if (n.contains('أطفال') || n.contains('حفاض') || n.contains('بيبي')) {
      return Icons.child_care_rounded;
    }
    return Icons.shopping_bag_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final validUrl = (imageUrl != null && imageUrl!.trim().isNotEmpty && imageUrl!.startsWith('http'));

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppTheme.border.withOpacity(0.6)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: validUrl
            ? Image.network(
                imageUrl!,
                fit: fit,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return ShimmerBox(width: width, height: height, radius: borderRadius);
                },
                errorBuilder: (context, error, stackTrace) => _buildFallback(),
              )
            : _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Container(
        width: width * 0.75,
        height: height * 0.75,
        decoration: BoxDecoration(
          color: AppTheme.primaryContainer.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getFallbackIcon(),
          size: width * 0.42,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}
