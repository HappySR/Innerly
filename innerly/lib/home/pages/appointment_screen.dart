import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/appointment_service.dart';

class AppointmentScreen extends StatefulWidget {
  final Map<String, dynamic> therapist;

  const AppointmentScreen({super.key, required this.therapist});

  @override
  _AppointmentScreenState createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  Map<String, dynamic>? _selectedSlot;
  final _notesController = TextEditingController();
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _availabilitySlots = [];
  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>> _existingAppointments = {};

  @override
  void initState() {
    super.initState();
    _loadAvailabilitySlots();
  }

  Future<void> _loadAvailabilitySlots() async {
    setState(() => _isLoading = true);

    try {
      // Get all availability slots for the therapist
      final response = await _supabase
          .from('therapists_availability')
          .select()
          .eq('therapist_id', widget.therapist['id']);

      // Get existing appointments for the therapist
      final appointmentsResponse = await _supabase
          .from('appointments')
          .select()
          .eq('therapist_id', widget.therapist['id'])
          .inFilter('status', ['pending', 'confirmed']);

      // Process existing appointments
      for (final appointment in appointmentsResponse) {
        final date = DateTime.parse(appointment['scheduled_at']).toLocal();
        final dateStr = DateFormat('yyyy-MM-dd').format(date);

        if (!_existingAppointments.containsKey(dateStr)) {
          _existingAppointments[dateStr] = [];
        }

        _existingAppointments[dateStr]!.add({
          'id': appointment['id'],
          'start_time': date,
          'end_time': DateTime.parse(appointment['end_time']).toLocal(),
          'user_id': appointment['user_id'],
          'availability_id': appointment['availability_id'],
        });
      }

      setState(() {
        _availabilitySlots = response.map<Map<String, dynamic>>((slot) {
          final start = DateTime.parse(slot['scheduled_at']).toLocal();
          final end = DateTime.parse(slot['end_time']).toLocal();

          return {
            'id': slot['id'],
            'start_time': start,
            'end_time': end,
            'target_weekday': slot['target_weekday'],
            'is_recurring': slot['is_recurring'] ?? false,
            'max_patients': slot['max_patients'] ?? 1,
            'duration': slot['duration'],
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading slots: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getSlotsForDate(DateTime date) {
    // Convert to weekday (0-6, where 0 is Monday)
    final selectedWeekday = date.weekday - 1;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    final availableSlots = _availabilitySlots.where((slot) {
      final isRecurring = slot['is_recurring'] as bool;
      final targetWeekday = slot['target_weekday'] as int;
      final originalDate = slot['start_time'] as DateTime;

      // For recurring slots, check if the weekday matches and the date is not before the original date
      if (isRecurring) {
        return selectedWeekday == targetWeekday &&
            !date.isBefore(DateTime(originalDate.year, originalDate.month, originalDate.day));
      }

      // For non-recurring slots, check if the date matches exactly
      return date.year == originalDate.year &&
          date.month == originalDate.month &&
          date.day == originalDate.day;
    }).toList();

    // Create new slots with the selected date and filter out fully booked slots
    return availableSlots.map((slot) {
      final startTime = slot['start_time'] as DateTime;
      final endTime = slot['end_time'] as DateTime;
      final maxPatients = slot['max_patients'] as int;

      // Create new DateTime objects with the selected date but keep the original time
      final adjustedStartTime = DateTime(
        date.year,
        date.month,
        date.day,
        startTime.hour,
        startTime.minute,
      );

      final adjustedEndTime = DateTime(
        date.year,
        date.month,
        date.day,
        endTime.hour,
        endTime.minute,
      );

      // If end time is earlier than start time, it means it extends to the next day
      if (endTime.hour < startTime.hour ||
          (endTime.hour == startTime.hour && endTime.minute < startTime.minute)) {
        // Create a new DateTime to avoid modifying the original
        final nextDay = DateTime(date.year, date.month, date.day + 1, endTime.hour, endTime.minute);
        return {
          ...slot,
          'start_time': adjustedStartTime,
          'end_time': nextDay,
          'booked_count': _getBookedCount(dateStr, slot['id']),
        };
      }

      return {
        ...slot,
        'start_time': adjustedStartTime,
        'end_time': adjustedEndTime,
        'booked_count': _getBookedCount(dateStr, slot['id']),
      };
    }).where((slot) {
      // Filter out fully booked slots
      return slot['booked_count'] < slot['max_patients'];
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        title: Text(
          'Book with ${widget.therapist['name']}',
          style: GoogleFonts.montserrat(),
        ),
        backgroundColor: const Color(0xFFFDF6F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6FA57C)))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildDatePicker(),
              if (_selectedDate != null) _buildTimeSlots(),
              const SizedBox(height: 20),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Additional Notes',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelStyle: GoogleFonts.montserrat(),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF6FA57C), width: 2),
                  ),
                ),
                style: GoogleFonts.montserrat(),
                maxLines: 3,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submitAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6FA57C),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Book Appointment',
                  style: GoogleFonts.aclonica(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(
          _selectedDate == null
              ? 'Select Date'
              : 'Selected Date: ${DateFormat.yMMMd().format(_selectedDate!)}',
          style: GoogleFonts.montserrat(),
        ),
        trailing: const Icon(Icons.calendar_today, color: Color(0xFF4A707A)),
        onTap: () async {
          final pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            builder: (context, child) => Theme(
              data: ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF6FA57C),
                ),
                dialogBackgroundColor: const Color(0xFFFDF6F0),
              ),
              child: child!,
            ),
          );
          if (pickedDate != null) {
            setState(() {
              _selectedDate = pickedDate;
              _selectedSlot = null;
            });
          }
        },
      ),
    );
  }

  Widget _buildTimeSlots() {
    final slots = _getSlotsForDate(_selectedDate!);

    if (slots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Icon(
                  Icons.event_busy,
                  color: Color(0xFF4A707A),
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'No available slots for this day',
                  style: GoogleFonts.montserrat(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: Text(
            'Available Time Slots:',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: slots.length,
          itemBuilder: (context, index) {
            final slot = slots[index];
            final startTime = slot['start_time'] as DateTime;
            final endTime = slot['end_time'] as DateTime;
            final formattedStartTime = DateFormat('h:mm a').format(startTime);
            final formattedEndTime = DateFormat('h:mm a').format(endTime);
            final isSelected = _selectedSlot != null && _selectedSlot!['id'] == slot['id'];
            final maxPatients = slot['max_patients'] as int;
            final bookedCount = slot['booked_count'] as int? ?? 0;
            final availableSpots = maxPatients - bookedCount;

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF6FA57C) : Colors.transparent,
                  width: 2,
                ),
              ),
              color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
              child: InkWell(
                onTap: () => setState(() => _selectedSlot = isSelected ? null : slot),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Color(0xFF4A707A), size: 20),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$formattedStartTime - $formattedEndTime',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (maxPatients > 1)
                            Text(
                              '$availableSpots of $maxPatients spots available',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                      if (slot['is_recurring'])
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Chip(
                            label: Text(
                              'Weekly',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: const Color(0xFF7E9680),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                        ),
                      const Spacer(),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: Color(0xFF6FA57C)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  int _getBookedCount(String dateStr, String? availabilityId) {
    if (availabilityId == null || !_existingAppointments.containsKey(dateStr)) {
      return 0;
    }

    return _existingAppointments[dateStr]!
        .where((appointment) => appointment['availability_id'] == availabilityId)
        .length;
  }

  void _submitAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null || _selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date and time slot'),
          backgroundColor: Color(0xFF4A707A),
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF6FA57C)),
        ),
      );

      final slotStart = _selectedSlot!['start_time'] as DateTime;
      final slotEnd = _selectedSlot!['end_time'] as DateTime;
      final availabilityId = _selectedSlot!['id'] as String?;

      // Ensure we use the selected date with the slot's time
      final appointmentTime = slotStart;
      final endTime = slotEnd;

      final appointmentData = {
        'therapistId': widget.therapist['id'],
        'therapistName': widget.therapist['name'],
        'appointmentTime': appointmentTime,
        'endTime': endTime,
        'notes': _notesController.text,
      };

      // Add availability_id if it exists
      if (availabilityId != null) {
        appointmentData['availabilityId'] = availabilityId;
      }

      final success = await Provider.of<AppointmentService>(context, listen: false)
          .bookAppointment(
        therapistId: widget.therapist['id'],
        therapistName: widget.therapist['name'],
        appointmentTime: appointmentTime,
        endTime: endTime,
        notes: _notesController.text,
        availabilityId: availabilityId,
      );

      // Close loading dialog
      Navigator.pop(context);

      if (success) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Success!',
              style: GoogleFonts.aclonica(color: const Color(0xFF6FA57C)),
            ),
            content: Text(
              'Your appointment has been booked successfully.',
              style: GoogleFonts.montserrat(),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to previous screen
                },
                child: Text(
                  'OK',
                  style: GoogleFonts.montserrat(color: const Color(0xFF6FA57C)),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to book appointment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}