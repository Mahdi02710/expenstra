import 'dart:async';
import 'dart:math' as math;
import 'dart:ui'; // Required for ImageFilter

import 'package:expensetra/core/theme/app_colors.dart';
import 'package:expensetra/core/theme/app_text_styles.dart';
import 'package:expensetra/data/services/auth_service.dart';
import 'package:expensetra/data/services/session_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../shared/utils/app_snackbar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool hidePassword = true;
  bool isSignUp = false;

  // Animation Controllers
  late AnimationController _backgroundController;
  late AnimationController _entranceController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  StreamSubscription<User?>? _authSubscription;
  final AuthService _authService = AuthService();
  final SessionService _sessionService = SessionService();

  @override
  void initState() {
    super.initState();

    // 1. Background Animation (Slow, organic movement)
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);

    // 2. Entrance Animation (Fade & Slide up)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Start entrance after a tiny delay for smoothness
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _entranceController.forward();
    });

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted || user == null) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _backgroundController.dispose();
    _entranceController.dispose();
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
          _showSnackBar("Verification email sent.", AppColors.success);
        }
      } else {
        await _authService.signIn(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        await _sessionService.setGuestMode(false);
        if (mounted) {
          _showSnackBar("Sign in successful!", AppColors.success);
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar(e.toString(), AppColors.error);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar('Enter your email to reset password', AppColors.warning);
      return;
    }
    setState(() => isLoading = true);
    try {
      await _authService.sendPasswordResetEmail(email);
      if (mounted) {
        _showSnackBar('Password reset email sent', AppColors.success);
      }
    } catch (e) {
      if (mounted) _showSnackBar(e.toString(), AppColors.error);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => isLoading = true);
    try {
      await _authService.signInWithGoogle();
      await _sessionService.setGuestMode(false);
    } catch (e) {
      if (mounted) _showSnackBar(e.toString(), AppColors.error);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _continueAsGuest() async {
    await _sessionService.setGuestMode(true);
    if (mounted) {
      _showSnackBar('Continuing as guest', AppColors.success);
    }
  }

  void _showSnackBar(String message, Color color) {
    showAppSnackBar(context, message, backgroundColor: color);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: Stack(
        children: [
          // 1. Fluid Background Animation
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _AuroraBackgroundPainter(
                    animation: _backgroundController.value,
                    isDark: isDark,
                  ),
                );
              },
            ),
          ),

          // 2. Blur / Glass Effect Overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: (isDark ? Colors.black : Colors.white).withValues(
                  alpha: 0.1,
                ),
              ),
            ),
          ),

          // 3. Scrollable Content (Prevents Overflow)
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              // Header
                              _buildHeader(isDark),
                              const SizedBox(height: 40),
                              // Glass Card
                              _buildGlassLoginCard(isDark),
                              const SizedBox(height: 24),
                              // Footer
                              const Spacer(),
                              _buildGuestOption(isDark),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: 0.05,
            ),
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withValues(
                alpha: 0.1,
              ),
            ),
          ),
          child: Image.asset(
            'assets/images/ExpensTra-Logo.png',
            width: 64,
            height: 64,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'ExpensTra',
          style: AppTextStyles.h1.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Track expenses. Build wealth.',
          style: AppTextStyles.body2.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassLoginCard(bool isDark) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 450),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkCardBackground : Colors.white)
            .withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isSignUp ? 'Create Account' : 'Welcome Back',
                textAlign: TextAlign.center,
                style: AppTextStyles.h2.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 24),

              // Inputs
              _buildModernTextField(
                controller: emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                isDark: isDark,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => !v!.contains('@') ? 'Invalid email' : null,
              ),
              const SizedBox(height: 16),
              _buildModernTextField(
                controller: passwordController,
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                isDark: isDark,
                obscureText: hidePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                  onPressed: () => setState(() => hidePassword = !hidePassword),
                ),
                validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
              ),

              // Forgot Password
              if (!isSignUp)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: GestureDetector(
                      onTap: isLoading ? null : _handleForgotPassword,
                      child: Text(
                        'Forgot Password?',
                        style: AppTextStyles.body2.copyWith(
                          color: isDark ? AppColors.gold : AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Primary Button
              _buildPrimaryButton(isDark),

              const SizedBox(height: 16),

              // Google Button
              _buildGoogleButton(isDark),

              const SizedBox(height: 24),

              // Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isSignUp ? 'Already a member? ' : "New here? ",
                    style: AppTextStyles.body2.copyWith(
                      color: isDark ? Colors.white60 : Colors.black54,
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final borderColor = isDark ? Colors.white12 : Colors.black12;
    final focusColor = isDark ? AppColors.gold : AppColors.primary;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
        prefixIcon: Icon(icon, color: isDark ? Colors.white54 : Colors.black45),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? Colors.black26 : const Color(0xFFF5F7FA),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: focusColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(bool isDark) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.goldGradient : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.gold : AppColors.primary).withValues(
              alpha: 0.3,
            ),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : _handleAuth,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    isSignUp ? 'Create Account' : 'Sign In',
                    style: const TextStyle(
                      color: Colors.white, // Always white on gradient
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(bool isDark) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : _handleGoogleSignIn,
      icon: const Icon(Icons.g_mobiledata, size: 28),
      label: const Text('Continue with Google'),
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? Colors.white : AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildGuestOption(bool isDark) {
    return TextButton(
      onPressed: isLoading ? null : _continueAsGuest,
      child: Text(
        'Continue as Guest',
        style: TextStyle(
          color: isDark ? Colors.white54 : Colors.black45,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// Modern "Aurora" Mesh Gradient Painter
// --------------------------------------------------------------------------
class _AuroraBackgroundPainter extends CustomPainter {
  final double animation;
  final bool isDark;

  _AuroraBackgroundPainter({required this.animation, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final paint = Paint();

    // 1. Base Background Color
    paint.color = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    canvas.drawRect(rect, paint);

    // 2. Define "Orbs" of color
    // We move these orbs based on the animation value (0.0 to 1.0)
    // using Sine/Cosine to make them float organically.

    final primaryColor = isDark ? AppColors.navy : AppColors.primary;
    final secondaryColor = isDark ? AppColors.gold : AppColors.secondary;
    final accentColor = isDark
        ? AppColors.blueDark
        : AppColors.primary.withValues(alpha: 0.5);

    // Orb 1: Top Left - Circular motion
    _drawOrb(
      canvas: canvas,
      center: Offset(
        size.width * 0.2 + math.cos(animation * 2 * math.pi) * 50,
        size.height * 0.2 + math.sin(animation * 2 * math.pi) * 50,
      ),
      radius: size.width * 0.6,
      color: primaryColor.withValues(alpha: isDark ? 0.4 : 0.2),
    );

    // Orb 2: Bottom Right - Figure 8 motion
    _drawOrb(
      canvas: canvas,
      center: Offset(
        size.width * 0.8 - math.sin(animation * 2 * math.pi) * 60,
        size.height * 0.8 + math.cos(animation * 4 * math.pi) * 40,
      ),
      radius: size.width * 0.5,
      color: secondaryColor.withValues(alpha: isDark ? 0.3 : 0.2),
    );

    // Orb 3: Middle Left - Vertical floating
    _drawOrb(
      canvas: canvas,
      center: Offset(
        size.width * 0.1,
        size.height * 0.5 + math.sin(animation * 2 * math.pi) * 80,
      ),
      radius: size.width * 0.4,
      color: accentColor.withValues(alpha: isDark ? 0.3 : 0.15),
    );
  }

  void _drawOrb({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required Color color,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _AuroraBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.isDark != isDark;
  }
}
