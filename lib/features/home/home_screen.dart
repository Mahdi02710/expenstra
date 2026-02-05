import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
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
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutQuart,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double tabWidth = (screenWidth - 32) / _tabs.length;

    final activeColor = Theme.of(context).brightness == Brightness.dark
        ? AppColors.gold
        : AppColors.primary;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: _tabs.map((tab) => tab['screen'] as Widget).toList(),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: bottomPadding > 0 ? bottomPadding : 8,
          top: 12, // Increased top padding for the indicator
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Sliding Top Indicator (Replaces the vertical line)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack, // Sits nicely with a tiny bounce
              left: _currentIndex * tabWidth + (tabWidth * 0.25),
              top: -12, // Align to the very top of the bar
              child: Container(
                width: tabWidth * 0.5,
                height: 3,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),

            // 2. Navigation Items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _tabs.asMap().entries.map((entry) {
                final index = entry.key;
                final tab = entry.value;
                final isActive = _currentIndex == index;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onTabTapped(index),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated Scale and Color for the Icon
                        AnimatedScale(
                          scale: isActive ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            tab['icon'] as IconData,
                            size: 24,
                            color: isActive ? activeColor : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Animated Text Color
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Inter', // Or your default font
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isActive ? activeColor : AppColors.textMuted,
                          ),
                          child: Text(tab['label'] as String),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
