// lib/screens/profile/complete_your_profile_screen.dart
// Pixel-perfect match of CompleteYourProfileScreen.png
// White bg · lavender blob · purple avatar circle · edit badge · title · desc · CTA · maybe later

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../home/main_nav_screen.dart';
import '../profile/edit_profile_screen.dart';

class CompleteYourProfileScreen extends StatelessWidget {
  const CompleteYourProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final mq      = MediaQuery.of(context);
    final sw      = mq.size.width;
    final sh      = mq.size.height;
    final bg      = isDark ? AppColors.darkBackground : Colors.white;
    final textPri = isDark ? AppColors.darkTextPrimary : const Color(0xFF111128);
    final textSec = isDark ? AppColors.darkTextSecondary : const Color(0xFF8A8A9A);

    final blobSize   = sw * 0.60;
    final avatarSize = sw * 0.38;
    final badgeSize  = sw * 0.110;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [

          // ── Illustration zone ─────────────────────────────────────────
          SizedBox(
            height: sh * 0.48,
            width: sw,
            child: Stack(alignment: Alignment.center, children: [

              // Scattered dots + sparkles
              Positioned(left: sw*0.10, top: sh*0.04,
                  child: _Dot(isDark: isDark, size: 8)),
              Positioned(right: sw*0.12, top: sh*0.07,
                  child: _Dot(isDark: isDark, size: 6, opacity: 0.50)),
              Positioned(left: sw*0.16, bottom: sh*0.05,
                  child: _Dot(isDark: isDark, size: 7, opacity: 0.45)),
              Positioned(right: sw*0.16, bottom: sh*0.07,
                  child: _Dot(isDark: isDark, size: 5, opacity: 0.35)),
              Positioned(left: sw*0.04, top: sh*0.19,
                  child: _Sparkle(isDark: isDark, size: 14)),
              Positioned(right: sw*0.06, top: sh*0.15,
                  child: _Sparkle(isDark: isDark, size: 11, opacity: 0.45)),
              Positioned(right: sw*0.07, bottom: sh*0.13,
                  child: _Sparkle(isDark: isDark, size: 10, opacity: 0.35)),

              // Lavender blob
              Container(
                width: blobSize, height: blobSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : const Color(0xFFEEEBFF),
                ),
              ).animate().scale(duration: 480.ms, curve: Curves.easeOutCubic,
                  begin: const Offset(0.8, 0.8)),

              // Purple avatar circle
              Container(
                width: avatarSize, height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [BoxShadow(
                    color: AppColors.primary.withOpacity(0.28),
                    blurRadius: 22, offset: const Offset(0, 8))],
                ),
                child: Icon(Icons.person_rounded,
                    color: Colors.white.withOpacity(0.92),
                    size: avatarSize * 0.54),
              ).animate()
                  .scale(duration: 620.ms, curve: Curves.elasticOut,
                      begin: const Offset(0.65, 0.65))
                  .fadeIn(duration: 380.ms),

              // Edit/pencil badge bottom-right of avatar
              Positioned(
                left: sw / 2 + avatarSize * 0.28,
                top:  sh * 0.48 / 2 + avatarSize * 0.27,
                child: Container(
                  width: badgeSize, height: badgeSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    border: Border.all(color: bg, width: 2.5),
                    boxShadow: [BoxShadow(
                      color: AppColors.primary.withOpacity(0.30),
                      blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Icon(Icons.edit_rounded,
                      color: Colors.white, size: badgeSize * 0.46),
                ).animate()
                    .fadeIn(delay: 300.ms)
                    .scale(delay: 300.ms, curve: Curves.easeOutBack,
                        begin: const Offset(0.4, 0.4)),
              ),
            ]),
          ),

          // ── Text + actions ────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: sw * 0.08),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  // Title
                  Text('Complete Your Profile',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 24, fontWeight: FontWeight.w800,
                      color: textPri, letterSpacing: -0.4, height: 1.2),
                  ).animate().fadeIn(delay: 110.ms).slideY(begin: 0.08),

                  SizedBox(height: sh * 0.014),

                  // Description
                  Text(
                    'Add a few details to personalize your\nexperience and get the most out of\nthe app.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 15, color: textSec, height: 1.60),
                  ).animate().fadeIn(delay: 160.ms),

                  const Spacer(),

                  // Complete Profile CTA
                  _GradientBtn(
                    label: 'Complete Profile',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const EditProfileScreen())),
                  ).animate().fadeIn(delay: 240.ms).slideY(begin: 0.10),

                  SizedBox(height: sh * 0.018),

                  // Maybe later
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const MainNavScreen()),
                      (_) => false),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('Maybe later',
                        style: GoogleFonts.dmSans(
                          fontSize: 15, fontWeight: FontWeight.w500,
                          color: textSec)),
                    ),
                  ).animate().fadeIn(delay: 300.ms),

                  SizedBox(height: sh * 0.040),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _Dot extends StatelessWidget {
  final bool isDark; final double size; final double opacity;
  const _Dot({required this.isDark, required this.size, this.opacity = 0.65});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle,
      color: (isDark ? AppColors.darkPrimary : AppColors.primary).withOpacity(opacity)));
}

class _Sparkle extends StatelessWidget {
  final bool isDark; final double size; final double opacity;
  const _Sparkle({required this.isDark, required this.size, this.opacity = 0.60});
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size,
    child: CustomPaint(painter: _SpP(
      color: (isDark ? AppColors.darkPrimary : AppColors.primary).withOpacity(opacity))));
}

class _SpP extends CustomPainter {
  final Color color; const _SpP({required this.color});
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = color..strokeWidth = s.width*0.18
      ..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    c.drawLine(Offset(s.width/2,0), Offset(s.width/2,s.height), p);
    c.drawLine(Offset(0,s.height/2), Offset(s.width,s.height/2), p);
  }
  @override bool shouldRepaint(_) => false;
}

class _GradientBtn extends StatefulWidget {
  final String label; final VoidCallback onTap;
  const _GradientBtn({required this.label, required this.onTap});
  @override State<_GradientBtn> createState() => _GradientBtnState();
}
class _GradientBtnState extends State<_GradientBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this, duration: 90.ms, reverseDuration: 170.ms,
    lowerBound: 0.96, upperBound: 1.0, value: 1.0);
  @override void dispose() { _ac.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _ac.reverse(),
    onTapUp:   (_) => _ac.forward(),
    onTapCancel: () => _ac.forward(),
    onTap: widget.onTap,
    child: ScaleTransition(
      scale: CurvedAnimation(parent: _ac, curve: Curves.easeOut),
      child: Container(
        width: double.infinity, height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(99),
          boxShadow: [BoxShadow(
            color: AppColors.primary.withOpacity(0.36),
            blurRadius: 18, offset: const Offset(0, 8), spreadRadius: -3)]),
        alignment: Alignment.center,
        child: Text(widget.label,
          style: GoogleFonts.dmSans(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    ),
  );
}