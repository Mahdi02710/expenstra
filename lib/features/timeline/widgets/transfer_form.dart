import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/data_service.dart';

class TransferForm extends StatefulWidget {
  const TransferForm({super.key});

  @override
  State<TransferForm> createState() => _TransferFormState();
}

class _TransferFormState extends State<TransferForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String? _fromWalletId;
  String? _toWalletId;
  final DataService _dataService = DataService();

  @override
  void initState() {
    super.initState();
    final wallets = _dataService.wallets;
    if (wallets.length >= 2) {
      _fromWalletId = wallets[0].id;
      _toWalletId = wallets[1].id;
    } else if (wallets.length == 1) {
      _fromWalletId = wallets[0].id;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallets = _dataService.wallets;

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
                    'Transfer Money',
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

            // Form fields
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // From Wallet
                    _buildWalletSelector(
                      label: 'From',
                      selectedWalletId: _fromWalletId,
                      onSelected: (id) => setState(() => _fromWalletId = id),
                      excludeWalletId: _toWalletId,
                    ),

                    const SizedBox(height: 24),

                    // Transfer icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_downward,
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // To Wallet
                    _buildWalletSelector(
                      label: 'To',
                      selectedWalletId: _toWalletId,
                      onSelected: (id) => setState(() => _toWalletId = id),
                      excludeWalletId: _fromWalletId,
                    ),

                    const SizedBox(height: 24),

                    // Amount
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: '\$ ',
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
                          return 'Please enter an amount';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid amount';
                        }
                        if (_fromWalletId != null) {
                          final fromWallet = _dataService.getWallet(_fromWalletId!);
                          if (fromWallet != null && amount > fromWallet.balance) {
                            return 'Insufficient balance';
                          }
                        }
                        return null;
                      },
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
                        fillColor: Theme.of(context).brightness == Brightness.dark
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
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Transfer',
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

  Widget _buildWalletSelector({
    required String label,
    required String? selectedWalletId,
    required Function(String) onSelected,
    String? excludeWalletId,
  }) {
    final wallets = _dataService.wallets
        .where((w) => w.id != excludeWalletId)
        .toList();

    if (wallets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Text(
          'No wallets available for $label',
          style: AppTextStyles.body2.copyWith(color: AppColors.warning),
        ),
      );
    }

    final selectedWallet = selectedWalletId != null
        ? _dataService.getWallet(selectedWalletId)
        : null;

    return InkWell(
      onTap: () => _showWalletPicker(label, onSelected, excludeWalletId),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                if (selectedWallet != null) ...[
                  Row(
                    children: [
                      Text(
                        selectedWallet.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        selectedWallet.name,
                        style: AppTextStyles.body1.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Balance: ${selectedWallet.formattedBalance}',
                    style: AppTextStyles.caption,
                  ),
                ] else
                  Text(
                    'Select wallet',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  void _showWalletPicker(
    String label,
    Function(String) onSelected,
    String? excludeWalletId,
  ) {
    final wallets = _dataService.wallets
        .where((w) => w.id != excludeWalletId)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select $label Wallet',
                style: AppTextStyles.h4.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: wallets.length,
              itemBuilder: (context, index) {
                final wallet = wallets[index];
                final isSelected = wallet.id == (label == 'From' ? _fromWalletId : _toWalletId);

                return ListTile(
                  leading: Text(wallet.icon, style: const TextStyle(fontSize: 32)),
                  title: Text(wallet.name),
                  subtitle: Text(wallet.formattedBalance),
                  trailing: isSelected
                      ? Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    onSelected(wallet.id);
                    Navigator.pop(context);
                  },
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_fromWalletId == null || _toWalletId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both wallets')),
      );
      return;
    }

    if (_fromWalletId == _toWalletId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('From and To wallets must be different')),
      );
      return;
    }

    final amount = double.parse(_amountController.text);
    final note = _noteController.text.trim();

    // Return transfer data
    Navigator.of(context).pop({
      'fromWalletId': _fromWalletId,
      'toWalletId': _toWalletId,
      'amount': amount,
      'note': note.isEmpty ? null : note,
    });
  }
}

