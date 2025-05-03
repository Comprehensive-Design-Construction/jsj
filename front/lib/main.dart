import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/utils/preferences_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefsService = PreferencesService();
  final bool onboardingComplete = await prefsService.isOnboardingComplete();

  runApp(ProviderScope(child: MyApp(onboardingComplete: onboardingComplete)));
}
