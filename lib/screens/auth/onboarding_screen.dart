// lib/screens/auth/onboarding_screen.dart
// Visuals: assets/images/Onboard1.png, Onboard2.png, Onboard3.png
// Layout matches onboardingscreenoutput.png exactly.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

const _kPrimary = Color(0xFF5B4FE8);
const _kInk     = Color(0xFF111128);
const _kGrey    = Color(0xFF6B6B80);

// ─────────────────────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  void _skip()    => _push(const SignupScreen());
  void _toLogin() => _push(const LoginScreen());
  void _toSignup()=> _push(const SignupScreen());

  void _push(Widget w) => Navigator.of(context).push(PageRouteBuilder(
    pageBuilder: (_, a, __) => w,
    transitionsBuilder: (_, a, __, child) =>
        FadeTransition(opacity: a, child: child),
    transitionDuration: const Duration(milliseconds: 280),
  ));

  void _onCTA() {
    if (_page < 2) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      _toSignup();
    }
  }

  String get _ctaLabel =>
      _page == 0 ? 'Get Started' : _page == 1 ? 'Next' : "Let's Go! 🎉";

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final sh = mq.size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(children: [

          // ── Main column ───────────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: sh * 0.050), // room for Skip chip

              // PageView
              Expanded(
                child: PageView(
                  controller: _ctrl,
                  onPageChanged: (i) => setState(() => _page = i),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _OnboardPage(
                      imagePath: 'assets/images/Onboard1.png',
                      heading1: 'Welcome to',
                      heading2: 'Swaply',
                      heading2Inline: false,
                      body: 'The campus exchange hub where\nskills, services and good vibes\ncreate endless opportunities.',
                      sw: sw, sh: sh,
                    ),
                    _OnboardPage(
                      imagePath: 'assets/images/Onboard2.png',
                      heading1: 'Exchange ',
                      heading2: 'Your Way',
                      heading2Inline: true,
                      body: "Barter skills, get help, or offer money,\ntreats, or anything that works for you.\nIt's flexible, fair, and student-friendly.",
                      sw: sw, sh: sh,
                    ),
                    _OnboardPage(
                      imagePath: 'assets/images/Onboard3.png',
                      heading1: 'Build Connections,',
                      heading2: 'Grow Together',
                      heading2Inline: false,
                      body: 'Join a trusted campus community,\nearn points, unlock badges, and\nmake an impact together.',
                      sw: sw, sh: sh,
                    ),
                  ],
                ),
              ),

              // Dots
              _DotsIndicator(count: 3, active: _page),
              SizedBox(height: sh * 0.028),

              // CTA
              Padding(
                padding: EdgeInsets.symmetric(horizontal: sw * 0.060),
                child: _GradientButton(label: _ctaLabel, onTap: _onCTA),
              ),
              SizedBox(height: sh * 0.018),

              // Footer
              GestureDetector(
                onTap: _toLogin,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.dmSans(fontSize: 14, color: _kGrey),
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Sign in',
                          style: GoogleFonts.dmSans(
                              color: _kPrimary, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: sh * 0.028),
            ],
          ),

          // ── Skip pill — top-right overlay ─────────────────────────────────
          Positioned(
            top: sh * 0.006,
            right: sw * 0.042,
            child: GestureDetector(
              onTap: _skip,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('Skip',
                  style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Single page: image + heading + body
// ─────────────────────────────────────────────────────────────────────────────
class _OnboardPage extends StatelessWidget {
  final String imagePath;
  final String heading1;
  final String heading2;
  final bool   heading2Inline;
  final String body;
  final double sw, sh;

  const _OnboardPage({
    required this.imagePath,
    required this.heading1,
    required this.heading2,
    required this.heading2Inline,
    required this.body,
    required this.sw,
    required this.sh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [

        // ── Asset image (central visual) ────────────────────────────────────
        // 52 % of screen height. BoxFit.contain keeps full illustration
        // visible; aligned bottom-centre so figures always touch baseline.
        SizedBox(
          width: sw,
          height: sh * 0.520,
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
          ),
        )
            .animate()
            .fadeIn(duration: 420.ms)
            .slideY(begin: 0.03, curve: Curves.easeOutCubic),

        SizedBox(height: sh * 0.022),

        // ── Heading ─────────────────────────────────────────────────────────
        if (heading2Inline)
          // "Exchange Your Way" — same line, mixed colour
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(children: [
              TextSpan(text: heading1,
                style: GoogleFonts.dmSans(fontSize: 27, fontWeight: FontWeight.w800,
                    color: _kInk, letterSpacing: -0.3, height: 1.15)),
              TextSpan(text: heading2,
                style: GoogleFonts.dmSans(fontSize: 27, fontWeight: FontWeight.w800,
                    color: _kPrimary, letterSpacing: -0.3, height: 1.15)),
            ]),
          ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.08)
        else ...[
          // Two separate lines: black then purple
          Text(heading1,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 27, fontWeight: FontWeight.w800,
                color: _kInk, letterSpacing: -0.3, height: 1.15),
          ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.08),
          Text(heading2,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 27, fontWeight: FontWeight.w800,
                color: _kPrimary, letterSpacing: -0.3, height: 1.15),
          ).animate().fadeIn(delay: 110.ms).slideY(begin: 0.08),
        ],

        SizedBox(height: sh * 0.014),

        // ── Body paragraph ───────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(horizontal: sw * 0.095),
          child: Text(body,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 15, color: _kGrey, height: 1.62),
          ),
        ).animate().fadeIn(delay: 160.ms),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Animated pill-dot page indicator
// ─────────────────────────────────────────────────────────────────────────────
class _DotsIndicator extends StatelessWidget {
  final int count, active;
  const _DotsIndicator({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final on = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 270),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width:  on ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: on ? _kPrimary : _kPrimary.withOpacity(0.22),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Full-width gradient pill button with → arrow
// ─────────────────────────────────────────────────────────────────────────────
class _GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _GradientButton({required this.label, required this.onTap});
  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    reverseDuration: const Duration(milliseconds: 170),
    lowerBound: 0.96, upperBound: 1.0, value: 1.0);

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => _ac.reverse(),
      onTapUp:     (_) => _ac.forward(),
      onTapCancel: () => _ac.forward(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _ac, curve: Curves.easeOut),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(99),
            boxShadow: [BoxShadow(
              color: _kPrimary.withOpacity(0.36),
              blurRadius: 20, offset: const Offset(0, 8), spreadRadius: -3)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.label,
                style: GoogleFonts.dmSans(
                    color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700,
                    letterSpacing: 0.1)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}