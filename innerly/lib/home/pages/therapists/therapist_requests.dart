import 'package:Innerly/home/pages/therapists/therapist_appointment.dart';
import 'package:Innerly/home/pages/therapists/therapist_schedule.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatientsRequests extends StatefulWidget {
  final String status;
  const PatientsRequests({super.key, this.status = 'pending'});

  @override
  State<PatientsRequests> createState() => _PatientsRequestsState();
}

class _PatientsRequestsState extends State<PatientsRequests> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

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
          .eq('status', widget.status)
          .order('created_at', ascending: false);

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

  Future<void> _updateAppointmentStatus(String appointmentId, String status) async {
    try {
      await _supabase
          .from('appointments')
          .update({'status': status})
          .eq('id', appointmentId);

      _fetchAppointments();
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

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.schedule, color: Color(0xFF6FA57C)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TherapistsAppointmentScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.02,  // Reduced vertical padding
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Image.asset(
                  'assets/images/meditation.png',
                  width: screenWidth * 0.8,
                  height: screenHeight * 0.25,  // Adjusted height
                  fit: BoxFit.contain,
                ),
                SizedBox(height: screenHeight * 0.02),
                Text(
                  'Take a deep breath',
                  style: GoogleFonts.aclonica(
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  widget.status == 'pending'
                      ? '"You have ${_appointments.length} new requests from users."'
                      : '"You have ${_appointments.length} approved appointments."',
                  style: GoogleFonts.abyssinicaSil(
                    fontSize: screenWidth * 0.04,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.status == 'pending')
                  Padding(
                    padding: EdgeInsets.only(top: screenHeight * 0.03),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ScheduleScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6FA57C),
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.015,
                          horizontal: screenWidth * 0.1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.06),
                        ),
                      ),
                      child: Text(
                        'Appointments',
                        style: GoogleFonts.aclonica(
                          fontSize: screenWidth * 0.05,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: screenHeight * 0.03),
            Text(
              widget.status == 'pending' ? 'Pending Requests' : 'Approved Appointments',
              style: GoogleFonts.montserrat(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: screenHeight * 0.015),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : _appointments.isEmpty
                ? Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Text(
                widget.status == 'pending'
                    ? 'No pending requests'
                    : 'No approved appointments',
                style: GoogleFonts.abyssinicaSil(
                  fontSize: screenWidth * 0.04,
                  color: Colors.grey,
                ),
              ),
            )
                : Column(
              children: _appointments
                  .map((appointment) => _sessionCard(
                appointment: appointment,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sessionCard({
    required Map<String, dynamic> appointment,
    required double screenWidth,
    required double screenHeight,
  }) {
    final client = appointment['client'] as Map<String, dynamic>? ?? {};
    final meta = client['raw_user_meta_data'] ?? {};
    final scheduledAt = DateTime.parse(appointment['scheduled_at']).toLocal();

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
      child: Row(
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta['full_name']?.toString() ?? 'Anonymous User',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      DateFormat('MMM dd, yyyy - hh:mm a').format(scheduledAt),
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                    if (appointment['notes'] != null)
                      Padding(
                        padding: EdgeInsets.only(top: screenHeight * 0.005),
                        child: Text(
                          appointment['notes'].toString(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: screenWidth * 0.035,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.015),
                if (widget.status == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(screenWidth * 0.03),
                            border: Border.all(
                              color: const Color(0xFF4CAF50),
                              width: 1,
                            ),
                          ),
                          child: TextButton(
                            onPressed: () => _updateAppointmentStatus(
                              appointment['id'].toString(),
                              'approved',
                            ),
                            child: Text(
                              'Accept',
                              style: TextStyle(
                                color: const Color(0xFF4CAF50),
                                fontWeight: FontWeight.w500,
                                fontSize: screenWidth * 0.04,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(screenWidth * 0.03),
                            border: Border.all(
                              color: const Color(0xFFE53935),
                              width: 1,
                            ),
                          ),
                          child: TextButton(
                            onPressed: () => _updateAppointmentStatus(
                              appointment['id'].toString(),
                              'declined',
                            ),
                            child: Text(
                              'Decline',
                              style: TextStyle(
                                color: const Color(0xFFE53935),
                                fontWeight: FontWeight.w500,
                                fontSize: screenWidth * 0.04,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}