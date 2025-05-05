import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:Innerly/home/pages/chat_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  DateTime? _selectedDay = DateTime.now();
  DateTime? _focusedDay = DateTime.now();
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;
  // Timer for periodic checking of appointment status
  Timer? _statusCheckTimer;

  List<Map<String, dynamic>> get upcomingAppointments {
    final upcoming = _appointments
        .where((appt) => appt['status'] == 'confirmed')
        .toList();
    upcoming.sort((a, b) => DateTime.parse(a['scheduled_at'])
        .compareTo(DateTime.parse(b['scheduled_at'])));
    return upcoming;
  }

  List<Map<String, dynamic>> get pastAppointments {
    final past = _appointments
        .where((appt) => appt['status'] == 'completed')
        .toList();
    past.sort((a, b) => DateTime.parse(b['scheduled_at'])
        .compareTo(DateTime.parse(a['scheduled_at'])));
    return past;
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
          .eq('therapist_id', userId)
          .inFilter('status', ['confirmed', 'completed'])
          .order('scheduled_at', ascending: true);

      if (appointments.isEmpty) {
        setState(() {
          _appointments = [];
          _isLoading = false;
        });
        return;
      }

      final userIds = appointments
          .map<String>((a) => a['user_id'] as String)
          .toList();

      final users = await _supabase.rpc(
          'get_therapist_clients',
          params: {'user_ids': userIds}
      ).select();

      final combined = appointments.map((appointment) {
        final user = users.firstWhere(
              (u) => u['id'] == appointment['user_id'],
          orElse: () => {},
        );
        return {...appointment, 'client': user};
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
    final appointmentsNeedingUpdate = <String>[];
    final appointmentsNeedingMeetLink = <Map<String, dynamic>>[];

    // Check confirmed appointments that should be completed
    for (final appointment in _appointments) {
      if (appointment['status'] == 'confirmed') {
        // Calculate end time based on scheduled_at and duration
        final int durationMinutes = appointment['duration'] ?? 60;
        final DateTime startTime = DateTime.parse(appointment['scheduled_at']).toLocal();
        final DateTime endTime = startTime.add(Duration(minutes: durationMinutes));

        // If end time has passed, mark for completion
        if (now.isAfter(endTime)) {
          appointmentsNeedingUpdate.add(appointment['id'].toString());
        }

        // Check if appointment is within 10 minutes of starting and needs a meet link
        if (startTime.difference(now).inMinutes <= 10 &&
            appointment['meet_link'] == null) {
          appointmentsNeedingMeetLink.add(appointment);
        }
      }
    }

    // Generate meet links for appointments that need them
    if (appointmentsNeedingMeetLink.isNotEmpty) {
      try {
        await Future.wait(
            appointmentsNeedingMeetLink.map((appointment) async {
              final meetLink = _generateMeetLink();
              await _supabase
                  .from('appointments')
                  .update({'meet_link': meetLink})
                  .eq('id', appointment['id']);
            })
        );
      } catch (e) {
        print('Meet link generation error: $e');
      }
    }

    // Update status for appointments that need it
    if (appointmentsNeedingUpdate.isNotEmpty) {
      try {
        await Future.wait(
            appointmentsNeedingUpdate.map((id) =>
                _supabase
                    .from('appointments')
                    .update({'status': 'completed'})
                    .eq('id', id)
            )
        );

        // Refresh appointments after updating
        _fetchAppointments();
      } catch (e) {
        print('Status update error: $e');
      }
    }
  }

  String _generateMeetLink() {
    final random = Random();
    final code = List.generate(10, (_) =>
    'abcdefghijklmnopqrstuvwxyz'[random.nextInt(26)]
    ).join();
    return 'https://meet.google.com/$code';
  }

  Future<void> _launchMeetLink(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate dynamic sizes based on screen dimensions
    final double titleFontSize = min(screenWidth * 0.065, 28.0);
    final double subtitleFontSize = min(screenWidth * 0.045, 20.0);
    final double normalFontSize = min(screenWidth * 0.04, 16.0);
    final double smallFontSize = min(screenWidth * 0.035, 14.0);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF6F0),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFDF6F0),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            "TODAY'S SCHEDULE",
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
                        "Appointments",
                        style: GoogleFonts.montserrat(
                          fontSize: subtitleFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                  ],
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  child: TabBar(
                    tabs: [
                      Tab(
                        child: Text(
                          'Upcoming',
                          style: GoogleFonts.montserrat(
                            fontSize: normalFontSize,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Tab(
                        child: Text(
                          'Past',
                          style: GoogleFonts.montserrat(
                            fontSize: normalFontSize,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    indicatorColor: const Color(0xFF6FA57C),
                    labelColor: Colors.black,
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
    );
  }

  Widget _buildAppointmentsList(
      List<Map<String, dynamic>> appointments,
      double screenWidth,
      double screenHeight,
      double titleFontSize,
      double normalFontSize,
      double smallFontSize, {
        required bool showMeetButton, // Moved this inside the curly braces
      }) {
    final padding = min(max(screenWidth * 0.04, 10.0), 20.0);

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : appointments.isEmpty
        ? Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Text(
          'No appointments found',
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
      itemBuilder: (context, index) => _appointmentCard(
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

  Widget _calendar(double screenWidth, double normalFontSize, double smallFontSize) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(min(screenWidth * 0.04, 16.0))),
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
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: const Color(0xFF6FA57C),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: const Color.fromARGB(161, 146, 240, 223),
                    shape: BoxShape.circle,
                  ),
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
    final client = appointment['client'] as Map<String, dynamic>? ?? {};
    final clientId = appointment['user_id'] as String? ?? '';
    final meta = client['raw_user_meta_data'] ?? {};
    final scheduledAt = DateTime.parse(appointment['scheduled_at']).toLocal();
    final date = DateFormat('d').format(scheduledAt);
    final monthYear = DateFormat('MMMM y').format(scheduledAt);
    final time = DateFormat('h:mm a').format(scheduledAt);
    final now = DateTime.now();

    // Calculate time to appointment start
    final Duration timeToStart = scheduledAt.difference(now);
    final bool isWithin10Min = timeToStart.inMinutes <= 10 && timeToStart.isNegative == false;
    final bool hasStarted = timeToStart.isNegative && appointment['status'] == 'confirmed';

    // Calculate estimated end time for display
    final int durationMinutes = appointment['duration'] ?? 60;
    final endTime = scheduledAt.add(Duration(minutes: durationMinutes));
    final endTimeFormatted = DateFormat('h:mm a').format(endTime);

    // Dynamic padding based on screen size
    final double horizontalPadding = min(max(screenWidth * 0.04, 12.0), 20.0);
    final double verticalPadding = min(max(screenHeight * 0.02, 12.0), 20.0);
    final double betweenItemsSpace = min(max(screenHeight * 0.015, 8.0), 16.0);
    final double avatarRadius = min(max(screenWidth * 0.07, 24.0), 32.0);

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
                backgroundImage: const AssetImage('assets/icons/user.png'),
                radius: avatarRadius,
              ),
              SizedBox(width: horizontalPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta['full_name']?.toString() ?? 'Anonymous User',
                      style: GoogleFonts.montserrat(
                        fontSize: normalFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: betweenItemsSpace / 2),
                    Text(
                      "Issue: ${appointment['notes']?.toString() ?? 'General Consultation'}",
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
                            color: appointment['status'] == 'completed' ? Colors.grey : Colors.green
                        ),
                        SizedBox(width: horizontalPadding / 3),
                        Text(
                          "Status: ${appointment['status']}",
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
                        builder: (context) => ChatScreen(
                          receiverId: clientId,
                          receiverName: meta['full_name']?.toString() ?? 'Client',
                          isTherapist: true,
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.message,
                    size: min(screenWidth * 0.05, 20.0),
                    color: Colors.black,
                  ),
                  label: Text(
                    'Message',
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
                    padding: EdgeInsets.symmetric(vertical: min(screenWidth * 0.03, 12.0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(min(screenWidth * 0.025, 10.0)),
                    ),
                  ),
                ),
              ),

              // Meet Button (Only for upcoming and within 10 minutes of start)
              if (showMeetButton) ...[
                SizedBox(width: horizontalPadding),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (isWithin10Min || hasStarted) && appointment['meet_link'] != null
                        ? () => _launchMeetLink(appointment['meet_link'])
                        : null,
                    icon: Icon(
                      Icons.videocam,
                      size: min(screenWidth * 0.05, 20.0),
                      color: (isWithin10Min || hasStarted) && appointment['meet_link'] != null
                          ? Colors.black
                          : Colors.grey,
                    ),
                    label: Text(
                      (isWithin10Min || hasStarted) && appointment['meet_link'] != null
                          ? 'Join Meet'
                          : 'Meet (${timeToStart.inMinutes > 10 ? "${timeToStart.inMinutes} mins" : "soon"})',
                      style: TextStyle(
                        color: (isWithin10Min || hasStarted) && appointment['meet_link'] != null
                            ? Colors.black
                            : Colors.grey,
                        fontWeight: FontWeight.w500,
                        fontSize: smallFontSize,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: (isWithin10Min || hasStarted) && appointment['meet_link'] != null
                            ? const Color(0xFF6FA57C)
                            : const Color(0xFFCED4DA),
                        width: 1,
                      ),
                      padding: EdgeInsets.symmetric(vertical: min(screenWidth * 0.03, 12.0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(min(screenWidth * 0.025, 10.0)),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
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

  String _getOrdinal(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar child;

  _StickyTabBarDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFFDF6F0),
      child: child,
    );
  }

  @override
  double get maxExtent => child.preferredSize.height;

  @override
  double get minExtent => child.preferredSize.height;

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}