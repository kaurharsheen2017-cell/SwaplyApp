import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:badges/badges.dart' as badges;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';
import 'feed_screen.dart';
import '../explore/explore_screen.dart';
import '../posts/create_post_screen.dart';
import '../chat/chat_list_screen.dart';
import '../profile/profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MainNavScreen  — root shell with IndexedStack + themed bottom nav
//  Matches image: Home / Explore / Post Swap (FAB) / Messages / Profile
//  All colours resolve from Theme.of(context) — works in light + dark.
// ─────────────────────────────────────────────────────────────────────────────
class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  late List<AnimationController> _iconCtrl;
  late List<Animation<double>> _iconScale;

  // Screens kept alive in IndexedStack — order must match nav items
  final List<Widget> _screens = const [
    FeedScreen(),
    ExploreScreen(),
    CreatePostScreen(),
    ChatListScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _iconCtrl = List.generate(
      5,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 160),
        lowerBound: 0.85,
        upperBound: 1.0,
        value: 1.0,
      ),
    );
    _iconScale = _iconCtrl
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .toList();

    // Subscribe to realtime notifications once on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationService>().subscribeToNotifications();
      context.read<NotificationService>().fetchNotifications();
    });
  }

  @override
  void dispose() {
    for (final c in _iconCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    _iconCtrl[index].reverse().then((_) => _iconCtrl[index].forward());
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg =
        isDark ? AppColors.darkBackground : AppColors.background;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        iconScales: _iconScale,
        onTap: _onNavTap,
        isDark: isDark,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _BottomNav  — themed, animated bottom navigation bar
// ─────────────────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<Animation<double>> iconScales;
  final ValueChanged<int> onTap;
  final bool isDark;

  const _BottomNav({
    required this.currentIndex,
    required this.iconScales,
    required this.onTap,
    required this.isDark,
  });

  // Resolved per-theme colours
  Color get _navBg     => isDark ? AppColors.darkBackground : AppColors.surface;
  Color get _border    => isDark ? AppColors.darkBorder     : AppColors.divider;
  Color get _active    => isDark ? AppColors.darkPrimary    : AppColors.primary;
  Color get _inactive  => isDark ? AppColors.darkTextLight  : AppColors.textLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _navBg,
        border: Border(top: BorderSide(color: _border, width: 1)),
        boxShadow: isDark ? null : AppShadows.bottomNav,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _navItem(
                idx: 0,
                outline: Icons.home_outlined,
                filled: Icons.home_rounded,
                label: 'Home',
              ),
              _navItem(
                idx: 1,
                outline: Icons.search_outlined,
                filled: Icons.search_rounded,
                label: 'Explore',
              ),
              _postSwapBtn(),
              _messagesItem(context),
              _navItem(
                idx: 4,
                outline: Icons.person_outline_rounded,
                filled: Icons.person_rounded,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Regular nav item ─────────────────────────────────────────────────────
  Widget _navItem({
    required int idx,
    required IconData outline,
    required IconData filled,
    required String label,
  }) {
    final active = currentIndex == idx;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(idx),
        child: ScaleTransition(
          scale: iconScales[idx],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  active ? filled : outline,
                  key: ValueKey(active),
                  size: 22,
                  color: active ? _active : _inactive,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 160),
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  color: active ? _active : _inactive,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Centre "Post Swap" FAB button — matches image (rounded square + purple)
  Widget _postSwapBtn() {
    final isActive = currentIndex == 2;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: iconScales[2],
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: isActive
                      ? LinearGradient(
                          colors: [
                            isDark
                                ? AppColors.darkPrimary
                                : AppColors.primary,
                            isDark
                                ? const Color(0xFF6D28D9)
                                : const Color(0xFF5B21B6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppShadows.fab,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 160),
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? _active : _inactive,
              ),
              child: const Text('Post Swap'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Messages item with unread badge ─────────────────────────────────────
  Widget _messagesItem(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (_, ns, __) {
        final active = currentIndex == 3;
        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(3),
            child: ScaleTransition(
              scale: iconScales[3],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  badges.Badge(
                    showBadge: ns.unreadCount > 0,
                    badgeContent: Text(
                      ns.unreadCount > 9 ? '9+' : ns.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    badgeStyle: badges.BadgeStyle(
                      badgeColor: isDark
                          ? AppColors.darkPrimary
                          : AppColors.secondary,
                      padding: const EdgeInsets.all(4),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        active
                            ? Icons.chat_bubble_rounded
                            : Icons.chat_bubble_outline_rounded,
                        key: ValueKey(active),
                        size: 25,
                        color: active ? _active : _inactive,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 160),
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                      color: active ? _active : _inactive,
                    ),
                    child: const Text('Messages'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}