import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:avalia/features/auth/presentation/screens/login_screen.dart';
import 'package:avalia/core/navigation/app_route_observer.dart';
import 'package:avalia/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mnyoqrpohiyydrgwsbap.supabase.co',
    anonKey: 'sb_secret_5zP04RzVVrhnxecW840x6g_mrYFQA-y',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      navigatorObservers: [appRouteObserver],
      home: LoginScreen(),
    );
  }
}
