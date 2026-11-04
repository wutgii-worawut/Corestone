// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get home => 'Home';

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageThai => 'ไทย';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in with your email and password.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get invalidEmail => 'Enter a valid email address';

  @override
  String get loginWrongCredentials => 'Wrong email or password.';

  @override
  String get errorOffline =>
      'You\'re offline. Check your connection and try again.';

  @override
  String get errorServer =>
      'Something went wrong on our side. Try again later.';

  @override
  String get errorGeneric => 'Something went wrong. Try again.';

  @override
  String get signOutConfirmTitle => 'Sign out?';

  @override
  String get signOutConfirmBody =>
      'You will need to sign in again to use the app.';

  @override
  String get cancel => 'Cancel';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountBody =>
      'This permanently deletes your account and its data, then signs you out. You cannot undo it.';

  @override
  String get deleteAccountConfirm => 'Delete my account';

  @override
  String get lockTitle => 'Enter your PIN';

  @override
  String wrongPin(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wrong PIN. $count tries left before you are signed out.',
      one: 'Wrong PIN. 1 try left before you are signed out.',
    );
    return '$_temp0';
  }

  @override
  String get lockedOut => 'Too many wrong PINs. Signing you out.';

  @override
  String get forgotPin => 'Forgot PIN? Sign out';

  @override
  String get pinCreateTitle => 'Create a 6-digit PIN';

  @override
  String get pinCreateSubtitle => 'You will enter it to open the app.';

  @override
  String get pinConfirmTitle => 'Enter the PIN again';

  @override
  String get pinMismatch => 'The PINs did not match. Try again.';

  @override
  String get pinCurrentTitle => 'Enter your current PIN';

  @override
  String get changePin => 'Change PIN';

  @override
  String get pinChanged => 'PIN changed';

  @override
  String get pinDelete => 'Delete';

  @override
  String pinDigitsEntered(int entered, int total) {
    return '$entered of $total digits entered';
  }
}
