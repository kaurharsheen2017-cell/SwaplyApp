import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/theme_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  SettingsScreen  — Profile > Settings
//  Contains the Light / Dark / System theme toggle (persisted via
//  ThemeProvider + SharedPreferences) plus placeholder setting rows.
//  All colours are resolved from Theme.of(context) — works in both modes.
// ─────────────────────────────────────────────────────────────────────────────
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? AppColors.darkBackground    : AppColors.background;
    final cardBg  = isDark ? AppColors.darkCardBg        : AppColors.surface;
    final border  = isDark ? AppColors.darkBorder        : AppColors.divider;
    final textPri = isDark ? AppColors.darkTextPrimary   : AppColors.textPrimary;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final primary = isDark ? AppColors.darkPrimary       : AppColors.primary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPri, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.dmSans(
            color: textPri,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // ── Appearance section ─────────────────────────────────────────
          _SectionLabel(label: 'Appearance', textColor: textSec),
          const SizedBox(height: 8),
          _ThemeToggleCard(
            isDark: isDark,
            cardBg: cardBg,
            border: border,
            textPri: textPri,
            textSec: textSec,
            primary: primary,
          ),

          const SizedBox(height: 24),

          // ── Notifications section ──────────────────────────────────────
          _SectionLabel(label: 'Notifications', textColor: textSec),
          const SizedBox(height: 8),
          _SettingsGroup(
            isDark: isDark,
            cardBg: cardBg,
            border: border,
            children: [
              _SwitchRow(
                icon: Icons.notifications_outlined,
                label: 'Push Notifications',
                iconBg: const Color(0xFF7C3AED),
                isDark: isDark,
                textPri: textPri,
                textSec: textSec,
                value: true,
                onChanged: (_) {},
              ),
              _RowDivider(color: border),
              _SwitchRow(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Message Alerts',
                iconBg: const Color(0xFF0D9488),
                isDark: isDark,
                textPri: textPri,
                textSec: textSec,
                value: true,
                onChanged: (_) {},
              ),
              _RowDivider(color: border),
              _SwitchRow(
                icon: Icons.swap_horiz_rounded,
                label: 'Swap Requests',
                iconBg: const Color(0xFFEA580C),
                isDark: isDark,
                textPri: textPri,
                textSec: textSec,
                value: false,
                onChanged: (_) {},
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Privacy section ────────────────────────────────────────────
          _SectionLabel(label: 'Privacy', textColor: textSec),
          const SizedBox(height: 8),
          _SettingsGroup(
            isDark: isDark,
            cardBg: cardBg,
            border: border,
            children: [
              _NavRow(
                icon: Icons.lock_outline_rounded,
                label: 'Account Privacy',
                iconBg: const Color(0xFF16A34A),
                isDark: isDark,
                textPri: textPri,
                primary: primary,
                onTap: () {},
              ),
              _RowDivider(color: border),
              _NavRow(
                icon: Icons.block_rounded,
                label: 'Blocked Users',
                iconBg: const Color(0xFFDC2626),
                isDark: isDark,
                textPri: textPri,
                primary: primary,
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── About section ──────────────────────────────────────────────
          _SectionLabel(label: 'About', textColor: textSec),
          const SizedBox(height: 8),
          _SettingsGroup(
            isDark: isDark,
            cardBg: cardBg,
            border: border,
            children: [
              _NavRow(
                icon: Icons.info_outline_rounded,
                label: 'App Version',
                iconBg: const Color(0xFF6B7280),
                isDark: isDark,
                textPri: textPri,
                primary: primary,
                trailing: Text(
                  '1.0.0',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: textSec,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {},
              ),
              _RowDivider(color: border),
              _NavRow(
                icon: Icons.description_outlined,
                label: 'Terms of Service',
                iconBg: const Color(0xFF0284C7),
                isDark: isDark,
                textPri: textPri,
                primary: primary,
                onTap: () {},
              ),
              _RowDivider(color: border),
              _NavRow(
                icon: Icons.shield_outlined,
                label: 'Privacy Policy',
                iconBg: const Color(0xFF7C3AED),
                isDark: isDark,
                textPri: textPri,
                primary: primary,
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Theme Toggle Card  — the centrepiece of this screen
//  Three segmented options: Light / System / Dark
//  Active selection highlighted with primary colour pill.
// ─────────────────────────────────────────────────────────────────────────────
class _ThemeToggleCard extends StatelessWidget {
  final bool isDark;
  final Color cardBg, border, textPri, textSec, primary;

  const _ThemeToggleCard({
    required this.isDark,
    required this.cardBg,
    required this.border,
    required this.textPri,
    required this.textSec,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider>();
    final current  = provider.appThemeMode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.palette_outlined,
                  color: primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textPri,
                    ),
                  ),
                  Text(
                    _currentLabel(current),
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: textSec,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ── Segmented control ─────────────────────────────────────────
          Container(
            height: 44,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _Segment(
                  label: 'Light',
                  icon: Icons.light_mode_rounded,
                  mode: AppThemeMode.light,
                  current: current,
                  primary: primary,
                  textPri: textPri,
                  textSec: textSec,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<ThemeProvider>().setTheme(AppThemeMode.light);
                  },
                ),
                _Segment(
                  label: 'System',
                  icon: Icons.brightness_auto_rounded,
                  mode: AppThemeMode.system,
                  current: current,
                  primary: primary,
                  textPri: textPri,
                  textSec: textSec,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<ThemeProvider>().setTheme(AppThemeMode.system);
                  },
                ),
                _Segment(
                  label: 'Dark',
                  icon: Icons.dark_mode_rounded,
                  mode: AppThemeMode.dark,
                  current: current,
                  primary: primary,
                  textPri: textPri,
                  textSec: textSec,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<ThemeProvider>().setTheme(AppThemeMode.dark);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _currentLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:  return 'Light mode active';
      case AppThemeMode.dark:   return 'Dark mode active';
      case AppThemeMode.system: return 'Following system preference';
    }
  }
}

// ── Single segment button ──────────────────────────────────────────────────
class _Segment extends StatelessWidget {
  final String label;
  final IconData icon;
  final AppThemeMode mode;
  final AppThemeMode current;
  final Color primary, textPri, textSec;
  final bool isDark;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.icon,
    required this.mode,
    required this.current,
    required this.primary,
    required this.textPri,
    required this.textSec,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = current == mode;
    final activeBg = isDark ? AppColors.darkCardBg : AppColors.surface;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: double.infinity,
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? primary : textSec,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? primary : textSec,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared helper widgets
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final Color textColor;
  const _SectionLabel({required this.label, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final bool isDark;
  final Color cardBg, border;
  final List<Widget> children;

  const _SettingsGroup({
    required this.isDark,
    required this.cardBg,
    required this.border,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(children: children),
    );
  }
}

class _RowDivider extends StatelessWidget {
  final Color color;
  const _RowDivider({required this.color});
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, color: color, indent: 56);
}

class _SwitchRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color iconBg;
  final bool isDark, value;
  final Color textPri, textSec;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.iconBg,
    required this.isDark,
    required this.textPri,
    required this.textSec,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_SwitchRow> createState() => _SwitchRowState();
}

class _SwitchRowState extends State<_SwitchRow> {
  late bool _val;

  @override
  void initState() {
    super.initState();
    _val = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.isDark ? AppColors.darkPrimary : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _IconBox(icon: widget.icon, bg: widget.iconBg),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              widget.label,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: widget.textPri,
              ),
            ),
          ),
          Switch.adaptive(
            value: _val,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _val = v);
              widget.onChanged(v);
            },
            activeColor: primary,
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconBg;
  final bool isDark;
  final Color textPri, primary;
  final VoidCallback onTap;
  final Widget? trailing;

  const _NavRow({
    required this.icon,
    required this.label,
    required this.iconBg,
    required this.isDark,
    required this.textPri,
    required this.primary,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            _IconBox(icon: icon, bg: iconBg),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textPri,
                ),
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? AppColors.darkTextLight
                      : AppColors.textLight,
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color bg;
  const _IconBox({required this.icon, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.white, size: 17),
    );
  }
}