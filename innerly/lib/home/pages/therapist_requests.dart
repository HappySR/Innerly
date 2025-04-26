import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatientsRequests extends StatefulWidget {
  const PatientsRequests({super.key});

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

      // 1. Get appointments
      final appointments = await _supabase
          .from('appointments')
          .select()
          .eq('therapist_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      if (appointments.isEmpty) {
        setState(() {
          _appointments = [];
          _isLoading = false;
        });
        return;
      }

      // 2. Get user IDs
      final userIds = appointments
          .map<String>((a) => a['user_id'] as String)
          .toList();

      // 3. CORRECTED: Access auth.users through rpc
      // Call with explicit parameter type
      final users = await _supabase.rpc(
          'get_therapist_clients',
          params: {'user_ids': userIds}
      ).select();

      // 4. Combine data
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
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Image.asset(
                  'assets/images/meditation.png',
                  width: 500,
                  height: 300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Take a deep breath',
                  style: GoogleFonts.getFont(
                    'Aclonica',
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '"You have ${_appointments.length} new requests from users."',
                  style: GoogleFonts.abyssinicaSil(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6FA57C),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 38,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'Appointments',
                    style: GoogleFonts.aclonica(
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Pending Requests
            Text(
              'Pending Requests',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _appointments.isEmpty
                ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No pending requests',
                    style: GoogleFonts.abyssinicaSil(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                )
                : Column(
                  children:
                      _appointments
                          .map(
                            (appointment) =>
                                _sessionCard(appointment: appointment),
                          )
                          .toList(),
                ),
          ],
        ),
      ),
    );
  }

  Widget _sessionCard({required Map<String, dynamic> appointment}) {
    final client = appointment['client'] as Map<String, dynamic>? ?? {};
    final meta = client['raw_user_meta_data'] ?? {};
    final scheduledAt = DateTime.parse(appointment['scheduled_at']).toLocal();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            backgroundImage: NetworkImage(
              meta['avatar_url']?.toString() ?? 'https://example.com/placeholder.png',
            ),
            onBackgroundImageError: (e, stack) {
              print('Failed to load avatar: $e');
            },
            radius: 28,
            child: meta['avatar_url'] == null
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 12),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy - hh:mm a').format(scheduledAt),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    if (appointment['notes'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          appointment['notes'].toString(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
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
                          child: const Text(
                            'Accept',
                            style: TextStyle(
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
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
                          child: const Text(
                            'Decline',
                            style: TextStyle(
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
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
