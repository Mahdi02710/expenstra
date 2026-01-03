import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/wallet.dart';

class WalletGrid extends StatelessWidget {
  final List<Wallet> wallets;
  final Function(String) onWalletTap;

  const WalletGrid({
    super.key,
    required this.wallets,
    required this.onWalletTap,
  });

  @override
  Widget build(BuildContext context) {
    if (wallets.isEmpty) {
      return _buildEmptyState(context);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = 2;
          final crossAxisSpacing = 16.0;
          final mainAxisSpacing = 16.0;
          final width = (constraints.maxWidth - crossAxisSpacing) / crossAxisCount;
          final mainAxisExtent = width * 1.25; // Increased from 1.05 to 1.25 to prevent overflow

          return GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: crossAxisSpacing,
              mainAxisSpacing: mainAxisSpacing,
              mainAxisExtent: mainAxisExtent,
            ),
            itemCount: wallets.length,
            itemBuilder: (context, index) {
              return WalletCard(
                wallet: wallets[index],
                onTap: () => onWalletTap(wallets[index].id),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryWithOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text('No wallets yet', style: AppTextStyles.h4),
          const SizedBox(height: 8),
          Text(
            'Add your first wallet to start tracking your finances.',
            style: AppTextStyles.body2,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class WalletCard extends StatefulWidget {
  final Wallet wallet;
  final VoidCallback onTap;

  const WalletCard({super.key, required this.wallet, required this.onTap});

  @override
  State<WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<WalletCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: _getWalletBackgroundColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getWalletBorderColor(context),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getWalletAccentColor().withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Background gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getWalletAccentColor().withValues(alpha: 0.05),
                            _getWalletAccentColor().withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Wallet icon and status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: _getWalletAccentColor().withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  widget.wallet.icon,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                            if (!widget.wallet.isActive)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.textMuted,
                                  shape: BoxShape.circle,
                                ),
                              )
                            else if (widget.wallet.isCredit &&
                                widget.wallet.balance < 0)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.warning,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Wallet name
                        Text(
                          widget.wallet.name,
                          style: AppTextStyles.subtitle1.copyWith(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Account number
                        Text(
                          widget.wallet.maskedAccountNumber,
                          style: AppTextStyles.caption.copyWith(
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        // Balance
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.wallet.balanceStatus,
                              style: AppTextStyles.caption.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                widget.wallet.formattedBalanceWithSign,
                                style: AppTextStyles.subtitle1.copyWith(
                                  color: _getBalanceColor(),
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Credit utilization indicator
                  if (widget.wallet.isCredit &&
                      widget.wallet.creditLimit != null)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _getUtilizationColor().withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${(widget.wallet.creditUtilization * 100).toInt()}%',
                            style: AppTextStyles.caption.copyWith(
                              color: _getUtilizationColor(),
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getWalletBackgroundColor(BuildContext context) {
    return Theme.of(context).cardColor;
  }

  Color _getWalletBorderColor(BuildContext context) {
    return Theme.of(context).dividerColor;
  }

  Color _getWalletAccentColor() {
    switch (widget.wallet.type) {
      case WalletType.bank:
        return AppColors.primary;
      case WalletType.savings:
        return AppColors.income;
      case WalletType.credit:
        return AppColors.expense;
      case WalletType.cash:
        return AppColors.gold;
      case WalletType.investment:
        return AppColors.secondary;
    }
  }

  Color _getBalanceColor() {
    if (widget.wallet.isCredit) {
      return widget.wallet.balance < 0 ? AppColors.expense : AppColors.income;
    }
    return widget.wallet.balance >= 0 ? AppColors.income : AppColors.expense;
  }

  Color _getUtilizationColor() {
    final utilization = widget.wallet.creditUtilization;
    if (utilization >= 0.8) {
      return AppColors.expense;
    } else if (utilization >= 0.5) {
      return AppColors.warning;
    } else {
      return AppColors.income;
    }
  }
}
