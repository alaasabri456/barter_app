import 'package:barter/config/theme_manager.dart';
import 'package:barter/core/prefs_manager/prefs_manager.dart';
import 'package:barter/core/routes_manager/routes_manager.dart';
import 'package:barter/firebase/firebase_service.dart';
import 'package:barter/models/user_model.dart';
import 'package:barter/provider/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PrefsManager.init();
  final onboardingCompleted =PrefsManager.prefs.getBool('onboardingCompleted') ?? false;
  await Firebase.initializeApp();
  if(FirebaseAuth.instance.currentUser!=null){
     UserModel.currentUser=await FirebaseService.getUserFromFireStore(FirebaseAuth.instance.currentUser!.uid);
   }


  runApp(
      MultiProvider(providers: [ChangeNotifierProvider(create:(context) =>ThemeProvider())],
          child:  MyApp(onboardingCompleted: onboardingCompleted,)));
}

class MyApp extends StatelessWidget {
 final bool onboardingCompleted;

  const MyApp({super.key, required this.onboardingCompleted,});


  @override
  Widget build(BuildContext context) {
    var themeProvider=Provider.of<ThemeProvider>(context);
    return ScreenUtilInit(
      designSize: Size(393, 841),
      splitScreenMode: true,
      minTextAdapt: true,
      builder: (context, child) =>  MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateRoute:RoutesManager.router,
         initialRoute: FirebaseAuth.instance.currentUser == null
            ? (onboardingCompleted ? RoutesManager.splashScreen: RoutesManager.startScreen)
           : RoutesManager.splashScreen,
       // initialRoute: RoutesManager.initiateTrade,
        theme: ThemeManager.light,
        darkTheme:ThemeManager.dark ,
        themeMode: themeProvider.currentTheme,



      ),

    );

  }
}
