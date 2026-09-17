import 'package:flutter/material.dart';

const supportedLanguages = <Locale>[Locale('en'), Locale('si'), Locale('ta')];

class AppLocalizations {
  const AppLocalizations(this.locale);
  final Locale locale;
  static const delegate = _AppLocalizationsDelegate();
  static AppLocalizations of(BuildContext context) => Localizations.of<AppLocalizations>(context, AppLocalizations) ?? const AppLocalizations(Locale('en'));
  String get languageName => {'en': 'English', 'si': 'සිංහල', 'ta': 'தமிழ்'}[locale.languageCode] ?? 'English';
  String t(String key) => _values[locale.languageCode]?[key] ?? _values['en']![key] ?? key;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override bool isSupported(Locale locale) => ['en', 'si', 'ta'].contains(locale.languageCode);
  @override Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);
  @override bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

const _values = <String, Map<String, String>>{
  'en': {
    'home': 'Home', 'restaurants': 'Restaurants', 'orders': 'Orders', 'cart': 'Cart', 'wallet': 'Wallet', 'profile': 'Profile',
    'language': 'Language', 'theme': 'Theme', 'system': 'System default', 'light': 'Light', 'dark': 'Dark',
    'orderPlaced': 'Order placed', 'accepted': 'Accepted', 'confirmed': 'Confirmed', 'preparing': 'Preparing', 'ready_for_pickup': 'Ready for pickup', 'rider_assigned': 'Rider assigned', 'picked_up': 'Picked up', 'out_for_delivery': 'Out for delivery', 'delivered': 'Delivered', 'cancelled': 'Cancelled', 'delivery_failed': 'Delivery failed',
    'payNow': 'Pay Now', 'trackOrder': 'Track Order', 'viewOrder': 'View Order', 'leaveReview': 'Leave Review', 'reviewed': 'Reviewed', 'save': 'Save', 'save_error': 'Could not save your preference. Please try again.',
  },
  'si': {
    'home': 'මුල් පිටුව', 'restaurants': 'ආපනශාලා', 'orders': 'ඇණවුම්', 'cart': 'කරත්තය', 'wallet': 'පසුම්බිය', 'profile': 'පැතිකඩ',
    'language': 'භාෂාව', 'theme': 'තේමාව', 'system': 'පද්ධති පෙරනිමිය', 'light': 'ආලෝකය', 'dark': 'අඳුරු',
    'orderPlaced': 'ඇණවුම යොමු කළා', 'accepted': 'පිළිගත්තා', 'confirmed': 'තහවුරු කළා', 'preparing': 'සූදානම් කරමින්', 'ready_for_pickup': 'ලබා ගැනීමට සූදානම්', 'rider_assigned': 'බෙදාහරින්නෙකු පවරා ඇත', 'picked_up': 'ලබා ගත්තා', 'out_for_delivery': 'බෙදාහරිමින්', 'delivered': 'බෙදාහැරීම අවසන්', 'cancelled': 'අවලංගු කළා', 'delivery_failed': 'බෙදාහැරීම අසාර්ථකයි',
    'payNow': 'දැන් ගෙවන්න', 'trackOrder': 'ඇණවුම හඹා යන්න', 'viewOrder': 'ඇණවුම බලන්න', 'leaveReview': 'සමාලෝචනයක් දාන්න', 'reviewed': 'සමාලෝචනය කළා', 'save': 'සුරකින්න',
  },
  'ta': {
    'home': 'முகப்பு', 'restaurants': 'உணவகங்கள்', 'orders': 'ஆர்டர்கள்', 'cart': 'வண்டி', 'wallet': 'பணப்பை', 'profile': 'சுயவிவரம்',
    'language': 'மொழி', 'theme': 'தீம்', 'system': 'கணினி இயல்புநிலை', 'light': 'வெளிச்சம்', 'dark': 'இருள்',
    'orderPlaced': 'ஆர்டர் வழங்கப்பட்டது', 'accepted': 'ஏற்றுக்கொள்ளப்பட்டது', 'confirmed': 'உறுதிசெய்யப்பட்டது', 'preparing': 'தயாராகிறது', 'ready_for_pickup': 'பெற தயாராக உள்ளது', 'rider_assigned': 'விநியோகஸ்தர் ஒதுக்கப்பட்டார்', 'picked_up': 'பெறப்பட்டது', 'out_for_delivery': 'விநியோகத்தில் உள்ளது', 'delivered': 'விநியோகம் முடிந்தது', 'cancelled': 'ரத்து செய்யப்பட்டது', 'delivery_failed': 'விநியோகம் தோல்வியடைந்தது',
    'payNow': 'இப்போது செலுத்தவும்', 'trackOrder': 'ஆர்டரை கண்காணிக்கவும்', 'viewOrder': 'ஆர்டரை பார்க்கவும்', 'leaveReview': 'மதிப்புரை வழங்கவும்', 'reviewed': 'மதிப்புரை வழங்கப்பட்டது', 'save': 'சேமிக்கவும்',
  },
};
