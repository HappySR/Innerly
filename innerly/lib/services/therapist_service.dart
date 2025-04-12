import 'package:supabase_flutter/supabase_flutter.dart';

class TherapistService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getAvailableTherapists() async {
    final response = await _supabase
        .from('therapists')
        .select()
        .eq('available', true)
        .order('rating', ascending: false);

    return response;
  }

  Future<Map<String, dynamic>> getTherapistProfile(String therapistId) async {
    final response = await _supabase
        .from('therapists')
        .select()
        .eq('id', therapistId)
        .single();

    return response;
  }

  Future<void> requestConsultation(String therapistId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _supabase.from('consultations').insert({
      'user_id': userId,
      'therapist_id': therapistId,
      'status': 'requested',
    });
  }
}