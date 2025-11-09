import 'package:flutter/material.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'More',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00033a),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFd2ab17).withOpacity(0.1),
                    border: Border.all(
                      color: const Color(0xFFd2ab17).withOpacity(0.2),
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'v2.1.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFd2ab17),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF163473).withOpacity(0.05),
                    const Color(0xFF162647).withOpacity(0.05),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                border: Border.all(
                  color: const Color(0xFF163473).withOpacity(0.2),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF163473),
                          Color(0xFF162647),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Center(
                      child: Text(
                        'JD',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'John Doe',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF00033a),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'john.doe@email.com',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6b7280),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                border: Border.all(
                                  color: Colors.green[200]!,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Premium',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF162647).withOpacity(0.2),
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Member since 2023',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6b7280),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings Sections
            _SettingsSection(
              title: 'Account',
              items: [
                _SettingsItem(
                  icon: Icons.person_outline,
                  title: 'Profile Settings',
                  subtitle: 'Update your personal information',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.security,
                  title: 'Security',
                  subtitle: 'Password, PIN, biometric settings',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Manage your notification preferences',
                  onTap: () {},
                ),
              ],
            ),

            _SettingsSection(
              title: 'Financial',
              items: [
                _SettingsItem(
                  icon: Icons.import_export,
                  title: 'Export Data',
                  subtitle: 'Download your financial data',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.sync,
                  title: 'Bank Sync',
                  subtitle: 'Connect and sync bank accounts',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.category_outlined,
                  title: 'Categories',
                  subtitle: 'Manage expense categories',
                  onTap: () {},
                ),
              ],
            ),

            _SettingsSection(
              title: 'App',
              items: [
                _SettingsItem(
                  icon: Icons.palette_outlined,
                  title: 'Theme',
                  subtitle: 'Light, dark, or system theme',
                  trailing: const Text(
                    'Light',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6b7280),
                    ),
                  ),
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.language,
                  title: 'Language',
                  subtitle: 'Choose your preferred language',
                  trailing: const Text(
                    'English',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6b7280),
                    ),
                  ),
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.currency_exchange,
                  title: 'Currency',
                  subtitle: 'Set your default currency',
                  trailing: const Text(
                    'USD',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6b7280),
                    ),
                  ),
                  onTap: () {},
                ),
              ],
            ),

            _SettingsSection(
              title: 'Support',
              items: [
                _SettingsItem(
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  subtitle: 'Get answers to common questions',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.chat_outlined,
                  title: 'Contact Support',
                  subtitle: 'Reach out to our support team',
                  onTap: () {},
                ),
                _SettingsItem(
                  icon: Icons.star_outline,
                  title: 'Rate ExpensTra',
                  subtitle: 'Share your experience with others',
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 24),

            // App Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 32,
                    color: const Color(0xFFd2ab17),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ExpensTra',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF00033a),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Personal Expense Tracker',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6b7280),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Made with ❤️ for better financial management',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6b7280),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '© 2024 ExpensTra. All rights reserved.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6b7280),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80), // Bottom navigation space
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6b7280),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: const Color(0xFF162647).withOpacity(0.1),
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
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
                  item,
                  if (!isLast)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFf1f5f9),
                      indent: 56,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF163473).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: const Color(0xFF163473),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF00033a),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6b7280),
                    ),
                  ),
                ],
              ),
            ),

            trailing ??
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: const Color(0xFF6b7280),
                ),
          ],
        ),
      ),
    );
  }
}