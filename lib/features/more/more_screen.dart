import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'More',
                      style: AppTextStyles.h1.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Settings and additional features',
                      style: AppTextStyles.body2,
                    ),
                  ],
                ),
              ),

              // Profile section
              _buildProfileSection(),
              
              const SizedBox(height: 24),
              
              // Settings sections
              _buildSettingsSection('Account', [
                _SettingsItem(
                  icon: Icons.person_outline,
                  title: 'Profile Settings',
                  subtitle: 'Update your personal information',
                  onTap: () => _showComingSoon(context, 'Profile Settings'),
                ),
                _SettingsItem(
                  icon: Icons.security,
                  title: 'Security & Privacy',
                  subtitle: 'Password, biometrics, and data settings',
                  onTap: () => _showComingSoon(context, 'Security Settings'),
                ),
                _SettingsItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Manage your notification preferences',
                  onTap: () => _showComingSoon(context, 'Notification Settings'),
                ),
              ]),
              
              const SizedBox(height: 24),
              
              _buildSettingsSection('Preferences', [
                _SettingsItem(
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                  subtitle: 'Theme, colors, and display options',
                  onTap: () => _showThemeSelector(context),
                ),
                _SettingsItem(
                  icon: Icons.language,
                  title: 'Language & Region',
                  subtitle: 'Change app language and currency',
                  onTap: () => _showComingSoon(context, 'Language Settings'),
                ),
                _SettingsItem(
                  icon: Icons.backup_outlined,
                  title: 'Backup & Sync',
                  subtitle: 'Cloud backup and device sync',
                  onTap: () => _showComingSoon(context, 'Backup Settings'),
                ),
              ]),
              
              const SizedBox(height: 24),
              
              _buildSettingsSection('Features', [
                _SettingsItem(
                  icon: Icons.category_outlined,
                  title: 'Categories',
                  subtitle: 'Manage transaction categories',
                  onTap: () => _showComingSoon(context, 'Category Management'),
                ),
                _SettingsItem(
                  icon: Icons.import_export,
                  title: 'Import & Export',
                  subtitle: 'Import/export your financial data',
                  onTap: () => _showComingSoon(context, 'Data Import/Export'),
                ),
                _SettingsItem(
                  icon: Icons.schedule,
                  title: 'Recurring Transactions',
                  subtitle: 'Set up automatic transactions',
                  onTap: () => _showComingSoon(context, 'Recurring Transactions'),
                ),
              ]),
              
              const SizedBox(height: 24),
              
              _buildSettingsSection('Support', [
                _SettingsItem(
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  subtitle: 'FAQs and support articles',
                  onTap: () => _showComingSoon(context, 'Help Center'),
                ),
                _SettingsItem(
                  icon: Icons.feedback_outlined,
                  title: 'Send Feedback',
                  subtitle: 'Help us improve ExpensTra',
                  onTap: () => _showComingSoon(context, 'Feedback'),
                ),
                _SettingsItem(
                  icon: Icons.info_outline,
                  title: 'About ExpensTra',
                  subtitle: 'Version info and legal documents',
                  onTap: () => _showAboutDialog(context),
                ),
              ]),
              
              // Bottom padding for navigation bar
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.goldGradient : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.gold : AppColors.primary).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 30,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Profile info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back!',
                  style: AppTextStyles.h4.copyWith(
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  'Manage your ExpensTra account',
                  style: AppTextStyles.body2.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          
          // Settings button
          IconButton(
            onPressed: () => _showComingSoon(context, 'Profile Settings'),
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<_SettingsItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            title,
            style: AppTextStyles.h4.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;
              
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.gold
                            : AppColors.primary).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.gold
                            : AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: AppTextStyles.subtitle1,
                    ),
                    subtitle: Text(
                      item.subtitle,
                      style: AppTextStyles.body2,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      size: 20,
                    ),
                    onTap: item.onTap,
                  ),
                  
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 72,
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

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Coming Soon'),
        content: Text('$feature will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showThemeSelector(BuildContext context) {
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
            Text(
              'Choose Theme',
              style: AppTextStyles.h3,
            ),
            
            const SizedBox(height: 24),
            
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('System Default'),
              onTap: () => Navigator.pop(context),
            ),
            
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Light Mode'),
              onTap: () => Navigator.pop(context),
            ),
            
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark Mode'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'ExpensTra',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.account_balance_wallet,
          color: Colors.white,
          size: 30,
        ),
      ),
      children: [
        const Text('A beautiful and intuitive expense tracking app to help you manage your finances.'),
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