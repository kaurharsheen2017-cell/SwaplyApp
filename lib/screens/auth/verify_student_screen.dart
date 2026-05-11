import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_button.dart';
import '../home/main_nav_screen.dart';

class VerifyStudentScreen extends StatelessWidget {
  const VerifyStudentScreen({super.key});

  void _verifyWithEmail(BuildContext context) {
    // Supabase email verification is sent on signup.
    // Show info snack, then go home.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Verification email sent! Check your inbox.',
          style: GoogleFonts.dmSans(),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavScreen()),
      (_) => false,
    );
  }

  void _doLater(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavScreen()),
      (_) => false,
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

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Shield illustration
              _ShieldIllustration()
                  .animate()
                  .scale(
                    duration: 700.ms,
                    curve: Curves.elasticOut,
                    begin: const Offset(0.6, 0.6),
                  )
                  .fadeIn(),

              const SizedBox(height: 40),

              Text(
                'Verify your\nstudent account',
                style: GoogleFonts.dmSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: textPri,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

              const SizedBox(height: 14),

              Text(
                "We just need to verify that\nyou're a student.",
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: textSec,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 260.ms),

              const Spacer(flex: 2),

              // Verify with College Email button
              GradientButton(
                onPressed: () => _verifyWithEmail(context),
                label: 'Verify with College Email',
                icon: Icons.email_outlined,
              ).animate().fadeIn(delay: 340.ms).slideY(begin: 0.1),

              const SizedBox(height: 14),

              // I'll do it later (outline)
              GestureDetector(
                onTap: () => _doLater(context),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor, width: 1.5),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "I'll do it later",
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPri,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 24),

              Text(
                'Verifying unlocks more features\nand builds trust in the community.',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: textSec.withOpacity(0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 460.ms),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shield illustration ───────────────────────────────────────────────────────
class _ShieldIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background glow circle
          Container(
            width: 160,
            height: 160,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEEEAFF),
            ),
          ),

          // Sparkle top-left
          Positioned(
            top: 24,
            left: 28,
            child: _Sparkle(size: 18, color: AppColors.primary.withOpacity(0.5)),
          ),
          Positioned(
            top: 14,
            right: 36,
            child: _Sparkle(size: 12, color: AppColors.secondary.withOpacity(0.6)),
          ),
          Positioned(
            bottom: 28,
            right: 24,
            child: _Sparkle(size: 14, color: AppColors.primary.withOpacity(0.4)),
          ),

          // Shield icon with gradient bg
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: 50,
            ),
          ),

          // Check badge
          Positioned(
            bottom: 26,
            right: 26,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sparkle helper ────────────────────────────────────────────────────────────
class _Sparkle extends StatelessWidget {
  final double size;
  final Color color;

  const _Sparkle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SparklePainter(color: color),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final Color color;
  const _SparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.15
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // 4-pointed star / sparkle cross
    canvas.drawLine(Offset(cx, cy - r), Offset(cx, cy + r), paint);
    canvas.drawLine(Offset(cx - r, cy), Offset(cx + r, cy), paint);
    canvas.drawLine(
        Offset(cx - r * 0.6, cy - r * 0.6), Offset(cx + r * 0.6, cy + r * 0.6), paint);
    canvas.drawLine(
        Offset(cx + r * 0.6, cy - r * 0.6), Offset(cx - r * 0.6, cy + r * 0.6), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}