import 'package:flutter/material.dart';
import '../../services/therapist_service.dart';

class TherapistsListScreen extends StatelessWidget {
  const TherapistsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final therapistService = TherapistService();

    return Scaffold(
      appBar: AppBar(title: const Text('Available Therapists')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: therapistService.getAvailableTherapists(),
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
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(therapist['full_name']),
                subtitle: Text(therapist['specialization']),
                trailing: Icon(
                  therapist['available'] ? Icons.chat : Icons.do_not_disturb,
                  color: therapist['available'] ? Colors.green : Colors.grey,
                ),
                onTap: () {
                  if (therapist['available']) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TherapistDetailScreen(
                          therapistId: therapist['id'],
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class TherapistDetailScreen extends StatelessWidget {
  final String therapistId;

  const TherapistDetailScreen({super.key, required this.therapistId});

  @override
  Widget build(BuildContext context) {
    final therapistService = TherapistService();

    return Scaffold(
      appBar: AppBar(title: const Text('Therapist Profile')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: therapistService.getTherapistProfile(therapistId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading profile: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final therapist = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline, size: 40),
                  title: Text(
                    therapist['full_name'],
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: Text(
                    therapist['specialization'],
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 20),
                _buildDetailRow(Icons.work, 'License Number', therapist['license_number']),
                _buildDetailRow(Icons.translate, 'Languages', (therapist['languages'] as List).join(', ')),
                _buildDetailRow(Icons.access_time, 'Availability',
                    therapist['available'] ? 'Available now' : 'Currently unavailable'),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.chat),
                    label: const Text('Request Consultation'),
                    onPressed: therapist['available'] ? () {
                      therapistService.requestConsultation(therapistId);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Consultation request sent!')),
                      );
                    } : null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}