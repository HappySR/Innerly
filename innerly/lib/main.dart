import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:Innerly/services/role.dart';
import 'package:Innerly/services/auth_service.dart';
import 'package:Innerly/started/splash_screen_view.dart';
import 'package:Innerly/widget/innerly_theme.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home/providers/bottom_nav_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BottomNavProvider()),
        Provider(create: (_) => AuthService()),
      ],
      child: const MyApp(),
    ),
  );

  SystemChrome.setSystemUIOverlayStyle(_systemUiOverlayStyle());
}

Future<void> _initializeApp() async {
  try {
    // Load environment variables
    await dotenv.load(fileName: 'assets/.env');

    // Initialize Supabase with enhanced configuration
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON']!,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.debug,
      ),
      debug: true,
    );

    // Verify connection
    try {
      final response = await Supabase.instance.client
          .from('therapists')
          .select('id')
          .limit(1);
      debugPrint('Supabase connection test: ${response.length} records found');
    } catch (e) {
      debugPrint('Supabase connection test failed: $e');
    }

    // Load user role if a session exists
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      await UserRole.loadRole();
      debugPrint('User session loaded: ${session.user?.email}');
    }
  } catch (e, stack) {
    debugPrint('Initialization error: $e\n$stack');
    exit(1);
  }
}

SystemUiOverlayStyle _systemUiOverlayStyle() {
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: !kIsWeb && Platform.isAndroid
        ? Brightness.dark
        : Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Innerly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: InnerlyTheme.textTheme,
        platform: TargetPlatform.iOS,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Authentication error'));
        }

        final session = Supabase.instance.client.auth.currentSession;
        debugPrint('Auth state: ${session != null ? "Authenticated" : "Not authenticated"}');

        return const AnimatedSplashScreen();
      },
    );
  }
}