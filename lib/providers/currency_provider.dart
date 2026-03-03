import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/currency_helper.dart';

/// CurrencyProvider manages country/currency selection with persistence.
/// All screens read `currencySymbol` from this provider instead of hardcoding '$'.
class CurrencyProvider extends ChangeNotifier {
  static const String _countryCodeKey = 'selected_country_code';

  CurrencyInfo _currency = CurrencyHelper.defaultCurrency;

  /// The currently selected currency info.
  CurrencyInfo get currency => _currency;

  /// Shorthand for the currency symbol (e.g. '$', '₹', '€').
  String get currencySymbol => _currency.currencySymbol;

  /// Currency code (e.g. 'USD', 'INR', 'EUR').
  String get currencyCode => _currency.currencyCode;

  /// Country name (e.g. 'United States').
  String get countryName => _currency.countryName;

  /// Flag emoji (e.g. '🇺🇸').
  String get flag => _currency.flag;

  /// Initialize from saved preferences.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_countryCodeKey);
    if (savedCode != null) {
      final info = CurrencyHelper.getByCountryCode(savedCode);
      if (info != null) {
        _currency = info;
      }
    }
    notifyListeners();
  }

  /// Set a new country/currency selection and persist it.
  Future<void> setCountry(CurrencyInfo info) async {
    _currency = info;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_countryCodeKey, info.countryCode);
    notifyListeners();
  }

  /// Format an amount with the current currency symbol.
  String format(double amount, {int decimals = 2}) {
    return '$currencySymbol${amount.toStringAsFixed(decimals)}';
  }

  /// Format with sign (+ or -).
  String formatSigned(double amount, {int decimals = 2}) {
    final sign = amount >= 0 ? '+' : '-';
    return '$sign$currencySymbol${amount.abs().toStringAsFixed(decimals)}';
  }
}
