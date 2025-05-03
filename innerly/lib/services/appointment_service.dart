import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentService with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<bool> bookAppointment({
    required String therapistId,
    required DateTime appointmentTime,
    required DateTime endTime,
    required String notes,
    required String therapistName,
    String? availabilityId,
  }) async {
    try {
      // Validate user authentication
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        if (kDebugMode) {
          print('User not authenticated');
        }
        return false;
      }

      // Convert to UTC times
      final utcStart = appointmentTime.toUtc();
      final utcEnd = endTime.toUtc();

      // Check if the slot is still available (not fully booked)
      if (availabilityId != null) {
        final existingAppointments = await _supabase
            .from('appointments')
            .select('id')
            .eq('availability_id', availabilityId)
            .inFilter('status', ['pending', 'confirmed']);

        final availabilitySlot = await _supabase
            .from('therapists_availability')
            .select('max_patients')
            .eq('id', availabilityId)
            .single();

        final maxPatients = availabilitySlot['max_patients'] ?? 1;

        if (existingAppointments.length >= maxPatients) {
          if (kDebugMode) {
            print('Slot is fully booked');
          }
          return false;
        }
      }

      // Execute the insert
      final response = await _supabase.from('appointments').insert({
        'therapist_id': therapistId,
        'user_id': userId,
        'availability_id': availabilityId,
        'scheduled_at': utcStart.toIso8601String(),
        'end_time': utcEnd.toIso8601String(),
        'notes': notes,
        'status': 'pending',
        'therapist_name': therapistName,
      });

      if (kDebugMode) {
        print('Successfully booked appointment at $utcStart');
      }

      // Notify listeners that the appointments list has changed
      notifyListeners();

      return true;
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('Supabase error: ${e.message}');
        print('Details: ${e.details}');
        print('Code: ${e.code}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('General error: $e');
      }
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUserAppointments() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('appointments')
          .select('*, therapists(name, profile_photo)')
          .eq('user_id', userId)
          .order('scheduled_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching appointments: $e');
      }
      return [];
    }
  }

  Future<bool> cancelAppointment(String appointmentId) async {
    try {
      await _supabase
          .from('appointments')
          .update({'status': 'cancelled'})
          .eq('id', appointmentId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling appointment: $e');
      }
      return false;
    }
  }
}