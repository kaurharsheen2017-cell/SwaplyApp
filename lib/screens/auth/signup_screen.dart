import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_button.dart';
import 'login_screen.dart';
import '../auth/complete_your_profile_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please agree to the Terms of Service and Privacy Policy.',
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final auth = context.read<AuthService>();
    final username =
        _emailCtrl.text.trim().split('@').first.replaceAll('.', '_');
    final ok = await auth.signUp(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      username: username,
      fullName: _fullNameCtrl.text.trim(),
    );
    if (ok && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (_) => const CompleteYourProfileScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : Colors.white;
    final textPri = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSec =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Back button
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

                const SizedBox(height: 24),

                // Heading
                Text(
                  'Create your',
                  style: GoogleFonts.dmSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: textPri,
                    letterSpacing: -0.4,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Swaply',
                        style: GoogleFonts.dmSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: primary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      TextSpan(
                        text: ' account',
                        style: GoogleFonts.dmSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: textPri,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Join your campus community\nand start exchanging!',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: textSec,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 28),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _SwaplyInput(
                        controller: _fullNameCtrl,
                        hint: 'Full Name',
                        prefixIcon: Icons.person_outline_rounded,
                        isDark: isDark,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),

                      const SizedBox(height: 14),

                      _SwaplyInput(
                        controller: _emailCtrl,
                        hint: 'name@college.edu',
                        label: 'College Email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        isDark: isDark,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      _SwaplyInput(
                        controller: _passwordCtrl,
                        hint: 'Password',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscure: _obscurePass,
                        isDark: isDark,
                        onToggleObscure: () =>
                            setState(() => _obscurePass = !_obscurePass),
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Min 6 characters'
                            : null,
                      ),

                      const SizedBox(height: 14),

                      _SwaplyInput(
                        controller: _confirmPassCtrl,
                        hint: 'Confirm Password',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscure: _obscureConfirm,
                        isDark: isDark,
                        onToggleObscure: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v != _passwordCtrl.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 18),

                      // Terms checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: Checkbox(
                              value: _agreedToTerms,
                              onChanged: (v) =>
                                  setState(() => _agreedToTerms = v ?? false),
                              activeColor: primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              side: BorderSide(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.border,
                                width: 1.5,
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: textSec,
                                ),
                                children: [
                                  const TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: GoogleFonts.dmSans(
                                      color: primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const TextSpan(text: '\nand '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: GoogleFonts.dmSans(
                                      color: primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

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

                      Consumer<AuthService>(
                        builder: (_, auth, __) => GradientButton(
                          onPressed: auth.isLoading ? null : _signup,
                          isLoading: auth.isLoading,
                          label: 'Sign Up',
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 120.ms).slideY(
                    begin: 0.08, curve: Curves.easeOutCubic),

                const SizedBox(height: 24),

                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, a, __) => const LoginScreen(),
                        transitionsBuilder: (_, a, __, child) =>
                            FadeTransition(opacity: a, child: child),
                        transitionDuration:
                            const Duration(milliseconds: 280),
                      ),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style:
                            GoogleFonts.dmSans(fontSize: 14, color: textSec),
                        children: [
                          const TextSpan(text: 'Already have an account? '),
                          TextSpan(
                            text: 'Sign in',
                            style: GoogleFonts.dmSans(
                              color: primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 280.ms),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared input field ────────────────────────────────────────────────────────
class _SwaplyInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? label;
  final IconData prefixIcon;
  final bool obscure;
  final bool isDark;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final VoidCallback? onToggleObscure;

  const _SwaplyInput({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    required this.isDark,
    this.label,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    final textPri =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final hintColor = isDark ? AppColors.darkTextLight : AppColors.textLight;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final fillColor =
        isDark ? AppColors.darkSearchBg : const Color(0xFFF7F7FB);
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final iconColor = isDark ? AppColors.darkTextLight : AppColors.textLight;

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.dmSans(
        color: textPri,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        labelText: label,
        hintStyle: GoogleFonts.dmSans(color: hintColor, fontSize: 14),
        labelStyle: GoogleFonts.dmSans(
          color: hintColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        prefixIcon: Icon(prefixIcon, size: 19, color: iconColor),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 19,
                  color: iconColor,
                ),
                onPressed: onToggleObscure,
              )
            : null,
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
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}