import 'package:flutter/material.dart';
import '../data/services/data_service.dart';
import '../data/models/wallet.dart';

class WalletsScreen extends StatelessWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = DataService();
    final wallets = dataService.wallets;
    final totalBalance = dataService.getTotalBalance();

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
                  'Wallets',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00033a),
                  ),
                ),
                Icon(
                  Icons.visibility,
                  size: 18,
                  color: const Color(0xFF6b7280),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Total Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF163473).withOpacity(0.1),
                border: Border.all(
                  color: const Color(0xFF163473).withOpacity(0.2),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Balance',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6b7280),
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
                        child: Text(
                          '${wallets.length} Accounts',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFd2ab17),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${totalBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00033a),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Wallets List
            ...wallets.map(
              (wallet) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: WalletCard(wallet: wallet),
              ),
            ),

            const SizedBox(height: 16),

            // Add New Wallet Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showAddWalletDialog(context);
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add New Wallet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFd2ab17),
                  foregroundColor: const Color(0xFF00033a),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00033a),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.swap_horiz,
                    label: 'Transfer',
                    color: const Color(0xFF163473),
                    onTap: () {
                      _showTransferDialog(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.receipt_long,
                    label: 'History',
                    color: const Color(0xFF162647),
                    onTap: () {
                      _showHistoryDialog(context);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 80), // Bottom navigation space
          ],
        ),
      ),
    );
  }

  void _showAddWalletDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Wallet'),
          content: const Text(
            'Wallet creation feature will be implemented soon!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showTransferDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Transfer Money'),
          content: const Text(
            'Transfer functionality will be implemented soon!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Transaction History'),
          content: const Text(
            'History functionality will be implemented soon!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

// Top-level helper: convert simple color names (or hex strings) to Color.
Color _getColorFromString(String colorString) {
  final s = colorString.trim().toLowerCase();
  switch (s) {
    case 'blue':
      return const Color(0xFF163473);
    case 'green':
      return const Color(0xFF10B981);
    case 'red':
      return const Color(0xFFEF4444);
    case 'yellow':
      return const Color(0xFFD2AB17);
    case 'purple':
      return const Color(0xFF8B5CF6);
    default:
      final hex = s.replaceAll('#', '').replaceAll('0x', '');
      // Accept 6 (RRGGBB) or 8 (AARRGGBB) hex digits, case-insensitive
      if (RegExp(r'^[0-9a-fA-F]{6}(?:[0-9a-fA-F]{2})?$').hasMatch(hex)) {
        try {
          final value = int.parse(hex, radix: 16);
          final colorValue = hex.length == 6 ? 0xFF000000 | value : value;
          return Color(colorValue);
        } catch (_) {
          // fallthrough to default
        }
      }
      return const Color(0xFF163473);
  }
}

class WalletCard extends StatelessWidget {
  final Wallet wallet;

  const WalletCard({super.key, required this.wallet});

  @override
  Widget build(BuildContext context) {
    final isCredit = wallet.type == WalletType.credit;
    final balanceColor = isCredit
        ? (wallet.balance < 0 ? Colors.red[600] : Colors.green[600])
        : const Color(0xFF00033a);

    // Convert wallet.color string to Color object
    final Color walletColor = _getColorFromString(wallet.color);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: walletColor.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: walletColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              wallet.icon,
              style: TextStyle(fontSize: 24, color: walletColor),
            ),
          ),
          const SizedBox(width: 16),

          // Wallet details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wallet.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00033a),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  wallet.accountNumber,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6b7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getWalletTypeLabel(wallet.type),
                  style: TextStyle(
                    fontSize: 12,
                    color: walletColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Balance
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isCredit && wallet.balance < 0
                    ? '-\$${(-wallet.balance).toStringAsFixed(2)}'
                    : '\$${wallet.balance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: balanceColor,
                ),
              ),
              if (isCredit)
                Text(
                  wallet.balance < 0 ? 'Balance Due' : 'Credit Available',
                  style: TextStyle(
                    fontSize: 12,
                    color: wallet.balance < 0
                        ? Colors.red[600]
                        : Colors.green[600],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _getWalletTypeLabel(WalletType type) {
    switch (type) {
      case WalletType.bank:
        return 'Bank Account';
      case WalletType.savings:
        return 'Savings';
      case WalletType.credit:
        return 'Credit Card';
      case WalletType.cash:
        return 'Cash';
      case WalletType.investment:
        return 'Investment';
    }
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          border: Border.all(color: color.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
