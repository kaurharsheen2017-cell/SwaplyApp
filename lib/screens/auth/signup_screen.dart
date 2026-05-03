import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_button.dart';
import '../home/main_nav_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey         = GlobalKey<FormState>();
  final _emailCtrl       = TextEditingController();
  final _passwordCtrl    = TextEditingController();
  final _usernameCtrl    = TextEditingController();
  final _fullNameCtrl    = TextEditingController();
  bool _obscurePassword  = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameCtrl.dispose();
    _fullNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    final ok = await auth.signUp(
      email:    _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      username: _usernameCtrl.text.trim(),
      fullName: _fullNameCtrl.text.trim(),
    );
    if (ok && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
        (r) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bgColor  = isDark ? AppColors.darkBackground : AppColors.background;
    final cardBg   = isDark ? AppColors.darkCardBg     : AppColors.surface;
    final textPri  = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSec  = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final divColor = isDark ? AppColors.darkBorder     : AppColors.divider;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── Gradient header band ───────────────────────────────────────
          Container(
            height: MediaQuery.of(context).size.height * 0.38,
            decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Create Account',
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Join the campus skill community',
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ── Form card ──────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: isDark
                          ? Border.all(color: divColor)
                          : null,
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.12),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Full Name
                          TextFormField(
                            controller: _fullNameCtrl,
                            style: GoogleFonts.dmSans(
                                color: textPri, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              labelStyle:
                                  GoogleFonts.dmSans(color: textSec),
                              prefixIcon: Icon(Icons.person_outline,
                                  color: textSec, size: 20),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 14),

                          // Username
                          TextFormField(
                            controller: _usernameCtrl,
                            style: GoogleFonts.dmSans(
                                color: textPri, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Username',
                              labelStyle:
                                  GoogleFonts.dmSans(color: textSec),
                              prefixIcon: Icon(Icons.alternate_email,
                                  color: textSec, size: 20),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Required';
                              }
                              if (v.trim().length < 3) {
                                return 'At least 3 characters';
                              }
                              if (!RegExp(r'^[a-zA-Z0-9_]+$')
                                  .hasMatch(v.trim())) {
                                return 'Only letters, numbers, underscore';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Email
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.dmSans(
                                color: textPri, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle:
                                  GoogleFonts.dmSans(color: textSec),
                              prefixIcon: Icon(Icons.email_outlined,
                                  color: textSec, size: 20),
                            ),
                            validator: (v) {
                              if (v == null || !v.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Password
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            style: GoogleFonts.dmSans(
                                color: textPri, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle:
                                  GoogleFonts.dmSans(color: textSec),
                              prefixIcon: Icon(Icons.lock_outline,
                                  color: textSec, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: textSec,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword =
                                        !_obscurePassword),
                              ),
                            ),
                            validator: (v) =>
                                (v == null || v.length < 6)
                                    ? 'Minimum 6 characters'
                                    : null,
                          ),
                          const SizedBox(height: 28),

                          // ── Error banner ───────────────────────────────
                          Consumer<AuthService>(
                            builder: (_, auth, __) {
                              if (auth.errorMessage == null) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 16),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(
                                        isDark ? 0.15 : 0.10),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.error
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    auth.errorMessage!,
                                    style: GoogleFonts.dmSans(
                                        color: AppColors.error,
                                        fontSize: 13),
                                  ),
                                ),
                              );
                            },
                          ),

                          // ── Sign-up button ─────────────────────────────
                          Consumer<AuthService>(
                            builder: (_, auth, __) => GradientButton(
                              onPressed:
                                  auth.isLoading ? null : _signup,
                              isLoading: auth.isLoading,
                              label: 'Create Account',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}