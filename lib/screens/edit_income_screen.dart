import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/income_provider.dart';
import '../providers/currency_provider.dart';
import '../models/income_model.dart';
import '../utils/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/animated_button.dart';
import '../widgets/income_card.dart';

/// EditIncomeScreen - Pre-filled form for editing an existing income.
class EditIncomeScreen extends StatefulWidget {
  const EditIncomeScreen({super.key});

  @override
  State<EditIncomeScreen> createState() => _EditIncomeScreenState();
}

class _EditIncomeScreenState extends State<EditIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  late String _selectedCategory;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _selectedPaymentMethod;
  late bool _isRecurring;
  late String _selectedFrequency;
  IncomeModel? _income;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final income = ModalRoute.of(context)?.settings.arguments as IncomeModel?;
      if (income != null) {
        _income = income;
        _amountController.text = income.amount.toStringAsFixed(2);
        _descriptionController.text = income.description;
        _selectedCategory = income.category;
        _selectedDate = income.date;
        final timeParts = income.time.split(':');
        _selectedTime = TimeOfDay(
          hour: int.tryParse(timeParts[0]) ?? 0,
          minute: int.tryParse(timeParts.length > 1 ? timeParts[1] : '0') ?? 0,
        );
        _selectedPaymentMethod = income.paymentMethod;
        _isRecurring = income.isRecurring;
        _selectedFrequency =
            income.recurringFrequency ?? IncomeModel.recurringFrequencies[2];
      } else {
        _selectedCategory = IncomeModel.categories.first;
        _selectedDate = DateTime.now();
        _selectedTime = TimeOfDay.now();
        _selectedPaymentMethod = IncomeModel.paymentMethods.first;
        _isRecurring = false;
        _selectedFrequency = IncomeModel.recurringFrequencies[2];
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.accentGreen,
                ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.accentGreen,
                ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate() || _income == null) return;

    final incomeProvider = context.read<IncomeProvider>();

    DateTime? nextRecurring;
    if (_isRecurring) {
      switch (_selectedFrequency.toLowerCase()) {
        case 'weekly':
          nextRecurring = _selectedDate.add(const Duration(days: 7));
          break;
        case 'bi-weekly':
          nextRecurring = _selectedDate.add(const Duration(days: 14));
          break;
        case 'monthly':
          nextRecurring = DateTime(
              _selectedDate.year, _selectedDate.month + 1, _selectedDate.day);
          break;
        case 'quarterly':
          nextRecurring = DateTime(
              _selectedDate.year, _selectedDate.month + 3, _selectedDate.day);
          break;
        case 'yearly':
          nextRecurring = DateTime(
              _selectedDate.year + 1, _selectedDate.month, _selectedDate.day);
          break;
      }
    }

    final updated = _income!.copyWith(
      amount: double.parse(_amountController.text.trim()),
      category: _selectedCategory,
      description: _descriptionController.text.trim(),
      date: _selectedDate,
      time:
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
      paymentMethod: _selectedPaymentMethod,
      isRecurring: _isRecurring,
      recurringFrequency: _isRecurring ? _selectedFrequency : null,
      nextRecurringDate: nextRecurring,
    );

    final success = await incomeProvider.updateIncome(updated);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Income updated successfully!'),
            ],
          ),
          backgroundColor: AppTheme.accentGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleDelete() async {
    if (_income == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Income'),
        content:
            const Text('Are you sure you want to delete this income entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = context.read<AuthProvider>();
      final incomeProvider = context.read<IncomeProvider>();
      final uid = authProvider.currentUid;
      if (uid != null) {
        await incomeProvider.deleteIncome(uid, _income!.id);
        if (mounted) Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Income'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _handleDelete,
            icon: const Icon(Icons.delete_rounded, color: Colors.red),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('Amount', isDark),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: Validators.validateAmount,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    prefixText:
                        '${context.watch<CurrencyProvider>().currencySymbol} ',
                    prefixStyle: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionLabel('Category', isDark),
                const SizedBox(height: 12),
                _buildCategorySelector(isDark),
                const SizedBox(height: 24),
                _buildSectionLabel('Description', isDark),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  validator: Validators.validateDescription,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'What is this income for?',
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionLabel('Payment Method', isDark),
                const SizedBox(height: 12),
                _buildPaymentMethodSelector(isDark),
                const SizedBox(height: 24),
                _buildSectionLabel('Date & Time', isDark),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DateTimeCard(
                        label: DateFormat('MMM dd, yyyy').format(_selectedDate),
                        icon: Icons.calendar_today_rounded,
                        onTap: _pickDate,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateTimeCard(
                        label: _selectedTime.format(context),
                        icon: Icons.access_time_rounded,
                        onTap: _pickTime,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildRecurringSection(isDark),
                const SizedBox(height: 40),
                Consumer<IncomeProvider>(
                  builder: (context, provider, _) {
                    return AnimatedGradientButton(
                      text: 'Update Income',
                      icon: Icons.check_rounded,
                      isLoading: provider.isLoading,
                      onPressed: _handleUpdate,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E676), Color(0xFF00C853)],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white70 : const Color(0xFF475569),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildCategorySelector(bool isDark) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: IncomeModel.categories.map((category) {
        final isSelected = _selectedCategory == category;
        final color =
            IncomeCard.incomeCategoryColors[category] ?? AppTheme.accentGreen;
        final icon = IncomeModel.categoryIcons[category] ?? '📦';

        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? color.withOpacity(0.2)
                  : (isDark
                      ? Colors.white.withOpacity(0.05)
                      : const Color(0xFFF1F5F9)),
              border: Border.all(
                color: isSelected
                    ? color
                    : (isDark
                        ? Colors.white.withOpacity(0.1)
                        : const Color(0xFFE2E8F0)),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? color
                        : (isDark ? Colors.white70 : const Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentMethodSelector(bool isDark) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: IncomeModel.paymentMethods.map((method) {
        final isSelected = _selectedPaymentMethod == method;
        return GestureDetector(
          onTap: () => setState(() => _selectedPaymentMethod = method),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? AppTheme.accentGreen.withOpacity(0.2)
                  : (isDark
                      ? Colors.white.withOpacity(0.05)
                      : const Color(0xFFF1F5F9)),
              border: Border.all(
                color: isSelected
                    ? AppTheme.accentGreen
                    : (isDark
                        ? Colors.white.withOpacity(0.1)
                        : const Color(0xFFE2E8F0)),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              method,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? AppTheme.accentGreen
                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecurringSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFF1F5F9),
            border: Border.all(
              color: _isRecurring
                  ? AppTheme.accentGreen
                  : (isDark
                      ? Colors.white.withOpacity(0.1)
                      : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.repeat_rounded,
                  color: _isRecurring
                      ? AppTheme.accentGreen
                      : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                  size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Recurring Income',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
              Switch(
                value: _isRecurring,
                onChanged: (value) => setState(() => _isRecurring = value),
                activeColor: AppTheme.accentGreen,
              ),
            ],
          ),
        ),
        if (_isRecurring) ...[
          const SizedBox(height: 12),
          _buildSectionLabel('Frequency', isDark),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: IncomeModel.recurringFrequencies.map((frequency) {
              final isSelected = _selectedFrequency == frequency;
              return GestureDetector(
                onTap: () => setState(() => _selectedFrequency = frequency),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? AppTheme.accentGreen.withOpacity(0.2)
                        : (isDark
                            ? Colors.white.withOpacity(0.05)
                            : const Color(0xFFF1F5F9)),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.accentGreen
                          : (isDark
                              ? Colors.white.withOpacity(0.1)
                              : const Color(0xFFE2E8F0)),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    frequency,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? AppTheme.accentGreen
                          : (isDark ? Colors.white70 : const Color(0xFF475569)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _DateTimeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _DateTimeCard({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color:
              isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.accentGreen),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
