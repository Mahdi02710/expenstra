import 'dart:math' as math;
import 'package:expensetra/core/theme/app_colors.dart';
import 'package:expensetra/core/theme/app_text_styles.dart';
import 'package:expensetra/data/services/auth_service.dart';
import 'package:expensetra/data/services/session_service.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool hidePassword = true;
  bool isSignUp = false;

  late AnimationController _backgroundAnimationController;
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late AnimationController _floatingAnimationController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatingAnimation;

  final AuthService _authService = AuthService();
  final SessionService _sessionService = SessionService();

  @override
  void initState() {
    super.initState();

    // Background animation (slow rotation)
    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Fade in animation
    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Slide animation
    _slideAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Floating animation
    _floatingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _floatingAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _floatingAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animations
    _fadeAnimationController.forward();
    _slideAnimationController.forward();
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _floatingAnimationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      if (isSignUp) {
        await _authService.signUp(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account created successfully!"),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        await _authService.signIn(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Login Successful!"),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your email to reset your password'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    setState(() => isLoading = true);
    try {
      await _authService.sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => isLoading = true);
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _continueAsGuest() async {
    await _sessionService.setGuestMode(true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Continuing as guest (local-only mode)'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated background with geometric shapes
          _buildAnimatedBackground(isDark, size),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),

                        // Logo and title section
                        _buildHeader(isDark),

                        const SizedBox(height: 48),

                        // Login form card
                        _buildLoginCard(isDark),

                        const SizedBox(height: 24),

                        // Toggle sign up / sign in
                        _buildToggleAuth(isDark),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(bool isDark, Size size) {
    return AnimatedBuilder(
      animation: _backgroundAnimationController,
      builder: (context, child) {
        return CustomPaint(
          size: size,
          painter: _GeometricBackgroundPainter(
            animationValue: _backgroundAnimationController.value,
            isDark: isDark,
            floatingOffset: _floatingAnimation.value,
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value * 0.5),
          child: Column(
            children: [
              // App logo with gradient
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: isDark
                      ? AppColors.goldGradient
                      : AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? AppColors.gold : AppColors.primary)
                          .withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/ExpensTra-Logo.png',
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // App name
              Text(
                'ExpensTra',
                style: AppTextStyles.h1.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),

              const SizedBox(height: 8),

              // Tagline
              Text(
                'Track your expenses, grow your wealth',
                style: AppTextStyles.body2.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoginCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCardBackground.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withValues(alpha: 0.3)
              : AppColors.border.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              isSignUp ? 'Create Account' : 'Welcome Back',
              style: AppTextStyles.h2.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
                fontSize: 28,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              isSignUp
                  ? 'Start tracking your expenses today'
                  : 'Sign in to continue',
              style: AppTextStyles.body2.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 32),

            // Email field
            _buildTextField(
              controller: emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
              isDark: isDark,
            ),

            const SizedBox(height: 20),

            // Password field
            _buildTextField(
              controller: passwordController,
              label: 'Password',
              icon: Icons.lock_outlined,
              obscureText: hidePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
                onPressed: () {
                  setState(() => hidePassword = !hidePassword);
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (isSignUp && value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
              isDark: isDark,
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isLoading ? null : _handleForgotPassword,
                child: Text(
                  'Forgot password?',
                  style: AppTextStyles.body2.copyWith(
                    color: isDark ? AppColors.gold : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Submit button
            _buildSubmitButton(isDark),

            const SizedBox(height: 16),

            // Google sign-in
            OutlinedButton.icon(
              onPressed: isLoading ? null : _handleGoogleSignIn,
              icon: const Icon(Icons.g_mobiledata, size: 28),
              label: const Text('Sign in with Google'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color: isDark ? AppColors.gold : AppColors.primary,
                ),
                foregroundColor: isDark ? AppColors.gold : AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: isLoading ? null : _continueAsGuest,
              child: Text(
                'Continue as guest',
                style: AppTextStyles.buttonMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: AppTextStyles.body1.copyWith(
        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: isDark ? AppColors.gold : AppColors.primary,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark
            ? AppColors.darkInputBackground
            : AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.gold : AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
        labelStyle: AppTextStyles.body2.copyWith(
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.goldGradient : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.gold : AppColors.primary)
                .withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleAuth,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                isSignUp ? 'Sign Up' : 'Sign In',
                style: AppTextStyles.buttonLarge.copyWith(
                  color: isDark ? AppColors.navy : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildToggleAuth(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isSignUp ? 'Already have an account? ' : "Don't have an account? ",
          style: AppTextStyles.body2.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              isSignUp = !isSignUp;
              _formKey.currentState?.reset();
            });
          },
          child: Text(
            isSignUp ? 'Sign In' : 'Sign Up',
            style: AppTextStyles.buttonMedium.copyWith(
              color: isDark ? AppColors.gold : AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// Custom painter for animated geometric background
class _GeometricBackgroundPainter extends CustomPainter {
  final double animationValue;
  final bool isDark;
  final double floatingOffset;

  _GeometricBackgroundPainter({
    required this.animationValue,
    required this.isDark,
    required this.floatingOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Background gradient
    final backgroundGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              AppColors.navy,
              AppColors.blueDark,
              AppColors.blueMedium,
            ]
          : [
              const Color(0xFFF0F4F8),
              const Color(0xFFE8F0F8),
              Colors.white,
            ],
    );

    final backgroundRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final backgroundShader =
        backgroundGradient.createShader(backgroundRect);
    paint.shader = backgroundShader;
    canvas.drawRect(backgroundRect, paint);

    // Draw floating geometric shapes
    _drawFloatingShapes(canvas, size, paint);
  }

  void _drawFloatingShapes(Canvas canvas, Size size, Paint paint) {
    final shapes = [
      // Large circle (top left)
      _Shape(
        type: ShapeType.circle,
        x: size.width * 0.1,
        y: size.height * 0.15 + floatingOffset * 2,
        size: 120,
        color: (isDark ? AppColors.gold : AppColors.primary)
            .withValues(alpha: 0.1),
        rotation: animationValue * 2 * math.pi,
      ),
      // Medium circle (top right)
      _Shape(
        type: ShapeType.circle,
        x: size.width * 0.85,
        y: size.height * 0.2 - floatingOffset,
        size: 80,
        color: (isDark ? AppColors.primary : AppColors.success)
            .withValues(alpha: 0.08),
        rotation: -animationValue * 2 * math.pi,
      ),
      // Triangle (bottom left)
      _Shape(
        type: ShapeType.triangle,
        x: size.width * 0.15,
        y: size.height * 0.75 + floatingOffset * 1.5,
        size: 100,
        color: (isDark ? AppColors.success : AppColors.gold)
            .withValues(alpha: 0.12),
        rotation: animationValue * math.pi,
      ),
      // Hexagon (bottom right)
      _Shape(
        type: ShapeType.hexagon,
        x: size.width * 0.9,
        y: size.height * 0.8 - floatingOffset * 2,
        size: 90,
        color: (isDark ? AppColors.primary : AppColors.secondary)
            .withValues(alpha: 0.1),
        rotation: -animationValue * math.pi * 1.5,
      ),
      // Small circles scattered
      for (int i = 0; i < 5; i++)
        _Shape(
          type: ShapeType.circle,
          x: size.width * (0.2 + i * 0.15),
          y: size.height * (0.3 + (i % 2) * 0.4) +
              floatingOffset * (i % 2 == 0 ? 1 : -1),
          size: 40 + i * 10,
          color: (isDark ? AppColors.gold : AppColors.primary)
              .withValues(alpha: 0.06),
          rotation: animationValue * (i + 1) * math.pi,
        ),
    ];

    for (final shape in shapes) {
      _drawShape(canvas, shape, paint);
    }
  }

  void _drawShape(Canvas canvas, _Shape shape, Paint paint) {
    paint.color = shape.color;
    canvas.save();
    canvas.translate(shape.x, shape.y);
    canvas.rotate(shape.rotation);

    switch (shape.type) {
      case ShapeType.circle:
        canvas.drawCircle(
          Offset.zero,
          shape.size / 2,
          paint,
        );
        break;
      case ShapeType.triangle:
        final path = Path();
        final radius = shape.size / 2;
        for (int i = 0; i < 3; i++) {
          final angle = (i * 2 * math.pi / 3) - math.pi / 2;
          final x = radius * math.cos(angle);
          final y = radius * math.sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
        break;
      case ShapeType.hexagon:
        final path = Path();
        final radius = shape.size / 2;
        for (int i = 0; i < 6; i++) {
          final angle = (i * 2 * math.pi / 6) - math.pi / 2;
          final x = radius * math.cos(angle);
          final y = radius * math.sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_GeometricBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.floatingOffset != floatingOffset ||
        oldDelegate.isDark != isDark;
  }
}

enum ShapeType { circle, triangle, hexagon }

class _Shape {
  final ShapeType type;
  final double x;
  final double y;
  final double size;
  final Color color;
  final double rotation;

  _Shape({
    required this.type,
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.rotation,
  });
}
