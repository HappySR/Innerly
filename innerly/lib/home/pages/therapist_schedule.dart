import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

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

  List<Map<String, dynamic>> get upcomingAppointments {
    final upcoming = _appointments
        .where((appt) => appt['status'] == 'approved')
        .toList();
    upcoming.sort((a, b) => DateTime.parse(a['scheduled_at'])
        .compareTo(DateTime.parse(b['scheduled_at'])));
    return upcoming;
  }

  List<Map<String, dynamic>> get pastAppointments {
    final past = _appointments
        .where((appt) => appt['status'] == 'done')
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
    });
  }

  Future<void> _fetchAppointments() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final appointments = await _supabase
          .from('appointments')
          .select()
          .eq('therapist_id', userId)
          .inFilter('status', ['approved', 'done'])
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
    } catch (e) {
      print('Fetch error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAppointmentDone(String appointmentId) async {
    try {
      await _supabase
          .from('appointments')
          .update({'status': 'done'})
          .eq('id', appointmentId);
      await _fetchAppointments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF6F0),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: screenHeight * 0.04),
                        child: Text(
                          "TODAY'S SCHEDULE",
                          style: GoogleFonts.aboreto(
                            fontSize: screenWidth * 0.065,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    _calendar(screenWidth),
                    SizedBox(height: screenHeight * 0.03),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.02),
                      child: Text(
                        "Appointments",
                        style: GoogleFonts.montserrat(
                          fontSize: screenWidth * 0.045,
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
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Tab(
                        child: Text(
                          'Past',
                          style: GoogleFonts.montserrat(
                            fontSize: screenWidth * 0.04,
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
              _buildAppointmentsList(upcomingAppointments, screenWidth, screenHeight),
              _buildAppointmentsList(pastAppointments, screenWidth, screenHeight),
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
      ) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : appointments.isEmpty
        ? Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Text(
          'No appointments found',
          style: GoogleFonts.abyssinicaSil(
            fontSize: screenWidth * 0.04,
            color: Colors.grey,
          ),
        ),
      ),
    )
        : ListView.builder(
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.02),
      itemCount: appointments.length,
      itemBuilder: (context, index) => _appointmentCard(
        appointment: appointments[index],
        screenWidth: screenWidth,
        screenHeight: screenHeight,
      ),
    );
  }

  Widget _calendar(double screenWidth) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(screenWidth * 0.04)),
          elevation: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.all(screenWidth * 0.03),
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
                  cellPadding: EdgeInsets.all(screenWidth * 0.015),
                  defaultTextStyle: TextStyle(
                    fontSize: screenWidth * 0.035,
                  ),
                  todayTextStyle: TextStyle(
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: const Color(0xFF7A2DED),
                    fontWeight: FontWeight.w600,
                    fontSize: screenWidth * 0.035,
                  ),
                  weekendStyle: TextStyle(
                    color: const Color(0xFF7A2DED),
                    fontWeight: FontWeight.w600,
                    fontSize: screenWidth * 0.035,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: screenWidth * 0.045,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    size: screenWidth * 0.06,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    size: screenWidth * 0.06,
                  ),
                  headerPadding: EdgeInsets.only(
                    bottom: screenWidth * 0.04,
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
  }) {
    final client = appointment['client'] as Map<String, dynamic>? ?? {};
    final meta = client['raw_user_meta_data'] ?? {};
    final scheduledAt = DateTime.parse(appointment['scheduled_at']).toLocal();
    final date = DateFormat('d').format(scheduledAt);
    final monthYear = DateFormat('MMMM y').format(scheduledAt);
    final time = DateFormat('h:mm a').format(scheduledAt);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.02,
      ),
      margin: EdgeInsets.only(bottom: screenHeight * 0.015),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
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
                radius: screenWidth * 0.07,
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta['full_name']?.toString() ?? 'Anonymous User',
                      style: GoogleFonts.montserrat(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      "Issue: ${appointment['notes']?.toString() ?? 'General Consultation'}",
                      style: TextStyle(fontSize: screenWidth * 0.035),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Row(
                      children: [
                        Icon(Icons.circle,
                            size: screenWidth * 0.03, color: Colors.green),
                        SizedBox(width: screenWidth * 0.015),
                        Text(
                          "Status: ${appointment['status']}",
                          style: TextStyle(fontSize: screenWidth * 0.035),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _infoBox(
                  icon: Icons.calendar_today,
                  label: "$date ${_getOrdinal(int.parse(date))} $monthYear",
                  screenWidth: screenWidth,
                ),
                SizedBox(width: screenWidth * 0.04),
                _infoBox(
                  icon: Icons.access_time,
                  label: time,
                  screenWidth: screenWidth,
                ),
              ],
            ),
          ),
          if (appointment['status'] == 'approved')
            Padding(
              padding: EdgeInsets.only(top: screenHeight * 0.015),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6FA57C),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: screenHeight * 0.01,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                  ),
                  onPressed: () => _markAppointmentDone(appointment['id'].toString()),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoBox({
    required IconData icon,
    required String label,
    required double screenWidth,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.06,
        vertical: screenWidth * 0.02,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        border: Border.all(color: const Color(0xFF6FA57C), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: screenWidth * 0.04, color: Colors.black87),
          SizedBox(width: screenWidth * 0.015),
          Text(
            label,
            style: TextStyle(
              fontSize: screenWidth * 0.035,
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