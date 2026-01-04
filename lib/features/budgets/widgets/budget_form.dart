import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/budget.dart';

class BudgetForm extends StatefulWidget {
  final Budget? budget;

  const BudgetForm({super.key, this.budget});

  @override
  State<BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends State<BudgetForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();
  final _alertThresholdController = TextEditingController();

  late BudgetPeriod _period;
  String _selectedCategory = 'Food & Drink';
  String _selectedIcon = '🍽️';
  String _selectedColor = 'blue';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  // Category configurations
  final Map<String, Map<String, dynamic>> _categories = {
    'Food & Drink': {'icon': '🍽️', 'color': 'blue'},
    'Transportation': {'icon': '🚗', 'color': 'green'},
    'Shopping': {'icon': '🛍️', 'color': 'red'},
    'Housing': {'icon': '🏠', 'color': 'purple'},
    'Entertainment': {'icon': '🎬', 'color': 'orange'},
    'Health & Fitness': {'icon': '💊', 'color': 'pink'},
    'Education': {'icon': '📚', 'color': 'indigo'},
    'Bills & Utilities': {'icon': '💡', 'color': 'yellow'},
    'Other': {'icon': '💰', 'color': 'grey'},
  };

  @override
  void initState() {
    super.initState();
    _period = BudgetPeriod.monthly;

    if (widget.budget != null) {
      final budget = widget.budget!;
      _nameController.text = budget.name;
      _limitController.text = budget.limit.toStringAsFixed(2);
      _alertThresholdController.text =
          (budget.alertThreshold ?? 0.8).toStringAsFixed(2);
      _period = budget.period;
      _selectedCategory = budget.category;
      _selectedIcon = budget.icon;
      _selectedColor = budget.color;
      _startDate = budget.startDate;
      _endDate = budget.endDate;
    } else {
      // Set default dates based on period
      _updateDatesForPeriod();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    _alertThresholdController.dispose();
    super.dispose();
  }

  void _updateDatesForPeriod() {
    final now = DateTime.now();
    switch (_period) {
      case BudgetPeriod.weekly:
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = _startDate.add(const Duration(days: 7));
        break;
      case BudgetPeriod.monthly:
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case BudgetPeriod.yearly:
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31);
        break;
    }
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
                  widget.budget == null ? 'Create New Budget' : 'Edit Budget',
                  style: AppTextStyles.h2.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 24),

                // Budget Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Budget Name',
                    hintText: 'e.g., Food & Dining',
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
                      return 'Please enter a budget name';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Category
                Text('Category', style: AppTextStyles.subtitle2),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _showCategoryPicker,
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
                        Text(_selectedIcon, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedCategory,
                            style: AppTextStyles.body1.copyWith(
                              color: Theme.of(context).brightness == Brightness.dark
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

                // Period
                Text('Period', style: AppTextStyles.subtitle2),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildPeriodButton(BudgetPeriod.weekly, 'Weekly'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPeriodButton(BudgetPeriod.monthly, 'Monthly'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPeriodButton(BudgetPeriod.yearly, 'Yearly'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Budget Limit
                TextFormField(
                  controller: _limitController,
                  decoration: InputDecoration(
                    labelText: 'Budget Limit',
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
                      return 'Please enter a budget limit';
                    }
                    final limit = double.tryParse(value);
                    if (limit == null || limit <= 0) {
                      return 'Please enter a valid budget limit';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Alert Threshold
                TextFormField(
                  controller: _alertThresholdController,
                  decoration: InputDecoration(
                    labelText: 'Alert Threshold (%)',
                    hintText: '80',
                    suffixText: '%',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkInputBackground
                        : AppColors.inputBackground,
                    helperText: 'Get notified when you reach this percentage',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final threshold = double.tryParse(value);
                      if (threshold == null ||
                          threshold < 0 ||
                          threshold > 100) {
                        return 'Please enter a value between 0 and 100';
                      }
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Date Range
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(true),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Date',
                                style: AppTextStyles.caption,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM dd, yyyy').format(_startDate),
                                style: AppTextStyles.body1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(false),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'End Date',
                                style: AppTextStyles.caption,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM dd, yyyy').format(_endDate),
                                style: AppTextStyles.body1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
                    widget.budget == null ? 'Create Budget' : 'Update Budget',
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

  Widget _buildPeriodButton(BudgetPeriod period, String label) {
    final isSelected = _period == period;
    final color = Theme.of(context).brightness == Brightness.dark
        ? AppColors.gold
        : AppColors.primary;

    return InkWell(
      onTap: () {
        setState(() {
          _period = period;
          _updateDatesForPeriod();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.body2.copyWith(
              color: isSelected ? color : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _categories.entries.map((entry) {
                      final category = entry.key;
                      final config = entry.value;
                      final isSelected = _selectedCategory == category;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                            _selectedIcon = config['icon'] as String;
                            _selectedColor = config['color'] as String;
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                config['icon'] as String,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                category,
                                style: AppTextStyles.body2.copyWith(
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
                  ),
                ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).viewInsets.bottom,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate.subtract(const Duration(days: 30));
          }
        }
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final limit = double.parse(_limitController.text);
    final alertThreshold = _alertThresholdController.text.isNotEmpty
        ? double.tryParse(_alertThresholdController.text) ?? 0.8
        : 0.8;

    final budget = Budget(
      id: widget.budget?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      spent: widget.budget?.spent ?? 0.0,
      limit: limit,
      icon: _selectedIcon,
      color: _selectedColor,
      period: _period,
      category: _selectedCategory,
      startDate: _startDate,
      endDate: _endDate,
      isActive: widget.budget?.isActive ?? true,
      alertThreshold: alertThreshold / 100, // Convert percentage to decimal
      includedCategories: [_selectedCategory],
    );

    Navigator.of(context).pop(budget);
  }
}

