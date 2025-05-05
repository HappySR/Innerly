import 'package:Innerly/home/pages/therapists/therapist_edit_profile.dart';
import 'package:Innerly/widget/innerly_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import '../../../localization/i10n.dart';
import '../../../localization/language_provider.dart';
import '../../../started/welcome_page.dart';

class TherapistProfileView extends StatefulWidget {
  const TherapistProfileView({super.key});

  @override
  State<TherapistProfileView> createState() => _TherapistProfileViewState();
}

class _TherapistProfileViewState extends State<TherapistProfileView> {
  String? _therapistName = "Jane Tanner";
  String? _therapistTitle = "PhD, CBT";
  bool _isLoadingData = false;
  late Locale _selectedLocale;

  // Client stats
  final int _activeClients = 12;
  final int _sessionsThisWeek = 8;
  final int _sessionsNextWeek = 5;

  // Selected client for detailed view
  final String _selectedClientName = "Kate";
  final int _selectedClientScore = 85;
  final String _selectedClientStage = "Stage 3";

  @override
  void initState() {
    super.initState();
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
        _selectedLocale = newLocale;
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
              // Therapist Profile Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        L10n.getTranslatedText(context, 'Therapist Profile'),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _isLoadingData
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Text(
                        "$_therapistName, $_therapistTitle",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
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
                      builder: (context) => const EditTherapistProfileView(),
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
                icon: const Icon(Icons.edit, size: 16, color: Colors.black),
                label: Text(L10n.getTranslatedText(context, L10n.getTranslatedText(context, 'Edit Profile')), style: const TextStyle(color: Colors.black)),
              ),
              const SizedBox(height: 20),

              // Client Overview Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: InnerlyTheme.beige,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${L10n.getTranslatedText(context, 'Client')}: $_selectedClientName",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          L10n.getTranslatedText(context, 'Updated today'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Client Info Row
                    Row(
                      children: [
                        // Client Avatar
                        CircleAvatar(
                          radius: 25,
                          backgroundImage: const AssetImage('assets/user/user.png'),
                        ),
                        const SizedBox(width: 16),

                        // Client Metrics
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${L10n.getTranslatedText(context, 'Mental Health Score')}: $_selectedClientScore",
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),

                              // Mental Health Score Progress Bar
                              LinearProgressIndicator(
                                value: _selectedClientScore / 100,
                                backgroundColor: const Color(0xFFFEE2BE),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF6AA84F),
                                ),
                                minHeight: 6,
                              ),
                              const SizedBox(height: 12),

                              Text(
                                  "${L10n.getTranslatedText(context, 'Current Status')}: $_selectedClientStage",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6AA84F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.message, size: 20),
                      label: Text(L10n.getTranslatedText(context, 'Message')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6AA84F),
                        side: const BorderSide(color: Color(0xFF6AA84F)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.calendar_month, size: 20),
                      label: Text(L10n.getTranslatedText(context, 'Schedule Session')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Mood Tracking History
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: InnerlyTheme.beige,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      L10n.getTranslatedText(context, 'Mood Tracking History'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Weekly Mood Chart
                    SizedBox(
                      height: 120,
                      child: MoodChart(),
                    ),

                    const SizedBox(height: 8),

                    // Day labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _DayLabel(L10n.getTranslatedText(context, 'Mon')),
                        _DayLabel(L10n.getTranslatedText(context, 'Tue')),
                        _DayLabel(L10n.getTranslatedText(context, 'Wed')),
                        _DayLabel(L10n.getTranslatedText(context, 'Thu')),
                        _DayLabel(L10n.getTranslatedText(context, 'Fri')),
                        _DayLabel(L10n.getTranslatedText(context, 'Sat')),
                        _DayLabel(L10n.getTranslatedText(context, 'Sun')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Client Progress
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: InnerlyTheme.beige,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      L10n.getTranslatedText(context, 'Client Progress'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildProgressItem(
                      icon: Icons.check_circle_outline,
                      title: L10n.getTranslatedText(context, 'Journals Completed'),
                      value: "12/15",
                    ),
                    const Divider(height: 1, thickness: 0.5),
                    _buildProgressItem(
                      icon: Icons.flag_outlined,
                      title: L10n.getTranslatedText(context, 'Challenges Achieved'),
                      value: "5/8",
                    ),
                    const Divider(height: 1, thickness: 0.5),
                    _buildProgressItem(
                      icon: Icons.trending_up,
                      title: L10n.getTranslatedText(context, 'Wellness Goals Met'),
                      value: "4/5",
                    ),

                    const SizedBox(height: 16),
                    Text(
                      L10n.getTranslatedText(context, 'Treatment Notes:'),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      L10n.getTranslatedText(context, 'Client showing steady improvement in daily mindfulness practice. Continue monitoring sleep patterns.'),
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6AA84F),
                          side: const BorderSide(color: Color(0xFF6AA84F)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.edit_note, size: 20),
                        label: Text(L10n.getTranslatedText(context, 'Edit Notes')),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Dashboard Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.people,
                      title: L10n.getTranslatedText(context, 'Active Clients'),
                      value: _activeClients.toString(),
                      color: const Color(0xFF6AA84F),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.calendar_today,
                      title: L10n.getTranslatedText(context, 'Sessions This Week'),
                      value: _sessionsThisWeek.toString(),
                      color: const Color(0xFF8BC34A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.calendar_month,
                      title: L10n.getTranslatedText(context, 'Next Week'),
                      value: _sessionsNextWeek.toString(),
                      color: const Color(0xFFAED581),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Language Selector
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
                          _changeLanguage(newLocale);
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
              const SizedBox(height: 20),

              // Logout Button - Moved below language dropdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.redAccent,
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6AA84F), size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: InnerlyTheme.beige,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Day Label Widget
class _DayLabel extends StatelessWidget {
  final String day;

  const _DayLabel(this.day);

  @override
  Widget build(BuildContext context) {
    return Text(
      day,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
      ),
    );
  }
}

// Mood Chart Widget
class MoodChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: MoodChartPainter(),
      size: Size.infinite,
    );
  }
}

class MoodChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw horizontal guide lines
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw horizontal guides
    for (int i = 1; i <= 3; i++) {
      final y = size.height / 4 * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Draw mood line
    final moodPaint = Paint()
      ..color = const Color(0xFF6AA84F)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Mood data points (normalized to 0.0-1.0 range)
    final points = [
      Offset(0, size.height * 0.5), // Mon
      Offset(size.width / 6, size.height * 0.7), // Tue
      Offset(size.width / 6 * 2, size.height * 0.4), // Wed
      Offset(size.width / 6 * 3, size.height * 0.6), // Thu
      Offset(size.width / 6 * 4, size.height * 0.3), // Fri
      Offset(size.width / 6 * 5, size.height * 0.5), // Sat
      Offset(size.width, size.height * 0.2), // Sun
    ];

    // Create path for the line
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // Draw the path
    canvas.drawPath(path, moodPaint);

    // Draw points
    final pointPaint = Paint()
      ..color = const Color(0xFF6AA84F)
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    for (var point in points) {
      canvas.drawCircle(point, 5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

