import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';

/// PinSetupScreen – Allows users to create a 4-digit PIN for quick login.
/// Used during initial setup or from Settings to enable/change PIN.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final List<String> _pin = [];
  final List<String> _confirmPin = [];
  bool _isConfirming = false;
  bool _hasError = false;
  String _errorMessage = '';

  void _onKeyTap(String value) {
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });

    if (_isConfirming) {
      if (_confirmPin.length < 4) {
        setState(() => _confirmPin.add(value));
        if (_confirmPin.length == 4) {
          _verifyAndSave();
        }
      }
    } else {
      if (_pin.length < 4) {
        setState(() => _pin.add(value));
        if (_pin.length == 4) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() => _isConfirming = true);
            }
          });
        }
      }
    }
  }

  void _onDelete() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      if (_isConfirming) {
        if (_confirmPin.isNotEmpty) _confirmPin.removeLast();
      } else {
        if (_pin.isNotEmpty) _pin.removeLast();
      }
    });
  }

  Future<void> _verifyAndSave() async {
    if (_pin.join() != _confirmPin.join()) {
      setState(() {
        _hasError = true;
        _errorMessage = 'PINs don\'t match. Try again.';
        _confirmPin.clear();
      });
      return;
    }

    // Return the PIN to the caller
    if (mounted) {
      Navigator.pop(context, _pin.join());
    }
  }

  void _reset() {
    setState(() {
      _pin.clear();
      _confirmPin.clear();
      _isConfirming = false;
      _hasError = false;
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPin = _isConfirming ? _confirmPin : _pin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set PIN'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: AppTheme.neonGlow(AppTheme.primaryColor),
              ),
              child: const Icon(
                Icons.pin_rounded,
                size: 36,
                color: Colors.white,
              ),
            ).animate().scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 24),
            // Title
            Text(
              _isConfirming ? 'Confirm Your PIN' : 'Create a 4-Digit PIN',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 8),
            Text(
              _isConfirming
                  ? 'Re-enter your PIN to confirm'
                  : 'This PIN will be used for quick login',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? Colors.white.withOpacity(0.5)
                    : const Color(0xFF64748B),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
            const SizedBox(height: 32),
            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < currentPin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hasError
                        ? Colors.red
                        : isFilled
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                    border: Border.all(
                      color: _hasError
                          ? Colors.red
                          : AppTheme.primaryColor.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: isFilled && !_hasError
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),
            // Error message
            if (_hasError) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fadeIn().shake(),
            ],
            if (_isConfirming && !_hasError) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _reset,
                child: Text(
                  'Start over',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const Spacer(flex: 1),
            // Number pad
            _buildNumberPad(isDark),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad(bool isDark) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'delete'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: keys.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key.isEmpty) {
                return const SizedBox(width: 72, height: 72);
              }
              if (key == 'delete') {
                return _buildKeyButton(
                  isDark: isDark,
                  child: Icon(
                    Icons.backspace_outlined,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                    size: 24,
                  ),
                  onTap: _onDelete,
                );
              }
              return _buildKeyButton(
                isDark: isDark,
                child: Text(
                  key,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                onTap: () => _onKeyTap(key),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKeyButton({
    required bool isDark,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.1),
        ),
        child: Center(child: child),
      ),
    );
  }
}
