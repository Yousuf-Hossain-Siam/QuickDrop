import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:flutter/services.dart';
import 'app/app.dart';
import 'core/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService.instance.initialize();
  } on PlatformException catch (error, stackTrace) {
    debugPrint('Notification initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
  if (Platform.isAndroid) {
    MediaStore.appFolder = 'QuickDrop';
    await MediaStore.ensureInitialized();
  }
  runApp(const ProviderScope(child: QuickDrop()));
}
