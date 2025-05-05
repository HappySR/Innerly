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
  List<String> _offDays = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, List<Map<String, dynamic>>> _existingAppointments = {};

  @override
  void initState() {
    super.initState();
    _loadAvailabilitySlots();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailabilitySlots() async {
    setState(() => _isLoading = true);

    try {
      // 1. Get therapist availability slots
      final response = await _supabase
          .from('therapists_availability')
          .select()
          .eq('therapist_id', widget.therapist['id'])
          .eq('is_availability', true);

      debugPrint('Found ${response.length} availability slots'); // Debug log

      // 2. Get therapist's off days
      final exceptionsResponse = await _supabase
          .from('therapist_schedule_exceptions')
          .select()
          .eq('therapist_id', widget.therapist['id'])
          .eq('is_available', false);

      final offDays = exceptionsResponse.map<String>((exception) {
        return DateFormat('yyyy-MM-dd')
            .format(DateTime.parse(exception['exception_date']).toLocal());
      }).toList();

      debugPrint('Found ${offDays.length} off days: $offDays'); // Debug log

      // 3. Get existing appointments
      final appointmentsResponse = await _supabase
          .from('appointments')
          .select()
          .eq('therapist_id', widget.therapist['id'])
          .inFilter('status', ['pending', 'confirmed']);

      debugPrint('Found ${appointmentsResponse.length} existing appointments'); // Debug log

      // Create a map of existing appointments by date
      final existingAppointments = <String, List<Map<String, dynamic>>>{};
      for (final appointment in appointmentsResponse) {
        final date = DateTime.parse(appointment['scheduled_at']).toLocal();
        final dateStr = DateFormat('yyyy-MM-dd').format(date);

        if (!existingAppointments.containsKey(dateStr)) {
          existingAppointments[dateStr] = [];
        }

        existingAppointments[dateStr]!.add({
          'id': appointment['id'],
          'start_time': date,
          'end_time': appointment['end_time'] != null
              ? DateTime.parse(appointment['end_time']).toLocal()
              : date.add(const Duration(hours: 1)),
          'user_id': appointment['user_id'],
          'availability_id': appointment['availability_id'],
        });
      }

      // 4. Process availability slots
      final availabilitySlots = response.map<Map<String, dynamic>>((slot) {
        // Parse dates from UTC to local
        final start = DateTime.parse(slot['scheduled_at']).toLocal();
        final end = DateTime.parse(slot['end_time']).toLocal();

        return {
          'id': slot['id'],
          'start_time': start,
          'end_time': end,
          'target_weekday': slot['target_weekday'],
          'is_recurring': slot['is_recurring'] ?? true,
          'max_patients': slot['max_patients'] ?? 1,
        };
      }).toList();

      setState(() {
        _availabilitySlots = availabilitySlots;
        _offDays = offDays;
        _existingAppointments = existingAppointments;
        _isLoading = false;
      });

      debugPrint('Processed ${_availabilitySlots.length} slots for UI');

    } catch (e) {
      debugPrint('Error loading slots: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getSlotsForDate(DateTime date) {
    // Format the date as YYYY-MM-DD string for comparison
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    // If date is in off days or in the past, return empty list
    if (_offDays.contains(dateStr)) {
      debugPrint('Date $dateStr is in off days');
      return [];
    }

    // Check if date is in the past (before today)
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (date.isBefore(today)) {
      debugPrint('Date $dateStr is in the past');
      return [];
    }

    final now = DateTime.now();

    // Get the weekday (0 = Monday, 1 = Tuesday, ..., 6 = Sunday)
    final selectedWeekday = (date.weekday - 1) % 7;

    debugPrint('Selected weekday: $selectedWeekday for date $dateStr');

    // Filter slots applicable to the selected date
    List<Map<String, dynamic>> availableSlots = [];

    for (var slot in _availabilitySlots) {
      final isRecurring = slot['is_recurring'] as bool;
      final targetWeekday = slot['target_weekday'] as int;
      final slotStart = slot['start_time'] as DateTime;

      // For recurring slots, check if the weekday matches
      if (isRecurring) {
        // Check if weekday matches and original slot start date is not in the future
        final slotStartDate = DateTime(slotStart.year, slotStart.month, slotStart.day);
        debugPrint('Checking recurring slot: target weekday=$targetWeekday, selected weekday=$selectedWeekday');

        if (selectedWeekday == targetWeekday && !slotStartDate.isAfter(date)) {
          availableSlots.add(slot);
          debugPrint('Added recurring slot for weekday $targetWeekday');
        }
      }
      // For non-recurring slots, check if the date matches exactly
      else {
        final slotDateStr = DateFormat('yyyy-MM-dd').format(slotStart);
        debugPrint('Checking non-recurring slot: slotDate=$slotDateStr, selected=$dateStr');

        if (slotDateStr == dateStr) {
          availableSlots.add(slot);
          debugPrint('Added non-recurring slot for exact date $dateStr');
        }
      }
    }

    debugPrint('Found ${availableSlots.length} potential slots for $dateStr');

    // Now adjust the times for the specific date and filter out unavailable slots
    final result = availableSlots.map((slot) {
      final slotStart = slot['start_time'] as DateTime;
      final slotEnd = slot['end_time'] as DateTime;
      final maxPatients = slot['max_patients'] as int;

      // Adjust start and end times for the selected date
      final adjustedStart = DateTime(
        date.year,
        date.month,
        date.day,
        slotStart.hour,
        slotStart.minute,
      );

      var adjustedEnd = DateTime(
        date.year,
        date.month,
        date.day,
        slotEnd.hour,
        slotEnd.minute,
      );

      // Handle slots that cross midnight
      if (slotEnd.hour < slotStart.hour ||
          (slotEnd.hour == slotStart.hour && slotEnd.minute < slotStart.minute)) {
        adjustedEnd = adjustedEnd.add(const Duration(days: 1));
      }

      // Skip slots that have already passed for today
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        if (adjustedStart.isBefore(now)) {
          debugPrint('Slot ${DateFormat('HH:mm').format(adjustedStart)} - ${DateFormat('HH:mm').format(adjustedEnd)} has already passed');
          return null;
        }
      }

      // For recurring slots, we need to check the specific date's bookings
      // Get the availability ID for booking matching
      final availabilityId = slot['id'];

      // Count how many appointments are already booked for this slot
      final bookedCount = _getBookedCountForSlot(dateStr, availabilityId, adjustedStart, adjustedEnd);

      // Check if the slot is fully booked
      if (bookedCount >= maxPatients) {
        debugPrint('Slot ${DateFormat('HH:mm').format(adjustedStart)} is fully booked ($bookedCount/$maxPatients)');
        return null;
      }

      return {
        ...slot,
        'start_time': adjustedStart,
        'end_time': adjustedEnd,
        'booked_count': bookedCount,
        'adjusted_date': dateStr, // Store the adjusted date for booking
      };
    })
        .where((slot) => slot != null)
        .toList()
        .cast<Map<String, dynamic>>();

    debugPrint('Returning ${result.length} valid slots after filtering');
    return result;
  }

  int _getBookedCountForSlot(String dateStr, dynamic availabilityId, DateTime start, DateTime end) {
    if (availabilityId == null || !_existingAppointments.containsKey(dateStr)) {
      return 0;
    }

    // For recurring slots, we need to check all appointments for this date
    // that match the time slot (not just the availability ID)
    int count = 0;

    for (var appt in _existingAppointments[dateStr]!) {
      final apptStart = appt['start_time'] as DateTime;

      // Check if this appointment starts at the same time as our slot
      if (apptStart.hour == start.hour && apptStart.minute == start.minute) {
        // If it has the same availability ID or time matches exactly, count it
        if (appt['availability_id'] == availabilityId) {
          count++;
        }
      }
    }

    return count;
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

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    if (_offDays.contains(dateStr)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This day is marked as unavailable by the therapist'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final slotStart = _selectedSlot!['start_time'] as DateTime;
      final slotEnd = _selectedSlot!['end_time'] as DateTime;
      final success = await Provider.of<AppointmentService>(context, listen: false)
          .bookAppointment(
        therapistId: widget.therapist['id'],
        appointmentTime: slotStart,
        endTime: slotEnd,
        notes: _notesController.text,
        availabilityId: _selectedSlot!['id'],
        appointmentDate: dateStr, // Pass the actual date string for this instance
      );

      setState(() => _isSubmitting = false);

      if (!mounted) return;
      if (success) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Success!',
              style: GoogleFonts.aclonica(color: const Color(0xFF6FA57C)),
            ),
            content: Text(
              'Appointment booked successfully',
              style: GoogleFonts.montserrat(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: GoogleFonts.montserrat(color: const Color(0xFF6FA57C)),
                ),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Slot no longer available'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                    borderSide: const BorderSide(
                        color: Color(0xFF6FA57C), width: 2),
                  ),
                ),
                style: GoogleFonts.montserrat(),
                maxLines: 3,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6FA57C),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
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
            selectableDayPredicate: (DateTime day) {
              final dateStr = DateFormat('yyyy-MM-dd').format(day);
              return !_offDays.contains(dateStr);
            },
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

    debugPrint('Found ${slots.length} available slots for selected date');

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
            final start = slot['start_time'] as DateTime;
            final end = slot['end_time'] as DateTime;
            final formattedStart = DateFormat('h:mm a').format(start);
            final formattedEnd = DateFormat('h:mm a').format(end);
            final isSelected = _selectedSlot?['id'] == slot['id'] &&
                _selectedSlot?['adjusted_date'] == slot['adjusted_date'];
            final maxPatients = slot['max_patients'] as int;
            final available = maxPatients - (slot['booked_count'] as int);

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
                            '$formattedStart - $formattedEnd',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (maxPatients > 1)
                            Text(
                              '$available of $maxPatients spots available',
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
}