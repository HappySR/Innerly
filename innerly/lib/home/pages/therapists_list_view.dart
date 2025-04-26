import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'chat_screen.dart';
import 'appointment_screen.dart';

class TherapistsListScreen extends StatelessWidget {
  const TherapistsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5E6), // Light creamy background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF5E6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Therapists',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: const AvailableTherapistsTab(),
    );
  }
}

class AvailableTherapistsTab extends StatelessWidget {
  const AvailableTherapistsTab({super.key});

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
          return Center(child: Text('Failed to load therapists.'));
        }

        final therapists = snapshot.data ?? [];

        if (therapists.isEmpty) {
          return const Center(child: Text('No Therapists Available'));
        }

        // Dummy split (you can split based on some criteria like tags)
        final greatMatch = therapists.take(2).toList();
        final specializing = therapists.skip(2).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 16),
              _buildSectionTitle(context, 'Great Match'),
              const SizedBox(height: 8),
              _buildTherapistList(context, greatMatch, cardColor: const Color(0xFFFFF1DC)),
              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Specializing in Sleep help'),
              const SizedBox(height: 8),
              _buildTherapistList(context, specializing, cardColor: const Color(0xFFFFE4E1)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
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
          child: const Text('See All'),
        ),
      ],
    );
  }

  Widget _buildTherapistList(BuildContext context, List<Map<String, dynamic>> therapists, {required Color cardColor}) {
    return Column(
      children: therapists.map((therapist) {
        final name = therapist['name']?.toString() ?? 'Therapist';
        final specialization = therapist['specialization']?.toString() ?? 'Mental Health';
        return Card(
          color: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TherapistDetailScreen(therapist: therapist),
                ),
              );
            },
            leading: CircleAvatar(
              backgroundImage: NetworkImage(therapist['photo_url'] ?? 'https://cdn.pixabay.com/photo/2017/05/10/13/36/doctor-2300898_1280.png'), // fallback if needed
              backgroundColor: Colors.grey[200],
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(specialization),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.orange, size: 18),
                const SizedBox(width: 4),
                const Text('5.0'),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class ChatHistoryTab extends StatelessWidget {
  const ChatHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final chatHistory = [
      {'therapist': 'Dr. Smith', 'lastMessage': 'How are you feeling today?', 'time': '2h ago'},
      {'therapist': 'Dr. Johnson', 'lastMessage': 'Remember our session tomorrow', 'time': '1d ago'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: chatHistory.length,
      itemBuilder: (context, index) {
        final chat = chatHistory[index];
        return Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[50],
              child: const Icon(Icons.chat, color: Colors.blue),
            ),
            title: Text(chat['therapist']!),
            subtitle: Text(chat['lastMessage']!),
            trailing: Text(chat['time']!, style: const TextStyle(color: Colors.grey)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    receiverId: 'therapist_id_here', // Replace
                    receiverName: chat['therapist']!,
                    isTherapist: true,
                  ),
                ),
              );
            },
          ),
        );
      },
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
        title: const Text('Therapist Profile'),
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
                        isOnline ? 'Online Now' : 'Offline',
                        style: TextStyle(
                          color: isOnline ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (lastActive != null && !isOnline) ...[
                        const SizedBox(width: 8),
                        Text(
                          '• Last active: ${_formatLastActive(lastActive)}',
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
              'Professional Information',
              [
                _buildDetailRow(
                    Icons.work_outline,
                    'Experience',
                    '$experience years'
                ),
                if (hourlyRate != null)
                  _buildDetailRow(
                      Icons.attach_money,
                      'Hourly Rate',
                      '\$${hourlyRate.toStringAsFixed(2)}'
                  ),
                _buildDetailRow(
                    Icons.verified,
                    'Verification Status',
                    status
                ),
              ],
            ),
            const SizedBox(height: 16),

            // About Section
            _buildDetailSection(
              context,
              'About',
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
                    label: const Text('Start Chat'),
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
                    label: const Text('Book Appointment'),
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
        const SnackBar(content: Text('Invalid therapist ID')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          receiverId: therapistId,
          receiverName: therapist['name'] ?? 'Therapist',
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

  String _formatLastActive(DateTime lastActive) {
    final difference = DateTime.now().difference(lastActive);
    if (difference.inDays > 30) return '${difference.inDays ~/ 30}mo ago';
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    return '${difference.inMinutes}m ago';
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