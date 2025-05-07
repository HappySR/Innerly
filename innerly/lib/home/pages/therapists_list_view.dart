import 'package:Innerly/localization/i10n.dart';
import 'package:Innerly/widget/innerly_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../providers/bottom_nav_provider.dart';
import 'chat_screen.dart';
import 'appointment_screen.dart';

class TherapistsListScreen extends StatelessWidget {
  const TherapistsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // When back button is pressed, navigate to home page (index 0)
        final provider = Provider.of<BottomNavProvider>(context, listen: false);
        provider.currentIndex = 0; // Set to home page index
        return false; // Prevent default back button behavior
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: const Color(0xFFFDF5E6),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFDF5E6),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                // When back button in AppBar is clicked, navigate to home page
                final provider = Provider.of<BottomNavProvider>(context, listen: false);
                provider.currentIndex = 0; // Set to home page index
              },
            ),
            title: Text(
              L10n.getTranslatedText(context, 'Therapists'),
              style: GoogleFonts.lora(color: Colors.black),
            ),
            centerTitle: true,
            bottom: TabBar(
              tabs: [
                Tab(text: L10n.getTranslatedText(context, 'Available')),
                Tab(text: L10n.getTranslatedText(context, 'Chat History')),
              ],
              labelColor: Colors.black,
              indicatorColor: Colors.black,
              labelStyle: GoogleFonts.rubik(fontWeight: FontWeight.w500),
            ),
          ),
          body: const TabBarView(
            children: [
              OnlineTherapistsTab(),
              ChatHistoryTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class OnlineTherapistsTab extends StatelessWidget {
  const OnlineTherapistsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final therapistService = Provider.of<AuthService>(context);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: therapistService.getAvailableTherapistsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(L10n.getTranslatedText(context, 'Failed to load therapists.')));
        }

        final therapists = snapshot.data ?? [];

        if (therapists.isEmpty) {
          return Center(child: Text(L10n.getTranslatedText(context, 'No Therapists Available')));
        }

        // Dummy split (you can split based on some criteria like tags)
        final greatMatch = therapists.take(2).toList();
        final specializing = therapists.skip(2).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildSectionTitle(context, L10n.getTranslatedText(context, 'Great Match')),
              const SizedBox(height: 8),
              _buildTherapistList(context, greatMatch, cardColor: InnerlyTheme.beige),
              const SizedBox(height: 24),
              _buildSectionTitle(context, L10n.getTranslatedText(context, 'Specializing in Sleep help')),
              const SizedBox(height: 8),
              _buildTherapistList(context, specializing, cardColor: InnerlyTheme.pink),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: () {},
          child: Text(L10n.getTranslatedText(context, 'See All')),
        ),
      ],
    );
  }

  Widget _buildTherapistList(
      BuildContext context,
      List<Map<String, dynamic>> therapists, {
        required Color cardColor,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(therapists.length, (index) {
          final therapist = therapists[index];
          final name = therapist['name']?.toString() ?? 'Therapist';
          final specialization = therapist['specialization']?.toString() ?? 'Mental Health';
          final imageUrl = therapist['photo_url'] ??
              'https://cdn.pixabay.com/photo/2017/05/10/13/36/doctor-2300898_1280.png';

          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TherapistDetailScreen(therapist: therapist),
                    ),
                  );
                },
                leading: CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(imageUrl),
                  backgroundColor: Colors.grey[200],
                ),
                title: Text(
                  name,
                  style: GoogleFonts.rubik(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  specialization,
                  style: GoogleFonts.rubik(fontWeight: FontWeight.w400),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.star, color: Colors.orange, size: 18),
                    SizedBox(width: 4),
                    Text('5.0'),
                  ],
                ),
              ),
              // Divider except after last item
              if (index < therapists.length - 1)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 330, // Adjust this value based on desired width
                      child: Divider(
                        height: 0.0,
                        thickness: 1,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
            ],
          );
        }),
      ),
    );
  }
}

class ChatHistoryTab extends StatelessWidget {
  const ChatHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUserId = authService.currentUserId;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: authService.getChatHistoryStream(currentUserId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(L10n.getTranslatedText(context, 'Failed to load chat history.')));
        }

        final messages = snapshot.data ?? [];
        Map<String, Map<String, dynamic>> therapistMessages = {};

        for (var msg in messages) {
          String therapistId = (msg['sender_id'] == currentUserId)
              ? msg['receiver_id']
              : msg['sender_id'];

          // Parse timestamps to DateTime
          final msgCreatedAt = DateTime.parse(msg['created_at'] as String);
          final existingMsg = therapistMessages[therapistId];

          if (existingMsg == null) {
            therapistMessages[therapistId] = msg;
          } else {
            final existingCreatedAt = DateTime.parse(existingMsg['created_at'] as String);
            if (msgCreatedAt.isAfter(existingCreatedAt)) {
              therapistMessages[therapistId] = msg;
            }
          }
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: therapistMessages.length,
          itemBuilder: (context, index) {
            final therapistId = therapistMessages.keys.elementAt(index);
            final lastMessage = therapistMessages[therapistId]!;

            return FutureBuilder<Map<String, dynamic>>(
              future: authService.getTherapist(therapistId),
              builder: (context, therapistSnapshot) {
                if (therapistSnapshot.connectionState != ConnectionState.done) {
                  return ListTile(
                    leading: CircleAvatar(),
                    title: Text("${L10n.getTranslatedText(context, 'Loading')}..."),
                  );
                }
                final therapist = therapistSnapshot.data ?? {};
                return Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(therapist['photo_url'] ?? 'https://cdn.pixabay.com/photo/2017/05/10/13/36/doctor-2300898_1280.png'),
                    ),
                    title: Text(therapist['name'] ?? 'Therapist'),
                    subtitle: Text(lastMessage['message'] ?? ''),
                    trailing: Text(_formatTime(DateTime.parse(lastMessage['created_at'] as String))),
                    onTap: () => _navigateToChat(context, {
                      'id': therapist['id']?.toString() ?? '', // Match working version
                      'name': therapist['name']?.toString() ?? 'Therapist'
                    }),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  void _navigateToChat(BuildContext context, Map<String, dynamic> therapist) {
    // Change from 'user_id' to 'id' to match working version
    final receiverId = therapist['id']?.toString() ?? '';
    final receiverName = therapist['name']?.toString() ?? 'Therapist';

    if (receiverId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.getTranslatedText(context, 'Invalid therapist ID'))),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          receiverId: receiverId,
          receiverName: receiverName,
          isTherapist: true,
        ),
      ),
    );
  }
}

class TherapistDetailScreen extends StatelessWidget {
  final Map<String, dynamic> therapist;

  const TherapistDetailScreen({super.key, required this.therapist});

  @override
  Widget build(BuildContext context) {
    // Extract all therapist details
    final name = therapist['name']?.toString() ?? 'Anonymous Therapist';
    final specialization = therapist['specialization']?.toString() ?? 'Mental Health Professional';
    final bio = therapist['bio']?.toString() ?? 'No biography provided';
    final hourlyRate = therapist['hourly_rate'] is num
        ? (therapist['hourly_rate'] as num).toDouble()
        : null;
    final experience = therapist['experience']?.toString() ?? 'Not specified';
    final isOnline = therapist['is_online'] == true;
    final lastActive = therapist['last_active'] != null
        ? DateTime.parse(therapist['last_active'].toString())
        : null;
    final status = therapist['document_status']?.toString().toUpperCase() ?? 'PENDING';

    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.getTranslatedText(context, 'Therapist Profile')),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue[50],
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'T',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    specialization,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isOnline ? L10n.getTranslatedText(context, 'Online Now') : L10n.getTranslatedText(context, 'Offline'),
                        style: TextStyle(
                          color: isOnline ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (lastActive != null && !isOnline) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• ${L10n.getTranslatedText(context, 'Last active')}: ${_formatLastActive(lastActive, context)}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Professional Information
            _buildDetailSection(
              context,
              L10n.getTranslatedText(context, 'Professional Information'),
              [
                _buildDetailRow(
                    Icons.work_outline,
                    L10n.getTranslatedText(context, 'Experience'),
                    '$experience ${L10n.getTranslatedText(context, 'years')}'
                ),
                if (hourlyRate != null)
                  _buildDetailRow(
                      Icons.attach_money,
                      L10n.getTranslatedText(context, 'Hourly Rate'),
                      '\$${hourlyRate.toStringAsFixed(2)}'
                  ),
                _buildDetailRow(
                    Icons.verified,
                    L10n.getTranslatedText(context, 'Verification Status'),
                    status
                ),
              ],
            ),
            const SizedBox(height: 16),

            // About Section
            _buildDetailSection(
              context,
              L10n.getTranslatedText(context, 'About'),
              [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    bio,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Center(
              child: Column(
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.chat, size: 20),
                    label: Text(L10n.getTranslatedText(context, 'Start Chat')),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(200, 48),
                    ),
                    onPressed: isOnline
                        ? () => _navigateToChat(context)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 20),
                    label: Text(L10n.getTranslatedText(context, 'Book Appointment')),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(200, 48),
                    ),
                    onPressed: () => _navigateToAppointment(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _navigateToChat(BuildContext context) {
    final therapistId = therapist['id']?.toString() ?? '';
    if (therapistId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.getTranslatedText(context, 'Invalid therapist ID'))),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          receiverId: therapistId,
          receiverName: therapist['name'] ?? L10n.getTranslatedText(context, 'Therapist'),
          isTherapist: true,
        ),
      ),
    );
  }

  void _navigateToAppointment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentScreen(
          therapist: therapist,
        ),
      ),
    );
  }

  String _formatLastActive(DateTime lastActive, BuildContext context) {
    final difference = DateTime.now().difference(lastActive);
    if (difference.inDays > 30) return '${difference.inDays ~/ 30}mo ${L10n.getTranslatedText(context, 'ago')}';
    if (difference.inDays > 0) return '${difference.inDays}d ${L10n.getTranslatedText(context, 'ago')}';
    if (difference.inHours > 0) return '${difference.inHours}h ${L10n.getTranslatedText(context, 'ago')}';
    return '${difference.inMinutes}m ${L10n.getTranslatedText(context, 'ago')}';
  }

  Widget _buildDetailSection(
      BuildContext context,
      String title,
      List<Widget> children
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}