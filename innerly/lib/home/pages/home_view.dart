import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../widget/imageCard.dart';
import '../../widget/innerly_theme.dart';

class MentalHealthHome extends StatefulWidget {
  const MentalHealthHome({super.key});

  @override
  State<MentalHealthHome> createState() => _MentalHealthHomeState();
}

class _MentalHealthHomeState extends State<MentalHealthHome> {
  bool _isInitializing = true;
  final _storage = const FlutterSecureStorage();
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _initializeAnonymousUser();
  }

  Future<void> _initializeAnonymousUser() async {
    try {
      // Check for existing user ID
      String? userId = await _storage.read(key: 'anonymous_user_id');

      // Create new user if doesn't exist
      if (userId == null) {
        userId = _uuid.v4();
        await _storage.write(key: 'anonymous_user_id', value: userId);

        // Insert new user into Supabase (corrected syntax)
        final response = await Supabase.instance.client
            .from('users')
            .insert({
          'id': userId,
          'created_at': DateTime.now().toIso8601String(),
          'is_anonymous': true,
        });

        if (response.error != null) {
          throw Exception('Supabase error: ${response.error!.message}');
        }
      }

      setState(() => _isInitializing = false);
    } catch (e) {
      print('Error initializing anonymous user: $e');
      setState(() => _isInitializing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      drawer: const Drawer(),
      backgroundColor: InnerlyTheme.appBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.filter_list_sharp, color: Colors.black87),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: SizedBox(
          height: 36,
          child: TextField(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: 'Search',
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Hello, Julia',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'HOW ARE YOU FEELING TODAY',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 108,
              height: 108,
              child: ClipOval(
                child: Image.asset(
                  'assets/user/user.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '"Hey, are you feeling low. Talk to our\nexpert therapist for instant relaxation"',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              children: const [
                Expanded(child: ShadowImageCard(imagePath: 'assets/images/explore.png')),
                SizedBox(width: 12),
                Expanded(child: ShadowImageCard(imagePath: 'assets/images/interact.png')),
              ],
            ),
            const SizedBox(height: 25),
            const ShadowImageCard(
              imagePath: 'assets/images/global_chat.png',
              height: 220,
            ),
          ],
        ),
      ),
    );
  }
}