import 'dart:async';
import 'dart:math';

import 'package:Innerly/widget/innerly_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:Innerly/home/pages/chat_screen.dart';

import '../../localization/i10n.dart';
import '../../services/auth_service.dart';
import '../providers/bottom_nav_provider.dart';
import 'appointment_screen.dart';

class UserAppointmentsScreen extends StatefulWidget {
  const UserAppointmentsScreen({super.key});

  @override
  State<UserAppointmentsScreen> createState() => _UserAppointmentsScreenState();
}

class _UserAppointmentsScreenState extends State<UserAppointmentsScreen> {
  // Helper method to get ordinal suffix for dates (1st, 2nd, 3rd, etc.)
  String _getOrdinal(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  final SupabaseClient _supabase = Supabase.instance.client;
  DateTime? _selectedDay = DateTime.now();
  DateTime? _focusedDay = DateTime.now();
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  // Timer for periodic checking of appointment status
  Timer? _statusCheckTimer;

  // Get events for calendar highlighting
  Map<DateTime, List<Map<String, dynamic>>> get _events {
    final Map<DateTime, List<Map<String, dynamic>>> eventsByDay = {};

    for (final appointment in _appointments) {
      final date = DateTime.parse(appointment['scheduled_at']).toLocal();
      final day = DateTime(date.year, date.month, date.day);

      if (eventsByDay[day] == null) {
        eventsByDay[day] = [];
      }
      eventsByDay[day]!.add(appointment);
    }

    return eventsByDay;
  }

  List<Map<String, dynamic>> get upcomingAppointments {
    final upcoming = _appointments
        .where((appt) => appt['status'] == 'confirmed')
        .toList();
    upcoming.sort((a, b) =>
        DateTime.parse(a['scheduled_at'])
            .compareTo(DateTime.parse(b['scheduled_at'])));
    return upcoming;
  }

  List<Map<String, dynamic>> get pastAppointments {
    final past = _appointments
        .where((appt) => appt['status'] == 'completed')
        .toList();
    past.sort((a, b) =>
        DateTime.parse(b['scheduled_at'])
            .compareTo(DateTime.parse(a['scheduled_at'])));
    return past;
  }

  List<Map<String, dynamic>> getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAppointments();
      // Set up periodic status check (every minute)
      _statusCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        _checkAppointmentStatus();
      });
    });
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAppointments() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final appointments = await _supabase
          .from('appointments')
          .select()
          .eq('user_id', userId) // User's appointments instead of therapist's
          .inFilter('status', ['confirmed', 'completed'])
          .order('scheduled_at', ascending: true);

      if (appointments.isEmpty) {
        setState(() {
          _appointments = [];
          _isLoading = false;
        });
        return;
      }

      final therapistIds = appointments
          .map<String>((a) => a['therapist_id'] as String)
          .toList();

      // Get therapist details
      final therapists = await _supabase
          .from('profiles')
          .select()
          .inFilter('id', therapistIds);

      final combined = appointments.map((appointment) {
        final therapist = therapists.firstWhere(
              (t) => t['id'] == appointment['therapist_id'],
          orElse: () => {},
        );
        return {...appointment, 'therapist': therapist};
      }).toList();

      setState(() {
        _appointments = List<Map<String, dynamic>>.from(combined);
        _isLoading = false;
      });

      // Check status immediately after fetching
      _checkAppointmentStatus();
    } catch (e) {
      print('Fetch error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _checkAppointmentStatus() async {
    final now = DateTime.now();

    // Check confirmed appointments that should be completed
    for (final appointment in _appointments) {
      if (appointment['status'] == 'confirmed') {
        // Calculate end time based on scheduled_at and duration
        final int durationMinutes = appointment['duration'] ?? 60;
        final DateTime startTime = DateTime.parse(appointment['scheduled_at'])
            .toLocal();
        final DateTime endTime = startTime.add(
            Duration(minutes: durationMinutes));

        // If appointment is within 10 minutes of starting, refresh to get the meet link
        if (startTime
            .difference(now)
            .inMinutes <= 10 && appointment['meet_link'] == null) {
          _fetchAppointments();
          break; // Only need to refresh once
        }
      }
    }
  }

  Future<void> _launchMeetLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    // Calculate dynamic sizes based on screen dimensions
    final double titleFontSize = min(screenWidth * 0.065, 28.0);
    final double subtitleFontSize = min(screenWidth * 0.045, 20.0);
    final double normalFontSize = min(screenWidth * 0.04, 16.0);
    final double smallFontSize = min(screenWidth * 0.035, 14.0);

    return WillPopScope(
      onWillPop: () async {
        // When back button is pressed, navigate to therapist's home (index 0)
        Provider.of<BottomNavProvider>(context, listen: false).currentIndex = 0;
        return false; // Prevent default back behavior
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: InnerlyTheme.appBackground,
          appBar: AppBar(
            backgroundColor: InnerlyTheme.appBackground,
            elevation: 0,
            title: Text(
              L10n.getTranslatedText(context, 'MY APPOINTMENTS'),
              style: GoogleFonts.aboreto(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _calendar(screenWidth, normalFontSize, smallFontSize),
                        SizedBox(height: screenHeight * 0.03),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: max(screenWidth * 0.02, 8.0)),
                          child: Text(
                            L10n.getTranslatedText(context, 'My Sessions'),
                            style: GoogleFonts.montserrat(
                              fontSize: subtitleFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                      ],
                    )),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyTabBarDelegate(
                    child: TabBar(
                      tabs: [
                        Tab(
                          child: Text(
                            L10n.getTranslatedText(context, 'Upcoming'),
                            style: GoogleFonts.montserrat(
                              fontSize: normalFontSize,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Tab(
                          child: Text(
                            L10n.getTranslatedText(context, 'Past'),
                            style: GoogleFonts.montserrat(
                              fontSize: normalFontSize,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      indicatorColor: const Color(0xFF6FA57C),
                      labelColor: InnerlyTheme.secondary,
                      unselectedLabelColor: Colors.grey,
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              children: [
                _buildAppointmentsList(
                  upcomingAppointments,
                  screenWidth,
                  screenHeight,
                  titleFontSize,
                  normalFontSize,
                  smallFontSize,
                  showMeetButton: true,
                ),
                _buildAppointmentsList(
                  pastAppointments,
                  screenWidth,
                  screenHeight,
                  titleFontSize,
                  normalFontSize,
                  smallFontSize,
                  showMeetButton: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(List<Map<String, dynamic>> appointments,
      double screenWidth,
      double screenHeight,
      double titleFontSize,
      double normalFontSize,
      double smallFontSize, {
        required bool showMeetButton,
      }) {
    final padding = min(max(screenWidth * 0.04, 10.0), 20.0);

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : appointments.isEmpty
        ? Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Text(
          L10n.getTranslatedText(context, 'No appointments found'),
          style: GoogleFonts.abyssinicaSil(
            fontSize: normalFontSize,
            color: Colors.grey,
          ),
        ),
      ),
    )
        : ListView.builder(
      padding: EdgeInsets.symmetric(
          horizontal: padding, vertical: screenHeight * 0.02),
      itemCount: appointments.length,
      itemBuilder: (context, index) =>
          _appointmentCard(
            appointment: appointments[index],
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            titleFontSize: titleFontSize,
            normalFontSize: normalFontSize,
            smallFontSize: smallFontSize,
            showMeetButton: showMeetButton,
          ),
    );
  }

  Widget _calendar(double screenWidth, double normalFontSize,
      double smallFontSize) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(min(screenWidth * 0.04,
                  16.0))),
          elevation: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(min(screenWidth * 0.04, 16.0)),
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.all(min(screenWidth * 0.03, 12.0)),
              constraints: BoxConstraints(
                minHeight: constraints.maxWidth * 0.8,
              ),
              child: TableCalendar(
                focusedDay: _focusedDay ?? DateTime.now(),
                firstDay: DateTime(2020),
                lastDay: DateTime(2030),
                calendarFormat: CalendarFormat.month,
                startingDayOfWeek: StartingDayOfWeek.monday,
                selectedDayPredicate: (day) =>
                _selectedDay != null && isSameDay(_selectedDay!, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                eventLoader: (day) => getEventsForDay(day),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: const Color(0xFF6FA57C),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: const Color.fromARGB(161, 146, 240, 223),
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: const Color(0xFF7A2DED),
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 3,
                  cellPadding: EdgeInsets.all(min(screenWidth * 0.015, 6.0)),
                  defaultTextStyle: TextStyle(
                    fontSize: smallFontSize,
                  ),
                  todayTextStyle: TextStyle(
                    fontSize: smallFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: const Color(0xFF7A2DED),
                    fontWeight: FontWeight.w600,
                    fontSize: smallFontSize,
                  ),
                  weekendStyle: TextStyle(
                    color: const Color(0xFF7A2DED),
                    fontWeight: FontWeight.w600,
                    fontSize: smallFontSize,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: normalFontSize,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    size: min(screenWidth * 0.06, 24.0),
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    size: min(screenWidth * 0.06, 24.0),
                  ),
                  headerPadding: EdgeInsets.only(
                    bottom: min(screenWidth * 0.04, 16.0),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _appointmentCard({
    required Map<String, dynamic> appointment,
    required double screenWidth,
    required double screenHeight,
    required double titleFontSize,
    required double normalFontSize,
    required double smallFontSize,
    required bool showMeetButton,
  }) {
    final therapist = appointment['therapist'] as Map<String, dynamic>? ?? {};
    final therapistId = appointment['therapist_id'] as String? ?? '';
    final scheduledAt = DateTime.parse(appointment['scheduled_at']).toLocal();
    final date = DateFormat('d').format(scheduledAt);
    final monthYear = DateFormat('MMMM y').format(scheduledAt);
    final time = DateFormat('h:mm a').format(scheduledAt);
    final now = DateTime.now();

    // Calculate time to appointment start
    final Duration timeToStart = scheduledAt.difference(now);
    final bool isWithin10Min = timeToStart.inMinutes <= 10 &&
        timeToStart.isNegative == false;
    final bool hasStarted = timeToStart.isNegative &&
        appointment['status'] == 'confirmed';

    // Calculate estimated end time for display
    final int durationMinutes = appointment['duration'] ?? 60;
    final endTime = scheduledAt.add(Duration(minutes: durationMinutes));
    final endTimeFormatted = DateFormat('h:mm a').format(endTime);

    // Dynamic padding based on screen size
    final double horizontalPadding = min(max(screenWidth * 0.04, 12.0), 20.0);
    final double verticalPadding = min(max(screenHeight * 0.02, 12.0), 20.0);
    final double betweenItemsSpace = min(max(screenHeight * 0.015, 8.0), 16.0);
    final double avatarRadius = min(max(screenWidth * 0.07, 24.0), 32.0);

    final imageUrl = therapist['photo_url'] ?? 'https://cdn.pixabay.com/photo/2017/05/10/13/36/doctor-2300898_1280.png';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      margin: EdgeInsets.only(bottom: betweenItemsSpace),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(min(screenWidth * 0.04, 16.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(imageUrl),
                radius: avatarRadius,
              ),
              SizedBox(width: horizontalPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      therapist['full_name']?.toString() ?? L10n.getTranslatedText(context, 'Therapist'),
                      style: GoogleFonts.montserrat(
                        fontSize: normalFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: betweenItemsSpace / 2),
                    Text(
                      therapist['specialization']?.toString() ??
                          L10n.getTranslatedText(context, 'Mental Health Professional'),
                      style: TextStyle(
                        fontSize: smallFontSize,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: betweenItemsSpace / 2),
                    Text(
                      "${L10n.getTranslatedText(context, 'Issue')}: ${appointment['notes']?.toString() ??
                          L10n.getTranslatedText(context, 'General Consultation')}",
                      style: TextStyle(fontSize: smallFontSize),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: betweenItemsSpace / 2),
                    Row(
                      children: [
                        Icon(
                            Icons.circle,
                            size: min(screenWidth * 0.03, 12.0),
                            color: appointment['status'] == 'completed' ? Colors
                                .grey : Colors.green
                        ),
                        SizedBox(width: horizontalPadding / 3),
                        Text(
                          appointment['status'] == 'completed'
                              ? L10n.getTranslatedText(context, 'Completed')
                              : L10n.getTranslatedText(context, 'Confirmed'),
                          style: TextStyle(fontSize: smallFontSize),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: betweenItemsSpace),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _infoBox(
                  icon: Icons.calendar_today,
                  label: "$date ${_getOrdinal(int.parse(date))} $monthYear",
                  screenWidth: screenWidth,
                  fontSize: smallFontSize,
                ),
                SizedBox(width: horizontalPadding),
                _infoBox(
                  icon: Icons.access_time,
                  label: "$time - $endTimeFormatted",
                  screenWidth: screenWidth,
                  fontSize: smallFontSize,
                ),
                SizedBox(width: horizontalPadding),
                _infoBox(
                  icon: Icons.timelapse,
                  label: "${durationMinutes} minutes",
                  screenWidth: screenWidth,
                  fontSize: smallFontSize,
                ),
              ],
            ),
          ),
          SizedBox(height: betweenItemsSpace),

          // Action Buttons (Message and Meet)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ChatScreen(
                              receiverId: therapistId,
                              receiverName: therapist['full_name']
                                  ?.toString() ?? 'Therapist',
                              isTherapist: false,
                            ),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.message,
                    size: min(screenWidth * 0.05, 20.0),
                    color: Colors.black,
                  ),
                  label: Text(L10n.getTranslatedText(context, 'Message'),
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: smallFontSize,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFFCED4DA),
                      width: 1,
                    ),
                    padding: EdgeInsets.symmetric(
                        vertical: min(screenWidth * 0.03, 12.0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          min(screenWidth * 0.025, 10.0)),
                    ),
                  ),
                ),
              ),

              // Meet Button (Only for upcoming and within 10 minutes of start)
              if (showMeetButton) ...[
                SizedBox(width: horizontalPadding),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (isWithin10Min || hasStarted) &&
                        appointment['meet_link'] != null
                        ? () => _launchMeetLink(appointment['meet_link'])
                        : null,
                    icon: Icon(
                      Icons.videocam,
                      size: min(screenWidth * 0.05, 20.0),
                      color: (isWithin10Min || hasStarted) &&
                          appointment['meet_link'] != null
                          ? Colors.black
                          : Colors.grey,
                    ),
                    label: Text(
                      (isWithin10Min || hasStarted) &&
                          appointment['meet_link'] != null
                          ? L10n.getTranslatedText(context, 'Join Session')
                          : timeToStart.isNegative
                          ? L10n.getTranslatedText(context, 'Waiting for link')
                          : '${L10n.getTranslatedText(context, 'Session in')} ${timeToStart.inMinutes > 10
                          ? "${timeToStart.inMinutes ~/ 60}h ${timeToStart
                          .inMinutes % 60}m"
                          : "${timeToStart.inMinutes}m"}',
                      style: TextStyle(
                        color: (isWithin10Min || hasStarted) &&
                            appointment['meet_link'] != null
                            ? Colors.black
                            : Colors.grey,
                        fontWeight: FontWeight.w500,
                        fontSize: smallFontSize,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: (isWithin10Min || hasStarted) &&
                            appointment['meet_link'] != null
                            ? const Color(0xFF6FA57C)
                            : const Color(0xFFCED4DA),
                        width: 1,
                      ),
                      padding: EdgeInsets.symmetric(
                          vertical: min(screenWidth * 0.03, 12.0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(min(screenWidth *
                            0.025, 10.0)),
                      ),
                    ),
                  ),
                ),
              ],

              // Show a cancel button for upcoming appointments
              if (showMeetButton && timeToStart.inHours > 24) ...[
                SizedBox(width: horizontalPadding),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showCancellationDialog(appointment),
                    icon: Icon(
                      Icons.cancel_outlined,
                      size: min(screenWidth * 0.05, 20.0),
                      color: Colors.red[700],
                    ),
                    label: Text(
                      L10n.getTranslatedText(context, 'Cancel'),
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                        fontSize: smallFontSize,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.red[300]!,
                        width: 1,
                      ),
                      padding: EdgeInsets.symmetric(
                          vertical: min(screenWidth * 0.03, 12.0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(min(screenWidth *
                            0.025, 10.0)),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),

          // For past appointments, show a rebook option
          if (!showMeetButton) ...[
            SizedBox(height: betweenItemsSpace),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showRebookDialog(appointment),
                icon: Icon(
                  Icons.replay,
                  size: min(screenWidth * 0.05, 20.0),
                  color: const Color(0xFF6FA57C),
                ),
                label: Text(
                  L10n.getTranslatedText(context, 'Schedule Another Session'),
                  style: TextStyle(
                    color: const Color(0xFF6FA57C),
                    fontWeight: FontWeight.w500,
                    fontSize: smallFontSize,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Color(0xFF6FA57C),
                    width: 1,
                  ),
                  padding: EdgeInsets.symmetric(
                      vertical: min(screenWidth * 0.03, 12.0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        min(screenWidth * 0.025, 10.0)),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCancellationDialog(Map<String, dynamic> appointment) {
    final scheduledAt = DateTime.parse(appointment['scheduled_at']).toLocal();
    final formattedDate = DateFormat('MMMM d, yyyy').format(scheduledAt);
    final formattedTime = DateFormat('h:mm a').format(scheduledAt);

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(L10n.getTranslatedText(context, 'Cancel Appointment')),
            content: Text(
                'Are you sure you want to cancel your appointment on $formattedDate at $formattedTime?\n\n'
                    'Please note that cancellations less than 24 hours before the appointment may incur a fee.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(L10n.getTranslatedText(context, 'No, Keep It')),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _cancelAppointment(appointment['id']);
                },
                child: Text(L10n.getTranslatedText(context, 'Yes, Cancel'), style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void _showRebookDialog(Map<String, dynamic> appointment) {
    final therapist = appointment['therapist'] as Map<String, dynamic>? ?? {};
    final therapistId = appointment['therapist_id'] as String? ?? '';
    final therapistName = therapist['full_name']?.toString() ?? 'Therapist';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Schedule New Session'),
        content: Text(
            'Would you like to schedule another session with $therapistName?\n\n'
                'You will be redirected to the booking page.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Not Now'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (therapistId.isNotEmpty) {
                _navigateToBooking(therapistId, therapist);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Therapist ID not found'))
                );
              }
            },
            child: Text('Book Session',
                style: TextStyle(color: const Color(0xFF6FA57C))),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelAppointment(int appointmentId) async {
    try {
      setState(() => _isLoading = true);

      await _supabase
          .from('appointments')
          .update({'status': 'cancelled'})
          .eq('id', appointmentId);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.getTranslatedText(context, 'Appointment cancelled successfully')),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh appointments
      _fetchAppointments();
    } catch (e) {
      print('Cancel error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.getTranslatedText(context, 'Failed to cancel appointment. Please try again.')),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  void _navigateToBooking(String therapistId, Map<String, dynamic>? existingTherapistData) async {
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) =>
        const Center(child: CircularProgressIndicator()),
      );

      // If we already have complete therapist data, use it
      // Otherwise fetch it using the AuthService
      Map<String, dynamic> therapistData;
      if (existingTherapistData != null &&
          existingTherapistData.containsKey('full_name') &&
          existingTherapistData.containsKey('specialization')) {
        therapistData = existingTherapistData;
      } else {
        therapistData = await authService.getTherapist(therapistId);
      }

      // Close loading dialog
      Navigator.of(context, rootNavigator: true).pop();

      if (therapistData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10n.getTranslatedText(context, 'Therapist not found')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Navigate to the AppointmentScreen with the therapist data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AppointmentScreen(
            therapist: therapistData,
          ),
        ),
      );
    } catch (e) {
      // Close loading dialog if still showing
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      print('Navigation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.getTranslatedText(context, 'Error loading therapist data')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _infoBox({
    required IconData icon,
    required String label,
    required double screenWidth,
    required double fontSize,
  }) {
    final double horizontalPadding = min(max(screenWidth * 0.04, 12.0), 20.0);
    final double verticalPadding = min(max(screenWidth * 0.02, 8.0), 12.0);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(min(screenWidth * 0.03, 12.0)),
        border: Border.all(color: const Color(0xFF6FA57C), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: fontSize * 1.1, color: Colors.black87),
          SizedBox(width: horizontalPadding / 4),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar child;

  _StickyTabBarDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: InnerlyTheme.appBackground,
      child: child,
    );
  }

  @override
  double get maxExtent => child.preferredSize.height;

  @override
  double get minExtent => child.preferredSize.height;

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}