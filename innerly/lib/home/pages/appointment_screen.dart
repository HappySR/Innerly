import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    _loadAvailabilitySlots();
  }

  Future<void> _loadAvailabilitySlots() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _supabase
          .from('appointments')
          .select()
          .eq('therapist_id', widget.therapist['id'])
          .eq('is_availability', true);

      setState(() {
        _availabilitySlots = response.map((slot) {
          final start = DateTime.parse(slot['scheduled_at']).toLocal();
          final end = DateTime.parse(slot['end_time']).toLocal();

          return {
            'id': slot['id'],
            'start_time': start,
            'end_time': end,
            'target_weekday': slot['target_weekday'] ?? start.weekday - 1,
            'is_recurring': slot['is_recurring'] ?? false,
          };
        }).toList();

        _isLoading = false;
      });

      // Debug info
      print('Loaded ${_availabilitySlots.length} availability slots');
    } catch (e) {
      print('Error loading slots: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getSlotsForDate(DateTime date) {
    // First make sure we have the local date for comparison
    final selectedDate = date;
    final selectedWeekday = selectedDate.weekday - 1; // 0-based weekday (0=Monday)

    print('Getting slots for date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}, weekday: $selectedWeekday');

    final filteredSlots = _availabilitySlots.where((slot) {
      final isRecurring = slot['is_recurring'] as bool;
      final targetWeekday = slot['target_weekday'] as int;
      final originalDate = slot['start_time'] as DateTime;

      if (isRecurring) {
        // For recurring slots, we check if the weekday matches
        final matchesWeekday = selectedWeekday == targetWeekday;
        // And we check if the selected date is after or on the original date
        final isAfterStart = !selectedDate.isBefore(DateTime(
            originalDate.year,
            originalDate.month,
            originalDate.day
        ));

        print('Recurring slot weekday: $targetWeekday, matches: $matchesWeekday, isAfterStart: $isAfterStart');
        return matchesWeekday && isAfterStart;
      } else {
        // For non-recurring slots, check if it's the exact same date
        final isSameDate = selectedDate.year == originalDate.year &&
            selectedDate.month == originalDate.month &&
            selectedDate.day == originalDate.day;

        print('Non-recurring slot date: ${DateFormat('yyyy-MM-dd').format(originalDate)}, matches: $isSameDate');
        return isSameDate;
      }
    }).toList();

    print('Found ${filteredSlots.length} available slots for selected date');
    return filteredSlots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Book with ${widget.therapist['name']}',
          style: GoogleFonts.montserrat(),
        ),
        backgroundColor: const Color(0xFFFDF6F0),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                  border: const OutlineInputBorder(),
                  labelStyle: GoogleFonts.montserrat(),
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
            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
            builder: (context, child) => Theme(
              data: ThemeData.light().copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF6FA57C),
                ),
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
        child: Text(
          'No available slots for this day',
          style: GoogleFonts.montserrat(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
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

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF6FA57C)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedSlot = isSelected ? null : slot;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: const Color(0xFF4A707A),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$formattedStartTime - $formattedEndTime',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
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
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      const Spacer(),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF6FA57C),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  void _submitAppointment() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedSlot == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select date and time slot')),
        );
        return;
      }

      // Get the start time from the selected slot
      final slotStartTime = _selectedSlot!['start_time'] as DateTime;
      final slotEndTime = _selectedSlot!['end_time'] as DateTime;

      // Create appointment time by combining selected date with slot time
      final appointmentTime = DateTime.utc(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        slotStartTime.hour,
        slotStartTime.minute,
      );

      // Create end time by combining selected date with slot end time
      final endTime = DateTime.utc(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        slotEndTime.hour,
        slotEndTime.minute,
      );

      try {
        await _supabase.from('appointments').insert({
          'therapist_id': widget.therapist['id'],
          'user_id': _supabase.auth.currentUser?.id,
          'scheduled_at': appointmentTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'status': 'pending',
          'notes': _notesController.text,
          'is_availability': false,
          'target_weekday': appointmentTime.weekday - 1,
        });

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment requested successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}