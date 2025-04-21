import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'features/auth/providers/auth_provider.dart' as app_auth;
import 'features/measurements/providers/measurements_provider.dart';
import 'features/abayas/providers/abayas_provider.dart';
import 'features/summary/providers/summary_provider.dart';

// Global key for navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Run app with initialization wrapper
  runApp(const AppInitializer());
}

// Widget to handle Firebase initialization
class AppInitializer extends StatelessWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // Initialize Firebase asynchronously
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        // Show loading indicator while initializing
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Scaffold(
              backgroundColor: AppTheme.primaryColor,
              body: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          );
        }
        
        // Show error screen if initialization failed
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'فشل في تهيئة التطبيق',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'يرجى التحقق من اتصال الإنترنت وإعادة المحاولة',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'خطأ: ${snapshot.error}',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        
        // Initialization successful, launch the main app
        return const MyApp();
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()), 
        ChangeNotifierProxyProvider<app_auth.AuthProvider, MeasurementsProvider>(
          create: (_) => MeasurementsProvider(),
          update: (_, auth, measurements) => measurements!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<app_auth.AuthProvider, AbayasProvider>(
          create: (_) => AbayasProvider(),
          update: (_, auth, abayas) => abayas!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<app_auth.AuthProvider, SummaryProvider>(
          create: (_) => SummaryProvider(),
          update: (_, auth, summary) => summary!..updateAuth(auth),
        ),
      ],
      child: MaterialApp.router(
        title: 'تطبيق تفصيل العباية',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        locale: const Locale('ar'),
        supportedLocales: const [
          Locale('ar'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },
        routerConfig: AppRouter.router,
      ),
    );
  }
}