import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    final ok = await auth.resetPassword(_emailCtrl.text.trim());
    if (ok && mounted) {
      setState(() => _sent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _sent ? _EmailSentView(email: _emailCtrl.text.trim()) : _ForgotView(
      formKey: _formKey,
      emailCtrl: _emailCtrl,
      onSend: _send,
    );
  }
}

// ── Forgot password entry screen ─────────────────────────────────────────────
class _ForgotView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final VoidCallback onSend;

  const _ForgotView({
    required this.formKey,
    required this.emailCtrl,
    required this.onSend,
  });

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

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Back arrow
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

              // Padlock illustration
              Center(
                child: _LockIllustration()
                    .animate()
                    .scale(
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                      begin: const Offset(0.7, 0.7),
                    )
                    .fadeIn(),
              ),

              const SizedBox(height: 36),

              // Heading
              Text(
                'Forgot Password?',
                style: GoogleFonts.dmSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: textPri,
                  letterSpacing: -0.4,
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

              const SizedBox(height: 12),

              Text(
                'No worries! Enter your college email\nand we\'ll send you a link to reset\nyour password.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: textSec,
                  height: 1.6,
                ),
              ).animate().fadeIn(delay: 160.ms),

              const SizedBox(height: 32),

              // Email field
              Form(
                key: formKey,
                child: TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.dmSans(color: textPri, fontSize: 14),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'College Email',
                    hintText: 'name@college.edu',
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
                      borderSide: const BorderSide(
                          color: AppColors.error, width: 1),
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
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 32),

              // Error
              Consumer<AuthService>(
                builder: (_, auth, __) {
                  if (auth.errorMessage == null) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color:
                          AppColors.error.withOpacity(isDark ? 0.15 : 0.07),
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
                          child: Text(auth.errorMessage!,
                              style: GoogleFonts.dmSans(
                                  color: AppColors.error, fontSize: 13)),
                        ),
                      ],
                    ),
                  );
                },
              ),

              Consumer<AuthService>(
                builder: (_, auth, __) => GradientButton(
                  onPressed: auth.isLoading ? null : onSend,
                  isLoading: auth.isLoading,
                  label: 'Send Reset Link',
                ),
              ).animate().fadeIn(delay: 260.ms),

              const SizedBox(height: 28),

              // Back to Sign in
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.maybePop(context),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.dmSans(
                          fontSize: 14, color: textSec),
                      children: [
                        const TextSpan(text: 'Back to '),
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
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Email sent confirmation screen ────────────────────────────────────────────
class _EmailSentView extends StatelessWidget {
  final String email;
  const _EmailSentView({required this.email});

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Envelope illustration
              _EnvelopeIllustration()
                  .animate()
                  .scale(
                    duration: 700.ms,
                    curve: Curves.elasticOut,
                    begin: const Offset(0.6, 0.6),
                  )
                  .fadeIn(),

              const SizedBox(height: 40),

              Text(
                'Check your email!',
                style: GoogleFonts.dmSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: textPri,
                  letterSpacing: -0.4,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

              const SizedBox(height: 14),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: textSec,
                    height: 1.6,
                  ),
                  children: [
                    const TextSpan(
                        text: "We've sent a password reset link to\n"),
                    TextSpan(
                      text: email,
                      style: GoogleFonts.dmSans(
                        color: primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 280.ms),

              const SizedBox(height: 10),

              Text(
                'The link will expire in 15 minutes.',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: textSec.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 330.ms),

              const Spacer(flex: 2),

              GradientButton(
                onPressed: () => Navigator.of(context).popUntil(
                  (r) => r.isFirst,
                ),
                label: 'Back to Sign In',
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Lock illustration ─────────────────────────────────────────────────────────
class _LockIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEEEAFF),
            ),
          ),

          // Small decorative dots
          Positioned(
            top: 16,
            right: 22,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
          ),
          Positioned(
            bottom: 22,
            left: 18,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(0.4),
              ),
            ),
          ),

          // Lock icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Envelope illustration ─────────────────────────────────────────────────────
class _EnvelopeIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 160,
            height: 160,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEEEAFF),
            ),
          ),

          // Envelope icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.30),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.mail_outline_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),

          // Paper plane top-right
          Positioned(
            top: 18,
            right: 14,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),

          // Green check badge bottom-right
          Positioned(
            bottom: 20,
            right: 20,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFF59E0B),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}