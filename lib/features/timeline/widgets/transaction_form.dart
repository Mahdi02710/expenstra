import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/transaction.dart';
import '../../../data/models/wallet.dart';
import '../../../data/services/category_service.dart';
import '../../../data/services/settings_service.dart';
import '../../../data/services/unified_data_service.dart';

class TransactionForm extends StatefulWidget {
  final TransactionType? initialType;
  final Transaction? transaction;

  const TransactionForm({super.key, this.initialType, this.transaction});

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _noteController = TextEditingController();

  late TransactionType _type;
  String _selectedCategory = 'Food & Drink';
  String _selectedIcon = '🍔';
  String _selectedCurrency = 'USD';
  String _selectedWalletId = '';
  DateTime _selectedDate = DateTime.now();
  final UnifiedDataService _unifiedService = UnifiedDataService();
  final CategoryService _categoryService = CategoryService();
  final SettingsService _settingsService = SettingsService();
  final List<String> _currencyOptions = ['USD', 'LBP'];

  // Common categories with icons
  List<CategoryItem> _categories = [];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? TransactionType.expense;
    _selectedCurrency = _settingsService.defaultCurrency.value;
    _loadCategories();

    // Initialize with existing transaction if editing
    if (widget.transaction != null) {
      final tx = widget.transaction!;
      _type = tx.type;
      final displayAmount = tx.originalAmount ?? tx.amount;
      _amountController.text = displayAmount.toStringAsFixed(2);
      _descriptionController.text = tx.description;
      _noteController.text = tx.note ?? '';
      _selectedCategory = tx.category;
      _selectedIcon = tx.icon;
      _selectedWalletId = tx.walletId;
      _selectedDate = tx.date;
      _selectedCurrency = tx.currencyCode;
    } else {
      // Set default wallet will be handled by StreamBuilder
      _selectedWalletId = '';
      // Set default category based on type
      if (_type == TransactionType.income) {
        _selectedCategory = 'Income';
        _selectedIcon = '💵';
      }
    }
  }

  Future<void> _loadCategories() async {
    final custom = await _categoryService.getCustomCategories();
    if (!mounted) return;
    setState(() {
      _categories = [..._categoryService.defaultCategories, ...custom];
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.transaction == null
                        ? 'Add Transaction'
                        : 'Edit Transaction',
                    style: AppTextStyles.h3.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Type selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTypeButton(TransactionType.income, 'Income'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeButton(TransactionType.expense, 'Expense'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Form fields
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Amount + Currency
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Amount',
                              prefixText:
                                  '${_currencySymbol(_selectedCurrency)} ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.darkInputBackground
                                  : AppColors.inputBackground,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an amount';
                              }
                              final amount = double.tryParse(value);
                              if (amount == null || amount <= 0) {
                                return 'Please enter a valid amount';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 110,
                          child: DropdownButtonFormField<String>(
                            value: _selectedCurrency,
                            items: _currencyOptions
                                .map(
                                  (code) => DropdownMenuItem(
                                    value: code,
                                    child: Text(code),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _selectedCurrency = value);
                            },
                            decoration: InputDecoration(
                              labelText: 'Currency',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.darkInputBackground
                                  : AppColors.inputBackground,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedCurrency == 'LBP')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Rate: 1 USD = ${_settingsService.lbpRate.value.toStringAsFixed(0)} LBP',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkInputBackground
                            : AppColors.inputBackground,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Category (only show for expenses)
                    if (_type == TransactionType.expense) ...[
                      InkWell(
                        onTap: _showCategoryPicker,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkInputBackground
                                : AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _selectedIcon,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedCategory,
                                  style: AppTextStyles.body1.copyWith(
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Wallet
                    StreamBuilder<List<Wallet>>(
                      stream: _unifiedService.getWallets(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          if (_selectedWalletId.isEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _selectedWalletId = snapshot.data!.first.id;
                                });
                              }
                            });
                          }
                          return _buildWalletSelector(snapshot.data!);
                        }
                        return _buildWalletSelector([]);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Date
                    InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
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
                              DateFormat('MMM dd, yyyy').format(_selectedDate),
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

                    const SizedBox(height: 16),

                    // Note (optional)
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: 'Note (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkInputBackground
                            : AppColors.inputBackground,
                      ),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 24),

                    // Submit button
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _type == TransactionType.income
                            ? AppColors.income
                            : AppColors.expense,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.transaction == null
                            ? 'Add Transaction'
                            : 'Update Transaction',
                        style: AppTextStyles.buttonLarge,
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(TransactionType type, String label) {
    final isSelected = _type == type;
    final color = type == TransactionType.income
        ? AppColors.income
        : AppColors.expense;

    return InkWell(
      onTap: () {
        setState(() {
          _type = type;
          // Set default category when switching types
          if (type == TransactionType.income) {
            _selectedCategory = 'Income';
            _selectedIcon = '💵';
          } else if (type == TransactionType.expense &&
              _selectedCategory == 'Income') {
            // Reset to default expense category if switching from income
            _selectedCategory = 'Food & Drink';
            _selectedIcon = '🍔';
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.subtitle1.copyWith(
              color: isSelected ? color : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletSelector(List<Wallet> wallets) {
    if (wallets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Text(
          'No wallets available. Please add a wallet first.',
          style: AppTextStyles.body2.copyWith(color: AppColors.warning),
        ),
      );
    }

    return InkWell(
      onTap: () => _showWalletPicker(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkInputBackground
              : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            StreamBuilder<List<Wallet>>(
              stream: _unifiedService.getWallets(),
              builder: (context, snapshot) {
                final wallets = snapshot.data ?? [];
                final selectedWallet = _getSelectedWallet(wallets);
                return Text(
                  selectedWallet?.icon ?? '💰',
                  style: const TextStyle(fontSize: 24),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StreamBuilder<List<Wallet>>(
                stream: _unifiedService.getWallets(),
                builder: (context, snapshot) {
                  final wallets = snapshot.data ?? [];
                  final selectedWallet = _getSelectedWallet(wallets);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedWallet?.name ?? 'Select Wallet',
                        style: AppTextStyles.body1.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (selectedWallet != null)
                        Text(
                          selectedWallet.formattedBalance,
                          style: AppTextStyles.caption,
                        ),
                    ],
                  );
                },
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Wallet? _getSelectedWallet(List<Wallet> wallets) {
    try {
      return wallets.firstWhere((w) => w.id == _selectedWalletId);
    } catch (e) {
      return null;
    }
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Select Category',
                style: AppTextStyles.h4.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: _categories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _categories.length) {
                        return InkWell(
                          onTap: () => _showAddCategoryDialog(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Add',
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final category = _categories[index];
                      final isSelected = _selectedCategory == category.name;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category.name;
                            _selectedIcon = category.icon;
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Theme.of(context).dividerColor,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                category.icon,
                                style: const TextStyle(fontSize: 32),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                category.name,
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  void _showWalletPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StreamBuilder<List<Wallet>>(
        stream: _unifiedService.getWallets(),
        builder: (context, snapshot) {
          final wallets = snapshot.data ?? [];

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Select Wallet',
                    style: AppTextStyles.h4.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (wallets.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No wallets available. Please add a wallet first.',
                      style: AppTextStyles.body2,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: wallets.length,
                    itemBuilder: (context, index) {
                      final wallet = wallets[index];
                      final isSelected = wallet.id == _selectedWalletId;

                      return ListTile(
                        leading: Text(
                          wallet.icon,
                          style: const TextStyle(fontSize: 32),
                        ),
                        title: Text(wallet.name),
                        subtitle: Text(wallet.formattedBalance),
                        trailing: isSelected
                            ? Icon(Icons.check, color: AppColors.primary)
                            : null,
                        onTap: () {
                          setState(() => _selectedWalletId = wallet.id);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _currencySymbol(String code) {
    switch (code) {
      case 'LBP':
        return 'LBP';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return '\$';
    }
  }

  double _convertToDefaultCurrency(
    double amount,
    String selected,
    String defaultCurrency,
  ) {
    if (selected == defaultCurrency) {
      return amount;
    }
    final lbpRate = _settingsService.lbpRate.value;
    if (selected == 'LBP' && defaultCurrency == 'USD') {
      return amount / lbpRate;
    }
    if (selected == 'USD' && defaultCurrency == 'LBP') {
      return amount * lbpRate;
    }
    return amount;
  }

  double? _exchangeRateForSelection(
    double amount,
    double convertedAmount,
    String selected,
    String defaultCurrency,
  ) {
    if (selected == defaultCurrency) {
      return null;
    }
    if (amount == 0) {
      return null;
    }
    return convertedAmount / amount;
  }

  Future<void> _showAddCategoryDialog() async {
    final nameController = TextEditingController();
    final iconController = TextEditingController(text: '⭐');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
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
              onPressed: () => Navigator.of(dialogContext).pop(),
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
                await _loadCategories();
                if (!mounted) return;
                setState(() {
                  _selectedCategory = name;
                  _selectedIcon = icon;
                });
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWalletId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a wallet')));
      return;
    }

    final amount = double.parse(_amountController.text);
    final defaultCurrency = _settingsService.defaultCurrency.value;
    final convertedAmount = _convertToDefaultCurrency(
      amount,
      _selectedCurrency,
      defaultCurrency,
    );
    final exchangeRate = _exchangeRateForSelection(
      amount,
      convertedAmount,
      _selectedCurrency,
      defaultCurrency,
    );
    // Use default category for income if not set
    final category = _type == TransactionType.income
        ? (_selectedCategory.isEmpty ? 'Income' : _selectedCategory)
        : _selectedCategory;
    final icon = _type == TransactionType.income
        ? (_selectedIcon.isEmpty ? '💵' : _selectedIcon)
        : _selectedIcon;

    final transaction = Transaction(
      id:
          widget.transaction?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      type: _type,
      amount: convertedAmount,
      description: _descriptionController.text.trim(),
      category: category,
      icon: icon,
      date: _selectedDate,
      walletId: _selectedWalletId,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      currencyCode: _selectedCurrency,
      originalAmount: _selectedCurrency == defaultCurrency ? null : amount,
      exchangeRate: exchangeRate,
    );

    Navigator.of(context).pop(transaction);
  }
}
