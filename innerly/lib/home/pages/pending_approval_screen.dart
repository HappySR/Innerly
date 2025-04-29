import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'therapists/started/signup_view.dart';
import 'bottom_nav.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final Stream<Map<String, dynamic>> _statusStream;

  @override
  void initState() {
    super.initState();
    _statusStream = _supabase
        .from('therapists')
        .stream(primaryKey: ['id'])
        .eq('id', _supabase.auth.currentUser!.id)
        .map((data) => data.first);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: StreamBuilder<Map<String, dynamic>>(
          stream: _statusStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final status = snapshot.data!['document_status'];

              if (status == 'approved') {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const BottomNav()),
                  );
                });
              }
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  'Your documents are under review',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                const Text('Approval typically takes 24-48 hours'),
                if (snapshot.hasData &&
                    snapshot.data!['document_status'] == 'rejected')
                  _buildRejectionMessage(snapshot.data!, context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRejectionMessage(Map<String, dynamic> data, BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.error, color: Colors.red, size: 40),
        const SizedBox(height: 10),
        Text('Rejection Reason: ${data['rejection_reason']}'),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TherapistSignUpPage()),
          ),
          child: const Text('Resubmit Documents'),
        ),
      ],
    );
  }
}