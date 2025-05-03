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
        targetWeekday: slot['target_weekday'] as int, // Get from database
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
        final newSlot = AvailabilitySlot(
          id: existingSlot.id,
          startTime: pickedStart!,
          endTime: pickedEnd!,
          originalDate: existingSlot.originalDate,
          targetWeekday: _daysOfWeek.indexOf(day),
          isRecurring: existingSlot.isRecurring,
        );
        _slots[day]![index] = newSlot;
        _updateSlotInDatabase(newSlot);
      } else {
        final newSlot = AvailabilitySlot(
          startTime: pickedStart!,
          endTime: pickedEnd!,
          originalDate: _nextDateForDay(day, DateTime.now()),
          targetWeekday: _daysOfWeek.indexOf(day),
          isRecurring: _allRecurring,
        );
        _slots[day]!.add(newSlot);
        _addSlotToDatabase(newSlot);
      }
      _sortSlots(day);
    });
    _updateAllRecurringState();
  }

  Future<void> _addSlotToDatabase(AvailabilitySlot slot) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final startDate = slot.originalDate;
      DateTime endDate = startDate;
      if (slot.endTime.hour < slot.startTime.hour ||
          (slot.endTime.hour == slot.startTime.hour &&
              slot.endTime.minute < slot.startTime.minute)) {
        endDate = endDate.add(const Duration(days: 1));
      }

      final startDateTime = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        slot.startTime.hour,
        slot.startTime.minute,
      );

      final endDateTime = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        slot.endTime.hour,
        slot.endTime.minute,
      );

      await _supabase.from('appointments').insert({
        'therapist_id': userId,
        'scheduled_at': startDateTime.toUtc().toIso8601String(),
        'end_time': endDateTime.toUtc().toIso8601String(),
        'is_availability': true,
        'is_recurring': slot.isRecurring,
        'target_weekday': slot.targetWeekday, // Add target weekday
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating slot: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateSlotInDatabase(AvailabilitySlot slot) async {
    try {
      if (slot.id == null) return;

      final startDate = slot.originalDate;
      DateTime endDate = startDate;
      if (slot.endTime.hour < slot.startTime.hour ||
          (slot.endTime.hour == slot.startTime.hour &&
              slot.endTime.minute < slot.startTime.minute)) {
        endDate = endDate.add(const Duration(days: 1));
      }

      final startDateTime = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        slot.startTime.hour,
        slot.startTime.minute,
      );

      final endDateTime = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        slot.endTime.hour,
        slot.endTime.minute,
      );

      await _supabase.from('appointments').update({
        'scheduled_at': startDateTime.toUtc().toIso8601String(),
        'end_time': endDateTime.toUtc().toIso8601String(),
        'is_recurring': slot.isRecurring,
        'target_weekday': slot.targetWeekday, // Add target weekday
      }).eq('id', slot.id!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating slot: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteSlotFromDatabase(String? slotId) async {
    try {
      if (slotId == null) return;
      await _supabase.from('appointments').delete().eq('id', slotId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting slot: ${e.toString()}')),
      );
    }
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
        _slots[day] = _slots[day]!.map((slot) {
          final updatedSlot = AvailabilitySlot(
            id: slot.id,
            startTime: slot.startTime,
            endTime: slot.endTime,
            originalDate: slot.originalDate,
            targetWeekday: slot.targetWeekday,
            isRecurring: value,
          );
          if (slot.isRecurring != value) {
            _updateSlotInDatabase(updatedSlot);
          }
          return updatedSlot;
        }).toList();
      }
    });
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
                _deleteSlotFromDatabase(slot.id);
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