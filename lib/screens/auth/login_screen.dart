import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_button.dart';
import '../home/main_nav_screen.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // Validate mru.ac.in domain only
  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final email = v.trim().toLowerCase();
    if (!email.endsWith('@mru.ac.in')) {
      return 'Use your college email (@mru.ac.in)';
    }
    return null;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    final ok = await auth.signIn(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (ok && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
        (_) => false,
      );
    }
  }

  Future<void> _googleSignIn() async {
    // Supabase OAuth — opens browser; handle via deep link / redirect
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Google Sign-In coming soon!',
          style: GoogleFonts.dmSans(),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : Colors.white;
    final textPri = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSec =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final fillColor =
        isDark ? AppColors.darkSearchBg : const Color(0xFFF7F7FB);
    final hintColor = isDark ? AppColors.darkTextLight : AppColors.textLight;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final iconColor = isDark ? AppColors.darkTextLight : AppColors.textLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back arrow (shown when navigated from onboarding)
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: textPri,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Heading
              Text(
                'Welcome back!',
                style: GoogleFonts.dmSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: textPri,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.1),

              const SizedBox(height: 8),

              Text(
                'Sign in to continue exchanging\nskills, services or anything\nof value.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: textSec,
                  height: 1.6,
                ),
              ).animate().fadeIn(delay: 130.ms),

              const SizedBox(height: 32),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // College Email
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.dmSans(color: textPri, fontSize: 14),
                      validator: _validateEmail,
                      decoration: InputDecoration(
                        labelText: 'College Email',
                        hintText: 'name@mru.ac.in',
                        hintStyle:
                            GoogleFonts.dmSans(color: hintColor, fontSize: 14),
                        labelStyle: GoogleFonts.dmSans(
                          color: hintColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        filled: true,
                        fillColor: fillColor,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 15),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primary, width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.error, width: 1),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.error, width: 1.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Password
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      style: GoogleFonts.dmSans(color: textPri, fontSize: 14),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Min 6 characters'
                          : null,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle:
                            GoogleFonts.dmSans(color: hintColor, fontSize: 14),
                        filled: true,
                        fillColor: fillColor,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 15),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 19,
                            color: iconColor,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primary, width: 1.5),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.error, width: 1),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.error, width: 1.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    // Forgot password — right aligned
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.only(top: 6, bottom: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot Password?',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Error banner
                    Consumer<AuthService>(
                      builder: (_, auth, __) {
                        if (auth.errorMessage == null) {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.error
                                .withOpacity(isDark ? 0.15 : 0.07),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.error
                                  .withOpacity(isDark ? 0.40 : 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.error, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  auth.errorMessage!,
                                  style: GoogleFonts.dmSans(
                                    color: AppColors.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Sign In button
                    Consumer<AuthService>(
                      builder: (_, auth, __) => GradientButton(
                        onPressed: auth.isLoading ? null : _login,
                        isLoading: auth.isLoading,
                        label: 'Sign In',
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Divider — or continue with
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: borderColor,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'or continue with',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: hintColor,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: borderColor,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Google button only
                    _SocialButton(
                      onPressed: _googleSignIn,
                      isDark: isDark,
                      borderColor: borderColor,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _GoogleIcon(),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.08),

              const SizedBox(height: 32),

              // Sign up link
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style:
                          GoogleFonts.dmSans(fontSize: 14, color: textSec),
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: 'Sign up',
                          style: GoogleFonts.dmSans(
                            color: primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 340.ms),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Social button container ───────────────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isDark;
  final Color borderColor;
  final Widget child;

  const _SocialButton({
    required this.onPressed,
    required this.isDark,
    required this.borderColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 64,
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

// ── Google "G" logo in Flutter ────────────────────────────────────────────────
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    // Draw colored arcs to approximate the Google G
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    void arc(double start, double sweep, Color color) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.32
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect.deflate(r * 0.16), start, sweep, false, paint);
    }

    const pi = 3.14159265;
    // Blue (top)
    arc(-pi * 0.08, pi * 0.68, const Color(0xFF4285F4));
    // Green (bottom-right)
    arc(pi * 0.60, pi * 0.50, const Color(0xFF34A853));
    // Yellow (bottom-left)
    arc(pi * 1.10, pi * 0.40, const Color(0xFFFBBC05));
    // Red (top-left to bottom-left)
    arc(pi * 1.50, pi * 0.42, const Color(0xFFEA4335));

    // Horizontal bar for the "G" cutout (right side)
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.28
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(
      Offset(cx + r * 0.12, cy),
      Offset(cx + r * 0.84, cy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}