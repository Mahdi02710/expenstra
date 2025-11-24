import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class HalfIcon extends StatefulWidget {
  final IconData icon;
  final bool isActive;
  final double size;
  final Duration animationDuration;
  final VoidCallback? onTap;

  const HalfIcon({
    super.key,
    required this.icon,
    required this.isActive,
    this.size = 24.0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.onTap,
  });

  @override
  State<HalfIcon> createState() => _HalfIconState();
}

class _HalfIconState extends State<HalfIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(HalfIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle for active state
                  if (widget.isActive)
                    Container(
                      width: widget.size + 16,
                      height: widget.size + 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isDark ? AppColors.gold : AppColors.primary)
                            .withValues(alpha: 0.1 * _fadeAnimation.value),
                      ),
                    ),

                  // Half-transparent overlay for inactive state
                  ClipRect(
                    child: Stack(
                      children: [
                        // Full icon (colored part)
                        Icon(
                          widget.icon,
                          size: widget.size,
                          color: widget.isActive
                              ? (isDark ? AppColors.gold : AppColors.primary)
                              : AppColors.textMuted,
                        ),

                        // Half overlay for inactive state
                        if (!widget.isActive)
                          Positioned.fill(
                            child: ClipPath(
                              clipper: HalfClipper(),
                              child: Container(
                                color: isDark
                                    ? AppColors.darkBackground.withValues(
                                        alpha: 0.6,
                                      )
                                    : AppColors.background.withValues(
                                        alpha: 0.6,
                                      ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Shine effect for active state
                  if (widget.isActive)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(
                            -widget.size + (widget.size * 2 * value),
                            0,
                          ),
                          child: Container(
                            width: widget.size * 0.3,
                            height: widget.size,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.white.withValues(alpha: 0.4),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class HalfClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Clip the right half
    path.moveTo(size.width * 0.5, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width * 0.5, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Alternative half icon with gradient effect
class GradientHalfIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final double size;

  const GradientHalfIcon({
    super.key,
    required this.icon,
    required this.isActive,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: size,
      height: size,
      child: ShaderMask(
        shaderCallback: (bounds) {
          if (isActive) {
            return LinearGradient(
              colors: [
                isDark ? AppColors.gold : AppColors.primary,
                isDark ? AppColors.gold : AppColors.primary,
              ],
            ).createShader(bounds);
          } else {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                isDark ? AppColors.gold : AppColors.primary,
                AppColors.textMuted,
              ],
              stops: const [0.5, 0.5],
            ).createShader(bounds);
          }
        },
        child: Icon(icon, size: size, color: Colors.white),
      ),
    );
  }
}
