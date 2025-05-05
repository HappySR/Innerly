import 'package:Innerly/home/pages/therapists/therapist_schedule.dart';
import 'package:Innerly/localization/i10n.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:Innerly/home/pages/therapists/therapist_patient_details.dart';
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

class _PatientsPageState extends State<PatientsPage>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Patient> _patients = [];
  List<Patient> _chatHistory = [];
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;
  late RealtimeChannel _messagesChannel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _messagesChannel = _supabase.channel('patients_messages');
    _setupRealtimeUpdates();
    _fetchData();
  }

  void _setupRealtimeUpdates() {
    _messagesChannel = Supabase.instance.client
        .channel('public:private_messages')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'private_messages',
      callback: (payload) {
        if (mounted) {
          _fetchData(); // Refresh data when new message is inserted
        }
      },
    )
        .subscribe();
  }

  Future<void> _fetchData() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception(L10n.getTranslatedText(context, 'User not authenticated'));

      // Fetch latest received messages
      final messagesResponse = await _supabase
          .from('private_messages')
          .select('sender_id, created_at, user_profiles!sender_id(*)')
          .eq('receiver_id', currentUser.id)
          .order('created_at', ascending: false);

      // Fetch sent messages history
      final historyResponse = await _supabase
          .from('private_messages')
          .select('receiver_id, created_at, user_profiles!receiver_id(*)')
          .eq('sender_id', currentUser.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _patients = _processMessages(messagesResponse, isReceived: true);
          _chatHistory = _processMessages(historyResponse, isReceived: false);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '${L10n.getTranslatedText(context, 'Failed to load data')}: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  List<Patient> _processMessages(List<dynamic> response, {required bool isReceived}) {
    final Map<String, Patient> uniquePatients = {};
    for (final message in response) {
      final patientId = isReceived
          ? message['sender_id'] as String
          : message['receiver_id'] as String;

      if (uniquePatients.containsKey(patientId)) continue;

      final profile = (message['user_profiles'] as Map<String, dynamic>?) ?? {};

      final name = profile['name'] ?? 'User#${patientId.substring(0, 6)}';
      final userIssue = profile['issue'] ?? L10n.getTranslatedText(context, 'Not specified');

      uniquePatients[patientId] = Patient(
        id: patientId,
        name: name,
        issue: userIssue,
        isActive: true,
        lastMessageTime: DateTime.parse(message['created_at'] as String),
      );
    }
    return uniquePatients.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EB),
      body: SafeArea(
        child: Column(
          children: [
            // Top illustration
            Container(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
              height: 250,
              child: Image.asset(
                'assets/images/patients.png',
                fit: BoxFit.contain,
              ),
            ),

            // Tabs
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicator: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                tabs: [
                  Tab(text: L10n.getTranslatedText(context, 'Latest Messages')),
                  Tab(text: L10n.getTranslatedText(context, 'Chat History')),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildContent(_patients),
                  _buildContent(_chatHistory),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<Patient> patients) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
        child: Column(
          children: [
            // Loading/Error states
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (_errorMessage != null) Center(child: Text(_errorMessage!)),
            if (!_isLoading && patients.isEmpty)
              Center(child: Text(L10n.getTranslatedText(context, 'No conversations found'))),

            // Patient List
            if (!_isLoading && patients.isNotEmpty)
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: patients.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      _buildPatientCard(context, patients[index]),
                      if (index != patients.length - 1)
                        const SizedBox(height: 12),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, Patient patient) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PatientDetails()),
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
                    '${L10n.getTranslatedText(context, 'Issue')}: ${patient.issue}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${L10n.getTranslatedText(context, 'Status')}: ',
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
                        patient.isActive ? L10n.getTranslatedText(context, 'Active') : L10n.getTranslatedText(context, 'Inactive'),
                        style: TextStyle(
                          fontSize: 14,
                          color: patient.isActive ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Buttons - Fixed widget hierarchy here
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
                            label: Text(
                              L10n.getTranslatedText(context, 'Message'),
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
                            label: Text(
                              L10n.getTranslatedText(context, 'Schedule'),
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

  @override
  void dispose() {
    _messagesChannel.unsubscribe();
    _tabController.dispose();
    super.dispose();
  }
}