import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/prefs_manager/prefs_manager.dart';
import 'core/routes_manager/routes_manager.dart';
import 'core/theme/theme_provider.dart';
import 'config/theme_manager.dart';
import 'services/push_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:barter/l10n/app_localizations.dart';
import 'core/i18n/language_provider.dart';
import 'services/payment_service.dart';

// ─── Repositories ────────────────────────────────────────────────────────
import 'data/services/notification_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/product_repository.dart';
import 'data/repositories/trade_repository.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/review_repository.dart';
import 'data/repositories/admin_repository.dart';
import 'data/repositories/payment_repository.dart';
import 'data/repositories/wallet_repository.dart';
import 'data/repositories/report_repository.dart';
import 'data/repositories/category_repository.dart';

// ─── ViewModels ──────────────────────────────────────────────────────────
import 'features/authentication/viewmodels/auth_viewmodel.dart';
import 'features/products/viewmodels/product_viewmodel.dart';
import 'features/trade/viewmodels/trade_viewmodel.dart';
import 'features/chat/viewmodels/chat_viewmodel.dart';
import 'features/notifications/viewmodels/notification_viewmodel.dart';
import 'features/reviews/viewmodels/review_viewmodel.dart';
import 'features/admin/viewmodels/admin_viewmodel.dart';
import 'features/payment/viewmodels/payment_viewmodel.dart';
import 'features/wallet/viewmodels/wallet_viewmodel.dart';
import 'features/favourites/viewmodels/favourites_viewmodel.dart';
import 'features/profile/viewmodels/profile_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await PrefsManager.init();

  // Initialize Paymob
  await PaymentService.initialize();

  // Initialize push notifications
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await PushNotificationService.initialize();

  // ─── Create shared services & repositories ──────────────────────────
  final notificationService = NotificationService();

  final authRepository = AuthRepository();
  final productRepository = ProductRepository();
  final tradeRepository = TradeRepository(
    notificationService: notificationService,
  );
  final chatRepository = ChatRepository(
    notificationService: notificationService,
  );
  final notificationRepository = NotificationRepository();
  final reviewRepository = ReviewRepository(
    notificationService: notificationService,
  );
  final adminRepository = AdminRepository();
  final paymentRepository = PaymentRepository();
  final walletRepository = WalletRepository();
  final reportRepository = ReportRepository(
    notificationService: notificationService,
  );
  final categoryRepository = CategoryRepository();

  runApp(
    MultiProvider(
      providers: [
        // ─── Theme & Language ──────────────────────────────────────────
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),

        // ─── ViewModels ────────────────────────────────────────────────
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(authRepository: authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductViewModel(
            productRepository: productRepository,
            tradeRepository: tradeRepository,
            notificationService: notificationService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => TradeViewModel(tradeRepository: tradeRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatViewModel(chatRepository: chatRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationViewModel(
            notificationRepository: notificationRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ReviewViewModel(reviewRepository: reviewRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminViewModel(
            adminRepository: adminRepository,
            reportRepository: reportRepository,
            categoryRepository: categoryRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PaymentViewModel(paymentRepository: paymentRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => WalletViewModel(walletRepository: walletRepository),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              FavouritesViewModel(productRepository: productRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileViewModel(
            authRepository: authRepository,
            adminRepository: adminRepository,
          ),
        ),
      ],
      child: const MyApp(onboardingCompleted: false),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool onboardingCompleted;

  const MyApp({super.key, required this.onboardingCompleted});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final themeProvider = Provider.of<ThemeProvider>(context);
        final languageProvider = Provider.of<LanguageProvider>(context);

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Barter App',
          themeMode: themeProvider.currentTheme,
          theme: ThemeManager.light,
          darkTheme: ThemeManager.dark,
          onGenerateRoute: RoutesManager.router,
          initialRoute: RoutesManager.splashScreen,
          locale: languageProvider.currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ar'),
          ],
        );
      },
    );
  }
}
