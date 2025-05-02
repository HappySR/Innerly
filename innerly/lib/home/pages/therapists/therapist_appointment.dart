import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TherapistsAppointmentScreen extends StatefulWidget {
  const TherapistsAppointmentScreen({super.key});

  @override
  State<TherapistsAppointmentScreen> createState() => _TherapistsAppointmentScreenState();
}

class _TherapistsAppointmentScreenState extends State<TherapistsAppointmentScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Map<String, List<AvailabilitySlot>> _slots = {};
  String _expandedDay = '';
  bool _allRecurring = false;
  final _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _initializeSlots();
    _loadExistingSlots();
    _setupRealtimeUpdates();
  }

  void _initializeSlots() {
    for (var day in _daysOfWeek) {
      _slots[day] = [];
    }
  }

  Future<void> _loadExistingSlots() async {
    final existingSlots = await _getAllDatabaseSlots();
    _processSlots(existingSlots);
  }

  void _setupRealtimeUpdates() {
    _supabase.channel('appointments')
        .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'appointments',
        callback: (payload) async {
          await _loadExistingSlots();
        }
    )
        .subscribe();
  }

  void _processSlots(List<AvailabilitySlot> slots) {
    for (var day in _daysOfWeek) {
      _slots[day]?.clear();
    }
    for (final slot in slots) {
      final day = _daysOfWeek[slot.targetWeekday];
      if (_slots.containsKey(day)) {
        _slots[day]!.add(slot);
      }
    }
    _updateAllRecurringState();
    setState(() {});
  }

  void _updateAllRecurringState() {
    bool allRecurring = true;
    bool hasSlots = false;

    for (var day in _daysOfWeek) {
      for (var slot in _slots[day]!) {
        hasSlots = true;
        if (!slot.isRecurring) {
          allRecurring = false;
          break;
        }
      }
      if (!allRecurring) break;
    }

    setState(() {
      _allRecurring = hasSlots ? allRecurring : false;
    });
  }

  Future<List<AvailabilitySlot>> _getAllDatabaseSlots() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('appointments')
        .select()
        .eq('therapist_id', userId)
        .eq('is_availability', true);

    return response.map((slot) {
      final start = DateTime.parse(slot['scheduled_at']).toLocal();
      return AvailabilitySlot(
        id: slot['id'],
        startTime: TimeOfDay.fromDateTime(start),
        endTime: TimeOfDay.fromDateTime(DateTime.parse(slot['end_time']).toLocal()),
        originalDate: start,
        targetWeekday: start.weekday - 1,
        isRecurring: slot['is_recurring'] ?? false,
      );
    }).toList();
  }

  bool _hasTimeOverlap(List<AvailabilitySlot> existingSlots, TimeOfDay newStart, TimeOfDay newEnd) {
    int newStartMin = newStart.hour * 60 + newStart.minute;
    int newEndMin = newEnd.hour * 60 + newEnd.minute;
    if (newEndMin <= newStartMin) newEndMin += 1440;

    for (final slot in existingSlots) {
      int slotStartMin = slot.startTime.hour * 60 + slot.startTime.minute;
      int slotEndMin = slot.endTime.hour * 60 + slot.endTime.minute;
      if (slotEndMin <= slotStartMin) slotEndMin += 1440;

      if (newStartMin < slotEndMin && newEndMin > slotStartMin) {
        return true;
      }
    }
    return false;
  }

  Future<void> _selectTime(BuildContext context, AvailabilitySlot? existingSlot, String day) async {
    const minDuration = 15;
    TimeOfDay? pickedStart;
    TimeOfDay? pickedEnd;

    pickedStart = await showTimePicker(
      context: context,
      initialTime: existingSlot?.startTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF6FA57C)),
          timePickerTheme: const TimePickerThemeData(
            backgroundColor: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (pickedStart == null) return;

    pickedEnd = await showTimePicker(
      context: context,
      initialTime: existingSlot?.endTime ?? TimeOfDay(
          hour: pickedStart.hour + 1,
          minute: pickedStart.minute
      ),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF6FA57C)),
        ),
        child: child!,
      ),
    );

    if (pickedEnd == null) return;

    if (!_isValidTimeRange(pickedStart, pickedEnd)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    final durationMinutes = (pickedEnd.hour * 60 + pickedEnd.minute) -
        (pickedStart.hour * 60 + pickedStart.minute);
    if (durationMinutes < minDuration) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum slot duration is 15 minutes')),
      );
      return;
    }

    final existingSlots = await _getAllDatabaseSlots();
    final existingSameDay = existingSlots.where((s) => _daysOfWeek[s.targetWeekday] == day).toList();
    if (existingSlot != null) {
      existingSameDay.removeWhere((s) => s.id == existingSlot.id);
    }

    final uiSlotsSameDay = _slots[day]!.where((s) => s != existingSlot).toList();
    final allSlotsSameDay = [...existingSameDay, ...uiSlotsSameDay];

    if (_hasTimeOverlap(allSlotsSameDay, pickedStart, pickedEnd)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This slot overlaps with an existing slot')),
      );
      return;
    }

    setState(() {
      if (existingSlot != null) {
        final index = _slots[day]!.indexOf(existingSlot);
        _slots[day]![index] = AvailabilitySlot(
          id: existingSlot.id,
          startTime: pickedStart!,
          endTime: pickedEnd!,
          originalDate: existingSlot.originalDate,
          targetWeekday: _daysOfWeek.indexOf(day),
          isRecurring: existingSlot.isRecurring,
        );
      } else {
        _slots[day]!.add(AvailabilitySlot(
          startTime: pickedStart!,
          endTime: pickedEnd!,
          originalDate: _nextDateForDay(day, DateTime.now()),
          targetWeekday: _daysOfWeek.indexOf(day),
          isRecurring: _allRecurring,
        ));
      }
      _sortSlots(day);
    });
    _updateAllRecurringState();
  }

  bool _isValidTimeRange(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return endMinutes > startMinutes;
  }

  void _sortSlots(String day) {
    _slots[day]!.sort((a, b) {
      final aStart = a.startTime.hour * 60 + a.startTime.minute;
      final bStart = b.startTime.hour * 60 + b.startTime.minute;
      return aStart.compareTo(bStart);
    });
  }

  void _toggleAllRecurring(bool? value) {
    if (value == null) return;
    setState(() {
      _allRecurring = value;
      for (var day in _daysOfWeek) {
        _slots[day] = _slots[day]!.map((slot) => AvailabilitySlot(
          id: slot.id,
          startTime: slot.startTime,
          endTime: slot.endTime,
          originalDate: slot.originalDate,
          targetWeekday: slot.targetWeekday,
          isRecurring: value,
        )).toList();
      }
    });
  }

  Future<void> _submitSlots() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final existingSlots = await _getAllDatabaseSlots();
      final List<Map<String, dynamic>> toInsert = [];
      final List<String> toDelete = [];
      final List<Map<String, dynamic>> toUpdate = [];

      final allSlots = _slots.values.expand((x) => x).toList();

      for (final newSlot in allSlots) {
        final existing = existingSlots.firstWhere(
              (s) => s.id == newSlot.id,
          orElse: () => AvailabilitySlot(
            startTime: const TimeOfDay(hour: 0, minute: 0),
            endTime: const TimeOfDay(hour: 0, minute: 0),
            originalDate: DateTime.now(),
            targetWeekday: 0,
            isRecurring: false,
          ),
        );

        final startDate = newSlot.originalDate;
        DateTime endDate = startDate;
        if (newSlot.endTime.hour < newSlot.startTime.hour ||
            (newSlot.endTime.hour == newSlot.startTime.hour &&
                newSlot.endTime.minute < newSlot.startTime.minute)) {
          endDate = endDate.add(const Duration(days: 1));
        }

        final startDateTime = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          newSlot.startTime.hour,
          newSlot.startTime.minute,
        );
        final endDateTime = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          newSlot.endTime.hour,
          newSlot.endTime.minute,
        );

        if (existing.id != null) {
          toUpdate.add({
            'id': existing.id,
            'scheduled_at': startDateTime.toUtc().toIso8601String(),
            'end_time': endDateTime.toUtc().toIso8601String(),
            'is_recurring': newSlot.isRecurring,
          });
        } else {
          toInsert.add({
            'therapist_id': userId,
            'user_id': null,
            'scheduled_at': startDateTime.toUtc().toIso8601String(),
            'end_time': endDateTime.toUtc().toIso8601String(),
            'status': 'available',
            'is_availability': true,
            'is_recurring': newSlot.isRecurring,
          });
        }
      }

      for (final existingSlot in existingSlots) {
        if (!allSlots.any((s) => s.id == existingSlot.id)) {
          toDelete.add(existingSlot.id!);
        }
      }

      if (toDelete.isNotEmpty) {
        await _supabase
            .from('appointments')
            .delete()
            .inFilter('id', toDelete);
      }

      for (final update in toUpdate) {
        await _supabase
            .from('appointments')
            .update(update)
            .eq('id', update['id']);
      }

      if (toInsert.isNotEmpty) {
        await _supabase
            .from('appointments')
            .insert(toInsert);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slots saved successfully!')),
      );
    } catch (e) {
      String errorMessage = 'Error saving slots: ${e.toString()}';
      if (e.toString().contains('Overlapping availability')) {
        errorMessage = 'Cannot save overlapping time slots';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  DateTime _nextDateForDay(String day, DateTime from) {
    int desiredDay = _daysOfWeek.indexOf(day) + 1;
    desiredDay = desiredDay > 7 ? 1 : desiredDay;

    DateTime date = from.add(const Duration(days: 1));
    while (date.weekday != desiredDay) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        title: Text('Weekly Availability',
            style: GoogleFonts.aclonica(color: Colors.black54)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.02,
        ),
        child: Column(
          children: [
            _buildRecurringCheckbox(screenWidth, screenHeight),
            SizedBox(height: screenHeight * 0.02),
            ..._daysOfWeek.map((day) => _buildDayCard(day, screenWidth, screenHeight)),
            SizedBox(height: screenHeight * 0.03),
            _buildSubmitButton(screenWidth, screenHeight),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(String day, double width, double height) {
    final isExpanded = _expandedDay == day;
    final hasSlots = _slots[day]!.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: EdgeInsets.only(bottom: height * 0.015),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () async {
              if (!isExpanded) {
                await _loadExistingSlots();
              }
              setState(() => _expandedDay = isExpanded ? '' : day);
            },
            title: Text(day,
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w500)),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: const Color(0xFF6FA57C),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: Container(
              height: isExpanded ? null : 0,
              padding: EdgeInsets.only(
                left: width * 0.04,
                right: width * 0.04,
                bottom: height * 0.02,
              ),
              child: Column(
                children: [
                  Divider(color: Colors.grey.shade300),
                  if (hasSlots) _buildTimeSlots(day, width, height),
                  _buildAddButton(day, width, height),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlots(String day, double width, double height) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _slots[day]!.length,
      itemBuilder: (context, index) {
        final slot = _slots[day]![index];
        return _buildTimeSlot(day, slot, width, height);
      },
    );
  }

  Widget _buildTimeSlot(String day, AvailabilitySlot slot, double width, double height) {
    final start = slot.startTime.format(context);
    final end = slot.endTime.format(context);

    return Container(
      margin: EdgeInsets.only(bottom: height * 0.01),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(width * 0.03),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
            horizontal: width * 0.04,
            vertical: height * 0.01),
        title: Text('$start - $end',
            style: GoogleFonts.montserrat(fontSize: width * 0.035)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, size: width * 0.05, color: Colors.grey[600]),
              onPressed: () => _selectTime(context, slot, day),
            ),
            IconButton(
              icon: Icon(Icons.close, size: width * 0.05, color: Colors.red[600]),
              onPressed: () {
                setState(() => _slots[day]!.remove(slot));
                _updateAllRecurringState();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(String day, double width, double height) {
    return Padding(
      padding: EdgeInsets.only(top: height * 0.02),
      child: InkWell(
        onTap: () => _selectTime(context, null, day),
        borderRadius: BorderRadius.circular(width * 0.03),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: height * 0.015),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF6FA57C)),
            borderRadius: BorderRadius.circular(width * 0.03),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: const Color(0xFF6FA57C), size: width * 0.05),
              SizedBox(width: width * 0.02),
              Text('Add Time Slot',
                  style: GoogleFonts.montserrat(
                    color: const Color(0xFF6FA57C),
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(double width, double height) {
    return ElevatedButton(
      onPressed: _submitSlots,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6FA57C),
        padding: EdgeInsets.symmetric(
          vertical: height * 0.02,
          horizontal: width * 0.15,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(width * 0.06),
        ),
      ),
      child: Text('Save Schedule',
          style: GoogleFonts.aclonica(
            fontSize: width * 0.045,
            color: Colors.white,
          )),
    );
  }

  Widget _buildRecurringCheckbox(double width, double height) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: height * 0.01,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CheckboxListTile(
        title: Text('Make All Slots Recurring',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4A707A),
            )),
        value: _allRecurring,
        onChanged: _toggleAllRecurring,
        activeColor: const Color(0xFF6FA57C),
        checkColor: Colors.white,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        dense: true,
      ),
    );
  }
}

class AvailabilitySlot {
  final String? id;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final DateTime originalDate;
  final int targetWeekday;
  final bool isRecurring;

  AvailabilitySlot({
    this.id,
    required this.startTime,
    required this.endTime,
    required this.originalDate,
    required this.targetWeekday,
    this.isRecurring = false,
  });
}

extension TimeOfDayExtension on TimeOfDay {
  static TimeOfDay fromDateTime(DateTime date) {
    return TimeOfDay(hour: date.hour, minute: date.minute);
  }

  String format(BuildContext context) {
    final now = DateTime.now();
    return DateFormat('h:mm a').format(DateTime(now.year, now.month, now.day, hour, minute));
  }
}