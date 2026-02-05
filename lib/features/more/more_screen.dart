// ignore_for_file: use_build_context_synchronously

import 'package:expensetra/core/theme/app_colors.dart';
import 'package:expensetra/core/theme/app_text_styles.dart';
import 'package:expensetra/data/models/wallet.dart';
import 'package:expensetra/data/services/auth_service.dart';
import 'package:expensetra/data/services/unified_data_service.dart';
import 'package:expensetra/data/services/notification_service.dart';
import 'package:expensetra/data/services/settings_service.dart';
import 'package:expensetra/data/services/session_service.dart';
import 'package:expensetra/data/services/sync_service.dart';
import 'package:expensetra/data/services/category_service.dart';
import 'package:expensetra/data/services/admin_service.dart';
import 'package:expensetra/features/admin/admin_screen.dart';
import 'package:expensetra/login_page/login_page.dart';
import 'package:expensetra/shared/utils/app_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expensetra/data/models/recurring_payment.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final UnifiedDataService _unifiedService = UnifiedDataService();
  final SettingsService _settingsService = SettingsService();
  final NotificationService _notificationService = NotificationService();
  final SessionService _sessionService = SessionService();
  final SyncService _syncService = SyncService();
  final CategoryService _categoryService = CategoryService();
  final AdminService _adminService = AdminService();

  AnimationController? _headerAnimationController;
  AnimationController? _cardAnimationController;
  AnimationController? _floatingAnimationController;

  Animation<double>? _headerAnimation;
  Animation<double>? _cardAnimation;
  Animation<double>? _floatingAnimation;

  ThemeMode _currentThemeMode = ThemeMode.system;
  late Future<bool> _isAdminFuture;

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
    _currentThemeMode = _settingsService.themeMode.value;
    _isAdminFuture = _adminService.isAdmin();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
        await _unifiedService.clearLocalData();
        await _syncService.resetSyncState();
        await _sessionService.setGuestMode(false);
        await _authService.signOut();
        if (mounted) {
          showAppSnackBar(
            context,
            'Signed out successfully',
            backgroundColor: AppColors.success,
          );
        }
      } catch (e) {
        if (mounted) {
          showAppSnackBar(
            context,
            'Error signing out: ${e.toString()}',
            backgroundColor: AppColors.error,
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
                        child: _buildAccountSection(isDark, user),
                      )
                    : _buildAccountSection(isDark, user),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Preferences Section
              SliverToBoxAdapter(
                child: _cardAnimation != null
                    ? FadeTransition(
                        opacity: _cardAnimation!,
                        child: _buildSettingsSection('Preferences', [
                          _SettingsItem(
                            icon: Icons.palette_outlined,
                            title: 'Appearance',
                            subtitle: 'Theme, colors, and display options',
                            onTap: () => _showThemeSelector(isDark),
                          ),
                          _SettingsItem(
                            icon: Icons.language,
                            title: 'Language & Region',
                            subtitle: 'Currency and exchange rates',
                            onTap: () => _showCurrencySettings(isDark),
                          ),
                          _SettingsItem(
                            icon: Icons.backup_outlined,
                            title: 'Backup & Sync',
                            subtitle: 'Manual backup and sync',
                            onTap: () => _showBackupAndSync(isDark),
                          ),
                        ], isDark),
                      )
                    : _buildSettingsSection('Preferences', [
                        _SettingsItem(
                          icon: Icons.palette_outlined,
                          title: 'Appearance',
                          subtitle: 'Theme, colors, and display options',
                          onTap: () => _showThemeSelector(isDark),
                        ),
                        _SettingsItem(
                          icon: Icons.language,
                          title: 'Language & Region',
                          subtitle: 'Currency and exchange rates',
                          onTap: () => _showCurrencySettings(isDark),
                        ),
                        _SettingsItem(
                          icon: Icons.backup_outlined,
                          title: 'Backup & Sync',
                          subtitle: 'Manual backup and sync',
                          onTap: () => _showBackupAndSync(isDark),
                        ),
                      ], isDark),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Features Section
              SliverToBoxAdapter(
                child: _cardAnimation != null
                    ? FadeTransition(
                        opacity: _cardAnimation!,
                        child: _buildSettingsSection('Features', [
                          _SettingsItem(
                            icon: Icons.category_outlined,
                            title: 'Categories',
                            subtitle: 'Manage transaction categories',
                            onTap: () => _showCategoryManager(isDark),
                          ),
                          _SettingsItem(
                            icon: Icons.import_export,
                            title: 'Import & Export',
                            subtitle: 'Import/export your financial data',
                            onTap: () => _showComingSoon('Data Import/Export'),
                          ),
                          _SettingsItem(
                            icon: Icons.schedule,
                            title: 'Reccuring Payments',
                            subtitle: 'Add Periodic Payments',
                            onTap: () => _showRecurringPayments(isDark),
                          ),
                        ], isDark),
                      )
                    : _buildSettingsSection('Features', [
                        _SettingsItem(
                          icon: Icons.category_outlined,
                          title: 'Categories',
                          subtitle: 'Manage transaction categories',
                          onTap: () => _showCategoryManager(isDark),
                        ),
                        _SettingsItem(
                          icon: Icons.import_export,
                          title: 'Import & Export',
                          subtitle: 'Import/export your financial data',
                          onTap: () => _showComingSoon('Data Import/Export'),
                        ),
                        _SettingsItem(
                          icon: Icons.schedule,
                          title: 'Reccuring Payments',
                          subtitle: 'Add Periodic Payments',
                          onTap: () => _showRecurringPayments(isDark),
                        ),
                      ], isDark),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Support Section
              SliverToBoxAdapter(
                child: _cardAnimation != null
                    ? FadeTransition(
                        opacity: _cardAnimation!,
                        child: _buildSettingsSection('Support', [
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
                        ], isDark),
                      )
                    : _buildSettingsSection('Support', [
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
                      ], isDark),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Logout Button
              SliverToBoxAdapter(
                child: _cardAnimation != null
                    ? FadeTransition(
                        opacity: _cardAnimation!,
                        child: _buildAuthAction(user, isDark),
                      )
                    : _buildAuthAction(user, isDark),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(User? user, bool isDark) {
    return ValueListenableBuilder<bool>(
      valueListenable: _sessionService.isGuestMode,
      builder: (context, isGuest, _) {
        final headerWidget = Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: isDark
                ? AppColors.goldGradient
                : AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (isDark ? AppColors.gold : AppColors.primary).withValues(
                  alpha: 0.3,
                ),
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
                    : const Icon(Icons.person, color: Colors.white, size: 35),
              ),

              const SizedBox(width: 16),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ??
                          (isGuest ? 'Guest Mode' : 'Welcome Back!'),
                      style: AppTextStyles.h3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      user?.email ??
                          (isGuest ? 'Local-only data' : 'Not signed in'),
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
      },
    );
  }

  Widget _buildQuickStats(bool isDark) {
    return StreamBuilder(
      stream: _unifiedService.getTransactions(),
      builder: (context, transactionsSnapshot) {
        return StreamBuilder(
          stream: _unifiedService.getWallets(),
          builder: (context, walletsSnapshot) {
            return StreamBuilder(
              stream: _unifiedService.getBudgets(),
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
                    border: Border.all(color: Theme.of(context).dividerColor),
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

  Widget _buildAccountSection(bool isDark, User? user) {
    return FutureBuilder<bool>(
      future: _isAdminFuture,
      builder: (context, snapshot) {
        final isAdmin = snapshot.data == true;
        final items = [
          _SettingsItem(
            icon: Icons.person_outline,
            title: 'Profile Settings',
            subtitle: user?.email ?? 'Not signed in',
            onTap: () => _showProfileSettings(user, isDark),
          ),
          _SettingsItem(
            icon: Icons.security,
            title: 'Security & Privacy',
            subtitle: 'Passcode and biometrics',
            onTap: () => _showSecuritySettings(isDark),
          ),
          _SettingsItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Reminders and budget alerts',
            onTap: () => _showNotificationSettings(isDark),
          ),
        ];

        if (isAdmin) {
          items.add(
            _SettingsItem(
              icon: Icons.admin_panel_settings,
              title: 'Admin Dashboard',
              subtitle: 'Users and system overview',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminScreen()),
                );
              },
            ),
          );
        }

        return _buildSettingsSection('Account', items, isDark);
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
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
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
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
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
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
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
                        top: index == 0
                            ? const Radius.circular(16)
                            : Radius.zero,
                        bottom: isLast
                            ? const Radius.circular(16)
                            : Radius.zero,
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
                                color:
                                    (isDark
                                            ? AppColors.gold
                                            : AppColors.primary)
                                        .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                item.icon,
                                color: isDark
                                    ? AppColors.gold
                                    : AppColors.primary,
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

  Widget _buildAuthAction(User? user, bool isDark) {
    return ValueListenableBuilder<bool>(
      valueListenable: _sessionService.isGuestMode,
      builder: (context, isGuest, _) {
        if (user != null) {
          return _buildLogoutButton(isDark);
        }
        if (isGuest) {
          return _buildLoginButton(isDark);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoginButton(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton.icon(
        onPressed: () async {
          await _sessionService.setGuestMode(false);
          if (!mounted) return;
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
        },
        icon: const Icon(Icons.login, size: 20),
        label: const Text(
          'Sign In',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.gold : AppColors.primary,
          foregroundColor: isDark ? AppColors.navy : Colors.white,
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
              trailing: user == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditDisplayName(user, isDark);
                      },
                    ),
            ),
            if (user == null) ...[
              const SizedBox(height: 8),
              Text(
                'Sign in to edit profile details.',
                style: AppTextStyles.body2.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
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

  void _showSecuritySettings(bool isDark) async {
    final existingPasscode = await _settingsService.getPasscode();
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
              'Security & Privacy',
              style: AppTextStyles.h3.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('App Passcode'),
              subtitle: Text(existingPasscode == null ? 'Not set' : 'Enabled'),
              trailing: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _promptPasscode(existingPasscode != null);
                },
                child: Text(existingPasscode == null ? 'Set' : 'Change'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.fingerprint),
              title: const Text('Biometrics'),
              subtitle: const Text('Use device biometrics to unlock'),
              trailing: Switch(
                value: _settingsService.biometricsEnabled.value,
                onChanged: (value) async {
                  await _settingsService.setBiometricsEnabled(value);
                  if (!mounted) return;
                  setState(() {});
                },
              ),
            ),
            if (existingPasscode != null)
              TextButton(
                onPressed: () async {
                  await _settingsService.setPasscode(null);
                  if (!mounted) return;
                  Navigator.pop(context);
                  showAppSnackBar(
                    context,
                    'Passcode removed',
                    backgroundColor: AppColors.success,
                  );
                },
                child: const Text('Remove Passcode'),
              ),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettings(bool isDark) {
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
              'Notifications',
              style: AppTextStyles.h3.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<bool>(
              valueListenable: _settingsService.notificationsEnabled,
              builder: (context, enabled, _) {
                return SwitchListTile(
                  title: const Text('Enable notifications'),
                  subtitle: const Text('Show reminders and alerts'),
                  value: enabled,
                  onChanged: (value) async {
                    await _settingsService.setNotificationsEnabled(value);
                    if (!value) {
                      await _notificationService.scheduleDailyReminder(
                        enabled: false,
                      );
                    }
                  },
                );
              },
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _settingsService.dailyReminderEnabled,
              builder: (context, reminderEnabled, _) {
                final notificationsEnabled =
                    _settingsService.notificationsEnabled.value;
                return SwitchListTile(
                  title: const Text('Daily reminder'),
                  subtitle: const Text('Get a daily expense check-in'),
                  value: reminderEnabled,
                  onChanged: notificationsEnabled
                      ? (value) async {
                          await _settingsService.setDailyReminderEnabled(value);
                          await _notificationService.scheduleDailyReminder(
                            enabled: value,
                          );
                        }
                      : null,
                );
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                _notificationService.showNotification(
                  'ExpensTra',
                  'This is a test notification.',
                );
              },
              child: const Text('Send test notification'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencySettings(bool isDark) {
    final rateController = TextEditingController(
      text: _settingsService.lbpRate.value.toStringAsFixed(0),
    );
    String selectedCurrency = _settingsService.defaultCurrency.value;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
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
                  'Currency & Exchange',
                  style: AppTextStyles.h3.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCurrency,
                  items: [
                    DropdownMenuItem(
                      value: 'USD',
                      child: Text('USD', style: AppTextStyles.body2),
                    ),
                    DropdownMenuItem(
                      value: 'LBP',
                      child: Text('LBP', style: AppTextStyles.body2),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setModalState(() => selectedCurrency = value);
                  },
                  style: AppTextStyles.body2.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Default currency',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: rateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'LBP per 1 USD',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final rate = double.tryParse(rateController.text.trim());
                    if (rate == null || rate <= 0) {
                      return;
                    }
                    await _settingsService.setDefaultCurrency(selectedCurrency);
                    await _settingsService.setLbpRate(rate);
                    if (!mounted) return;
                    Navigator.pop(context);
                    showAppSnackBar(
                      context,
                      'Currency settings saved',
                      backgroundColor: AppColors.success,
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showBackupAndSync(bool isDark) {
    final parentContext = context;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: Theme.of(sheetContext).scaffoldBackgroundColor,
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
              'Backup & Sync',
              style: AppTextStyles.h3.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your data stays local unless you press sync.',
              style: AppTextStyles.body2.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await _syncService.syncAll();
                if (!mounted) return;
                final navigator = Navigator.of(sheetContext);
                if (navigator.canPop()) {
                  navigator.pop();
                }
                showAppSnackBar(
                  parentContext,
                  'Sync completed',
                  backgroundColor: AppColors.success,
                );
              },
              icon: const Icon(Icons.cloud_sync),
              label: const Text('Sync Now'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryManager(bool isDark) async {
    final customCategories = await _categoryService.getCustomCategories();
    if (!mounted) return;

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
              'Custom Categories',
              style: AppTextStyles.h3.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            if (customCategories.isEmpty)
              Text(
                'No custom categories yet.',
                style: AppTextStyles.body2.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: customCategories.length,
                  itemBuilder: (context, index) {
                    final item = customCategories[index];
                    return ListTile(
                      leading: Text(
                        item.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(item.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await _categoryService.removeCustomCategory(
                            item.name,
                          );
                          if (!mounted) return;
                          Navigator.pop(context);
                          _showCategoryManager(isDark);
                        },
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                _showAddCategoryFromMore();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryFromMore() {
    final nameController = TextEditingController();
    final iconController = TextEditingController(text: '⭐');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Category name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: iconController,
              decoration: const InputDecoration(labelText: 'Icon / Emoji'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final icon = iconController.text.trim();
              if (name.isEmpty || icon.isEmpty) {
                return;
              }
              await _categoryService.addCustomCategory(
                CategoryItem(name: name, icon: icon),
              );
              if (!mounted) return;
              Navigator.pop(context);
              showAppSnackBar(
                context,
                'Category added',
                backgroundColor: AppColors.success,
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showRecurringPayments(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reccuring Payments',
                      style: AppTextStyles.h3.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<Wallet>>(
                  stream: _unifiedService.getWallets(),
                  builder: (context, walletSnapshot) {
                    final wallets = walletSnapshot.data ?? [];
                    final walletNames = {
                      for (final wallet in wallets) wallet.id: wallet.name,
                    };
                    return FutureBuilder<List<RecurringPayment>>(
                      future: _unifiedService.getRecurringPayments(),
                      builder: (context, snapshot) {
                        final payments = snapshot.data ?? [];
                        if (payments.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'No recurring payments yet.',
                              style: AppTextStyles.body2.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          );
                        }
                        return ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight:
                                MediaQuery.of(context).size.height * 0.45,
                          ),
                          child: ListView.builder(
                            itemCount: payments.length,
                            itemBuilder: (context, index) {
                              final payment = payments[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Text(
                                  payment.icon,
                                  style: const TextStyle(fontSize: 22),
                                ),
                                title: Text(payment.name),
                                subtitle: Text(
                                  '${walletNames[payment.walletId] ?? 'Wallet'} • '
                                  '${_recurrenceLabel(payment.period)} • '
                                  'Next: ${DateFormat('MMM dd, yyyy').format(payment.nextRunAt)}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    await _unifiedService
                                        .deleteRecurringPayment(payment.id);
                                    setModalState(() {});
                                  },
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _showAddRecurringPayment(isDark);
                    setModalState(() {});
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Reccuring Payment'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddRecurringPayment(bool isDark) async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final customCategories = await _categoryService.getCustomCategories();
    final categories = [
      ..._categoryService.defaultCategories,
      ...customCategories,
    ];
    CategoryItem selectedCategory = categories.isNotEmpty
        ? categories.first
        : const CategoryItem(name: 'Other', icon: '💰');
    DateTime selectedDate = DateTime.now();
    RecurrencePeriod selectedPeriod = RecurrencePeriod.monthly;
    String? selectedWalletId;

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
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
                    'Add Reccuring Payment',
                    style: AppTextStyles.h3.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Payment name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<CategoryItem>(
                    initialValue: selectedCategory,
                    items: categories
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(
                              '${item.icon} ${item.name}',
                              style: AppTextStyles.body2,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setModalState(() => selectedCategory = value);
                    },
                    style: AppTextStyles.body2.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<Wallet>>(
                    stream: _unifiedService.getWallets(),
                    builder: (context, snapshot) {
                      final wallets = snapshot.data ?? [];
                      if (wallets.isNotEmpty && selectedWalletId == null) {
                        selectedWalletId = wallets.first.id;
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: selectedWalletId,
                            items: wallets
                                .map(
                                  (wallet) => DropdownMenuItem(
                                    value: wallet.id,
                                    child: Text(
                                      '${wallet.icon} ${wallet.name}',
                                      style: AppTextStyles.body2,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: wallets.isEmpty
                                ? null
                                : (value) {
                                    if (value == null) return;
                                    setModalState(
                                      () => selectedWalletId = value,
                                    );
                                  },
                            style: AppTextStyles.body2.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Wallet',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          if (wallets.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Add a wallet to use recurring payments.',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<RecurrencePeriod>(
                    initialValue: selectedPeriod,
                    items: RecurrencePeriod.values
                        .map(
                          (period) => DropdownMenuItem(
                            value: period,
                            child: Text(
                              _recurrenceLabel(period),
                              style: AppTextStyles.body2,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setModalState(() => selectedPeriod = value);
                    },
                    style: AppTextStyles.body2.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Repeat',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('First payment date'),
                    subtitle: Text(
                      DateFormat('MMM dd, yyyy').format(selectedDate),
                    ),
                    trailing: const Icon(Icons.calendar_today, size: 18),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                      );
                      if (picked == null) return;
                      setModalState(() => selectedDate = picked);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final amount = double.tryParse(
                        amountController.text.trim(),
                      );
                      if (amount == null || amount <= 0) {
                        showAppSnackBar(
                          context,
                          'Enter a valid amount',
                          backgroundColor: AppColors.error,
                        );
                        return;
                      }
                      if (selectedWalletId == null) {
                        showAppSnackBar(
                          context,
                          'Select a wallet',
                          backgroundColor: AppColors.error,
                        );
                        return;
                      }

                      final name = nameController.text.trim().isEmpty
                          ? selectedCategory.name
                          : nameController.text.trim();
                      final payment = RecurringPayment(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        name: name,
                        amount: amount,
                        category: selectedCategory.name,
                        icon: selectedCategory.icon,
                        walletId: selectedWalletId!,
                        note: noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                        period: selectedPeriod,
                        startDate: selectedDate,
                        nextRunAt: selectedDate,
                      );
                      await _unifiedService.addRecurringPayment(payment);
                      if (!mounted) return;
                      Navigator.pop(context);
                      showAppSnackBar(
                        context,
                        'Reccuring payment added',
                        backgroundColor: AppColors.success,
                      );
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _recurrenceLabel(RecurrencePeriod period) {
    switch (period) {
      case RecurrencePeriod.daily:
        return 'Daily';
      case RecurrencePeriod.weekly:
        return 'Weekly';
      case RecurrencePeriod.monthly:
        return 'Monthly';
      case RecurrencePeriod.yearly:
        return 'Yearly';
    }
  }

  void _promptPasscode(bool hasPasscode) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(hasPasscode ? 'Change Passcode' : 'Set Passcode'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '4-digit passcode'),
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = controller.text.trim();
              if (code.length != 4) {
                return;
              }
              await _settingsService.setPasscode(code);
              if (!mounted) return;
              Navigator.pop(context);
              showAppSnackBar(
                context,
                'Passcode saved',
                backgroundColor: AppColors.success,
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditDisplayName(User user, bool isDark) {
    final controller = TextEditingController(text: user.displayName ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Display name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              await user.updateDisplayName(name.isEmpty ? null : name);
              if (!mounted) return;
              Navigator.pop(context);
              showAppSnackBar(
                context,
                'Profile updated',
                backgroundColor: AppColors.success,
              );
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
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
        _settingsService.setThemeMode(mode);
        setState(() => _currentThemeMode = mode);
        Navigator.pop(context);
        showAppSnackBar(
          context,
          'Theme updated',
          backgroundColor: AppColors.success,
        );
      },
    );
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
        child: const Center(child: Text('💰', style: TextStyle(fontSize: 30))),
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
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
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
