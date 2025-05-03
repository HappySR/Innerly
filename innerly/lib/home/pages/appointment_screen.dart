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
  TimeOfDay? _selectedSlot;
  final _notesController = TextEditingController();
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _availabilitySlots = [];

  @override
  void initState() {
    super.initState();
    _loadAvailabilitySlots();
  }

  Future<void> _loadAvailabilitySlots() async {
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
          'start_time': TimeOfDay.fromDateTime(start),
          'end_time': TimeOfDay.fromDateTime(end),
          'target_weekday': slot['target_weekday'],
          'original_date': start,
          'is_recurring': slot['is_recurring'] ?? false,
        };
      }).toList();
    });
  }

  List<TimeOfDay> _getSlotsForDate(DateTime date) {
    final localDate = date.toLocal();
    return _availabilitySlots.where((slot) {
      final isRecurring = slot['is_recurring'] as bool;
      final originalDate = (slot['original_date'] as DateTime).toLocal();
      final targetWeekday = slot['target_weekday'] as int;

      if (isRecurring) {
        return localDate.weekday - 1 == targetWeekday &&
            !localDate.isBefore(originalDate);
      } else {
        return localDate.year == originalDate.year &&
            localDate.month == originalDate.month &&
            localDate.day == originalDate.day;
      }
    }).map((slot) {
      final start = slot['start_time'] as TimeOfDay;
      final end = slot['end_time'] as TimeOfDay;
      return _generateTimeSlots(start, end);
    }).expand((slots) => slots).toList();
  }

  List<TimeOfDay> _generateTimeSlots(TimeOfDay start, TimeOfDay end) {
    List<TimeOfDay> slots = [];
    DateTime temp = DateTime(0, 1, 1, start.hour, start.minute);
    final endDt = DateTime(0, 1, end.hour > start.hour ? 1 : 2, end.hour, end.minute);

    while (temp.isBefore(endDt)) {
      slots.add(TimeOfDay.fromDateTime(temp));
      temp = temp.add(const Duration(minutes: 15));
    }
    return slots;
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
      body: Padding(
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
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'Available Time Slots:',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: slots.map((slot) {
            final isSelected = _selectedSlot == slot;
            return ChoiceChip(
              label: Text(slot.format(context)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedSlot = selected ? slot : null);
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF6FA57C),
              labelStyle: GoogleFonts.montserrat(
                color: isSelected ? Colors.white : Colors.black,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF6FA57C)
                      : Colors.grey.shade300,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
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

      final appointmentTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedSlot!.hour,
        _selectedSlot!.minute,
      );

      try {
        await _supabase.from('appointments').insert({
          'therapist_id': widget.therapist['id'],
          'user_id': _supabase.auth.currentUser?.id,
          'scheduled_at': appointmentTime.toUtc().toIso8601String(),
          'status': 'pending',
          'notes': _notesController.text,
          'is_availability': false,
          'target_weekday': _selectedDate!.weekday - 1,
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

extension TimeOfDayExtension on TimeOfDay {
  String format(BuildContext context) {
    final now = DateTime.now();
    return DateFormat('h:mm a').format(DateTime(now.year, now.month, now.day, hour, minute));
  }
}
