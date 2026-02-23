// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'مقايضة';

  @override
  String get tagline => 'قايض • شارك • تواصل';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String version(String version) {
    return 'الإصدار $version';
  }

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get register => 'إنشاء حساب';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get welcomeBack => 'مرحباً بعودتك!';

  @override
  String get signInSubtitle => 'سجل دخولك للمتابعة في مقايضة';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get emailHint => 'أدخل بريدك الإلكتروني';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get passwordHint => 'أدخل كلمة المرور';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get orDivider => 'أو';

  @override
  String get signInWithGoogle => 'تسجيل الدخول بواسطة جوجل';

  @override
  String get continueAsGuest => 'المتابعة كضيف';

  @override
  String get home => 'الرئيسية';

  @override
  String get chats => 'المحادثات';

  @override
  String get items => 'العناصر';

  @override
  String get trades => 'المبادلات';

  @override
  String get profile => 'الحساب';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'الإنجليزية';

  @override
  String get arabic => 'العربية';

  @override
  String get theme => 'المظهر';

  @override
  String get lightMode => 'الوضع الفاتح';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get account => 'الحساب';

  @override
  String get preferences => 'التفضيلات';

  @override
  String get support => 'الدعم';

  @override
  String get adminPanel => 'لوحة التحكم';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get favorites => 'المفضلة';

  @override
  String get tradeHistory => 'سجل المبادلات';

  @override
  String get notifications => 'التنبيهات';

  @override
  String get helpSupport => 'المساعدة والدعم';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get about => 'حول التطبيق';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signInRegister => 'تسجيل الدخول / إنشاء حساب';

  @override
  String get exploreItems => 'استكشف العناصر';

  @override
  String get notificationNewOfferTitle => 'عرض مبادلة جديد';

  @override
  String notificationNewOfferBody(Object sender) {
    return 'أرسل لك $sender عرض مبادلة.';
  }

  @override
  String get notificationCounterOfferTitle => 'عرض مقابل جديد';

  @override
  String notificationCounterOfferBody(Object sender) {
    return 'أرسل $sender عرضاً مقابلاً.';
  }

  @override
  String get notificationTradeAcceptedTitle => 'تم قبول المبادلة!';

  @override
  String get notificationTradeAcceptedBody => 'تم قبول عرض المبادلة الخاص بك!';

  @override
  String get notificationTradeRejectedTitle => 'تم رفض المبادلة';

  @override
  String get notificationTradeRejectedBody => 'تم رفض عرض المبادلة الخاص بك.';

  @override
  String get nameLabel => 'الاسم الكامل';

  @override
  String get nameHint => 'أدخل اسمك الكامل';

  @override
  String get saveProfile => 'حفظ التغييرات';

  @override
  String get profileUpdated => 'تم تحديث الملف الشخصي بنجاح!';

  @override
  String get changePhoto => 'تغيير الصورة';

  @override
  String get takePhoto => 'التقاط صورة';

  @override
  String get chooseGallery => 'اختيار من المعرض';

  @override
  String get nameRequired => 'الاسم مطلوب';
}
