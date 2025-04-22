import 'package:supabase_flutter/supabase_flutter.dart';

class TherapistService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Set therapist availability slots
  Future<void> setAvailability({
    required String therapistId,
    required List<Map<String, dynamic>> slots,
  }) async {
    try {
      // Delete existing slots
      await _supabase
          .from('availability')
          .delete()
          .match({'therapist_id': therapistId});

      // Insert new slots
      await _supabase.from('availability').insert(
          slots.map((slot) => {
            'therapist_id': therapistId,
            'day_of_week': slot['day'],
            'start_time': slot['start'],
            'end_time': slot['end'],
            'is_recurring': slot['is_recurring'] ?? true,
          }).toList());
    } catch (e) {
      throw Exception('Failed to set availability: ${e.toString()}');
    }
  }

  // Get stream of available therapists (realtime updates)
  Stream<List<Map<String, dynamic>>> getAvailableTherapistsStream() {
    return _supabase
        .from('therapists')
        .stream(primaryKey: ['id'])
        .order('last_active', ascending: false)
        .map((data) => data.where((t) =>
    t['is_approved'] == true &&
        t['is_online'] == true).toList());
  }

  // Get single therapist profile
  Future<Map<String, dynamic>> getTherapistProfile(String therapistId) async {
    try {
      final response = await _supabase
          .from('therapists')
          .select('*, availability(*)')
          .eq('id', therapistId)
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to get therapist profile: ${e.toString()}');
    }
  }

  // Update therapist online status
  Future<void> updateOnlineStatus({
    required String therapistId,
    required bool isOnline,
  }) async {
    try {
      await _supabase.from('therapists')
          .update({
        'is_online': isOnline,
        'last_active': DateTime.now().toIso8601String(),
      })
          .eq('id', therapistId);
    } catch (e) {
      throw Exception('Failed to update online status: ${e.toString()}');
    }
  }

  // Get therapist's upcoming appointments
  Future<List<Map<String, dynamic>>> getUpcomingAppointments(
      String therapistId) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('appointments')
          .select('*, users(*)')
          .eq('therapist_id', therapistId)
          .gte('start_time', now)
          .order('start_time');

      return response;
    } catch (e) {
      throw Exception('Failed to get appointments: ${e.toString()}');
    }
  }

  // Get therapist availability for a specific day
  Future<List<Map<String, dynamic>>> getTherapistAvailability({
    required String therapistId,
    required int dayOfWeek,
  }) async {
    try {
      final response = await _supabase
          .from('availability')
          .select()
          .eq('therapist_id', therapistId)
          .eq('day_of_week', dayOfWeek)
          .order('start_time');

      return response;
    } catch (e) {
      throw Exception('Failed to get availability: ${e.toString()}');
    }
  }

  // Search therapists by specialization
  Future<List<Map<String, dynamic>>> searchTherapists({
    String? specialization,
    int? minExperience,
    double? maxRate,
  }) async {
    try {
      final response = await _supabase
          .from('therapists')
          .select()
          .eq('is_approved', true)
          .like('specialization', specialization != null ? '%$specialization%' : '%%')
          .gte('experience', minExperience ?? 0)
          .lte('hourly_rate', maxRate ?? double.infinity)
          .order('last_active', ascending: false);

      return response;
    } catch (e) {
      throw Exception('Failed to search therapists: ${e.toString()}');
    }
  }

  // Get therapist's working hours for a specific date
  Future<List<Map<String, dynamic>>> getTherapistWorkingHours({
    required String therapistId,
    required DateTime date,
  }) async {
    try {
      final dayOfWeek = date.weekday;
      final response = await _supabase
          .from('availability')
          .select()
          .eq('therapist_id', therapistId)
          .eq('day_of_week', dayOfWeek);

      return response;
    } catch (e) {
      throw Exception('Failed to get working hours: ${e.toString()}');
    }
  }
}