import 'package:Innerly/home/pages/therapist_schedule.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:Innerly/home/pages/therapist_patient_details.dart';
import 'package:Innerly/home/pages/chat_screen.dart';

class Patient {
  final String id;
  final String name;
  final String issue;
  final bool isActive;
  final DateTime lastMessageTime;

  Patient({
    required this.id,
    required this.name,
    required this.issue,
    required this.isActive,
    required this.lastMessageTime,
  });
}

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Patient> _patients = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // First, query the user_profiles table to check its structure
      final profilesStructure = await _supabase
          .from('user_profiles')
          .select()
          .limit(1);

      // Now use the appropriate field names in your main query
      final response = await _supabase
          .from('private_messages')
          .select('''
          sender_id, 
          created_at,
          user_profiles!sender_id(*)
        ''')
          .eq('receiver_id', currentUser.id)
          .order('created_at', ascending: false);

      final Map<String, Patient> uniquePatients = {};
      for (final message in response) {
        final senderId = message['sender_id'] as String;
        if (uniquePatients.containsKey(senderId)) continue;

        final profile = (message['user_profiles'] as Map<String, dynamic>?) ?? {};

        // Print the profile structure to debug
        print('Profile structure: $profile');

        // Try to find the right field names
        final name = profile['name'] ??
            profile['user_name'] ??
            profile['username'] ??
            profile['display_name'] ??
            'User#${senderId.substring(0, 6)}';

        final userIssue = profile['issue'] ??
            profile['health_issue'] ??
            profile['problem'] ??
            'Not specified';

        uniquePatients[senderId] = Patient(
          id: senderId,
          name: name,
          issue: userIssue,
          isActive: true,
          lastMessageTime: DateTime.parse(message['created_at'] as String),
        );
      }

      if (mounted) {
        setState(() {
          _patients = uniquePatients.values.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load patients: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top illustration
                Container(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/patients.png',
                    height: 300,
                  ),
                ),

                // Search bar
                Container(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                  child: TextField(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Search',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFCED4DA),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFCED4DA),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF4CAF50),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Loading/Error states
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
                if (_errorMessage != null)
                  Center(child: Text(_errorMessage!)),
                if (!_isLoading && _patients.isEmpty)
                  const Center(child: Text('No patients found')),

                // Patient List
                if (!_isLoading && _patients.isNotEmpty)
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _patients.length,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          _buildPatientCard(context, _patients[index]),
                          if (index != _patients.length - 1)
                            const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, Patient patient) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PatientDetails(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: const CircleAvatar(
                radius: 28,
                backgroundImage: AssetImage('assets/icons/user.png'),
              ),
            ),

            // User Info & Buttons
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Issue: ${patient.issue}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        'Status: ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: patient.isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                      Text(
                        patient.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 14,
                          color: patient.isActive ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  receiverId: patient.id,
                                  receiverName: patient.name,
                                  isTherapist: true,
                                ),
                              ),
                            );
                          },
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    receiverId: patient.id,
                                    receiverName: patient.name,
                                    isTherapist: true,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.message,
                              size: 18,
                              color: Colors.black,
                            ),
                            label: const Text(
                              'Message',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFFCED4DA),
                                width: 1,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ScheduleScreen(),
                              ),
                            );
                          },
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ScheduleScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Colors.black,
                            ),
                            label: const Text(
                              'Schedule',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFFCED4DA),
                                width: 1,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
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
      ),
    );
  }
}