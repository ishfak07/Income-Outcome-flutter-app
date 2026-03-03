import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/auth_provider.dart';
import '../providers/income_provider.dart';
import '../providers/currency_provider.dart';
import '../models/income_model.dart';
import '../utils/app_theme.dart';
import '../utils/validators.dart';
import '../widgets/animated_button.dart';
import '../widgets/income_card.dart';

/// AddIncomeScreen - Form to add a new income with amount, category,
/// description, date, time, payment method, and recurring settings.
class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = IncomeModel.categories.first;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedPaymentMethod = IncomeModel.paymentMethods.first;
  bool _isRecurring = false;
  String _selectedFrequency = IncomeModel.recurringFrequencies[2]; // Monthly

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
    if (date != null) {
      setState(() => _selectedDate = date);
    }
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
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  DateTime? _calculateNextRecurringDate() {
    if (!_isRecurring) return null;
    switch (_selectedFrequency.toLowerCase()) {
      case 'weekly':
        return _selectedDate.add(const Duration(days: 7));
      case 'bi-weekly':
        return _selectedDate.add(const Duration(days: 14));
      case 'monthly':
        return DateTime(
            _selectedDate.year, _selectedDate.month + 1, _selectedDate.day);
      case 'quarterly':
        return DateTime(
            _selectedDate.year, _selectedDate.month + 3, _selectedDate.day);
      case 'yearly':
        return DateTime(
            _selectedDate.year + 1, _selectedDate.month, _selectedDate.day);
      default:
        return DateTime(
            _selectedDate.year, _selectedDate.month + 1, _selectedDate.day);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final incomeProvider = context.read<IncomeProvider>();
    final uid = authProvider.currentUid;

    if (uid == null) return;

    final income = IncomeModel(
      id: const Uuid().v4(),
      userId: uid,
      amount: double.parse(_amountController.text.trim()),
      category: _selectedCategory,
      description: _descriptionController.text.trim(),
      date: _selectedDate,
      time:
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
      paymentMethod: _selectedPaymentMethod,
      isRecurring: _isRecurring,
      recurringFrequency: _isRecurring ? _selectedFrequency : null,
      nextRecurringDate: _calculateNextRecurringDate(),
      createdAt: DateTime.now(),
    );

    final success = await incomeProvider.addIncome(income);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Income added successfully!'),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Income'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
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
                // ─── AMOUNT INPUT ─────────────────────────────────────
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
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 24),

                // ─── CATEGORY SELECTOR ────────────────────────────────
                _buildSectionLabel('Category', isDark),
                const SizedBox(height: 12),
                _buildCategorySelector(isDark),
                const SizedBox(height: 24),

                // ─── DESCRIPTION ──────────────────────────────────────
                _buildSectionLabel('Description', isDark),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  validator: Validators.validateDescription,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'What is this income for?',
                  ),
                )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 200.ms)
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 24),

                // ─── PAYMENT METHOD ───────────────────────────────────
                _buildSectionLabel('Payment Method', isDark),
                const SizedBox(height: 12),
                _buildPaymentMethodSelector(isDark),
                const SizedBox(height: 24),

                // ─── DATE & TIME ──────────────────────────────────────
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
                )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 300.ms)
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 24),

                // ─── RECURRING TOGGLE ─────────────────────────────────
                _buildRecurringSection(isDark),
                const SizedBox(height: 40),

                // ─── SUBMIT BUTTON ────────────────────────────────────
                Consumer<IncomeProvider>(
                  builder: (context, provider, _) {
                    return AnimatedGradientButton(
                      text: 'Add Income',
                      icon: Icons.add_rounded,
                      isLoading: provider.isLoading,
                      onPressed: _handleSubmit,
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
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: 100.ms)
        .slideY(begin: 0.1, end: 0);
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
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: 250.ms)
        .slideY(begin: 0.1, end: 0);
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
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: 350.ms)
        .slideY(begin: 0.1, end: 0);
  }
}

// ─── DATE/TIME CARD WIDGET ──────────────────────────────────────────

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
