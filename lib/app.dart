import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'widgets/offline_banner.dart';

class ScentryXApp extends StatelessWidget {
  const ScentryXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return MaterialApp(
          title: 'ScentryX',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: const SplashScreen(),
          routes: AppRoutes.routes,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          builder: (context, child) {
            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                const Align(
                  alignment: Alignment.topCenter,
                  child: SafeArea(
                    child: OfflineBanner(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
