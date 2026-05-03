// File: lib/widgets/filter_sheet.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/post_model.dart';
import '../utils/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  PostFilter — immutable value object holding all active filter state
// ─────────────────────────────────────────────────────────────────────────────
class PostFilter {
  final SortOrder sortOrder;
  final String?   exchangeType; // null = all, 'barter', 'custom'
  final SkillType skillType;
  final bool      openOnly;

  const PostFilter({
    this.sortOrder    = SortOrder.newest,
    this.exchangeType,
    this.skillType    = SkillType.all,
    this.openOnly     = false,
  });

  bool get isActive =>
      sortOrder != SortOrder.newest ||
      exchangeType != null ||
      skillType != SkillType.all ||
      openOnly;

  PostFilter copyWith({
    SortOrder?  sortOrder,
    Object?     exchangeType = _sentinel,
    SkillType?  skillType,
    bool?       openOnly,
  }) {
    return PostFilter(
      sortOrder:    sortOrder    ?? this.sortOrder,
      exchangeType: exchangeType == _sentinel
          ? this.exchangeType
          : exchangeType as String?,
      skillType:    skillType    ?? this.skillType,
      openOnly:     openOnly     ?? this.openOnly,
    );
  }

  static const Object _sentinel = Object();
}

// ─────────────────────────────────────────────────────────────────────────────
//  Enums
// ─────────────────────────────────────────────────────────────────────────────
enum SortOrder {
  newest(   'Newest First',          Icons.arrow_downward_rounded),
  oldest(   'Oldest First',          Icons.arrow_upward_rounded),
  ratingHigh('Rating: High → Low',   Icons.star_rounded),
  ratingLow( 'Rating: Low → High',   Icons.star_outline_rounded);

  final String  label;
  final IconData icon;
  const SortOrder(this.label, this.icon);
}

enum SkillType {
  all(      'All Types',   null),
  technical('Technical',   Icons.code_rounded),
  creative( 'Creative',    Icons.palette_rounded),
  soft(     'Soft Skills', Icons.people_rounded),
  language( 'Language',    Icons.translate_rounded),
  academic( 'Academic',    Icons.school_rounded);

  final String   label;
  final IconData? icon;          // null only for 'all'
  const SkillType(this.label, this.icon);
}

// ─────────────────────────────────────────────────────────────────────────────
//  FilterButton — icon button shown beside search bars
//  Shows an active badge dot when any filter is on.
// ─────────────────────────────────────────────────────────────────────────────
class FilterButton extends StatelessWidget {
  final PostFilter filter;
  final bool isDark;
  final ValueChanged<PostFilter> onChanged;

  const FilterButton({
    super.key,
    required this.filter,
    required this.isDark,
    required this.onChanged,
  });

  Color get _bgColor   => isDark ? AppColors.darkSearchBg : const Color(0xFFF3F3F3);
  Color get _iconColor => filter.isActive
      ? (isDark ? AppColors.darkPrimary : AppColors.primary)
      : (isDark ? AppColors.darkTextSecondary : const Color(0xFF6B7280));

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await showModalBottomSheet<PostFilter>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _FilterSheet(current: filter, isDark: isDark),
        );
        if (result != null) onChanged(result);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: filter.isActive
                  ? (isDark
                      ? AppColors.darkPrimary.withOpacity(0.15)
                      : AppColors.primary.withOpacity(0.08))
                  : _bgColor,
              borderRadius: BorderRadius.circular(12),
              border: filter.isActive
                  ? Border.all(
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      width: 1.5)
                  : null,
            ),
            child: Icon(Icons.tune_rounded, color: _iconColor, size: 20),
          ),
          if (filter.isActive)
            Positioned(
              top: -2, right: -2,
              child: Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.darkBackground : Colors.white,
                    width: 1.5,
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
//  _FilterSheet — modal bottom sheet with all filter controls
// ─────────────────────────────────────────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  final PostFilter current;
  final bool isDark;
  const _FilterSheet({required this.current, required this.isDark});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late PostFilter _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.current;
  }

  Color get _bg      => widget.isDark ? AppColors.darkCardBg         : Colors.white;
  Color get _surface => widget.isDark ? AppColors.darkSurfaceVariant  : const Color(0xFFF8F8F8);
  Color get _border  => widget.isDark ? AppColors.darkBorder          : const Color(0xFFE5E7EB);
  Color get _textPri => widget.isDark ? AppColors.darkTextPrimary     : const Color(0xFF1A1A1A);
  Color get _textSec => widget.isDark ? AppColors.darkTextSecondary   : const Color(0xFF6B7280);
  Color get _primary => widget.isDark ? AppColors.darkPrimary         : AppColors.primary;

  int get _activeCount => [
    _draft.sortOrder != SortOrder.newest,
    _draft.exchangeType != null,
    _draft.skillType != SkillType.all,
    _draft.openOnly,
  ].where((b) => b).length;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // ── Handle ────────────────────────────────────────────────────
            const SizedBox(height: 10),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: _border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),

            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Text('Filters',
                    style: GoogleFonts.dmSans(
                        fontSize: 18, fontWeight: FontWeight.w800, color: _textPri)),
                if (_activeCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: _primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('$_activeCount active',
                        style: GoogleFonts.dmSans(
                            fontSize: 11, fontWeight: FontWeight.w700, color: _primary)),
                  ),
                ],
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _draft = const PostFilter()),
                  child: Text('Reset all',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: _draft.isActive ? _primary : _textSec)),
                ),
              ]),
            ),

            Divider(color: _border, height: 1),

            // ── Scrollable body ───────────────────────────────────────────
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  // ── Sort ────────────────────────────────────────────────
                  _label('Sort By'),
                  const SizedBox(height: 10),
                  ...SortOrder.values.map((s) => _RadioTile<SortOrder>(
                    value:      s,
                    groupValue: _draft.sortOrder,
                    label:      s.label,
                    icon:       s.icon,
                    primary:    _primary,
                    textPri:    _textPri,
                    textSec:    _textSec,
                    surface:    _surface,
                    border:     _border,
                    onChanged:  (v) => setState(() => _draft = _draft.copyWith(sortOrder: v)),
                  )),

                  const SizedBox(height: 20),

                  // ── Exchange type ────────────────────────────────────────
                  _label('Exchange Type'),
                  const SizedBox(height: 10),
                  _SegmentedRow(
                    options: const [
                      _Seg('All',    null,     Icons.apps_rounded),
                      _Seg('Barter', 'barter', Icons.swap_horiz_rounded),
                      _Seg('Money',  'custom', Icons.attach_money_rounded),
                    ],
                    selected:  _draft.exchangeType,
                    primary:   _primary,
                    surface:   _surface,
                    border:    _border,
                    textPri:   _textPri,
                    textSec:   _textSec,
                    isDark:    widget.isDark,
                    // when 'All' is tapped, v is null → clear exchangeType
                    onChanged: (v) => setState(() =>
                        _draft = _draft.copyWith(exchangeType: v)),
                  ),

                  const SizedBox(height: 20),

                  // ── Skill type ───────────────────────────────────────────
                  _label('Skill Type'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: SkillType.values.map((st) {
                      final active = _draft.skillType == st;
                      return GestureDetector(
                        onTap: () => setState(
                            () => _draft = _draft.copyWith(skillType: st)),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: active
                                ? _primary.withOpacity(
                                    widget.isDark ? 0.2 : 0.1)
                                : _surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active ? _primary : _border,
                              width: active ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Guard against null icon (only SkillType.all has null)
                              if (st.icon != null) ...[
                                Icon(st.icon!, size: 14,
                                    color: active ? _primary : _textSec),
                                const SizedBox(width: 5),
                              ],
                              Text(st.label,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      fontWeight: active
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: active ? _primary : _textSec)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // ── Open requests toggle ─────────────────────────────────
                  _label('Listing Type'),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => setState(() =>
                        _draft = _draft.copyWith(openOnly: !_draft.openOnly)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: _draft.openOnly
                            ? _primary.withOpacity(
                                widget.isDark ? 0.15 : 0.08)
                            : _surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _draft.openOnly ? _primary : _border,
                          width: _draft.openOnly ? 1.5 : 1,
                        ),
                      ),
                      child: Row(children: [
                        Icon(Icons.help_outline_rounded,
                            size: 18,
                            color: _draft.openOnly ? _primary : _textSec),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Open Requests Only',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _draft.openOnly
                                          ? _primary
                                          : _textPri)),
                              Text('Show posts where anyone can respond',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 11, color: _textSec)),
                            ],
                          ),
                        ),
                        // Custom animated toggle thumb
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 42, height: 24,
                          decoration: BoxDecoration(
                            color: _draft.openOnly ? _primary : _border,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            alignment: _draft.openOnly
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Container(
                                width: 18, height: 18,
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle),
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),

            // ── Apply button ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _draft),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _activeCount > 0
                        ? 'Apply $_activeCount filter${_activeCount > 1 ? "s" : ""}'
                        : 'Apply Filters',
                    style: GoogleFonts.dmSans(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.dmSans(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: _textSec, letterSpacing: 0.6));
}

// ─────────────────────────────────────────────────────────────────────────────
//  _RadioTile — single-select row for sort order
// ─────────────────────────────────────────────────────────────────────────────
class _RadioTile<T> extends StatelessWidget {
  final T value, groupValue;
  final String  label;
  final IconData icon;          // non-nullable — SortOrder.icon is always set
  final Color primary, textPri, textSec, surface, border;
  final ValueChanged<T> onChanged;

  const _RadioTile({
    required this.value,    required this.groupValue,
    required this.label,    required this.icon,
    required this.primary,  required this.textPri,
    required this.textSec,  required this.surface,
    required this.border,   required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final active = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: active ? primary.withOpacity(0.08) : surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: active ? primary : border, width: active ? 1.5 : 1),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: active ? primary : textSec),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? primary : textPri)),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 18, height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? primary : Colors.transparent,
              border: Border.all(
                  color: active ? primary : border, width: 2),
            ),
            child: active
                ? const Icon(Icons.check_rounded, size: 11, color: Colors.white)
                : null,
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _SegmentedRow — 3-way toggle for exchange type
// ─────────────────────────────────────────────────────────────────────────────
class _Seg {
  final String   label;
  final String?  value;        // null = "All" (clear filter)
  final IconData icon;
  const _Seg(this.label, this.value, this.icon);
}

class _SegmentedRow extends StatelessWidget {
  final List<_Seg> options;
  final String?    selected;
  final Color      primary, surface, border, textPri, textSec;
  final bool       isDark;
  final ValueChanged<String?> onChanged;

  const _SegmentedRow({
    required this.options,  required this.selected,
    required this.primary,  required this.surface,
    required this.border,   required this.textPri,
    required this.textSec,  required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: options.map((opt) {
          final active = selected == opt.value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(opt.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: active
                      ? (isDark ? AppColors.darkCardBg : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: active && !isDark
                      ? [BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1))]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(opt.icon, size: 14,
                        color: active ? primary : textSec),
                    const SizedBox(width: 5),
                    Text(opt.label,
                        style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w500,
                            color: active ? primary : textSec)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FilterPosts extension — client-side sort + skill-type keyword filter
//  Import this file wherever applyFilter() is needed.
// ─────────────────────────────────────────────────────────────────────────────
extension FilterPosts on List<PostModel> {
  List<PostModel> applyFilter(PostFilter f) {
    var result = List<PostModel>.from(this);

    // ── Skill-type keyword filter (client-side) ────────────────────────────
    if (f.skillType != SkillType.all) {
      const techKeywords = [
        'code', 'python', 'java', 'programming', 'data', 'excel', 'math',
        'calculus', 'engineering', 'web', 'app', 'software', 'ai', 'ml',
        'database', 'sql',
      ];
      const creativeKeywords = [
        'design', 'art', 'photo', 'video', 'music', 'drawing', 'animation',
        'ui', 'ux', 'figma', 'canva', 'edit', 'creative', 'illustration',
      ];
      const softKeywords = [
        'communication', 'speaking', 'leadership', 'management', 'coaching',
        'mentoring', 'writing', 'presentation', 'yoga', 'fitness',
      ];
      const langKeywords = [
        'language', 'english', 'hindi', 'spanish', 'french', 'german',
        'japanese', 'translate', 'grammar',
      ];
      const academicKeywords = [
        'tutor', 'tutoring', 'study', 'notes', 'academic', 'science',
        'physics', 'chemistry', 'biology', 'history',
      ];

      final List<String> keywords;
      switch (f.skillType) {
        case SkillType.technical: keywords = techKeywords;     break;
        case SkillType.creative:  keywords = creativeKeywords; break;
        case SkillType.soft:      keywords = softKeywords;     break;
        case SkillType.language:  keywords = langKeywords;     break;
        case SkillType.academic:  keywords = academicKeywords; break;
        case SkillType.all:       keywords = [];               break;
      }

      if (keywords.isNotEmpty) {
        result = result.where((p) {
          final haystack =
              '${p.title} ${p.skillOffered} ${p.tags.join(' ')}'
                  .toLowerCase();
          return keywords.any((kw) => haystack.contains(kw));
        }).toList();
      }
    }

    // ── Sort ──────────────────────────────────────────────────────────────
    switch (f.sortOrder) {
      case SortOrder.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOrder.oldest:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOrder.ratingHigh:
        result.sort((a, b) =>
            (b.profile?.averageRating ?? 0)
                .compareTo(a.profile?.averageRating ?? 0));
        break;
      case SortOrder.ratingLow:
        result.sort((a, b) =>
            (a.profile?.averageRating ?? 0)
                .compareTo(b.profile?.averageRating ?? 0));
        break;
    }

    return result;
  }
}