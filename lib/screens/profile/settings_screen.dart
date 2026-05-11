// lib/screens/profile/settings_screen.dart
// Settings: Appearance · Account (Edit Profile, Bookmarks) ·
//           Notifications · Privacy · About · Danger Zone (Delete Account, Sign Out)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/theme_provider.dart';
import '../auth/login_screen.dart';
import 'bookmarks_screen.dart';
import 'edit_profile_screen.dart';

// ═════════════════════════════════════════════════════════════════════════════
//  Top-level dialog helpers
// ═════════════════════════════════════════════════════════════════════════════

Future<void> _confirmSignOut(BuildContext context,
    bool isDark, Color cardBg, Color border, Color tPri, Color tSec) async {
  final ok = await _confirmDialog(
    context: context, isDark: isDark, cardBg: cardBg, border: border,
    tPri: tPri, tSec: tSec,
    iconData: Icons.logout_rounded,
    iconColor: const Color(0xFFDC2626),
    title: 'Sign Out?',
    body: "You'll need to sign back in\nto access your account.",
    confirmLabel: 'Sign Out',
    confirmColor: const Color(0xFFDC2626),
  );
  if (ok && context.mounted) {
    await context.read<AuthService>().signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }
}

Future<void> _confirmDeleteAccount(BuildContext context,
    bool isDark, Color cardBg, Color border, Color tPri, Color tSec) async {
  final ok = await _confirmDialog(
    context: context, isDark: isDark, cardBg: cardBg, border: border,
    tPri: tPri, tSec: tSec,
    iconData: Icons.delete_forever_rounded,
    iconColor: const Color(0xFFDC2626),
    title: 'Delete Account?',
    body: 'This is permanent. All your\nswaps, posts and data will be\ndeleted and cannot be recovered.',
    confirmLabel: 'Delete Account',
    confirmColor: const Color(0xFFDC2626),
  );
  if (ok && context.mounted) {
    try {
      // Delete via Supabase admin RPC (requires server-side function)
      // Fallback: sign out and delete profile row
      final auth = context.read<AuthService>();
      final uid = auth.currentUser?.id;
      if (uid != null) {
        await supabase.from('profiles').delete().eq('id', uid);
        await auth.signOut();
      }
    } catch (_) {
      await context.read<AuthService>().signOut();
    }
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }
}

/// Generic two-button confirmation dialog
Future<bool> _confirmDialog({
  required BuildContext context,
  required bool isDark,
  required Color cardBg, required Color border,
  required Color tPri, required Color tSec,
  required IconData iconData, required Color iconColor,
  required String title, required String body,
  required String confirmLabel, required Color confirmColor,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.50),
    builder: (ctx) => Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Icon
          Container(
            width: 62, height: 62,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(iconData, color: iconColor, size: 30)),
          const SizedBox(height: 16),
          // Title
          Text(title,
            style: GoogleFonts.dmSans(
              fontSize: 20, fontWeight: FontWeight.w800,
              color: tPri, letterSpacing: -0.3)),
          const SizedBox(height: 8),
          // Body
          Text(body,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 14, color: tSec, height: 1.5)),
          const SizedBox(height: 24),
          // Buttons
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx, false),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceVariant
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border, width: 1)),
                  alignment: Alignment.center,
                  child: Text('Cancel',
                    style: GoogleFonts.dmSans(
                      fontSize: 15, fontWeight: FontWeight.w700, color: tPri)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx, true),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: confirmColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(
                      color: confirmColor.withOpacity(0.30),
                      blurRadius: 12, offset: const Offset(0, 4))]),
                  alignment: Alignment.center,
                  child: Text(confirmLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: Colors.white)),
                ),
              ),
            ),
          ]),
        ]),
      ),
    ),
  );
  return result == true;
}

// ═════════════════════════════════════════════════════════════════════════════
//  SettingsScreen
// ═════════════════════════════════════════════════════════════════════════════
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? AppColors.darkBackground    : AppColors.background;
    final cardBg  = isDark ? AppColors.darkCardBg        : AppColors.surface;
    final border  = isDark ? AppColors.darkBorder        : AppColors.divider;
    final tPri    = isDark ? AppColors.darkTextPrimary   : AppColors.textPrimary;
    final tSec    = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final primary = isDark ? AppColors.darkPrimary       : AppColors.primary;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: tPri, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Settings',
          style: GoogleFonts.dmSans(
            color: tPri, fontSize: 17, fontWeight: FontWeight.w700,
            letterSpacing: -0.3)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: border)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [

          // ── Appearance ──────────────────────────────────────────────────
          _SectionLabel(label: 'Appearance', textColor: tSec),
          const SizedBox(height: 8),
          _ThemeToggleCard(isDark: isDark, cardBg: cardBg, border: border,
              tPri: tPri, tSec: tSec, primary: primary),

          const SizedBox(height: 24),

          // ── Account ─────────────────────────────────────────────────────
          _SectionLabel(label: 'Account', textColor: tSec),
          const SizedBox(height: 8),
          _SettingsGroup(isDark: isDark, cardBg: cardBg, border: border,
            children: [
              _NavRow(
                icon: Icons.edit_outlined,
                label: 'Edit Profile',
                iconBg: primary,
                isDark: isDark, tPri: tPri, primary: primary,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const EditProfileScreen())),
              ),
              _RowDivider(color: border),
              _NavRow(
                icon: Icons.bookmark_outline_rounded,
                label: 'Bookmarks',
                iconBg: const Color(0xFFF59E0B),
                isDark: isDark, tPri: tPri, primary: primary,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const BookmarksScreen())),
              ),
            ]),

          const SizedBox(height: 24),

          // ── Notifications ───────────────────────────────────────────────
          _SectionLabel(label: 'Notifications', textColor: tSec),
          const SizedBox(height: 8),
          _SettingsGroup(isDark: isDark, cardBg: cardBg, border: border,
            children: [
              _SwitchRow(
                icon: Icons.notifications_outlined,
                label: 'Push Notifications',
                iconBg: const Color(0xFF7C3AED),
                isDark: isDark, tPri: tPri, tSec: tSec,
                value: true, onChanged: (_) {},
              ),
              _RowDivider(color: border),
              _SwitchRow(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Message Alerts',
                iconBg: const Color(0xFF0D9488),
                isDark: isDark, tPri: tPri, tSec: tSec,
                value: true, onChanged: (_) {},
              ),
              _RowDivider(color: border),
              _SwitchRow(
                icon: Icons.swap_horiz_rounded,
                label: 'Swap Requests',
                iconBg: const Color(0xFFEA580C),
                isDark: isDark, tPri: tPri, tSec: tSec,
                value: false, onChanged: (_) {},
              ),
            ]),

          const SizedBox(height: 24),

          // ── Privacy ─────────────────────────────────────────────────────
          _SectionLabel(label: 'Privacy', textColor: tSec),
          const SizedBox(height: 8),
          _SettingsGroup(isDark: isDark, cardBg: cardBg, border: border,
            children: [
              _NavRow(
                icon: Icons.lock_outline_rounded,
                label: 'Account Privacy',
                iconBg: const Color(0xFF16A34A),
                isDark: isDark, tPri: tPri, primary: primary,
                onTap: () {},
              ),
              _RowDivider(color: border),
              _NavRow(
                icon: Icons.block_rounded,
                label: 'Blocked Users',
                iconBg: const Color(0xFFDC2626),
                isDark: isDark, tPri: tPri, primary: primary,
                onTap: () {},
              ),
            ]),

          const SizedBox(height: 24),

          // ── About ───────────────────────────────────────────────────────
          _SectionLabel(label: 'About', textColor: tSec),
          const SizedBox(height: 8),
          _SettingsGroup(isDark: isDark, cardBg: cardBg, border: border,
            children: [
              _NavRow(
                icon: Icons.info_outline_rounded,
                label: 'App Version',
                iconBg: const Color(0xFF6B7280),
                isDark: isDark, tPri: tPri, primary: primary,
                trailing: Text('1.0.0',
                  style: GoogleFonts.dmSans(
                    fontSize: 13, color: tSec, fontWeight: FontWeight.w500)),
                onTap: () {},
              ),
              _RowDivider(color: border),
              _NavRow(
                icon: Icons.description_outlined,
                label: 'Terms of Service',
                iconBg: const Color(0xFF0284C7),
                isDark: isDark, tPri: tPri, primary: primary,
                onTap: () {},
              ),
              _RowDivider(color: border),
              _NavRow(
                icon: Icons.shield_outlined,
                label: 'Privacy Policy',
                iconBg: const Color(0xFF7C3AED),
                isDark: isDark, tPri: tPri, primary: primary,
                onTap: () {},
              ),
            ]),

          const SizedBox(height: 24),

          // ── Danger Zone ─────────────────────────────────────────────────
          _SectionLabel(label: 'Danger Zone', textColor: const Color(0xFFDC2626)),
          const SizedBox(height: 8),
          _SettingsGroup(isDark: isDark, cardBg: cardBg, border: border,
            children: [
              _NavRow(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                iconBg: const Color(0xFFDC2626),
                isDark: isDark,
                tPri: const Color(0xFFDC2626),
                primary: primary,
                onTap: () => _confirmSignOut(
                    context, isDark, cardBg, border, tPri, tSec),
              ),
              _RowDivider(color: border),
              _NavRow(
                icon: Icons.delete_forever_rounded,
                label: 'Delete Account',
                iconBg: const Color(0xFF991B1B),
                isDark: isDark,
                tPri: const Color(0xFFDC2626),
                primary: primary,
                onTap: () => _confirmDeleteAccount(
                    context, isDark, cardBg, border, tPri, tSec),
              ),
            ]),

          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Theme toggle card — Light / System / Dark segmented control
// ═════════════════════════════════════════════════════════════════════════════
class _ThemeToggleCard extends StatelessWidget {
  final bool isDark;
  final Color cardBg, border, tPri, tSec, primary;
  const _ThemeToggleCard({required this.isDark, required this.cardBg,
    required this.border, required this.tPri, required this.tSec,
    required this.primary});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider>();
    final current  = provider.appThemeMode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.palette_outlined, color: primary, size: 18)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Theme',
              style: GoogleFonts.dmSans(
                fontSize: 15, fontWeight: FontWeight.w600, color: tPri)),
            Text(_label(current),
              style: GoogleFonts.dmSans(fontSize: 12, color: tSec)),
          ]),
        ]),
        const SizedBox(height: 14),
        Container(
          height: 44,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceVariant
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            _Seg(label: 'Light',  icon: Icons.light_mode_rounded,
                mode: AppThemeMode.light,  current: current,
                primary: primary, tPri: tPri, tSec: tSec, isDark: isDark,
                onTap: () { HapticFeedback.selectionClick();
                  context.read<ThemeProvider>().setTheme(AppThemeMode.light); }),
            _Seg(label: 'System', icon: Icons.brightness_auto_rounded,
                mode: AppThemeMode.system, current: current,
                primary: primary, tPri: tPri, tSec: tSec, isDark: isDark,
                onTap: () { HapticFeedback.selectionClick();
                  context.read<ThemeProvider>().setTheme(AppThemeMode.system); }),
            _Seg(label: 'Dark',   icon: Icons.dark_mode_rounded,
                mode: AppThemeMode.dark,   current: current,
                primary: primary, tPri: tPri, tSec: tSec, isDark: isDark,
                onTap: () { HapticFeedback.selectionClick();
                  context.read<ThemeProvider>().setTheme(AppThemeMode.dark); }),
          ]),
        ),
      ]),
    );
  }

  String _label(AppThemeMode m) {
    switch (m) {
      case AppThemeMode.light:  return 'Light mode active';
      case AppThemeMode.dark:   return 'Dark mode active';
      case AppThemeMode.system: return 'Following system preference';
    }
  }
}

class _Seg extends StatelessWidget {
  final String label; final IconData icon; final AppThemeMode mode, current;
  final Color primary, tPri, tSec; final bool isDark; final VoidCallback onTap;
  const _Seg({required this.label, required this.icon, required this.mode,
    required this.current, required this.primary, required this.tPri,
    required this.tSec, required this.isDark, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final on  = current == mode;
    final bg2 = isDark ? AppColors.darkCardBg : AppColors.surface;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: double.infinity,
          decoration: BoxDecoration(
            color: on ? bg2 : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: on && !isDark
                ? [BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6, offset: const Offset(0, 2))]
                : null),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16, color: on ? primary : tSec),
            const SizedBox(height: 2),
            Text(label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                color: on ? primary : tSec)),
          ]),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Shared helper widgets
// ═════════════════════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final String label; final Color textColor;
  const _SectionLabel({required this.label, required this.textColor});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 2),
    child: Text(label.toUpperCase(),
      style: GoogleFonts.dmSans(
        fontSize: 11, fontWeight: FontWeight.w700,
        color: textColor, letterSpacing: 0.8)));
}

class _SettingsGroup extends StatelessWidget {
  final bool isDark; final Color cardBg, border; final List<Widget> children;
  const _SettingsGroup({required this.isDark, required this.cardBg,
    required this.border, required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: cardBg, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: border, width: 1)),
    child: Column(children: children));
}

class _RowDivider extends StatelessWidget {
  final Color color;
  const _RowDivider({required this.color});
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, color: color, indent: 56);
}

class _SwitchRow extends StatefulWidget {
  final IconData icon; final String label; final Color iconBg;
  final bool isDark, value; final Color tPri, tSec;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({required this.icon, required this.label,
    required this.iconBg, required this.isDark, required this.tPri,
    required this.tSec, required this.value, required this.onChanged});
  @override
  State<_SwitchRow> createState() => _SwitchRowState();
}

class _SwitchRowState extends State<_SwitchRow> {
  late bool _val;
  @override void initState() { super.initState(); _val = widget.value; }
  @override
  Widget build(BuildContext context) {
    final primary = widget.isDark ? AppColors.darkPrimary : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        _IconBox(icon: widget.icon, bg: widget.iconBg),
        const SizedBox(width: 14),
        Expanded(child: Text(widget.label,
          style: GoogleFonts.dmSans(
            fontSize: 15, fontWeight: FontWeight.w500, color: widget.tPri))),
        Switch.adaptive(
          value: _val,
          onChanged: (v) {
            HapticFeedback.selectionClick();
            setState(() => _val = v);
            widget.onChanged(v);
          },
          activeColor: primary),
      ]),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon; final String label; final Color iconBg;
  final bool isDark; final Color tPri, primary;
  final VoidCallback onTap; final Widget? trailing;
  const _NavRow({required this.icon, required this.label,
    required this.iconBg, required this.isDark, required this.tPri,
    required this.primary, required this.onTap, this.trailing});
  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(children: [
        _IconBox(icon: icon, bg: iconBg),
        const SizedBox(width: 14),
        Expanded(child: Text(label,
          style: GoogleFonts.dmSans(
            fontSize: 15, fontWeight: FontWeight.w500, color: tPri))),
        trailing ?? Icon(Icons.chevron_right_rounded,
          color: isDark ? AppColors.darkTextLight : AppColors.textLight,
          size: 20),
      ]),
    ),
  );
}

class _IconBox extends StatelessWidget {
  final IconData icon; final Color bg;
  const _IconBox({required this.icon, required this.bg});
  @override
  Widget build(BuildContext context) => Container(
    width: 34, height: 34,
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
    child: Icon(icon, color: Colors.white, size: 17));
}