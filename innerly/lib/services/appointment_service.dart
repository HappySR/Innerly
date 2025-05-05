import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  /// Books an appointment with a therapist
  ///
  /// Returns true if booking was successful, false otherwise
  Future<bool> bookAppointment({
    required String therapistId,
    required DateTime appointmentTime,
    required DateTime endTime,
    required String availabilityId,
    required String appointmentDate,
    String? notes,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if the slot is still available
      final slotCheckResponse = await _checkSlotAvailability(
        therapistId: therapistId,
        appointmentDate: appointmentDate,
        availabilityId: availabilityId,
      );

      // If slot is no longer available, return false
      if (!slotCheckResponse.isAvailable) {
        debugPrint('Slot no longer available: ${slotCheckResponse.reason}');
        return false;
      }

      // Create appointment
      final appointmentData = {
        'user_id': userId,
        'therapist_id': therapistId,
        'scheduled_at': appointmentTime.toUtc().toIso8601String(),
        'end_time': endTime.toUtc().toIso8601String(),
        'notes': notes,
        'status': 'pending',
        'availability_id': availabilityId,
        'appointment_date': appointmentDate, // Add this line to include the appointment_date field
      };

      final response = await _supabase.from('appointments').insert(appointmentData).select();

      debugPrint('Appointment created: ${response.first['id']}');

      // Notify listeners that the data has changed
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error booking appointment: $e');
      rethrow;
    }
  }

  /// Checks if a slot is still available
  Future<SlotAvailabilityResponse> _checkSlotAvailability({
    required String therapistId,
    required String appointmentDate,
    required String availabilityId,
  }) async {
    try {
      // 1. Check if the day is marked as off day
      final exceptionsResponse = await _supabase
          .from('therapist_schedule_exceptions')
          .select()
          .eq('therapist_id', therapistId)
          .eq('is_available', false)
          .eq('exception_date', appointmentDate);

      if (exceptionsResponse.isNotEmpty) {
        return SlotAvailabilityResponse(
          isAvailable: false,
          reason: 'This day is marked as unavailable by the therapist',
        );
      }

      // 2. Check if the availability still exists
      final availabilityResponse = await _supabase
          .from('therapists_availability')
          .select()
          .eq('id', availabilityId)
          .eq('is_availability', true);

      if (availabilityResponse.isEmpty) {
        return SlotAvailabilityResponse(
          isAvailable: false,
          reason: 'This time slot is no longer available',
        );
      }

      // 3. Check if the slot is already fully booked
      final slot = availabilityResponse.first;
      final maxPatients = slot['max_patients'] ?? 1;

      // Get all existing appointments for this slot
      final appointmentsResponse = await _supabase
          .from('appointments')
          .select()
          .eq('therapist_id', therapistId)
          .eq('availability_id', availabilityId)
          .inFilter('status', ['pending', 'confirmed']);

      if (appointmentsResponse.length >= maxPatients) {
        return SlotAvailabilityResponse(
          isAvailable: false,
          reason: 'This time slot is fully booked',
        );
      }

      return SlotAvailabilityResponse(isAvailable: true);
    } catch (e) {
      debugPrint('Error checking slot availability: $e');
      rethrow;
    }
  }

  /// Gets all appointments for the current user
  Future<List<Map<String, dynamic>>> getUserAppointments() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('appointments')
          .select('''
            *,
            therapists (
              id, name, profile_image, specialization
            )
          ''')
          .eq('user_id', userId)
          .order('scheduled_at', ascending: true);

      // Convert to List<Map<String, dynamic>>
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting user appointments: $e');
      return [];
    }
  }

  /// Gets all upcoming appointments for the current user
  Future<List<Map<String, dynamic>>> getUpcomingAppointments() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now().toUtc().toIso8601String();

      final response = await _supabase
          .from('appointments')
          .select('''
            *,
            therapists (
              id, name, profile_image, specialization
            )
          ''')
          .eq('user_id', userId)
          .gte('scheduled_at', now)
          .inFilter('status', ['pending', 'confirmed'])
          .order('scheduled_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting upcoming appointments: $e');
      return [];
    }
  }

  /// Gets all past appointments for the current user
  Future<List<Map<String, dynamic>>> getPastAppointments() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now().toUtc().toIso8601String();

      final response = await _supabase
          .from('appointments')
          .select('''
            *,
            therapists (
              id, name, profile_image, specialization
            )
          ''')
          .eq('user_id', userId)
          .lt('scheduled_at', now)
          .order('scheduled_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting past appointments: $e');
      return [];
    }
  }

  /// Cancels an appointment
  Future<bool> cancelAppointment(String appointmentId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if appointment belongs to user
      final appointmentCheck = await _supabase
          .from('appointments')
          .select()
          .eq('id', appointmentId)
          .eq('user_id', userId)
          .single();

      if (appointmentCheck == null) {
        throw Exception('Appointment not found or does not belong to user');
      }

      // Update appointment status
      await _supabase
          .from('appointments')
          .update({'status': 'cancelled'})
          .eq('id', appointmentId);

      // Notify listeners that the data has changed
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error cancelling appointment: $e');
      return false;
    }
  }

  /// Reschedules an appointment
  Future<bool> rescheduleAppointment({
    required String appointmentId,
    required DateTime newAppointmentTime,
    required DateTime newEndTime,
    required String newAvailabilityId,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if appointment belongs to user
      final appointmentCheck = await _supabase
          .from('appointments')
          .select()
          .eq('id', appointmentId)
          .eq('user_id', userId)
          .single();

      if (appointmentCheck == null) {
        throw Exception('Appointment not found or does not belong to user');
      }

      // Get the appointment date for checking availability
      final appointmentDate = DateTime(
        newAppointmentTime.year,
        newAppointmentTime.month,
        newAppointmentTime.day,
      ).toIso8601String().split('T')[0];

      // Check if the new slot is available
      final slotCheckResponse = await _checkSlotAvailability(
        therapistId: appointmentCheck['therapist_id'],
        appointmentDate: appointmentDate,
        availabilityId: newAvailabilityId,
      );

      if (!slotCheckResponse.isAvailable) {
        debugPrint('New slot not available: ${slotCheckResponse.reason}');
        return false;
      }

      // Update appointment
      await _supabase
          .from('appointments')
          .update({
        'scheduled_at': newAppointmentTime.toUtc().toIso8601String(),
        'end_time': newEndTime.toUtc().toIso8601String(),
        'availability_id': newAvailabilityId,
        'appointment_date': appointmentDate, // Add this line to include the appointment_date field
        'status': 'pending',  // Reset to pending on reschedule
      })
          .eq('id', appointmentId);

      // Notify listeners that the data has changed
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Error rescheduling appointment: $e');
      return false;
    }
  }
}

/// Response class for slot availability check
class SlotAvailabilityResponse {
  final bool isAvailable;
  final String? reason;

  SlotAvailabilityResponse({
    required this.isAvailable,
    this.reason,
  });
}