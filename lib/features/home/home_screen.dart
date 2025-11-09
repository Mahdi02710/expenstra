import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/half_icon.dart';
import '../timeline/timeline_screen.dart';
import '../wallets/wallets_screen.dart';
import '../budgets/budgets_screen.dart';
import '../activity/activity_screen.dart';
import '../more/more_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _bottomNavAnimationController;

  final List<Map<String, dynamic>> _tabs = [
    {
      'icon': Icons.timeline,
      'label': 'Timeline',
      'screen': const TimelineScreen(),
    },
    {
      'icon': Icons.account_balance_wallet,
      'label': 'Wallets',
      'screen': const WalletsScreen(),
    },
    {
      'icon': Icons.track_changes,
      'label': 'Budgets',
      'screen': const BudgetsScreen(),
    },
    {
      'icon': Icons.analytics,
      'label': 'Activity',
      'screen': const ActivityScreen(),
    },
    {'icon': Icons.more_horiz, 'label': 'More', 'screen': const MoreScreen()},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _bottomNavAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bottomNavAnimationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );

      // Trigger animation for visual feedback
      _bottomNavAnimationController.forward().then((_) {
        _bottomNavAnimationController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _tabs.map((tab) => tab['screen'] as Widget).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _tabs.asMap().entries.map((entry) {
                final index = entry.key;
                final tab = entry.value;
                final isActive = _currentIndex == index;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onTabTapped(index),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Custom half icon with animation
                          HalfIcon(
                            icon: tab['icon'] as IconData,
                            isActive: isActive,
                            size: 24.0,
                            animationDuration: const Duration(
                              milliseconds: 300,
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Tab label
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isActive
                                  ? (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.gold
                                        : AppColors.primary)
                                  : AppColors.textMuted,
                            ),
                            child: Text(
                              tab['label'] as String,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Active indicator
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isActive ? 20 : 0,
                            height: 2,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.gold
                                        : AppColors.primary)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
