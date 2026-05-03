// File: lib/screens/posts/create_post_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/post_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/gradient_button.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});
  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen>
    with SingleTickerProviderStateMixin {
  final _formKey          = GlobalKey<FormState>();
  final _titleCtrl        = TextEditingController();
  final _descCtrl         = TextEditingController();
  final _skillOfferedCtrl = TextEditingController();
  final _skillWantedCtrl  = TextEditingController();
  final _customOfferCtrl  = TextEditingController();
  final _customTagCtrl    = TextEditingController();

  String _exchangeType  = 'barter';
  bool   _isOpenRequest = false;
  bool   _isOffering    = true;  // true = 'I want to OFFER', false = 'I need'
  bool   _isLoading     = false;

  final List<String> _selectedTags = [];

  // ── Availability ──────────────────────────────────────────────────────────
  DateTime?        _availableFrom;
  DateTime?        _availableTo;
  final List<bool> _selectedDays   = List.filled(7, false);
  String?          _selectedSlot;

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _timeSlots = [
    'Morning (6–12)',
    'Afternoon (12–17)',
    'Evening (17–21)',
    'Night (21–24)',
    'Flexible',
  ];

  // ── Tag groups ────────────────────────────────────────────────────────────
  static const _tagGroups = {
    'Urgency': ['Urgent', 'Quick Help', 'Flexible Timeline', 'Long-term'],
    'Format':  ['Online', 'In-person', 'Hybrid', 'Recorded Session'],
    'Level':   ['Beginner-friendly', 'Intermediate', 'Advanced'],
    'Skill':   ['Technical', 'Creative', 'Soft Skills', 'Academic', 'Language'],
    'Extras':  ['Certification Help', 'Portfolio Work', 'Hackathon', 'Mentorship'],
  };

  late TabController _tabCtrl;
  int _activeTagGroup = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
        length: _tagGroups.length, vsync: this);
    _tabCtrl.addListener(() => setState(() => _activeTagGroup = _tabCtrl.index));
  }

  @override
  void dispose() {
    for (final c in [
      _titleCtrl, _descCtrl, _skillOfferedCtrl,
      _skillWantedCtrl, _customOfferCtrl, _customTagCtrl,
    ]) { c.dispose(); }
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isFrom) async {
    final now     = DateTime.now();
    final initial = isFrom
        ? (_availableFrom ?? now)
        : (_availableTo   ?? (_availableFrom?.add(const Duration(days: 7)) ?? now));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _availableFrom = picked;
          if (_availableTo != null && _availableTo!.isBefore(picked)) {
            _availableTo = picked.add(const Duration(days: 1));
          }
        } else {
          _availableTo = picked;
        }
      });
    }
  }

  void _addCustomTag() {
    final tag = _customTagCtrl.text.trim();
    if (tag.isEmpty || _selectedTags.contains(tag)) return;
    setState(() {
      _selectedTags.add(tag);
      _customTagCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // Build availability note and append to description
    final availNote = _buildAvailabilityNote();
    final desc = _descCtrl.text.trim() +
        (availNote.isNotEmpty ? '\n\n📅 Availability: $availNote' : '');

    final post = await context.read<PostService>().createPost(
      title:         _titleCtrl.text.trim(),
      description:   desc,
      skillOffered:  _skillOfferedCtrl.text.trim(),
      skillWanted:   _exchangeType == 'barter' ? _skillWantedCtrl.text.trim() : null,
      exchangeType:  _exchangeType,
      customOffer:   _exchangeType == 'custom'  ? _customOfferCtrl.text.trim() : null,
      tags:          _selectedTags,
      isOpenRequest: !_isOffering,
    );
    setState(() => _isLoading = false);

    if (post != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text('Post published successfully! 🚀',
              style: GoogleFonts.dmSans(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ]),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      _resetForm();
    }
  }

  String _buildAvailabilityNote() {
    final parts = <String>[];
    if (_availableFrom != null) {
      final from = '${_availableFrom!.day}/${_availableFrom!.month}/${_availableFrom!.year}';
      final to   = _availableTo != null
          ? '${_availableTo!.day}/${_availableTo!.month}/${_availableTo!.year}'
          : null;
      parts.add(to != null ? '$from – $to' : 'From $from');
    }
    final days = <String>[];
    for (var i = 0; i < 7; i++) {
      if (_selectedDays[i]) days.add(_dayLabels[i]);
    }
    if (days.isNotEmpty) parts.add(days.join(', '));
    if (_selectedSlot != null) parts.add(_selectedSlot!);
    return parts.join(' | ');
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    for (final c in [
      _titleCtrl, _descCtrl, _skillOfferedCtrl,
      _skillWantedCtrl, _customOfferCtrl, _customTagCtrl,
    ]) { c.clear(); }
    setState(() {
      _selectedTags.clear();
      _exchangeType  = 'barter';
      _isOpenRequest = false;
      _isOffering    = true;
      _availableFrom = null;
      _availableTo   = null;
      _selectedSlot  = null;
      for (var i = 0; i < 7; i++) _selectedDays[i] = false;
    });
  }

  // ── Theme helpers ──────────────────────────────────────────────────────────
  Color _bg(bool d)      => d ? AppColors.darkBackground    : AppColors.background;
  Color _cardBg(bool d)  => d ? AppColors.darkCardBg        : Colors.white;
  Color _border(bool d)  => d ? AppColors.darkBorder        : AppColors.border;
  Color _textPri(bool d) => d ? AppColors.darkTextPrimary   : AppColors.textPrimary;
  Color _textSec(bool d) => d ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color _surface(bool d) => d ? AppColors.darkSurfaceVariant: AppColors.surfaceVariant;
  Color _primary(bool d) => d ? AppColors.darkPrimary       : AppColors.primary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _bg(isDark),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Gradient app bar ──────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 110,
            backgroundColor: Colors.transparent,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration:
                    const BoxDecoration(gradient: AppColors.heroGradient),
                child: Stack(children: [
                  Positioned(
                    top: -30, right: -30,
                    child: Container(
                      width: 130, height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -20, left: 40,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.04),
                      ),
                    ),
                  ),
                ]),
              ),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Post a Swap',
                      style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3)),
                  Text('Share your skill with the community',
                      style: GoogleFonts.dmSans(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 11,
                          fontWeight: FontWeight.w400)),
                ],
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 0, 14),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── OFFER / NEED segmented toggle ──────────────────────
                    _OfferNeedToggle(
                      isOffering: _isOffering,
                      isDark: isDark,
                      primary: _primary(isDark),
                      surface: _surface(isDark),
                      onChanged: (v) => setState(() => _isOffering = v),
                    ).animate().fadeIn(delay: 0.ms).slideY(begin: 0.06),

                    const SizedBox(height: 20),

                    // ── What are you offering / What do you need ────────────
                    _SectionLabel(
                      label: _isOffering ? 'What are you offering?' : 'What do you need?',
                      icon: _isOffering ? Icons.star_outline_rounded : Icons.search_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _FormCard(
                      isDark: isDark,
                      cardBg: _cardBg(isDark),
                      border: _border(isDark),
                      child: _Field(
                        controller: _skillOfferedCtrl,
                        isDark: isDark,
                        label: _isOffering ? 'What are you offering?' : 'What do you need?',
                        hint: _isOffering
                            ? 'e.g. Python Tutoring, Logo Design, Guitar Lessons'
                            : 'e.g. Math Help, Video Editing, Spanish Lessons',
                        icon: _isOffering ? Icons.star_outline_rounded : Icons.search_rounded,
                        maxLines: 1,
                        charLimit: 60,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'This field is required'
                            : null,
                      ),
                    ).animate().fadeIn(delay: 60.ms).slideY(begin: 0.06),

                    const SizedBox(height: 20),

                    // ── Exchange Type ───────────────────────────────────────
                    _SectionLabel(
                        label: 'Exchange Type',
                        icon: Icons.swap_horiz_rounded,
                        isDark: isDark),
                    const SizedBox(height: 10),
                    _FormCard(
                      isDark: isDark,
                      cardBg: _cardBg(isDark),
                      border: _border(isDark),
                      child: Column(children: [
                        Row(children: [
                          Expanded(
                            child: _ExchangeOption(
                              emoji: '⇌',
                              title: 'Barter',
                              subtitle: 'Skill for skill',
                              value: 'barter',
                              selected: _exchangeType,
                              surface: _surface(isDark),
                              isDark: isDark,
                              onTap: () =>
                                  setState(() => _exchangeType = 'barter'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ExchangeOption(
                              emoji: '💰',
                              title: 'Money',
                              subtitle: '₹ / Pay',
                              value: 'money',
                              selected: _exchangeType,
                              surface: _surface(isDark),
                              isDark: isDark,
                              onTap: () =>
                                  setState(() => _exchangeType = 'money'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ExchangeOption(
                              emoji: '🎁',
                              title: 'Custom',
                              subtitle: 'Treats, etc.',
                              value: 'custom',
                              selected: _exchangeType,
                              surface: _surface(isDark),
                              isDark: isDark,
                              onTap: () =>
                                  setState(() => _exchangeType = 'custom'),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 14),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, anim) =>
                              SizeTransition(sizeFactor: anim, child: FadeTransition(opacity: anim, child: child)),
                          child: _exchangeType == 'barter'
                              ? _Field(
                                  key: const ValueKey('barter'),
                                  controller: _skillWantedCtrl,
                                  isDark: isDark,
                                  label: 'Skill You Want in Return',
                                  hint: 'e.g. Graphic Design, Spanish',
                                  icon: Icons.swap_horiz_rounded,
                                  validator: (v) =>
                                      _exchangeType == 'barter' &&
                                              (v == null || v.trim().isEmpty)
                                          ? 'Required for barter'
                                          : null,
                                )
                              : _exchangeType == 'money'
                                  ? _Field(
                                      key: const ValueKey('money'),
                                      controller: _customOfferCtrl,
                                      isDark: isDark,
                                      label: 'Amount / Rate',
                                      hint: 'e.g. ₹200/hr, ₹500 fixed',
                                      icon: Icons.currency_rupee_rounded,
                                      validator: (v) =>
                                          _exchangeType == 'money' &&
                                                  (v == null || v.trim().isEmpty)
                                              ? 'Required'
                                              : null,
                                    )
                                  : _Field(
                                      key: const ValueKey('custom'),
                                      controller: _customOfferCtrl,
                                      isDark: isDark,
                                      label: 'Custom Offer',
                                      hint: 'e.g. Coffee, Lunch, Gift card',
                                      icon: Icons.card_giftcard_rounded,
                                      validator: (v) =>
                                          _exchangeType == 'custom' &&
                                                  (v == null || v.trim().isEmpty)
                                              ? 'Required'
                                              : null,
                                    ),
                        ),
                      ]),
                    ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.06),

                    const SizedBox(height: 20),

                    const SizedBox(height: 20),

                    // ── Description (between Exchange Type and Tags) ─────────
                    _SectionLabel(
                        label: 'Description',
                        icon: Icons.description_outlined,
                        isDark: isDark),
                    const SizedBox(height: 10),
                    _FormCard(
                      isDark: isDark,
                      cardBg: _cardBg(isDark),
                      border: _border(isDark),
                      child: _Field(
                        controller: _descCtrl,
                        isDark: isDark,
                        label: 'Description',
                        hint: 'Add more details about what you\'re offering...',
                        icon: Icons.description_outlined,
                        maxLines: 4,
                        charLimit: 300,
                        alignLabelWithHint: true,
                      ),
                    ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.06),

                    const SizedBox(height: 20),

                    // ── Tags ────────────────────────────────────────────────
                    _SectionLabel(
                        label: 'Add Tags',
                        icon: Icons.label_outline_rounded,
                        isDark: isDark),
                    const SizedBox(height: 10),
                    _FormCard(
                      isDark: isDark,
                      cardBg: _cardBg(isDark),
                      border: _border(isDark),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Selected tags preview
                            if (_selectedTags.isNotEmpty) ...[
                              Wrap(
                                spacing: 6, runSpacing: 6,
                                children: _selectedTags
                                    .map((t) => _SelectedTagChip(
                                          tag: t,
                                          isDark: isDark,
                                          primary: _primary(isDark),
                                          onRemove: () => setState(
                                              () => _selectedTags.remove(t)),
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 12),
                              Divider(
                                  color: _border(isDark), height: 1),
                              const SizedBox(height: 12),
                            ],

                            // Group tabs
                            SizedBox(
                              height: 34,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _tagGroups.keys.length,
                                itemBuilder: (_, i) {
                                  final name =
                                      _tagGroups.keys.elementAt(i);
                                  final active = _activeTagGroup == i;
                                  return GestureDetector(
                                    onTap: () {
                                      _tabCtrl.animateTo(i);
                                      setState(
                                          () => _activeTagGroup = i);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 180),
                                      margin: const EdgeInsets.only(
                                          right: 8),
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 7),
                                      decoration: BoxDecoration(
                                        color: active
                                            ? _primary(isDark)
                                            : _surface(isDark),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(name,
                                          style: GoogleFonts.dmSans(
                                              fontSize: 12,
                                              fontWeight: active
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: active
                                                  ? Colors.white
                                                  : _textSec(isDark))),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Tags for active group
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: (_tagGroups.values.elementAt(
                                      _activeTagGroup))
                                  .map((tag) {
                                final sel = _selectedTags.contains(tag);
                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      if (sel) {
                                        _selectedTags.remove(tag);
                                      } else {
                                        _selectedTags.add(tag);
                                      }
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      gradient: sel
                                          ? AppColors.primaryGradient
                                          : null,
                                      color: sel
                                          ? null
                                          : _surface(isDark),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      border: Border.all(
                                        color: sel
                                            ? Colors.transparent
                                            : _border(isDark),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (sel) ...[
                                          const Icon(
                                              Icons.check_rounded,
                                              size: 12,
                                              color: Colors.white),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(tag,
                                            style: GoogleFonts.dmSans(
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight.w600,
                                                color: sel
                                                    ? Colors.white
                                                    : _textSec(isDark))),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 14),

                            // Custom tag input
                            Row(children: [
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: TextField(
                                    controller: _customTagCtrl,
                                    style: GoogleFonts.dmSans(
                                        color: _textPri(isDark),
                                        fontSize: 13),
                                    onSubmitted: (_) => _addCustomTag(),
                                    decoration: InputDecoration(
                                      hintText: 'Add custom tag...',
                                      hintStyle: GoogleFonts.dmSans(
                                          color: _textSec(isDark),
                                          fontSize: 12),
                                      prefixIcon: Icon(
                                          Icons.add_rounded,
                                          color: _textSec(isDark),
                                          size: 18),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 10),
                                      isDense: true,
                                      filled: true,
                                      fillColor: _surface(isDark),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: _border(isDark)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: _border(isDark)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: _primary(isDark),
                                            width: 1.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _addCustomTag,
                                child: Container(
                                  height: 40, width: 40,
                                  decoration: BoxDecoration(
                                    color: _primary(isDark),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.add_rounded,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                            ]),
                          ]),
                    ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.06),

                    const SizedBox(height: 20),

                    // ── Availability ────────────────────────────────────────
                    _SectionLabel(
                        label: 'Availability',
                        icon: Icons.calendar_today_rounded,
                        isDark: isDark),
                    const SizedBox(height: 10),
                    _FormCard(
                      isDark: isDark,
                      cardBg: _cardBg(isDark),
                      border: _border(isDark),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date range
                            Text('Date Range',
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _textSec(isDark),
                                    letterSpacing: 0.4)),
                            const SizedBox(height: 8),
                            Row(children: [
                              Expanded(
                                child: _DatePickerTile(
                                  label: 'From',
                                  date: _availableFrom,
                                  isDark: isDark,
                                  cardBg: _surface(isDark),
                                  border: _border(isDark),
                                  textPri: _textPri(isDark),
                                  textSec: _textSec(isDark),
                                  primary: _primary(isDark),
                                  onTap: () => _pickDate(true),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10),
                                child: Icon(Icons.arrow_forward_rounded,
                                    size: 16,
                                    color: _textSec(isDark)),
                              ),
                              Expanded(
                                child: _DatePickerTile(
                                  label: 'To',
                                  date: _availableTo,
                                  isDark: isDark,
                                  cardBg: _surface(isDark),
                                  border: _border(isDark),
                                  textPri: _textPri(isDark),
                                  textSec: _textSec(isDark),
                                  primary: _primary(isDark),
                                  onTap: () => _pickDate(false),
                                ),
                              ),
                            ]),

                            const SizedBox(height: 16),

                            // Days of week
                            Text('Days Available',
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _textSec(isDark),
                                    letterSpacing: 0.4)),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: List.generate(7, (i) {
                                final active = _selectedDays[i];
                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(
                                        () => _selectedDays[i] = !active);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(
                                        milliseconds: 180),
                                    width: 38, height: 38,
                                    decoration: BoxDecoration(
                                      color: active
                                          ? _primary(isDark)
                                          : _surface(isDark),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border: active
                                          ? null
                                          : Border.all(
                                              color: _border(isDark)),
                                    ),
                                    child: Center(
                                      child: Text(_dayLabels[i],
                                          style: GoogleFonts.dmSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: active
                                                  ? Colors.white
                                                  : _textSec(isDark))),
                                    ),
                                  ),
                                );
                              }),
                            ),

                            const SizedBox(height: 16),

                            // Time slot
                            Text('Preferred Time',
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _textSec(isDark),
                                    letterSpacing: 0.4)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: _timeSlots.map((slot) {
                                final active = _selectedSlot == slot;
                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _selectedSlot =
                                        active ? null : slot);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(
                                        milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? _primary(isDark)
                                              .withOpacity(0.12)
                                          : _surface(isDark),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      border: Border.all(
                                        color: active
                                            ? _primary(isDark)
                                            : _border(isDark),
                                        width: active ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 12,
                                          color: active
                                              ? _primary(isDark)
                                              : _textSec(isDark),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(slot,
                                            style: GoogleFonts.dmSans(
                                                fontSize: 11,
                                                fontWeight: active
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color: active
                                                    ? _primary(isDark)
                                                    : _textSec(isDark))),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ]),
                    ).animate().fadeIn(delay: 240.ms).slideY(begin: 0.06),

                    const SizedBox(height: 28),

                    // ── Publish button ──────────────────────────────────────
                    GradientButton(
                      onPressed: _isLoading ? null : _submit,
                      isLoading: _isLoading,
                      label: 'Publish Skill Post',
                      icon: Icons.rocket_launch_rounded,
                    ).animate().fadeIn(delay: 300.ms),

                    SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Reusable sub-widgets
// ─────────────────────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────────────────────
//  _OfferNeedToggle — "I want to OFFER" / "I need" segmented pill toggle
// ─────────────────────────────────────────────────────────────────────────────
class _OfferNeedToggle extends StatelessWidget {
  final bool   isOffering, isDark;
  final Color  primary, surface;
  final ValueChanged<bool> onChanged;

  const _OfferNeedToggle({
    required this.isOffering, required this.isDark,
    required this.primary,    required this.surface,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final border   = isDark ? AppColors.darkBorder  : AppColors.border;
    final textSec  = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(children: [
        // I want to OFFER
        Expanded(
          child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); onChanged(true); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: isOffering ? AppColors.primaryGradient : null,
                color: isOffering ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                boxShadow: isOffering
                    ? [BoxShadow(color: primary.withOpacity(0.3),
                          blurRadius: 8, offset: const Offset(0, 3))]
                    : null,
              ),
              child: Center(
                child: Text(
                  'I want to OFFER',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isOffering ? Colors.white : textSec,
                  ),
                ),
              ),
            ),
          ),
        ),
        // I need
        Expanded(
          child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); onChanged(false); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: !isOffering
                    ? (isDark ? AppColors.darkCardBg : Colors.white)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                boxShadow: !isOffering && !isDark
                    ? [BoxShadow(color: Colors.black.withOpacity(0.08),
                          blurRadius: 6, offset: const Offset(0, 2))]
                    : null,
              ),
              child: Center(
                child: Text(
                  'I need',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: !isOffering ? primary : textSec,
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String   label;
  final IconData icon;
  final bool     isDark;
  const _SectionLabel({
    required this.label, required this.icon, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary  = isDark ? AppColors.darkPrimary      : AppColors.primary;
    final textPri  = isDark ? AppColors.darkTextPrimary  : AppColors.textPrimary;
    return Row(children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: primary.withOpacity(isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: primary),
      ),
      const SizedBox(width: 8),
      Text(label,
          style: GoogleFonts.dmSans(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: textPri, letterSpacing: 0.1)),
    ]);
  }
}

class _FormCard extends StatelessWidget {
  final bool isDark;
  final Color cardBg, border;
  final Widget child;
  const _FormCard({
    required this.isDark, required this.cardBg,
    required this.border, required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: border, width: 1),
      boxShadow: isDark ? null : AppShadows.card,
    ),
    child: child,
  );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final bool   isDark;
  final String label, hint;
  final IconData icon;
  final int    maxLines;
  final int?   charLimit;
  final bool   alignLabelWithHint;
  final String? Function(String?)? validator;

  const _Field({
    super.key,
    required this.controller, required this.isDark,
    required this.label,      required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.charLimit,
    this.alignLabelWithHint = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final textPri = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: charLimit,
      style: GoogleFonts.dmSans(color: textPri, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: maxLines > 1
            ? Padding(
                padding: EdgeInsets.only(bottom: (maxLines - 1) * 20.0),
                child: Icon(icon, size: 20))
            : Icon(icon, size: 20),
        alignLabelWithHint: alignLabelWithHint,
        counterStyle: GoogleFonts.dmSans(fontSize: 11, color: textSec),
      ),
      validator: validator,
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final bool  isDark, value;
  final Color cardBg, border, textPri, textSec;
  final ValueChanged<bool> onChanged;

  const _ToggleCard({
    required this.isDark, required this.value,
    required this.cardBg, required this.border,
    required this.textPri, required this.textSec,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: value ? primary.withOpacity(0.5) : border,
            width: value ? 1.5 : 1,
          ),
          boxShadow: isDark ? null : AppShadows.card,
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primary.withOpacity(isDark ? 0.20 : 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.help_outline_rounded, color: primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Open Request',
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700, fontSize: 14,
                        color: textPri)),
                Text('Anyone can respond to this post',
                    style: GoogleFonts.dmSans(color: textSec, fontSize: 12)),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged, activeColor: primary),
        ]),
      ),
    );
  }
}

class _ExchangeOption extends StatelessWidget {
  final String  emoji, title, subtitle, value, selected;
  final Color   surface;
  final bool    isDark;
  final VoidCallback onTap;

  const _ExchangeOption({
    required this.emoji,    required this.title,
    required this.subtitle, required this.value,
    required this.selected, required this.surface,
    required this.isDark,   required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    final primary    = isDark ? AppColors.darkPrimary : AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color:    isSelected ? null : surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border),
          boxShadow: isSelected
              ? [BoxShadow(
                  color: primary.withOpacity(0.3),
                  blurRadius: 10, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 5),
            Text(title,
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700, fontSize: 12,
                    color: isSelected ? Colors.white : null)),
            Text(subtitle,
                style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: isSelected
                        ? Colors.white.withOpacity(0.8)
                        : null)),
          ],
        ),
      ),
    );
  }
}

class _SelectedTagChip extends StatelessWidget {
  final String tag;
  final bool isDark;
  final Color primary;
  final VoidCallback onRemove;

  const _SelectedTagChip({
    required this.tag, required this.isDark,
    required this.primary, required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: primary.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(tag,
            style: GoogleFonts.dmSans(
                fontSize: 11, fontWeight: FontWeight.w600, color: primary)),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onRemove,
          child: Icon(Icons.close_rounded, size: 13, color: primary),
        ),
      ]),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final String    label;
  final DateTime? date;
  final bool      isDark;
  final Color     cardBg, border, textPri, textSec, primary;
  final VoidCallback onTap;

  const _DatePickerTile({
    required this.label,   required this.date,
    required this.isDark,  required this.cardBg,
    required this.border,  required this.textPri,
    required this.textSec, required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: hasDate ? primary.withOpacity(isDark ? 0.15 : 0.08) : cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasDate ? primary : border,
            width: hasDate ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded, size: 14,
              color: hasDate ? primary : textSec),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.dmSans(
                      fontSize: 10, color: textSec, fontWeight: FontWeight.w500)),
              Text(
                hasDate
                    ? '${date!.day}/${date!.month}/${date!.year}'
                    : 'Select',
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: hasDate ? primary : textSec),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}