import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/wallet.dart';

class WalletForm extends StatefulWidget {
  final Wallet? wallet;
  final WalletType? initialType;

  const WalletForm({super.key, this.wallet, this.initialType});

  @override
  State<WalletForm> createState() => _WalletFormState();
}

class _WalletFormState extends State<WalletForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _initialBalanceController = TextEditingController();

  late WalletType _type;
  String _selectedIcon = '💰';
  String _selectedColor = 'blue';
  bool _isMonthlyRollover = false;

  // Wallet type configurations
  final Map<WalletType, Map<String, dynamic>> _walletTypes = {
    WalletType.bank: {
      'icon': '🏦',
      'color': 'blue',
      'label': 'Bank Account',
    },
    WalletType.savings: {
      'icon': '💰',
      'color': 'green',
      'label': 'Savings Account',
    },
    WalletType.credit: {
      'icon': '💳',
      'color': 'red',
      'label': 'Credit Card',
    },
    WalletType.cash: {
      'icon': '💵',
      'color': 'yellow',
      'label': 'Cash',
    },
    WalletType.investment: {
      'icon': '📈',
      'color': 'purple',
      'label': 'Investment',
    },
  };

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? WalletType.bank;
    _selectedIcon = _walletTypes[_type]!['icon'] as String;
    _selectedColor = _walletTypes[_type]!['color'] as String;

    // Initialize with existing wallet if editing
    if (widget.wallet != null) {
      final wallet = widget.wallet!;
      _nameController.text = wallet.name;
      _accountNumberController.text = wallet.accountNumber;
      _bankNameController.text = wallet.bankName ?? '';
      _creditLimitController.text = wallet.creditLimit?.toStringAsFixed(2) ?? '';
      _initialBalanceController.text = wallet.balance.toStringAsFixed(2);
      _type = wallet.type;
      _selectedIcon = wallet.icon;
      _selectedColor = wallet.color;
      _isMonthlyRollover = wallet.isMonthlyRollover;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    _creditLimitController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Text(
                  widget.wallet == null ? 'Add New Wallet' : 'Edit Wallet',
                  style: AppTextStyles.h2.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 24),

                // Wallet Type
                Text(
                  'Wallet Type',
                  style: AppTextStyles.subtitle2,
                ),
                const SizedBox(height: 8),
                _buildTypeSelector(),

                const SizedBox(height: 24),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Wallet Name',
                    hintText: 'e.g., Chase Checking',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkInputBackground
                        : AppColors.inputBackground,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a wallet name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Account Number
                TextFormField(
                  controller: _accountNumberController,
                  decoration: InputDecoration(
                    labelText: 'Account Number',
                    hintText: 'Last 4 digits',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkInputBackground
                        : AppColors.inputBackground,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an account number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Bank Name (optional for cash)
                if (_type != WalletType.cash)
                  TextFormField(
                    controller: _bankNameController,
                    decoration: InputDecoration(
                      labelText: 'Bank Name (optional)',
                      hintText: 'e.g., Chase Bank',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkInputBackground
                          : AppColors.inputBackground,
                    ),
                  ),

                if (_type != WalletType.cash) const SizedBox(height: 16),

                // Credit Limit (only for credit cards)
                if (_type == WalletType.credit)
                  TextFormField(
                    controller: _creditLimitController,
                    decoration: InputDecoration(
                      labelText: 'Credit Limit',
                      hintText: '0.00',
                      prefixText: '\$',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkInputBackground
                          : AppColors.inputBackground,
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final limit = double.tryParse(value);
                        if (limit == null || limit <= 0) {
                          return 'Please enter a valid credit limit';
                        }
                      }
                      return null;
                    },
                  ),

                if (_type == WalletType.credit) const SizedBox(height: 16),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Monthly rollover to savings'),
                  subtitle: const Text(
                    'Move remaining balance to a savings wallet each month',
                  ),
                  value: _isMonthlyRollover,
                  onChanged: (value) {
                    setState(() => _isMonthlyRollover = value);
                  },
                ),

                const SizedBox(height: 8),

                // Initial Balance
                TextFormField(
                  controller: _initialBalanceController,
                  decoration: InputDecoration(
                    labelText: 'Initial Balance',
                    hintText: '0.00',
                    prefixText: '\$',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkInputBackground
                        : AppColors.inputBackground,
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an initial balance';
                    }
                    final balance = double.tryParse(value);
                    if (balance == null) {
                      return 'Please enter a valid balance';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Submit button
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.gold
                        : AppColors.primary,
                    foregroundColor: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.navy
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.wallet == null ? 'Add Wallet' : 'Update Wallet',
                    style: AppTextStyles.buttonLarge,
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: WalletType.values.map((type) {
        final config = _walletTypes[type]!;
        final isSelected = _type == type;
        final color = _getColorFromString(config['color'] as String);

        return InkWell(
          onTap: () {
            setState(() {
              _type = type;
              _selectedIcon = config['icon'] as String;
              _selectedColor = config['color'] as String;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : Theme.of(context).dividerColor,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  config['icon'] as String,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  config['label'] as String,
                  style: AppTextStyles.body2.copyWith(
                    color: isSelected ? color : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue':
        return AppColors.primary;
      case 'green':
        return AppColors.income;
      case 'red':
        return AppColors.expense;
      case 'yellow':
        return AppColors.gold;
      case 'purple':
        return AppColors.secondary;
      default:
        return AppColors.primary;
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final balance = double.parse(_initialBalanceController.text);
    final creditLimit = _creditLimitController.text.isNotEmpty
        ? double.tryParse(_creditLimitController.text)
        : null;

    final wallet = Wallet(
      id: widget.wallet?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      balance: balance,
      type: _type,
      icon: _selectedIcon,
      color: _selectedColor,
      accountNumber: _accountNumberController.text.trim(),
      bankName: _bankNameController.text.trim().isEmpty
          ? null
          : _bankNameController.text.trim(),
      creditLimit: creditLimit,
      isActive: widget.wallet?.isActive ?? true,
      createdAt: widget.wallet?.createdAt ?? DateTime.now(),
      lastTransactionDate: widget.wallet?.lastTransactionDate,
      isMonthlyRollover: _isMonthlyRollover,
      rolloverToWalletId: widget.wallet?.rolloverToWalletId,
      lastRolloverAt: widget.wallet?.lastRolloverAt,
    );

    Navigator.of(context).pop(wallet);
  }
}

