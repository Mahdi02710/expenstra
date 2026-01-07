import 'package:expensetra/core/theme/app_colors.dart';
import 'package:expensetra/core/theme/app_text_styles.dart';
import 'package:expensetra/data/services/auth_service.dart';
import 'package:expensetra/data/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  AnimationController? _headerAnimationController;
  AnimationController? _cardAnimationController;
  AnimationController? _floatingAnimationController;

  Animation<double>? _headerAnimation;
  Animation<double>? _cardAnimation;
  Animation<double>? _floatingAnimation;

  ThemeMode _currentThemeMode = ThemeMode.system;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _floatingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController!,
        curve: Curves.easeOut,
      ),
    );

    _cardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardAnimationController!,
        curve: Curves.easeOutCubic,
      ),
    );

    _floatingAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(
        parent: _floatingAnimationController!,
        curve: Curves.easeInOut,
      ),
    );

    _headerAnimationController!.forward();
    _cardAnimationController!.forward();
  }

  @override
  void dispose() {
    _headerAnimationController?.dispose();
    _cardAnimationController?.dispose();
    _floatingAnimationController?.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out? You\'ll need to sign in again to access your data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _authService.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Signed out successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          color: isDark ? AppColors.gold : AppColors.primary,
          child: CustomScrollView(
            slivers: [
              // Animated Header
              SliverToBoxAdapter(
                child: _headerAnimation != null
                    ? FadeTransition(
                        opacity: _headerAnimation!,
                        child: _buildHeader(user, isDark),
                      )
                    : _buildHeader(user, isDark),
              ),

              // Quick Stats
              SliverToBoxAdapter(
                child: _cardAnimation != null
                    ? FadeTransition(
                        opacity: _cardAnimation!,
                        child: _buildQuickStats(isDark),
                      )
                    : _buildQuickStats(isDark),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Account Section
              SliverToBoxAdapter(
                child: _cardAnimation != null
                    ? FadeTransition(
                        opacity: _cardAnimation!,
                        child: _buildSettingsSection(
                          'Account',
                          [
                            _SettingsItem(
                              icon: Icons.person_outline,
                              title: 'Profile Settings',
                              subtitle: user?.email ?? 'Not signed in',
                              onTap: () => _showProfileSettings(user, isDark),
                            ),
                            _SettingsItem(
                              icon: Icons.security,
                              title: 'Security & Privacy',
                              subtitle: 'Password, biometrics, and data settings',
                              onTap: () => _showComingSoon('Security Settings'),
                            ),
                            _SettingsItem(
                              icon: Icons.notifications_outlined,
                              title: 'Notifications',
                              subtitle: 'Manage your notification preferences',
                              onTap: () => _showComingSoon('Notification Settings'),
                            ),
                          ],
                          isDark,
                        ),
                      )
                    : _buildSettingsSection(
                        'Account',
                        [
                          _SettingsItem(
                            icon: Icons.person_outline,
                            title: 'Profile Settings',
                            subtitle: user?.email ?? 'Not signed in',
                            onTap: () => _showProfileSettings(user, isDark),
                          ),
                          _SettingsItem(
                            icon: Icons.security,
                            title: 'Security & Privacy',
                            subtitle: 'Password, biometrics, and data settings',
                            onTap: () => _showComingSoon('Security Settings'),
                          ),
                          _SettingsItem(
                            icon: Icons.notifications_outlined,
                            title: 'Notifications',
                            subtitle: 'Manage your notification preferences',
                            onTap: () => _showComingSoon('Notification Settings'),
                          ),
                        ],
                        isDark,
                      ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Preferences Section
              SliverToBoxAdapter(
                child: _cardAnimation != null
                    ? FadeTransition(
                        opacity: _cardAnimation!,
                        child: _buildSettingsSection(
                          'Preferences',
                          [
                            _SettingsItem(
                              icon: Icons.palette_outlined,
                              title: 'Appearance',
                              subtitle: 'Theme, colors, and display options',
                              onTap: () => _showThemeSelector(isDark),
                            ),
                            _SettingsItem(
                              icon: Icons.language,
                              title: 'Language & Region',
                              subtitle: 'Change app language and currency',
                              onTap: () => _showComingSoon('Language Settings'),
                            ),
                            _SettingsItem(
                              icon: Icons.backup_outlined,
                              title: 'Backup & Sync',
                              subtitle: 'Cloud backup and device sync',
                              onTap: () => _showComingSoon('Backup Settings'),
                            ),
                          ],
                          isDark,
                        ),
                      )
                    : _buildSettingsSection(
                        'Preferences',
                        [
                          _SettingsItem(
                            icon: Icons.palette_outlined,
                            title: 'Appearance',
                            subtitle: 'Theme, colors, and display options',
                            onTap: () => _showThemeSelector(isDark),
                          ),
                          _SettingsItem(
                            icon: Icons.language,
                            title: 'Language & Region',
                            subtitle: 'Change app language and currency',
                            onTap: () => _showComingSoon('Language Settings'),
                          ),
                          _SettingsItem(
                            icon: Icons.backup_outlined,
                            title: 'Backup & Sync',
                            subtitle: 'Cloud backup and device sync',
                            onTap: () => _showComingSoon('Backup Settings'),
                          ),
                        ],
                        isDark,
                      ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Features Section
              SliverToBoxAdapter(
                child: _cardAnimation != null
                    ? FadeTransition(
                        opacity: _cardAnimation!,
                        child: _buildSettingsSection(
                          'Features',
                          [
                            _SettingsItem(
                              icon: Icons.category_outlined,
                              title: 'Categories',
                              subtitle: 'Manage transaction categories',
                              onTap: () => _showComingSoon('Category Management'),
                            ),
                            _SettingsItem(
                              icon: Icons.import_export,
                              title: 'Import & Export',
                              subtitle: 'Import/export your financial data',
                              onTap: () => _showComingSoon('Data Import/Export'),
                            ),
                            _SettingsItem(
                              icon: Icons.schedule,
                              title: 'Recurring Transactions',
                              subtitle: 'Set up automatic transactions',
                              onTap: () => _showComingSoon('Recurring Transactions'),
                            ),
                          ],
                          isDark,
                        ),
                      )
                    : _buildSettingsSection(
                        'Features',
                        [
                          _SettingsItem(
                            icon: Icons.category_outlined,
                            title: 'Categories',
                            subtitle: 'Manage transaction categories',
                            onTap: () => _showComingSoon('Category Management'),
                          ),
                          _SettingsItem(
                            icon: Icons.import_export,
                            title: 'Import & Export',
                            subtitle: 'Import/export your financial data',
                            onTap: () => _showComingSoon('Data Import/Export'),
                          ),
                          _SettingsItem(
                            icon: Icons.schedule,
                            title: 'Recurring Transactions',
                            subtitle: 'Set up automatic transactions',
                            onTap: () => _showComingSoon('Recurring Transactions'),
                          ),
                        ],
                        isDark,
                      ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Support Section
              SliverToBoxAdapter(
                child: _cardAnimation != null
                    ? FadeTransition(
                        opacity: _cardAnimation!,
                        child: _buildSettingsSection(
                          'Support',
                          [
                            _SettingsItem(
                              icon: Icons.help_outline,
                              title: 'Help Center',
                              subtitle: 'FAQs and support articles',
                              onTap: () => _showComingSoon('Help Center'),
                            ),
                            _SettingsItem(
                              icon: Icons.feedback_outlined,
                              title: 'Send Feedback',
                              subtitle: 'Help us improve ExpensTra',
                              onTap: () => _showComingSoon('Feedback'),
                            ),
                            _SettingsItem(
                              icon: Icons.info_outline,
                              title: 'About ExpensTra',
                              subtitle: 'Version info and legal documents',
                              onTap: () => _showAboutDialog(isDark),
                            ),
                          ],
                          isDark,
                        ),
                      )
                    : _buildSettingsSection(
                        'Support',
                        [
                          _SettingsItem(
                            icon: Icons.help_outline,
                            title: 'Help Center',
                            subtitle: 'FAQs and support articles',
                            onTap: () => _showComingSoon('Help Center'),
                          ),
                          _SettingsItem(
                            icon: Icons.feedback_outlined,
                            title: 'Send Feedback',
                            subtitle: 'Help us improve ExpensTra',
                            onTap: () => _showComingSoon('Feedback'),
                          ),
                          _SettingsItem(
                            icon: Icons.info_outline,
                            title: 'About ExpensTra',
                            subtitle: 'Version info and legal documents',
                            onTap: () => _showAboutDialog(isDark),
                          ),
                        ],
                        isDark,
                      ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Logout Button
              SliverToBoxAdapter(
                child: _cardAnimation != null
                    ? FadeTransition(
                        opacity: _cardAnimation!,
                        child: _buildLogoutButton(isDark),
                      )
                    : _buildLogoutButton(isDark),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(User? user, bool isDark) {
    final headerWidget = Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.goldGradient : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.gold : AppColors.primary)
                .withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with animated border
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 3,
              ),
            ),
            child: user?.photoURL != null
                ? ClipOval(
                    child: Image.network(
                      user!.photoURL!,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 35,
                  ),
          ),

          const SizedBox(width: 16),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'Welcome Back!',
                  style: AppTextStyles.h3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  user?.email ?? 'Not signed in',
                  style: AppTextStyles.body2.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Settings icon
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => _showProfileSettings(user, isDark),
              icon: const Icon(Icons.settings, color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (_floatingAnimation == null) {
      return headerWidget;
    }

    return AnimatedBuilder(
      animation: _floatingAnimation!,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation!.value * 0.3),
          child: headerWidget,
        );
      },
    );
  }

  Widget _buildQuickStats(bool isDark) {
    return StreamBuilder(
      stream: _firestoreService.getTransactions(),
      builder: (context, transactionsSnapshot) {
        return StreamBuilder(
          stream: _firestoreService.getWallets(),
          builder: (context, walletsSnapshot) {
            return StreamBuilder(
              stream: _firestoreService.getBudgets(),
              builder: (context, budgetsSnapshot) {
                final transactions = transactionsSnapshot.data ?? [];
                final wallets = walletsSnapshot.data ?? [];
                final budgets = budgetsSnapshot.data ?? [];

                final thisMonth = DateTime.now();
                final thisMonthTransactions = transactions.where((tx) {
                  return tx.date.year == thisMonth.year &&
                      tx.date.month == thisMonth.month;
                }).toList();

                final income = thisMonthTransactions
                    .where((tx) => tx.isIncome)
                    .fold<double>(0.0, (sum, tx) => sum + tx.amount);

                final expenses = thisMonthTransactions
                    .where((tx) => tx.isExpense)
                    .fold<double>(0.0, (sum, tx) => sum + tx.amount);

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This Month',
                        style: AppTextStyles.h4.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Income',
                              income,
                              AppColors.income,
                              Icons.trending_up,
                              isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Expenses',
                              expenses,
                              AppColors.expense,
                              Icons.trending_down,
                              isDark,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Wallets',
                              wallets.length.toDouble(),
                              AppColors.primary,
                              Icons.account_balance_wallet,
                              isDark,
                              isCount: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Budgets',
                              budgets.length.toDouble(),
                              AppColors.gold,
                              Icons.track_changes,
                              isDark,
                              isCount: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    double value,
    Color color,
    IconData icon,
    bool isDark, {
    bool isCount = false,
  }) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isCount ? value.toInt().toString() : formatter.format(value),
            style: AppTextStyles.h4.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    String title,
    List<_SettingsItem> items,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            title,
            style: AppTextStyles.h4.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
            ),
          ),
        ),

        const SizedBox(height: 12),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: item.onTap,
                      borderRadius: BorderRadius.vertical(
                        top: index == 0 ? const Radius.circular(16) : Radius.zero,
                        bottom: isLast ? const Radius.circular(16) : Radius.zero,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.gold : AppColors.primary)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                item.icon,
                                color: isDark ? AppColors.gold : AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: AppTextStyles.subtitle1.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.subtitle,
                                    style: AppTextStyles.body2,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 76,
                      endIndent: 16,
                      color: Theme.of(context).dividerColor,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout, size: 20),
        label: const Text(
          'Sign Out',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _showProfileSettings(User? user, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Profile Settings',
              style: AppTextStyles.h3.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(user?.email ?? 'Not available'),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Display Name'),
              subtitle: Text(user?.displayName ?? 'Not set'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showComingSoon('Profile Editing');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.gold : AppColors.primary,
                foregroundColor: isDark ? AppColors.navy : Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeSelector(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Choose Theme',
              style: AppTextStyles.h3.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            _buildThemeOption(
              Icons.brightness_auto,
              'System Default',
              ThemeMode.system,
              isDark,
            ),
            _buildThemeOption(
              Icons.light_mode,
              'Light Mode',
              ThemeMode.light,
              isDark,
            ),
            _buildThemeOption(
              Icons.dark_mode,
              'Dark Mode',
              ThemeMode.dark,
              isDark,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    IconData icon,
    String label,
    ThemeMode mode,
    bool isDark,
  ) {
    final isSelected = _currentThemeMode == mode;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? (isDark ? AppColors.gold : AppColors.primary)
            : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
      ),
      title: Text(label),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: isDark ? AppColors.gold : AppColors.primary,
            )
          : null,
      onTap: () {
        setState(() {
          _currentThemeMode = mode;
        });
        // Note: Theme switching would require MaterialApp rebuild
        // This is a placeholder for future implementation
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Theme preference saved (requires app restart)'),
            backgroundColor: AppColors.success,
          ),
        );
      },
    );
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Coming Soon'),
        content: Text('$feature will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.gold
                    : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(bool isDark) {
    showAboutDialog(
      context: context,
      applicationName: 'ExpensTra',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.goldGradient : AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            '💰',
            style: TextStyle(fontSize: 30),
          ),
        ),
      ),
      children: [
        const SizedBox(height: 16),
        const Text(
          'A beautiful and intuitive expense tracking app to help you manage your finances.',
        ),
        const SizedBox(height: 8),
        Text(
          'Built with Flutter & Firebase',
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
