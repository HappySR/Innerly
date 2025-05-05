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
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAppointments());
  }

  Future<void> _fetchAppointments() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await _supabase
          .from('appointments')
          .select('*, therapists_availability(*)')
          .eq('therapist_id', userId)
          .eq('status', widget.status)
          .order('scheduled_at', ascending: false);

      final userIds = (response as List)
          .where((a) => a['user_id'] != null)
          .map<String>((a) => a['user_id'].toString())
          .toList();

      if (userIds.isEmpty) {
        setState(() {
          _appointments = [];
          _isLoading = false;
        });
        return;
      }

      final usersResponse = await _supabase
          .from('users')
          .select()
          .inFilter('id', userIds);

      final usersList = List<Map<String, dynamic>>.from(usersResponse as List);

      final combined = response.map((appointment) {
        final user = usersList.firstWhere(
              (u) => u['id'] == appointment['user_id'].toString(),
          orElse: () => <String, dynamic>{},
        );

        return {
          ...appointment,
          'client': {
            ...user,
            'raw_user_meta_data': (user['raw_user_meta_data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
          }
        };
      }).toList();

      setState(() {
        _appointments = List<Map<String, dynamic>>.from(combined);
        _isLoading = false;
      });
    } catch (e) {
      print('Fetch error: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load appointments: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateAppointmentStatus(String appointmentId, String status) async {
    try {
      await _supabase
          .from('appointments')
          .update({'status': status})
          .eq('id', appointmentId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment ${status.toLowerCase()} successfully')),
      );
      await _fetchAppointments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.schedule, color: Color(0xFF6FA57C)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TherapistsAppointmentScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenSize.width * 0.04,
          vertical: screenSize.height * 0.02,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderSection(screenSize),
            SizedBox(height: screenSize.height * 0.03),
            _buildAppointmentsList(screenSize),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(Size screenSize) {
    return Column(
      children: [
        Image.asset(
          'assets/images/meditation.png',
          width: screenSize.width * 0.8,
          height: screenSize.height * 0.25,
          fit: BoxFit.contain,
        ),
        SizedBox(height: screenSize.height * 0.02),
        Text(
          'Take a deep breath',
          style: GoogleFonts.aclonica(
            fontSize: screenSize.width * 0.06,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: screenSize.height * 0.01),
        Text(
          widget.status == 'pending'
              ? '"You have ${_appointments.length} new requests from users."'
              : '"You have ${_appointments.length} approved appointments."',
          style: GoogleFonts.abyssinicaSil(
            fontSize: screenSize.width * 0.04,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        if (widget.status == 'pending')
          Padding(
            padding: EdgeInsets.only(top: screenSize.height * 0.03),
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScheduleScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6FA57C),
                padding: EdgeInsets.symmetric(
                  vertical: screenSize.height * 0.015,
                  horizontal: screenSize.width * 0.1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenSize.width * 0.06),
                ),
              ),
              child: Text(
                'Appointments',
                style: GoogleFonts.aclonica(
                  fontSize: screenSize.width * 0.05,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAppointmentsList(Size screenSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.status == 'pending' ? 'Pending Requests' : 'Approved Appointments',
          style: GoogleFonts.montserrat(
            fontSize: screenSize.width * 0.045,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: screenSize.height * 0.015),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _appointments.isEmpty
            ? Padding(
          padding: EdgeInsets.all(screenSize.width * 0.04),
          child: Text(
            widget.status == 'pending' ? 'No pending requests' : 'No approved appointments',
            style: GoogleFonts.abyssinicaSil(
              fontSize: screenSize.width * 0.04,
              color: Colors.grey,
            ),
          ),
        )
            : Column(
          children: _appointments
              .map((appointment) => _SessionCard(
            appointment: appointment,
            screenSize: screenSize,
            status: widget.status,
            onUpdateStatus: _updateAppointmentStatus,
          ))
              .toList(),
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final Size screenSize;
  final String status;
  final Function(String, String) onUpdateStatus;

  const _SessionCard({
    required this.appointment,
    required this.screenSize,
    required this.status,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final client = (appointment['client'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final meta = (client['raw_user_meta_data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final scheduledAt = DateTime.parse(appointment['scheduled_at'].toString()).toLocal();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenSize.width * 0.04,
        vertical: screenSize.height * 0.02,
      ),
      margin: EdgeInsets.only(bottom: screenSize.height * 0.015),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenSize.width * 0.04),
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
            radius: screenSize.width * 0.07,
          ),
          SizedBox(width: screenSize.width * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta['full_name']?.toString() ?? 'Anonymous User',
                  style: TextStyle(
                    fontSize: screenSize.width * 0.04,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: screenSize.height * 0.005),
                Text(
                  DateFormat('MMM dd, yyyy - hh:mm a').format(scheduledAt),
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: screenSize.width * 0.035,
                  ),
                ),
                if (appointment['notes'] != null)
                  Padding(
                    padding: EdgeInsets.only(top: screenSize.height * 0.005),
                    child: Text(
                      appointment['notes'].toString(),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: screenSize.width * 0.035,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (status == 'pending') _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.only(top: screenSize.height * 0.015),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => onUpdateStatus(appointment['id'].toString(), 'confirmed'),
              style: _buttonStyle(color: const Color(0xFF4CAF50)),
              child: Text('Accept', style: _buttonTextStyle(color: const Color(0xFF4CAF50))),
            ),
          ),
          SizedBox(width: screenSize.width * 0.04),
          Expanded(
            child: OutlinedButton(
              onPressed: () => onUpdateStatus(appointment['id'].toString(), 'rejected'),
              style: _buttonStyle(color: const Color(0xFFE53935)),
              child: Text('Decline', style: _buttonTextStyle(color: const Color(0xFFE53935))),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _buttonStyle({required Color color}) {
    return OutlinedButton.styleFrom(
      side: BorderSide(color: color, width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenSize.width * 0.03),
      ),
    );
  }

  TextStyle _buttonTextStyle({required Color color}) {
    return TextStyle(
      color: color,
      fontWeight: FontWeight.w500,
      fontSize: screenSize.width * 0.04,
    );
  }
}