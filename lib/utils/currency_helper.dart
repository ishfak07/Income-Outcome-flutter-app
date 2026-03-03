/// Currency helper with country-to-currency mapping.
/// Provides currency symbols, codes, and country data for the app.
class CurrencyInfo {
  final String countryCode;
  final String countryName;
  final String currencyCode;
  final String currencySymbol;
  final String flag;

  const CurrencyInfo({
    required this.countryCode,
    required this.countryName,
    required this.currencyCode,
    required this.currencySymbol,
    required this.flag,
  });

  @override
  String toString() => '$flag $countryName ($currencyCode)';
}

class CurrencyHelper {
  CurrencyHelper._();

  /// Default currency info (United States).
  static const CurrencyInfo defaultCurrency = CurrencyInfo(
    countryCode: 'US',
    countryName: 'United States',
    currencyCode: 'USD',
    currencySymbol: '\$',
    flag: '🇺🇸',
  );

  /// Complete list of countries with their currencies.
  static const List<CurrencyInfo> allCurrencies = [
    CurrencyInfo(
        countryCode: 'AF',
        countryName: 'Afghanistan',
        currencyCode: 'AFN',
        currencySymbol: '؋',
        flag: '🇦🇫'),
    CurrencyInfo(
        countryCode: 'AL',
        countryName: 'Albania',
        currencyCode: 'ALL',
        currencySymbol: 'L',
        flag: '🇦🇱'),
    CurrencyInfo(
        countryCode: 'DZ',
        countryName: 'Algeria',
        currencyCode: 'DZD',
        currencySymbol: 'د.ج',
        flag: '🇩🇿'),
    CurrencyInfo(
        countryCode: 'AR',
        countryName: 'Argentina',
        currencyCode: 'ARS',
        currencySymbol: '\$',
        flag: '🇦🇷'),
    CurrencyInfo(
        countryCode: 'AU',
        countryName: 'Australia',
        currencyCode: 'AUD',
        currencySymbol: 'A\$',
        flag: '🇦🇺'),
    CurrencyInfo(
        countryCode: 'AT',
        countryName: 'Austria',
        currencyCode: 'EUR',
        currencySymbol: '€',
        flag: '🇦🇹'),
    CurrencyInfo(
        countryCode: 'BD',
        countryName: 'Bangladesh',
        currencyCode: 'BDT',
        currencySymbol: '৳',
        flag: '🇧🇩'),
    CurrencyInfo(
        countryCode: 'BE',
        countryName: 'Belgium',
        currencyCode: 'EUR',
        currencySymbol: '€',
        flag: '🇧🇪'),
    CurrencyInfo(
        countryCode: 'BR',
        countryName: 'Brazil',
        currencyCode: 'BRL',
        currencySymbol: 'R\$',
        flag: '🇧🇷'),
    CurrencyInfo(
        countryCode: 'BN',
        countryName: 'Brunei',
        currencyCode: 'BND',
        currencySymbol: 'B\$',
        flag: '🇧🇳'),
    CurrencyInfo(
        countryCode: 'BG',
        countryName: 'Bulgaria',
        currencyCode: 'BGN',
        currencySymbol: 'лв',
        flag: '🇧🇬'),
    CurrencyInfo(
        countryCode: 'KH',
        countryName: 'Cambodia',
        currencyCode: 'KHR',
        currencySymbol: '៛',
        flag: '🇰🇭'),
    CurrencyInfo(
        countryCode: 'CA',
        countryName: 'Canada',
        currencyCode: 'CAD',
        currencySymbol: 'C\$',
        flag: '🇨🇦'),
    CurrencyInfo(
        countryCode: 'CL',
        countryName: 'Chile',
        currencyCode: 'CLP',
        currencySymbol: '\$',
        flag: '🇨🇱'),
    CurrencyInfo(
        countryCode: 'CN',
        countryName: 'China',
        currencyCode: 'CNY',
        currencySymbol: '¥',
        flag: '🇨🇳'),
    CurrencyInfo(
        countryCode: 'CO',
        countryName: 'Colombia',
        currencyCode: 'COP',
        currencySymbol: '\$',
        flag: '🇨🇴'),
    CurrencyInfo(
        countryCode: 'HR',
        countryName: 'Croatia',
        currencyCode: 'EUR',
        currencySymbol: '€',
        flag: '🇭🇷'),
    CurrencyInfo(
        countryCode: 'CZ',
        countryName: 'Czech Republic',
        currencyCode: 'CZK',
        currencySymbol: 'Kč',
        flag: '🇨🇿'),
    CurrencyInfo(
        countryCode: 'DK',
        countryName: 'Denmark',
        currencyCode: 'DKK',
        currencySymbol: 'kr',
        flag: '🇩🇰'),
    CurrencyInfo(
        countryCode: 'EG',
        countryName: 'Egypt',
        currencyCode: 'EGP',
        currencySymbol: 'E£',
        flag: '🇪🇬'),
    CurrencyInfo(
        countryCode: 'ET',
        countryName: 'Ethiopia',
        currencyCode: 'ETB',
        currencySymbol: 'Br',
        flag: '🇪🇹'),
    CurrencyInfo(
        countryCode: 'FI',
        countryName: 'Finland',
        currencyCode: 'EUR',
        currencySymbol: '€',
        flag: '🇫🇮'),
    CurrencyInfo(
        countryCode: 'FR',
        countryName: 'France',
        currencyCode: 'EUR',
        currencySymbol: '€',
        flag: '🇫🇷'),
    CurrencyInfo(
        countryCode: 'DE',
        countryName: 'Germany',
        currencyCode: 'EUR',
        currencySymbol: '€',
        flag: '🇩🇪'),
    CurrencyInfo(
        countryCode: 'GH',
        countryName: 'Ghana',
        currencyCode: 'GHS',
        currencySymbol: 'GH₵',
        flag: '🇬🇭'),
    CurrencyInfo(
        countryCode: 'GR',
        countryName: 'Greece',
        currencyCode: 'EUR',
        currencySymbol: '€',
        flag: '🇬🇷'),
    CurrencyInfo(
        countryCode: 'HK',
        countryName: 'Hong Kong',
        currencyCode: 'HKD',
        currencySymbol: 'HK\$',
        flag: '🇭🇰'),
    CurrencyInfo(
        countryCode: 'HU',
        countryName: 'Hungary',
        currencyCode: 'HUF',
        currencySymbol: 'Ft',
        flag: '🇭🇺'),
    CurrencyInfo(
        countryCode: 'IS',
        countryName: 'Iceland',
        currencyCode: 'ISK',
        currencySymbol: 'kr',
        flag: '🇮🇸'),
    CurrencyInfo(
        countryCode: 'IN',
        countryName: 'India',
        currencyCode: 'INR',
        currencySymbol: '₹',
        flag: '🇮🇳'),
    CurrencyInfo(
        countryCode: 'ID',
        countryName: 'Indonesia',
        currencyCode: 'IDR',
        currencySymbol: 'Rp',
        flag: '🇮🇩'),
    CurrencyInfo(
        countryCode: 'IR',
        countryName: 'Iran',
        currencyCode: 'IRR',
        currencySymbol: '﷼',
        flag: '🇮🇷'),
    CurrencyInfo(
        countryCode: 'IQ',
        countryName: 'Iraq',
        currencyCode: 'IQD',
        currencySymbol: 'ع.د',
        flag: '🇮🇶'),
    CurrencyInfo(
        countryCode: 'IE',
        countryName: 'Ireland',
        currencyCode: 'EUR',
        currencySymbol: '€',
        flag: '🇮🇪'),
    CurrencyInfo(
        countryCode: 'IL',
        countryName: 'Israel',
        currencyCode: 'ILS',
        currencySymbol: '₪',
        flag: '🇮🇱'),
    CurrencyInfo(
        countryCode: 'IT',
        countryName: 'Italy',
        currencyCode: 'EUR',
        currencySymbol: '€',
        flag: '🇮🇹'),
    CurrencyInfo(
        countryCode: 'JP',
        countryName: 'Japan',
        currencyCode: 'JPY',
        currencySymbol: '¥',
        flag: '🇯🇵'),
    CurrencyInfo(
        countryCode: 'JO',
        countryName: 'Jordan',
        currencyCode: 'JOD',
        currencySymbol: 'د.ا',
        flag: '🇯🇴'),
    CurrencyInfo(
        countryCode: 'KE',
        countryName: 'Kenya',
        currencyCode: 'KES',
        currencySymbol: 'KSh',
        flag: '🇰🇪'),
    CurrencyInfo(
        countryCode: 'KW',
        countryName: 'Kuwait',
        currencyCode: 'KWD',
        currencySymbol: 'د.ك',
        flag: '🇰🇼'),
    CurrencyInfo(
        countryCode: 'LB',
        countryName: 'Lebanon',
        currencyCode: 'LBP',
        currencySymbol: 'ل.ل',
        flag: '🇱🇧'),
    CurrencyInfo(
        countryCode: 'MY',
        countryName: 'Malaysia',
        currencyCode: 'MYR',
        currencySymbol: 'RM',
        flag: '🇲🇾'),
    CurrencyInfo(
        countryCode: 'MV',
        countryName: 'Maldives',
        currencyCode: 'MVR',
        currencySymbol: 'Rf',
        flag: '🇲🇻'),
    CurrencyInfo(
        countryCode: 'MX',
        countryName: 'Mexico',
        currencyCode: 'MXN',
        currencySymbol: '\$',
        flag: '🇲🇽'),
    CurrencyInfo(
        countryCode: 'MA',
        countryName: 'Morocco',
        currencyCode: 'MAD',
        currencySymbol: 'د.م.',
        flag: '🇲🇦'),
    CurrencyInfo(
        countryCode: 'MM',
        countryName: 'Myanmar',
        currencyCode: 'MMK',
        currencySymbol: 'K',
        flag: '🇲🇲'),
    CurrencyInfo(
        countryCode: 'NP',
        countryName: 'Nepal',
        currencyCode: 'NPR',
        currencySymbol: 'रू',
        flag: '🇳🇵'),
    CurrencyInfo(
        countryCode: 'NL',
        countryName: 'Netherlands',
        currencyCode: 'EUR',
        currencySymbol: '€',
        flag: '🇳🇱'),
    CurrencyInfo(
        countryCode: 'NZ',
        countryName: 'New Zealand',
        currencyCode: 'NZD',
        currencySymbol: 'NZ\$',
        flag: '🇳🇿'),
    CurrencyInfo(
        countryCode: 'NG',
        countryName: 'Nigeria',
        currencyCode: 'NGN',
        currencySymbol: '₦',
        flag: '🇳🇬'),
    CurrencyInfo(
        countryCode: 'NO',
        countryName: 'Norway',
        currencyCode: 'NOK',
        currencySymbol: 'kr',
        flag: '🇳🇴'),
    CurrencyInfo(
        countryCode: 'OM',
        countryName: 'Oman',
        currencyCode: 'OMR',
        currencySymbol: 'ر.ع.',
        flag: '🇴🇲'),
    CurrencyInfo(
        countryCode: 'PK',
        countryName: 'Pakistan',
        currencyCode: 'PKR',
        currencySymbol: '₨',
        flag: '🇵🇰'),
    CurrencyInfo(
        countryCode: 'PS',
        countryName: 'Palestine',
        currencyCode: 'ILS',
        currencySymbol: '₪',
        flag: '🇵🇸'),
    CurrencyInfo(
        countryCode: 'PE',
        countryName: 'Peru',
        currencyCode: 'PEN',
        currencySymbol: 'S/',
        flag: '🇵🇪'),
    CurrencyInfo(
        countryCode: 'PH',
        countryName: 'Philippines',
        currencyCode: 'PHP',
        currencySymbol: '₱',
        flag: '🇵🇭'),
    CurrencyInfo(
        countryCode: 'PL',
        countryName: 'Poland',
        currencyCode: 'PLN',
        currencySymbol: 'zł',
        flag: '🇵🇱'),
    CurrencyInfo(
        countryCode: 'PT',
        countryName: 'Portugal',
        currencyCode: 'EUR',
        currencySymbol: '€',
        flag: '🇵🇹'),
    CurrencyInfo(
        countryCode: 'QA',
        countryName: 'Qatar',
        currencyCode: 'QAR',
        currencySymbol: 'ر.ق',
        flag: '🇶🇦'),
    CurrencyInfo(
        countryCode: 'RO',
        countryName: 'Romania',
        currencyCode: 'RON',
        currencySymbol: 'lei',
        flag: '🇷🇴'),
    CurrencyInfo(
        countryCode: 'RU',
        countryName: 'Russia',
        currencyCode: 'RUB',
        currencySymbol: '₽',
        flag: '🇷🇺'),
    CurrencyInfo(
        countryCode: 'SA',
        countryName: 'Saudi Arabia',
        currencyCode: 'SAR',
        currencySymbol: 'ر.س',
        flag: '🇸🇦'),
    CurrencyInfo(
        countryCode: 'SG',
        countryName: 'Singapore',
        currencyCode: 'SGD',
        currencySymbol: 'S\$',
        flag: '🇸🇬'),
    CurrencyInfo(
        countryCode: 'ZA',
        countryName: 'South Africa',
        currencyCode: 'ZAR',
        currencySymbol: 'R',
        flag: '🇿🇦'),
    CurrencyInfo(
        countryCode: 'KR',
        countryName: 'South Korea',
        currencyCode: 'KRW',
        currencySymbol: '₩',
        flag: '🇰🇷'),
    CurrencyInfo(
        countryCode: 'ES',
        countryName: 'Spain',
        currencyCode: 'EUR',
        currencySymbol: '€',
        flag: '🇪🇸'),
    CurrencyInfo(
        countryCode: 'LK',
        countryName: 'Sri Lanka',
        currencyCode: 'LKR',
        currencySymbol: 'Rs',
        flag: '🇱🇰'),
    CurrencyInfo(
        countryCode: 'SE',
        countryName: 'Sweden',
        currencyCode: 'SEK',
        currencySymbol: 'kr',
        flag: '🇸🇪'),
    CurrencyInfo(
        countryCode: 'CH',
        countryName: 'Switzerland',
        currencyCode: 'CHF',
        currencySymbol: 'CHF',
        flag: '🇨🇭'),
    CurrencyInfo(
        countryCode: 'TW',
        countryName: 'Taiwan',
        currencyCode: 'TWD',
        currencySymbol: 'NT\$',
        flag: '🇹🇼'),
    CurrencyInfo(
        countryCode: 'TZ',
        countryName: 'Tanzania',
        currencyCode: 'TZS',
        currencySymbol: 'TSh',
        flag: '🇹🇿'),
    CurrencyInfo(
        countryCode: 'TH',
        countryName: 'Thailand',
        currencyCode: 'THB',
        currencySymbol: '฿',
        flag: '🇹🇭'),
    CurrencyInfo(
        countryCode: 'TR',
        countryName: 'Turkey',
        currencyCode: 'TRY',
        currencySymbol: '₺',
        flag: '🇹🇷'),
    CurrencyInfo(
        countryCode: 'UA',
        countryName: 'Ukraine',
        currencyCode: 'UAH',
        currencySymbol: '₴',
        flag: '🇺🇦'),
    CurrencyInfo(
        countryCode: 'AE',
        countryName: 'United Arab Emirates',
        currencyCode: 'AED',
        currencySymbol: 'د.إ',
        flag: '🇦🇪'),
    CurrencyInfo(
        countryCode: 'GB',
        countryName: 'United Kingdom',
        currencyCode: 'GBP',
        currencySymbol: '£',
        flag: '🇬🇧'),
    CurrencyInfo(
        countryCode: 'US',
        countryName: 'United States',
        currencyCode: 'USD',
        currencySymbol: '\$',
        flag: '🇺🇸'),
    CurrencyInfo(
        countryCode: 'UY',
        countryName: 'Uruguay',
        currencyCode: 'UYU',
        currencySymbol: '\$U',
        flag: '🇺🇾'),
    CurrencyInfo(
        countryCode: 'VN',
        countryName: 'Vietnam',
        currencyCode: 'VND',
        currencySymbol: '₫',
        flag: '🇻🇳'),
    CurrencyInfo(
        countryCode: 'ZM',
        countryName: 'Zambia',
        currencyCode: 'ZMW',
        currencySymbol: 'ZK',
        flag: '🇿🇲'),
  ];

  /// Look up currency info by country code.
  static CurrencyInfo? getByCountryCode(String code) {
    try {
      return allCurrencies.firstWhere(
        (c) => c.countryCode.toUpperCase() == code.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Search currencies by country name, currency code, or country code.
  static List<CurrencyInfo> search(String query) {
    if (query.isEmpty) return allCurrencies;
    final q = query.toLowerCase();
    return allCurrencies.where((c) {
      return c.countryName.toLowerCase().contains(q) ||
          c.currencyCode.toLowerCase().contains(q) ||
          c.countryCode.toLowerCase().contains(q);
    }).toList();
  }
}
