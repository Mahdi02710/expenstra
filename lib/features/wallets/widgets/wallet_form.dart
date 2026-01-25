import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/recurring_payment.dart';
import '../../../data/models/transaction.dart';
import '../../../data/models/wallet.dart';
import '../../../data/services/unified_data_service.dart';
<<<<<<< HEAD
import '../../../shared/utils/app_snackbar.dart';
=======
>>>>>>> edb1ca075c4910a65d856bb5f693e4b8837fb69e

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
  final _monthlyIncomeController = TextEditingController();

  late WalletType _type;
  String _selectedIcon = '💰';
  String _selectedColor = 'blue';
  bool _isMonthlyRollover = false;
  String? _rolloverTargetId;
  bool _enableMonthlyIncome = false;
  DateTime _monthlyIncomeStartDate = DateTime.now();
  String? _salaryPaymentId;
  DateTime? _salaryLastRunAt;
  DateTime? _salaryNextRunAt;
  bool _salaryDateEdited = false;
  bool _isLoadingSalary = false;

  final UnifiedDataService _unifiedService = UnifiedDataService();
  static const String _salaryMarker = '[auto:monthly_salary]';

  // Wallet type configurations
  final Map<WalletType, Map<String, dynamic>> _walletTypes = {
    WalletType.bank: {'icon': '🏦', 'color': 'blue', 'label': 'Bank Account'},
    WalletType.savings: {
      'icon': '💰',
      'color': 'green',
      'label': 'Savings Account',
    },
    WalletType.credit: {'icon': '💳', 'color': 'red', 'label': 'Credit Card'},
    WalletType.cash: {'icon': '💵', 'color': 'yellow', 'label': 'Cash'},
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
      _creditLimitController.text =
          wallet.creditLimit?.toStringAsFixed(2) ?? '';
      _initialBalanceController.text = wallet.balance.toStringAsFixed(2);
      _type = wallet.type;
      _selectedIcon = wallet.icon;
      _selectedColor = wallet.color;
      _isMonthlyRollover = wallet.isMonthlyRollover;
      _rolloverTargetId = wallet.rolloverToWalletId;
      _loadSalaryPayment(wallet.id);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    _creditLimitController.dispose();
    _initialBalanceController.dispose();
    _monthlyIncomeController.dispose();
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
                Text('Wallet Type', style: AppTextStyles.subtitle2),
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
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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
                    setState(() {
                      _isMonthlyRollover = value;
                      if (!value) {
                        _rolloverTargetId = null;
                      }
                    });
                  },
                ),

                if (_isMonthlyRollover) ...[
                  const SizedBox(height: 8),
                  StreamBuilder<List<Wallet>>(
                    stream: _unifiedService.getWallets(),
                    builder: (context, snapshot) {
                      final wallets = (snapshot.data ?? [])
                          .where((wallet) => wallet.id != widget.wallet?.id)
                          .toList();
<<<<<<< HEAD
                      final selectedValue =
                          wallets.any(
=======
                      final selectedValue = wallets.any(
>>>>>>> edb1ca075c4910a65d856bb5f693e4b8837fb69e
                            (wallet) => wallet.id == _rolloverTargetId,
                          )
                          ? _rolloverTargetId
                          : null;
                      if (wallets.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'Add another wallet to choose a rollover target.',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        );
                      }
                      return DropdownButtonFormField<String>(
<<<<<<< HEAD
                        initialValue: selectedValue,
=======
                        value: selectedValue,
>>>>>>> edb1ca075c4910a65d856bb5f693e4b8837fb69e
                        isExpanded: true,
                        items: wallets
                            .map(
                              (wallet) => DropdownMenuItem(
                                value: wallet.id,
                                child: Text(
                                  '${wallet.icon} ${wallet.name}',
                                  style: AppTextStyles.body2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _rolloverTargetId = value);
                        },
                        decoration: InputDecoration(
                          labelText: 'Rollover target wallet',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor:
                              Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkInputBackground
                              : AppColors.inputBackground,
                        ),
                      );
                    },
                  ),
                ],

                if (_isMonthlyRollover) const SizedBox(height: 8),

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

                // Monthly income (salary)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Monthly income'),
                  subtitle: const Text(
                    'Add a recurring income transaction each month',
                  ),
                  value: _enableMonthlyIncome,
                  onChanged: (value) {
                    setState(() => _enableMonthlyIncome = value);
                  },
                ),

                if (_enableMonthlyIncome) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _monthlyIncomeController,
                    decoration: InputDecoration(
                      labelText: 'Monthly income amount',
                      hintText: '0.00',
                      prefixText: '\$',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
<<<<<<< HEAD
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkInputBackground
                          : AppColors.inputBackground,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
=======
                      fillColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkInputBackground
                          : AppColors.inputBackground,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
>>>>>>> edb1ca075c4910a65d856bb5f693e4b8837fb69e
                    validator: (value) {
                      if (!_enableMonthlyIncome) return null;
                      if (value == null || value.isEmpty) {
                        return 'Please enter a monthly income amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _selectMonthlyIncomeDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
<<<<<<< HEAD
                        color: Theme.of(context).brightness == Brightness.dark
=======
                        color:
                            Theme.of(context).brightness == Brightness.dark
>>>>>>> edb1ca075c4910a65d856bb5f693e4b8837fb69e
                            ? AppColors.darkInputBackground
                            : AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 12),
                          Text(
<<<<<<< HEAD
                            DateFormat(
                              'MMM dd, yyyy',
                            ).format(_monthlyIncomeStartDate),
=======
                            DateFormat('MMM dd, yyyy')
                                .format(_monthlyIncomeStartDate),
>>>>>>> edb1ca075c4910a65d856bb5f693e4b8837fb69e
                            style: AppTextStyles.body1.copyWith(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                if (_enableMonthlyIncome) const SizedBox(height: 24),

                // Submit button
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? AppColors.gold
                        : AppColors.primary,
                    foregroundColor:
                        Theme.of(context).brightness == Brightness.dark
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
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
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

  Future<void> _loadSalaryPayment(String walletId) async {
    setState(() => _isLoadingSalary = true);
    final payments = await _unifiedService.getRecurringPayments();
    RecurringPayment? salary;
    for (final payment in payments) {
      if (payment.walletId == walletId &&
          payment.note == _salaryMarker &&
          payment.type == TransactionType.income) {
        salary = payment;
        break;
      }
    }
    if (!mounted) return;
    if (salary != null) {
      _enableMonthlyIncome = true;
      _salaryPaymentId = salary.id;
      _salaryLastRunAt = salary.lastRunAt;
      _salaryNextRunAt = salary.nextRunAt;
      _monthlyIncomeStartDate = salary.startDate;
      _monthlyIncomeController.text = salary.amount.toStringAsFixed(2);
    }
    setState(() => _isLoadingSalary = false);
  }

  Future<void> _selectMonthlyIncomeDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _monthlyIncomeStartDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _monthlyIncomeStartDate = picked;
        _salaryDateEdited = true;
      });
    }
  }

  DateTime _nextMonthlyRunDate(DateTime startDate) {
    final now = DateTime.now();
    var candidate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      startDate.hour,
      startDate.minute,
    );
    if (!candidate.isAfter(now)) {
      candidate = DateTime(
        now.year,
        now.month + 1,
        startDate.day,
        startDate.hour,
        startDate.minute,
      );
    }
    return candidate;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoadingSalary) return;
    if (_isMonthlyRollover && _rolloverTargetId == null) {
<<<<<<< HEAD
      showAppSnackBar(
        context,
        'Please select a rollover target wallet',
        backgroundColor: AppColors.warning,
=======
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rollover target wallet'),
        ),
>>>>>>> edb1ca075c4910a65d856bb5f693e4b8837fb69e
      );
      return;
    }

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
      rolloverToWalletId: _isMonthlyRollover ? _rolloverTargetId : null,
      lastRolloverAt: widget.wallet?.lastRolloverAt,
    );

    RecurringPayment? salaryPayment;
    String? salaryPaymentIdToDelete;
    final salaryPaymentExists = _salaryPaymentId != null;

    if (_enableMonthlyIncome) {
      final amount = double.parse(_monthlyIncomeController.text);
      final nextRunAt = _salaryDateEdited || _salaryNextRunAt == null
          ? _nextMonthlyRunDate(_monthlyIncomeStartDate)
          : _salaryNextRunAt!;
      salaryPayment = RecurringPayment(
<<<<<<< HEAD
        id:
            _salaryPaymentId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
=======
        id: _salaryPaymentId ?? DateTime.now().millisecondsSinceEpoch.toString(),
>>>>>>> edb1ca075c4910a65d856bb5f693e4b8837fb69e
        name: '${_nameController.text.trim()} Salary',
        amount: amount,
        type: TransactionType.income,
        category: 'Income',
        icon: '💵',
        walletId: wallet.id,
        note: _salaryMarker,
        period: RecurrencePeriod.monthly,
        startDate: _monthlyIncomeStartDate,
        nextRunAt: nextRunAt,
        lastRunAt: _salaryLastRunAt,
      );
    } else if (_salaryPaymentId != null) {
      salaryPaymentIdToDelete = _salaryPaymentId;
    }

    Navigator.of(context).pop(
      WalletFormResult(
        wallet: wallet,
        recurringPayment: salaryPayment,
        recurringPaymentExists: salaryPaymentExists,
        recurringPaymentIdToDelete: salaryPaymentIdToDelete,
      ),
    );
  }
}

class WalletFormResult {
  final Wallet wallet;
  final RecurringPayment? recurringPayment;
  final bool recurringPaymentExists;
  final String? recurringPaymentIdToDelete;

  const WalletFormResult({
    required this.wallet,
    this.recurringPayment,
    this.recurringPaymentExists = false,
    this.recurringPaymentIdToDelete,
  });
}
<<<<<<< HEAD
=======

>>>>>>> edb1ca075c4910a65d856bb5f693e4b8837fb69e
