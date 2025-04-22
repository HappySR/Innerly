import 'package:flutter/material.dart';
import '../../services/therapist_service.dart';

class TherapistsListScreen extends StatelessWidget {
  const TherapistsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final therapistService = TherapistService();

    return Scaffold(
      appBar: AppBar(title: const Text('Available Therapists')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: therapistService.getAvailableTherapistsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final therapists = snapshot.data!;
          return ListView.builder(
            itemCount: therapists.length,
            itemBuilder: (context, index) {
              final therapist = therapists[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(therapist['name']?[0] ?? 'T'),
                  ),
                  title: Text(therapist['name'] ?? 'Therapist'),
                  subtitle: Text(therapist['specialization'] ?? 'Counselor'),
                  trailing: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: therapist['is_online'] ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TherapistDetailScreen(
                          therapist: therapist,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class TherapistDetailScreen extends StatelessWidget {
  final Map<String, dynamic> therapist;

  const TherapistDetailScreen({super.key, required this.therapist});

  @override
  Widget build(BuildContext context) {
    final therapistService = TherapistService();

    return Scaffold(
      appBar: AppBar(title: const Text('Therapist Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    child: Text(
                      therapist['name']?[0] ?? 'T',
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    therapist['name'] ?? 'Therapist',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    therapist['specialization'] ?? 'Counselor',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailSection(
              context,
              'Professional Information',
              [
                _buildDetailRow(Icons.work_outline, 'Experience',
                    '${therapist['experience'] ?? 'N/A'} years'),
                _buildDetailRow(Icons.attach_money, 'Hourly Rate',
                    '\$${therapist['hourly_rate']?.toStringAsFixed(2) ?? 'N/A'}'),
                _buildDetailRow(Icons.verified, 'Status',
                    therapist['is_approved'] ? 'Verified' : 'Pending Verification'),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailSection(
              context,
              'About',
              [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    therapist['bio'] ?? 'No bio provided',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.chat),
                    label: const Text('Start Chat'),
                    onPressed: therapist['is_online']
                        ? () {
                      // Navigate to chat screen
                    }
                        : null,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Book Appointment'),
                    onPressed: () {
                      // Navigate to booking screen
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}