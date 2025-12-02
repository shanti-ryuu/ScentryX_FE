import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'config/firebase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/device_provider.dart';
import 'providers/reading_provider.dart';
import 'providers/alert_provider.dart';
import 'providers/network_provider.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // ignore: avoid_print
  print('Handling background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: firebaseConfig['apiKey']!,
      authDomain: firebaseConfig['authDomain']!,
      projectId: firebaseConfig['projectId']!,
      storageBucket: firebaseConfig['storageBucket']!,
      messagingSenderId: firebaseConfig['messagingSenderId']!,
      appId: firebaseConfig['appId']!,
      measurementId: firebaseConfig['measurementId'],
      databaseURL: firebaseConfig['databaseURL'],
    ),
  );

  final storageService = await StorageService.getInstance();
  final notificationService = NotificationService();
  await notificationService.initialize();

  final firebaseService = FirebaseService();
  await firebaseService.initializeFCM();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(storageService, firebaseService),
        ),
        ChangeNotifierProvider(
          create: (_) => DeviceProvider(storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => ReadingProvider(firebaseService),
        ),
        ChangeNotifierProvider(
          create: (_) => AlertProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => NetworkProvider(),
        ),
      ],
      child: const ScentryXApp(),
    ),
  );
}
