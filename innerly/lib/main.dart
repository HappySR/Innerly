import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:Innerly/services/role.dart';
import 'package:Innerly/services/auth_service.dart';
import 'package:Innerly/services/chat_service.dart'; // Add these
import 'package:Innerly/services/appointment_service.dart';
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
        ChangeNotifierProvider(create: (_) => ChatService()), // Add these
        ChangeNotifierProvider(create: (_) => AppointmentService()),
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

    // Initialize Supabase with proper configuration
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON']!,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      debug: true,
    );

    // Verify database connection
    try {
      final response = await Supabase.instance.client
          .from('therapists')
          .select('id')
          .limit(1);
      debugPrint('✅ Supabase connection verified');
    } catch (e) {
      debugPrint('❌ Supabase connection error: $e');
      throw Exception('Failed to connect to database');
    }

    // Check existing session
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      await UserRole.loadRole();
      debugPrint('👤 User session restored: ${session.user?.email}');
    } else {
      debugPrint('🔒 No existing user session');
    }
  } catch (e, stack) {
    debugPrint('‼️ Critical initialization error: $e');
    debugPrint('🛑 Stack trace: $stack');
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
        useMaterial3: true,
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
        // Handle connection state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Handle errors
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Authentication Error',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }

        // Check authentication status
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          debugPrint('🔑 Authenticated user: ${session.user?.email}');
          // TODO: Add your authenticated home screen here
          return const AnimatedSplashScreen();
        }

        // Show login screen
        debugPrint('👥 Showing unauthenticated UI');
        return const AnimatedSplashScreen();
      },
    );
  }
}