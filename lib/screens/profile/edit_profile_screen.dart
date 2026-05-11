// lib/screens/profile/edit_profile_screen.dart
// Changes from previous version:
//   • Education section (Campus / University) REMOVED completely
//   • Bio maxLength raised to 300 characters
//   • _campusCtrl removed (field + dispose + save call)
//   • All else identical: purple AppBar, avatar upload, Skills, Links, Save Changes

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/avatar_widget.dart';

const _kP = AppColors.primary;

// ═════════════════════════════════════════════════════════════════════════════
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _skillsOfferedCtrl;
  late TextEditingController _skillsWantedCtrl;
  final List<TextEditingController> _linkCtrs = [];

  bool _saving         = false;
  bool _uploadingPhoto = false;
  String? _newAvatarUrl;

  @override
  void initState() {
    super.initState();
    final p           = context.read<AuthService>().currentProfile;
    _nameCtrl          = TextEditingController(text: p?.fullName  ?? '');
    _usernameCtrl      = TextEditingController(text: p?.username  ?? '');
    _bioCtrl           = TextEditingController(text: p?.bio       ?? '');
    _skillsOfferedCtrl = TextEditingController(
        text: p?.skillsOffered.join(', ') ?? '');
    _skillsWantedCtrl  = TextEditingController(
        text: p?.skillsWanted.join(', ')  ?? '');
    // Two empty link slots by default
    _linkCtrs.add(TextEditingController());
    _linkCtrs.add(TextEditingController());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _skillsOfferedCtrl.dispose();
    _skillsWantedCtrl.dispose();
    for (final c in _linkCtrs) c.dispose();
    super.dispose();
  }

  // ── Avatar upload ───────────────────────────────────────────────────────────
  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512);
    if (picked == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final Uint8List bytes = await picked.readAsBytes();
      final name = '${const Uuid().v4()}.jpg';
      await supabase.storage.from('avatars').uploadBinary(name, bytes,
          fileOptions:
              const FileOptions(cacheControl: '3600', upsert: true));
      setState(() => _newAvatarUrl =
          supabase.storage.from('avatars').getPublicUrl(name));
    } catch (e) {
      if (mounted) _snack('Upload failed: $e', isError: true);
    } finally {
      setState(() => _uploadingPhoto = false);
    }
  }

  List<String> _csv(String v) =>
      v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  // ── Save ────────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final ok = await context.read<AuthService>().updateProfile(
      fullName:      _nameCtrl.text.trim(),
      username:      _usernameCtrl.text.trim(),
      bio:           _bioCtrl.text.trim(),
      skillsOffered: _csv(_skillsOfferedCtrl.text),
      skillsWanted:  _csv(_skillsWantedCtrl.text),
      avatarUrl:     _newAvatarUrl,
    );

    setState(() => _saving = false);
    if (ok && mounted) {
      _snack('Profile saved!');
      Navigator.pop(context);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.dmSans(color: Colors.white)),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final profile = context.watch<AuthService>().currentProfile;
    final bg      = isDark ? AppColors.darkBackground       : const Color(0xFFF4F4F9);
    final tPri    = isDark ? AppColors.darkTextPrimary      : AppColors.textPrimary;
    final tSec    = isDark ? AppColors.darkTextSecondary    : AppColors.textSecondary;
    final cardBg  = isDark ? AppColors.darkCardBg           : Colors.white;
    final border  = isDark ? AppColors.darkBorder           : const Color(0xFFE8E8F0);
    final primary = isDark ? AppColors.darkPrimary          : _kP;

    return Scaffold(
      backgroundColor: bg,

      // ── Purple gradient AppBar ──────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2A22B8), Color(0xFF5B4FE8)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text('Edit Profile',
            style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text('Save',
                    style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 4),
        ],
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(children: [

            // ── Avatar ──────────────────────────────────────────────────────
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _uploadingPhoto ? null : _pickAvatar,
              child: Stack(alignment: Alignment.bottomRight, children: [
                _uploadingPhoto
                    ? Container(
                        width: 96, height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.surfaceVariant),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: primary))
                    : AvatarWidget(
                        avatarUrl: _newAvatarUrl ?? profile?.avatarUrl,
                        username:  profile?.username ?? '',
                        radius:    48,
                        borderColor: Colors.white),
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBackground
                          : Colors.white,
                      width: 2)),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 15)),
              ]),
            ),
            const SizedBox(height: 8),
            Text(
              _uploadingPhoto ? 'Uploading…' : 'Tap to change photo',
              style: GoogleFonts.dmSans(fontSize: 12.5, color: tSec)),

            const SizedBox(height: 26),

            // ── PERSONAL INFORMATION ────────────────────────────────────────
            _SectionHeader(
                icon: Icons.person_outline_rounded,
                label: 'Personal Information',
                isDark: isDark,
                tPri: tPri),
            const SizedBox(height: 10),

            _FieldCard(
              isDark: isDark, cardBg: cardBg, border: border,
              children: [
                _Field(
                  ctrl: _nameCtrl,
                  label: 'Full Name',
                  isDark: isDark, tPri: tPri, tSec: tSec, border: border,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Full name is required' : null),
                _Divider(isDark: isDark),
                _Field(
                  ctrl: _usernameCtrl,
                  label: 'Username',
                  isDark: isDark, tPri: tPri, tSec: tSec, border: border,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Username is required' : null),
                _Divider(isDark: isDark),
                // Bio — 300 char limit
                _Field(
                  ctrl: _bioCtrl,
                  label: 'Bio',
                  maxLines: 3,
                  maxLength: 300,
                  isDark: isDark, tPri: tPri, tSec: tSec, border: border),
              ],
            ),

            const SizedBox(height: 18),

            // ── SKILLS ──────────────────────────────────────────────────────
            _SectionHeader(
                icon: Icons.star_outline_rounded,
                label: 'Skills',
                isDark: isDark,
                tPri: tPri),
            const SizedBox(height: 10),

            _FieldCard(
              isDark: isDark, cardBg: cardBg, border: border,
              children: [
                _Field(
                  ctrl: _skillsOfferedCtrl,
                  label: 'Skills I Offer (comma-separated)',
                  hint: 'Python, DSA, Java',
                  isDark: isDark, tPri: tPri, tSec: tSec, border: border),
                _Divider(isDark: isDark),
                _Field(
                  ctrl: _skillsWantedCtrl,
                  label: 'Skills I Want (comma-separated)',
                  hint: 'Figma, GitHub, Git',
                  isDark: isDark, tPri: tPri, tSec: tSec, border: border),
              ],
            ),

            const SizedBox(height: 18),

            // ── LINKS ───────────────────────────────────────────────────────
            _SectionHeader(
                icon: Icons.link_rounded,
                label: 'Links',
                isDark: isDark,
                tPri: tPri),
            const SizedBox(height: 10),

            _FieldCard(
              isDark: isDark, cardBg: cardBg, border: border,
              children: [
                // Dynamic link rows
                ..._linkCtrs.asMap().entries.expand((e) {
                  final i = e.key;
                  final ctrl = e.value;
                  return [
                    if (i > 0) _Divider(isDark: isDark),
                    _LinkField(
                      ctrl: ctrl,
                      isDark: isDark, tPri: tPri, tSec: tSec, border: border,
                      onRemove: () => setState(() {
                        ctrl.dispose();
                        _linkCtrs.removeAt(i);
                      })),
                  ];
                }),

                // + Add another link
                _Divider(isDark: isDark),
                GestureDetector(
                  onTap: () =>
                      setState(() => _linkCtrs.add(TextEditingController())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add_rounded, size: 16, color: primary),
                      const SizedBox(width: 6),
                      Text('Add another link',
                        style: GoogleFonts.dmSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: primary)),
                    ]),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Save Changes ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SaveBtn(saving: _saving, onTap: _save),
            ),

            const SizedBox(height: 48),
          ]),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final IconData icon; final String label;
  final bool isDark; final Color tPri;
  const _SectionHeader({required this.icon, required this.label,
    required this.isDark, required this.tPri});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(children: [
      Icon(icon, size: 18, color: isDark ? AppColors.darkPrimary : _kP),
      const SizedBox(width: 8),
      Text(label, style: GoogleFonts.dmSans(
          fontSize: 15, fontWeight: FontWeight.w800, color: tPri)),
    ]),
  );
}

class _FieldCard extends StatelessWidget {
  final bool isDark; final Color cardBg, border;
  final List<Widget> children;
  const _FieldCard({required this.isDark, required this.cardBg,
    required this.border, required this.children});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: border, width: 1),
      boxShadow: isDark ? null : [BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10, offset: const Offset(0, 3))]),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: children));
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String? hint;
  final int maxLines;
  final int? maxLength;
  final IconData? suffixIcon;
  final bool isDark;
  final Color tPri, tSec, border;
  final String? Function(String?)? validator;

  const _Field({
    required this.ctrl, required this.label,
    this.hint, this.maxLines = 1, this.maxLength,
    this.suffixIcon, required this.isDark,
    required this.tPri, required this.tSec, required this.border,
    this.validator});

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.darkPrimary : _kP;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        maxLength: maxLength,
        validator: validator,
        style: GoogleFonts.dmSans(
            fontSize: 14.5, color: tPri, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.dmSans(
              fontSize: 12, color: tSec, fontWeight: FontWeight.w600),
          hintStyle: GoogleFonts.dmSans(fontSize: 14, color: tSec),
          counterStyle: GoogleFonts.dmSans(fontSize: 11, color: tSec),
          suffixIcon: suffixIcon != null
              ? Icon(suffixIcon, size: 20, color: tSec) : null,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          isDense: false,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _LinkField extends StatelessWidget {
  final TextEditingController ctrl;
  final bool isDark;
  final Color tPri, tSec, border;
  final VoidCallback onRemove;
  const _LinkField({required this.ctrl, required this.isDark,
    required this.tPri, required this.tSec, required this.border,
    required this.onRemove});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
    child: Row(children: [
      Icon(Icons.link_rounded, size: 18,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.textSecondary),
      const SizedBox(width: 10),
      Expanded(
        child: TextField(
          controller: ctrl,
          style: GoogleFonts.dmSans(
              fontSize: 14, color: tPri, fontWeight: FontWeight.w500),
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            hintText: 'https://',
            hintStyle: GoogleFonts.dmSans(fontSize: 14, color: tSec),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10)),
        ),
      ),
      GestureDetector(
        onTap: onRemove,
        child: Icon(Icons.close_rounded, size: 18,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary)),
    ]),
  );
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});
  @override
  Widget build(BuildContext context) => Divider(
    height: 1, thickness: 1,
    color: isDark ? AppColors.darkBorder : const Color(0xFFEEEEF5),
    indent: 16, endIndent: 16);
}

class _SaveBtn extends StatelessWidget {
  final bool saving; final VoidCallback onTap;
  const _SaveBtn({required this.saving, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: saving ? null : onTap,
    child: Container(
      width: double.infinity, height: 56,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: _kP.withOpacity(0.34),
          blurRadius: 18, offset: const Offset(0, 7), spreadRadius: -3)]),
      child: saving
          ? const Center(child: SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.2, color: Colors.white)))
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.save_alt_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Save Changes',
                style: GoogleFonts.dmSans(
                  color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.w700)),
            ]),
    ),
  );
}