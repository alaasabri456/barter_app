// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Barter';

  @override
  String get tagline => 'Trade • Share • Connect';

  @override
  String get loading => 'Loading...';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get welcomeBack => 'Welcome Back!';

  @override
  String get signInSubtitle => 'Sign in to continue to Barter';

  @override
  String get emailLabel => 'Email Address';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get orDivider => 'OR';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get continueAsGuest => 'Continue as Guest';

  @override
  String get home => 'Home';

  @override
  String get items => 'Items';

  @override
  String get trades => 'Trades';

  @override
  String get profile => 'Profile';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get theme => 'Theme';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get account => 'Account';

  @override
  String get preferences => 'Preferences';

  @override
  String get support => 'Support';

  @override
  String get adminPanel => 'Admin Panel';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get favorites => 'Favorites';

  @override
  String get tradeHistory => 'Trade History';

  @override
  String get notifications => 'Notifications';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get about => 'About';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signInRegister => 'Sign In / Register';

  @override
  String get exploreItems => 'Explore Items';

  @override
  String get notificationNewOfferTitle => 'New Trade Offer';

  @override
  String notificationNewOfferBody(Object sender) {
    return '$sender sent you a trade offer.';
  }

  @override
  String get notificationCounterOfferTitle => 'New Counter Offer';

  @override
  String notificationCounterOfferBody(Object sender) {
    return '$sender sent a counter offer.';
  }

  @override
  String get notificationTradeAcceptedTitle => 'Trade Accepted!';

  @override
  String get notificationTradeAcceptedBody =>
      'Your trade offer has been accepted!';

  @override
  String get notificationTradeRejectedTitle => 'Trade Rejected';

  @override
  String get notificationTradeRejectedBody => 'Your trade offer was rejected.';

  @override
  String get nameLabel => 'Full Name';

  @override
  String get nameHint => 'Enter your full name';

  @override
  String get saveProfile => 'Save Changes';

  @override
  String get profileUpdated => 'Profile updated successfully!';

  @override
  String get changePhoto => 'Change Photo';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseGallery => 'Choose from Gallery';

  @override
  String get nameRequired => 'Name is required';
}
