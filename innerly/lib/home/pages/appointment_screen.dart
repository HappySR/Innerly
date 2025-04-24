import 'package:flutter/material.dart';
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
  TimeOfDay? _selectedTime;
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book with ${widget.therapist['name']}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildDatePicker(),
              _buildTimePicker(),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitAppointment,
                child: const Text('Book Appointment'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      title: Text(
        _selectedDate == null
            ? 'Select Date'
            : 'Date: ${DateFormat.yMMMd().format(_selectedDate!)}',
      ),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (pickedDate != null) {
          setState(() => _selectedDate = pickedDate);
        }
      },
    );
  }

  Widget _buildTimePicker() {
    return ListTile(
      title: Text(
        _selectedTime == null
            ? 'Select Time'
            : 'Time: ${_selectedTime!.format(context)}',
      ),
      trailing: const Icon(Icons.access_time),
      onTap: () async {
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (pickedTime != null) {
          setState(() => _selectedTime = pickedTime);
        }
      },
    );
  }

  final _supabase = Supabase.instance.client;

  void _submitAppointment() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select date and time')),
        );
        return;
      }

      final appointmentTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final success = await Provider.of<AppointmentService>(context, listen: false)
          .bookAppointment(
        therapistId: widget.therapist['id'],
        therapistName: widget.therapist['name'],
        appointmentTime: appointmentTime,
        notes: _notesController.text,
      );

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to book appointment')),
        );
      }

      try {
        await _supabase.from('appointments').insert({
          'therapist_id': widget.therapist['id'],
          'user_id': _supabase.auth.currentUser?.id,
          'scheduled_at': appointmentTime.toIso8601String(),
          'status': 'pending',
          'notes': _notesController.text,
        });

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}