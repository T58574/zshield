import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/secrets.dart';
import 'core/theme/app_theme.dart';
import 'core/router.dart';
import 'providers/config_provider.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseSecrets.url,
    anonKey: SupabaseSecrets.anonKey,
  );

  final prefs = await SharedPreferences.getInstance();
  
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  // Trigger anonymous sign-in if not logged in
  final auth = container.read(authProvider.notifier);
  final authState = container.read(authProvider);
  if (!authState.isAuthenticated) {
    await auth.signInAnonymously();
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ZShieldApp(),
    ),
  );
}

class ZShieldApp extends StatelessWidget {
  const ZShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ZShield',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
