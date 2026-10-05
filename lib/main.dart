import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'app/bootstrap/app_services.dart';
import 'core/notifications/push_notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Color(0x00000000),
    statusBarColor: Color(0x00000000),
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
  ));
  final services = await AppServices.create();
  runApp(BInovaApp(services: services));
}
