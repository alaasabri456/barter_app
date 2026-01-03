import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'core/prefs_manager/prefs_manager.dart';
import 'core/routes_manager/routes_manager.dart';
import 'core/theme/theme_provider.dart';
import 'config/theme_manager.dart';
import 'services/push_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await PrefsManager.init();

  // Initialize push notifications
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await PushNotificationService.initialize();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
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

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Barter App',
          themeMode: themeProvider.currentTheme,
          theme: ThemeManager.light,
          darkTheme: ThemeManager.dark,
          onGenerateRoute: RoutesManager.router,
          initialRoute: RoutesManager.splashScreen,
        );
      },
    );
  }
}
