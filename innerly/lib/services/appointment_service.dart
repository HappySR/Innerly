import 'package:flutter/foundation.dart';

class AppointmentService with ChangeNotifier {
  Future<bool> bookAppointment({
    required String therapistId,
    required String therapistName,
    required DateTime appointmentTime,
    required String notes,
  }) async {
    // Implement your actual booking logic here
    // This is a mock implementation
    await Future.delayed(const Duration(seconds: 1));
    if (kDebugMode) {
      print('Booking appointment with $therapistName at $appointmentTime');
    }
    return true;
  }
}