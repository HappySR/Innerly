import 'package:Innerly/widget/innerly_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../../localization/i10n.dart';
import '../../localization/language_provider.dart';
import '../../started/welcome_page.dart';
import 'edit_profile_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isUuidRevealed = false;
  String? _uuid;
  bool _obscureUuid = true;
  bool _isLoadingUuid = false;
  late Locale _selectedLocale;

  Future<void> _getUserUuid() async {
    setState(() => _isLoadingUuid = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('users')
            .select('uuid')
            .eq('id', user.id)
            .single();

        if (response != null && mounted) {
          setState(() => _uuid = response['uuid'] as String?);
        }
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${L10n.getTranslatedText(context, 'Error fetching UUID')}: ${e.message}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingUuid = false);
      }
    }
  }

  Future<void> _authenticate() async {
    try {
      // First check if biometrics are available
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canAuthenticate || !isDeviceSupported) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10n.getTranslatedText(context, 'Biometric authentication not available'))),
        );
        return;
      }

      // Then authenticate
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: L10n.getTranslatedText(context, 'Authenticate to reveal your UUID'),
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow device credentials too
        ),
      );

      if (didAuthenticate) {
        setState(() {
          _isUuidRevealed = true;
          _obscureUuid = false;
        });
        await _getUserUuid();
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${L10n.getTranslatedText(context, 'Authentication failed')}: ${e.message}')),
      );
    }
  }

  void _copyToClipboard() {
    if (_uuid != null) {
      Clipboard.setData(ClipboardData(text: _uuid!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.getTranslatedText(context, 'UUID copied to clipboard'))),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _getUserUuid();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10n.getTranslatedText(context, 'Failed to load user information'))),
        );
      }
    });
    _selectedLocale = const Locale('en');
    _loadLanguage();
  }





  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language') ?? 'en';

    final newLocale = Locale(langCode);

    Future.microtask(() {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      if (languageProvider.locale != newLocale) {
        languageProvider.setLocale(newLocale);
      }
      setState(() {
        _selectedLocale = newLocale; // Ensure state is updated
      });
    });
  }

  void _changeLanguage(Locale locale) async {
    if (locale != _selectedLocale) {
      setState(() {
        _selectedLocale = locale;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', locale.languageCode);

      Provider.of<LanguageProvider>(context, listen: false).setLocale(locale);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF4E7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modified Profile Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${L10n.getTranslatedText(context, 'Hello')}, Kate",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () async {
                          if (_isLoadingUuid) return;

                          if (_uuid == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(L10n.getTranslatedText(context, 'UUID not available'))),
                            );
                            return;
                          }

                          if (!_isUuidRevealed) {
                            await _authenticate();
                          } else {
                            _copyToClipboard();
                          }
                        },
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isLoadingUuid)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              else
                                Flexible(
                                  child: Text(
                                    _isUuidRevealed && _uuid != null
                                        ? _obscureUuid
                                        ? '••••••••••••••••'
                                        : _uuid!
                                        : '${L10n.getTranslatedText(context, 'Tap to reveal UUID')} ',
                                    style: TextStyle(
                                      fontSize: MediaQuery.of(context).size.width * 0.035,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              if (_isUuidRevealed && _uuid != null && !_isLoadingUuid)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.02),
                                      child: GestureDetector(
                                        onTap: _copyToClipboard,
                                        child: Icon(
                                          Icons.copy,
                                          size: MediaQuery.of(context).size.width * 0.045,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.02),
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _isUuidRevealed = false;
                                            _obscureUuid = true;
                                          });
                                        },
                                        child: Icon(
                                          Icons.visibility_off,
                                          size: MediaQuery.of(context).size.width * 0.045,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: MediaQuery.of(context).size.width * 0.08,
                    backgroundImage: const AssetImage('assets/user/user.png'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Edit Profile Button
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfilePage(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  side: BorderSide(color: InnerlyTheme.beige),
                  backgroundColor: InnerlyTheme.beige,
                ),
                icon: const Icon(Icons.edit, size: 16, color: Colors.black,),
                label: Text(L10n.getTranslatedText(context, 'Edit Profile'), style: TextStyle(color: Colors.black),),
              ),
              const SizedBox(height: 20),

              // Mood Tracker Summary
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: InnerlyTheme.beige,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      L10n.getTranslatedText(context, 'Mood Tracker Summary'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Progress Bar
                    LinearProgressIndicator(
                      value: 0.3,
                      backgroundColor: Color(0xFFFEE2BE),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.green,
                      ),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 16),

                    // Mood Icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _MoodIcon(emoji: "😢", label: L10n.getTranslatedText(context, 'Low')),
                        _MoodIcon(emoji: "😐", label: L10n.getTranslatedText(context, 'Neutral')),
                        _MoodIcon(emoji: "😊", label: L10n.getTranslatedText(context, 'Happy')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Personal Growth Section
              Text(
                L10n.getTranslatedText(context, 'Personal Growth'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildGrowthItem(
                emoji: '📝',
                title: L10n.getTranslatedText(context, 'Journals Completed'),
                value: "12",
              ),
              _buildGrowthItem(
                emoji: '🎯',
                title: L10n.getTranslatedText(context, 'Challenges Achieved'),
                value: "5",
              ),
              _buildGrowthItem(
                emoji: '🔥',
                title: L10n.getTranslatedText(context, 'Current Journey Stage'),
                value: "Stage 3",
              ),
              const SizedBox(height: 24),

              // Therapist and Community Section
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildCard(
                        title: L10n.getTranslatedText(context, 'Therapist'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundImage: AssetImage(
                                'assets/user/user.png',
                              ), // therapist image
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Jane Tanner, PhD",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              "CBT",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ), // <-- added this
                                      ),
                                    ),
                                    child: Text(
                                      L10n.getTranslatedText(context, 'Message'),
                                      style: TextStyle(fontSize: 12,
                                      color: Colors.black),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ), // <-- added this
                                      ),
                                    ),
                                    child: Text(
                                      L10n.getTranslatedText(context, 'Book Session'),
                                      style: TextStyle(fontSize: 12,
                                          color: Colors.black),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCard(
                        title: L10n.getTranslatedText(context, 'My Community Posts'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "12 ${L10n.getTranslatedText(context, 'posts')} . 45 ${L10n.getTranslatedText(context, 'comments')}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "56 ${L10n.getTranslatedText(context, 'Followers')} . 45 ${L10n.getTranslatedText(context, 'comments')}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    12,
                                  ), // <-- added this
                                ),
                              ),
                              child: Text(
                                L10n.getTranslatedText(context, 'View my posts'),
                                style: TextStyle(fontSize: 12,
                                    color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Wellness Goals
              _buildCard(
                title: L10n.getTranslatedText(context, 'Wellness Goals'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GoalItem(
                      goal: L10n.getTranslatedText(context, 'Meditate 5 times this week'),
                      isCompleted: true,
                    ),
                    _GoalItem(goal: L10n.getTranslatedText(context, 'Log mood daily'), isCompleted: true),
                    _GoalItem(
                      goal: L10n.getTranslatedText(context, 'Eat 2 healthy meals daily'),
                      isCompleted: true,
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0), // Margin around button
                child: SizedBox(
                  width: double.infinity, // Full width
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0), // Padding inside button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // Rounded corners
                      ),
                      backgroundColor: Colors.redAccent, // Button color (optional, can remove if you want default color)
                    ),
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const WelcomePage()),
                            (route) => false,
                      );
                    },
                    child: Text(
                      L10n.getTranslatedText(context, 'Logout'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Text color
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Consumer<LanguageProvider>(
                  builder: (context, provider, child) {
                    return DropdownButton<Locale>(
                      value: provider.locale,
                      hint: Text(L10n.getTranslatedText(context, 'Choose Language')),
                      isExpanded: true,
                      onChanged: (Locale? newLocale) {
                        if (newLocale != null) {
                          _changeLanguage(newLocale); // Call the function
                        }
                      },
                      items: L10n.supportedLocales.map((Locale locale) {
                        return DropdownMenuItem(
                          value: locale,
                          child: Text(L10n.getLanguageName(locale.languageCode)),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrowthItem({
    required String emoji,
    required String title,
    required String value,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Text(emoji, style: const TextStyle(fontSize: 30)),

      title: Text(title),
      trailing: Text(value),
      onTap: () {},
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: InnerlyTheme.beige,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// Mood Icon Widget
class _MoodIcon extends StatelessWidget {
  final String emoji;
  final String label;

  const _MoodIcon({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// Wellness Goal Item
class _GoalItem extends StatelessWidget {
  final String goal;
  final bool isCompleted;

  const _GoalItem({required this.goal, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.check_circle, color: Color(0xFF6AA84F)),
      title: Text(goal, style: const TextStyle(fontSize: 14)),
    );
  }
}
