import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> bookAppointment({
    required String therapistId,
    required String userId,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    await _supabase.from('appointments').insert({
      'therapist_id': therapistId,
      'user_id': userId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'status': 'scheduled',
      'notes': notes,
    });
  }
}