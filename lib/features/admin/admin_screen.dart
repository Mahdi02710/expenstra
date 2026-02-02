import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/services/admin_service.dart';
import '../../shared/utils/app_snackbar.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AdminService _adminService = AdminService();

  late Future<AdminSummary> _summaryFuture;
  late Future<List<AdminUser>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _summaryFuture = _adminService.fetchSummary();
    _usersFuture = _adminService.fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor:
            isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_refresh);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FutureBuilder<AdminSummary>(
              future: _summaryFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final summary = snapshot.data!;
                return _buildSummary(summary, isDark);
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Users',
              style: AppTextStyles.h3.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<AdminUser>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final users = snapshot.data!;
                if (users.isEmpty) {
                  return const Text('No users found.');
                }
                return Column(
                  children: users.map((user) {
                    return Card(
                      child: ListTile(
                        title: Text(user.email ?? user.uid),
                        subtitle: Text('Role: ${user.role}'),
                        trailing: _buildStatusChip(user),
                        onTap: () => _toggleStatus(user),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(AdminSummary summary, bool isDark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: AppTextStyles.subtitle1.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Users', summary.usersCount.toString()),
            _buildSummaryRow('Transactions', summary.transactionsCount.toString()),
            _buildSummaryRow('Wallets', summary.walletsCount.toString()),
            _buildSummaryRow('Budgets', summary.budgetsCount.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body2),
          Text(value, style: AppTextStyles.subtitle2),
        ],
      ),
    );
  }

  Widget _buildStatusChip(AdminUser user) {
    final isActive = user.status == 'active';
    return Chip(
      label: Text(isActive ? 'Active' : 'Blocked'),
      backgroundColor: isActive
          ? AppColors.success.withValues(alpha: 0.15)
          : AppColors.error.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isActive ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _toggleStatus(AdminUser user) async {
    final nextStatus = user.status == 'active' ? 'blocked' : 'active';
    try {
      await _adminService.updateUserStatus(user.uid, nextStatus);
      if (!mounted) return;
      showAppSnackBar(
        context,
        'User status updated to $nextStatus',
        backgroundColor: AppColors.success,
      );
      setState(_refresh);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Failed to update status: $e',
        backgroundColor: AppColors.error,
      );
    }
  }
}
