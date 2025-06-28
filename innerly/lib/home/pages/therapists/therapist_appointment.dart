import 'package:Innerly/localization/i10n.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class TherapistsAppointmentScreen extends StatefulWidget {
  const TherapistsAppointmentScreen({super.key});

  @override
  State<TherapistsAppointmentScreen> createState() =>
      _TherapistsAppointmentScreenState();
}

class _TherapistsAppointmentScreenState
    extends State<TherapistsAppointmentScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Map<String, List<AvailabilitySlot>> _slots = {};
  String _expandedDay = '';
  bool _isLoading = true;
  final _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  // Map for weekday name to integer (0-6, Monday-Sunday)
  final Map<String, int> _weekdayToInt = {
    'Monday': 0,
    'Tuesday': 1,
    'Wednesday': 2,
    'Thursday': 3,
    'Friday': 4,
    'Saturday': 5,
    'Sunday': 6,
  };

  // Changed from 'StreamSubscription<PostgresChangePayload>?' to 'RealtimeChannel?'
  RealtimeChannel? _availabilitySubscription;
  RealtimeChannel? _exceptionSubscription;
  Timer? _updateDebounceTimer;

  @override
  void initState() {
    super.initState();
    _initializeSlots();
    _loadExistingSlots();
    _setupRealtimeUpdates();
  }

  @override
  void dispose() {
    _availabilitySubscription?.unsubscribe();
    _exceptionSubscription?.unsubscribe();
    _updateDebounceTimer?.cancel();
    super.dispose();
  }

  void _initializeSlots() {
    for (var day in _daysOfWeek) {
      _slots[day] = [];
    }
  }

  Future<void> _loadExistingSlots() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      final existingSlots = await _getAllDatabaseSlots();
      _processSlots(existingSlots);
    } catch (e, stack) {
      debugPrint('Error loading slots: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${L10n.getTranslatedText(context, 'Error loading availability')}: ${e.toString()}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setupRealtimeUpdates() {
    // Fixed: assign the RealtimeChannel to the subscription variables
    _availabilitySubscription =
        _supabase
            .channel('availability')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'therapists_availability',
              callback: _handleRealtimeUpdate,
            )
            .subscribe();

    _exceptionSubscription =
        _supabase
            .channel('exceptions')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'therapist_schedule_exceptions',
              callback: _handleRealtimeUpdate,
            )
            .subscribe();
  }

  void _handleRealtimeUpdate(PostgresChangePayload payload) {
    if (!mounted) return;

    // Debounce updates to prevent rapid reloads
    _updateDebounceTimer?.cancel();
    _updateDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) _loadExistingSlots();
    });
  }

  void _processSlots(List<AvailabilitySlot> slots) {
    for (var day in _daysOfWeek) {
      _slots[day]?.clear();
    }

    for (final slot in slots) {
      try {
        final dayIndex = slot.targetWeekday;
        final day = _daysOfWeek[dayIndex];
        if (_slots.containsKey(day)) {
          _slots[day]!.add(slot);
        }
      } catch (e) {
        debugPrint('${L10n.getTranslatedText(context, 'Error processing slot')}: $e');
      }
    }

    if (mounted) setState(() {});
  }

  Future<List<AvailabilitySlot>> _getAllDatabaseSlots() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('therapists_availability')
          .select()
          .eq('therapist_id', userId)
          .eq('is_availability', true);

      if (response.isEmpty) return [];

      return response.map((slot) {
        final scheduledAt = slot['scheduled_at'] as String? ?? '';
        final endTime = slot['end_time'] as String? ?? '';

        final start = DateTime.parse(scheduledAt).toLocal();
        return AvailabilitySlot(
          id: slot['id'],
          startTime: TimeOfDay.fromDateTime(start),
          endTime: TimeOfDay.fromDateTime(DateTime.parse(endTime).toLocal()),
          originalDate: start,
          targetWeekday: slot['target_weekday'] as int,
          maxPatients: slot['max_patients'] as int? ?? 1,
          timezone: slot['timezone'] as String? ?? 'UTC',
        );
      }).toList();
    } catch (e) {
      debugPrint('${L10n.getTranslatedText(context, 'Error fetching availability slots')}: $e');
      return [];
    }
  }

  bool _hasTimeOverlap(
    List<AvailabilitySlot> existingSlots,
    TimeOfDay newStart,
    TimeOfDay newEnd,
  ) {
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

  Future<void> _selectTime(
    BuildContext context,
    AvailabilitySlot? existingSlot,
    String day,
  ) async {
    const minDuration = 15;
    TimeOfDay? pickedStart;
    TimeOfDay? pickedEnd;
    int? maxPatients = existingSlot?.maxPatients ?? 1;

    pickedStart = await showTimePicker(
      context: context,
      initialTime: existingSlot?.startTime ?? TimeOfDay.now(),
      builder:
          (context, child) => Theme(
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
      initialTime:
          existingSlot?.endTime ??
          TimeOfDay(hour: pickedStart.hour + 1, minute: pickedStart.minute),
      builder:
          (context, child) => Theme(
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

    final durationMinutes =
        (pickedEnd.hour * 60 + pickedEnd.minute) -
        (pickedStart.hour * 60 + pickedStart.minute);
    if (durationMinutes < minDuration) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.getTranslatedText(context, 'Minimum slot duration is 15 minutes'))),
      );
      return;
    }

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(L10n.getTranslatedText(context, 'Maximum Patients'), style: GoogleFonts.montserrat()),
            content: StatefulBuilder(
              builder: (context, setStateDialog) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      L10n.getTranslatedText(context, 'How many patients can you see during this time slot?'),
                      style: GoogleFonts.montserrat(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            if (maxPatients! > 1) {
                              setStateDialog(() {
                                maxPatients = maxPatients! - 1;
                              });
                            }
                          },
                        ),
                        Text(
                          '$maxPatients',
                          style: GoogleFonts.montserrat(fontSize: 20),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setStateDialog(() {
                              maxPatients = maxPatients! + 1;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                child: Text(L10n.getTranslatedText(context, 'Cancel'), style: GoogleFonts.montserrat()),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text(L10n.getTranslatedText(context, 'Confirm'), style: GoogleFonts.montserrat()),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
    ).then((value) async {
      if (value != true) return;

      final existingSlots = await _getAllDatabaseSlots();
      final existingSameDay =
          existingSlots
              .where((s) => _daysOfWeek[(s.targetWeekday % 7)] == day)
              .toList();
      if (existingSlot != null) {
        existingSameDay.removeWhere((s) => s.id == existingSlot.id);
      }

      final uiSlotsSameDay =
          _slots[day]!.where((s) => s != existingSlot).toList();
      final allSlotsSameDay = [...existingSameDay, ...uiSlotsSameDay];

      if (_hasTimeOverlap(allSlotsSameDay, pickedStart!, pickedEnd!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10n.getTranslatedText(context, 'This slot overlaps with an existing slot')),
          ),
        );
        return;
      }

      if (mounted) {
        setState(() {
          if (existingSlot != null) {
            final index = _slots[day]!.indexOf(existingSlot);
            final newSlot = AvailabilitySlot(
              id: existingSlot.id,
              startTime: pickedStart!,
              endTime: pickedEnd!,
              originalDate: existingSlot.originalDate,
              targetWeekday: _weekdayToInt[day]!,
              maxPatients: maxPatients!,
              timezone: existingSlot.timezone,
            );
            _slots[day]![index] = newSlot;
            _updateSlotInDatabase(newSlot);
          } else {
            final newSlot = AvailabilitySlot(
              startTime: pickedStart!,
              endTime: pickedEnd!,
              originalDate: _nextDateForDay(day, DateTime.now()),
              targetWeekday: _weekdayToInt[day]!,
              maxPatients: maxPatients!,
              timezone: 'UTC',
            );
            _slots[day]!.add(newSlot);
            _addSlotToDatabase(newSlot);
          }
          _sortSlots(day);
        });
      }
    });
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

      await _supabase.from('therapists_availability').insert({
        'therapist_id': userId,
        'scheduled_at': startDateTime.toUtc().toIso8601String(),
        'end_time': endDateTime.toUtc().toIso8601String(),
        'is_availability': true,
        'target_weekday': slot.targetWeekday,
        'max_patients': slot.maxPatients,
        'timezone': slot.timezone,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${L10n.getTranslatedText(context, 'Error creating slot')}: ${e.toString()}')),
        );
      }
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

      await _supabase
          .from('therapists_availability')
          .update({
            'scheduled_at': startDateTime.toUtc().toIso8601String(),
            'end_time': endDateTime.toUtc().toIso8601String(),
            'target_weekday': slot.targetWeekday,
            'max_patients': slot.maxPatients,
            'timezone': slot.timezone,
          })
          .eq('id', slot.id!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${L10n.getTranslatedText(context, 'Error updating slot')}: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteSlotFromDatabase(String? slotId) async {
    try {
      if (slotId == null) return;
      await _supabase.from('therapists_availability').delete().eq('id', slotId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${L10n.getTranslatedText(context, 'Error deleting slot')}: ${e.toString()}')),
        );
      }
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

  Future<void> _showExceptionOptions(String day) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final nextDayDate = _nextDateForDay(day, DateTime.now());

    final result = await showDatePicker(
      context: context,
      initialDate: nextDayDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF6FA57C)),
          ),
          child: child!,
        );
      },
    );

    if (result == null) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(L10n.getTranslatedText(context, 'Set Exception'), style: GoogleFonts.montserrat()),
            content: Text(
              '${L10n.getTranslatedText(context, 'Do you want to mark')} ${DateFormat('EEEE, MMMM d, yyyy').format(result)} as unavailable? This will override your regular schedule for this day.',
              style: GoogleFonts.montserrat(),
            ),
            actions: [
              TextButton(
                child: Text(L10n.getTranslatedText(context, 'Cancel'), style: GoogleFonts.montserrat()),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: Text(
                  L10n.getTranslatedText(context, 'Mark as Unavailable'),
                  style: GoogleFonts.montserrat(color: Colors.red[700]),
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _addExceptionToDatabase(result);
                },
              ),
            ],
          ),
    );
  }

  Future<void> _addExceptionToDatabase(DateTime exceptionDate) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final existingExceptions = await _supabase
          .from('therapist_schedule_exceptions')
          .select()
          .eq('therapist_id', userId)
          .eq('exception_date', exceptionDate.toIso8601String().split('T')[0]);

      if (existingExceptions.isNotEmpty) {
        await _supabase
            .from('therapist_schedule_exceptions')
            .update({
              'is_available': false,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', existingExceptions[0]['id']);
      } else {
        await _supabase.from('therapist_schedule_exceptions').insert({
          'therapist_id': userId,
          'exception_date': exceptionDate.toIso8601String().split('T')[0],
          'is_available': false,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${L10n.getTranslatedText(context, 'Successfully marked')} ${DateFormat('MMM d, yyyy').format(exceptionDate)} as unavailable',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${L10n.getTranslatedText(context, 'Error creating exception')}: ${e.toString()}')),
        );
      }
    }
  }

  DateTime _nextDateForDay(String day, DateTime from) {
    final desiredDay = _weekdayToInt[day]!;
    final currentWeekday = from.weekday - 1;
    int daysToAdd = (desiredDay - currentWeekday + 7) % 7;
    return from.add(Duration(days: daysToAdd == 0 ? 7 : daysToAdd));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        title: Text(
          L10n.getTranslatedText(context, 'Weekly Availability'),
          style: GoogleFonts.aclonica(color: Colors.black54),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.black54),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TherapistExceptionsScreen(),
                ),
              );
            },
            tooltip: L10n.getTranslatedText(context, 'Manage Days Off'),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF6FA57C)),
              )
              : SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.02,
                ),
                child: Column(
                  children: [
                    SizedBox(height: screenHeight * 0.01),
                    ..._daysOfWeek.map(
                      (day) => _buildDayCard(day, screenWidth, screenHeight),
                    ),
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
              if (mounted) {
                setState(() => _expandedDay = isExpanded ? '' : day);
              }
            },
            title: Text(
              day,
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF6FA57C),
                    size: 20,
                  ),
                  onPressed: () => _showExceptionOptions(day),
                  tooltip: L10n.getTranslatedText(context, 'Add exception for this day'),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFF6FA57C),
                ),
              ],
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

  Widget _buildTimeSlot(
    String day,
    AvailabilitySlot slot,
    double width,
    double height,
  ) {
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
          vertical: height * 0.01,
        ),
        title: Text(
          '$start - $end',
          style: GoogleFonts.montserrat(fontSize: width * 0.035),
        ),
        subtitle: Text(
          '${L10n.getTranslatedText(context, 'Max Patients')}: ${slot.maxPatients}',
          style: GoogleFonts.montserrat(fontSize: width * 0.03),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.edit,
                size: width * 0.05,
                color: Colors.grey[600],
              ),
              onPressed: () => _selectTime(context, slot, day),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                size: width * 0.05,
                color: Colors.red[600],
              ),
              onPressed: () {
                if (mounted) {
                  setState(() => _slots[day]!.remove(slot));
                }
                _deleteSlotFromDatabase(slot.id);
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
              Icon(
                Icons.add,
                color: const Color(0xFF6FA57C),
                size: width * 0.05,
              ),
              SizedBox(width: width * 0.02),
              Text(
                L10n.getTranslatedText(context, 'Add Time Slot'),
                style: GoogleFonts.montserrat(
                  color: const Color(0xFF6FA57C),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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
  final int maxPatients;
  final String timezone;

  AvailabilitySlot({
    this.id,
    required this.startTime,
    required this.endTime,
    required this.originalDate,
    required this.targetWeekday,
    this.maxPatients = 1,
    this.timezone = 'UTC',
  });
}

extension TimeOfDayExtension on TimeOfDay {
  static TimeOfDay fromDateTime(DateTime date) {
    return TimeOfDay(hour: date.hour, minute: date.minute);
  }

  String format(BuildContext context) {
    final now = DateTime.now();
    return DateFormat(
      'h:mm a',
    ).format(DateTime(now.year, now.month, now.day, hour, minute));
  }
}

class TherapistExceptionsScreen extends StatefulWidget {
  const TherapistExceptionsScreen({super.key});

  @override
  State<TherapistExceptionsScreen> createState() =>
      _TherapistExceptionsScreenState();
}

class _TherapistExceptionsScreenState extends State<TherapistExceptionsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<ExceptionDay> _exceptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExceptions();
  }

  Future<void> _loadExceptions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('therapist_schedule_exceptions')
          .select()
          .eq('therapist_id', userId)
          .order('exception_date', ascending: true);

      _exceptions =
          response
              .map(
                (e) => ExceptionDay(
                  id: e['id'],
                  date: DateTime.parse(e['exception_date']),
                  isAvailable: e['is_available'] ?? false,
                ),
              )
              .toList();

      _exceptions =
          _exceptions
              .where(
                (e) => e.date.isAfter(
                  DateTime.now().subtract(const Duration(days: 1)),
                ),
              )
              .toList();
    } catch (e) {
      debugPrint('${L10n.getTranslatedText(context, 'Error loading exceptions')}: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addException() async {
    final result = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF6FA57C)),
          ),
          child: child!,
        );
      },
    );

    if (result == null) return;

    // Check if exception already exists
    final existingExceptionIndex = _exceptions.indexWhere(
      (e) =>
          DateFormat('yyyy-MM-dd').format(e.date) ==
          DateFormat('yyyy-MM-dd').format(result),
    );

    if (existingExceptionIndex != -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${L10n.getTranslatedText(context, 'Exception for')} ${DateFormat('MMM d, yyyy').format(result)} ${L10n.getTranslatedText(context, 'already exists')}',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(L10n.getTranslatedText(context, 'Set Exception'), style: GoogleFonts.montserrat()),
            content: Text(
              '${L10n.getTranslatedText(context, 'Do you want to mark')} ${DateFormat('EEEE, MMMM d, yyyy').format(result)} ${L10n.getTranslatedText(context, 'as unavailable')}?',
              style: GoogleFonts.montserrat(),
            ),
            actions: [
              TextButton(
                child: Text(L10n.getTranslatedText(context, 'Cancel'), style: GoogleFonts.montserrat()),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: Text(
                  L10n.getTranslatedText(context, 'Mark as Unavailable'),
                  style: GoogleFonts.montserrat(color: Colors.red[700]),
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _createException(result, false);
                },
              ),
            ],
          ),
    );
  }

  Future<void> _createException(DateTime date, bool isAvailable) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response =
          await _supabase.from('therapist_schedule_exceptions').insert({
            'therapist_id': userId,
            'exception_date': date.toIso8601String().split('T')[0],
            'is_available': isAvailable,
          }).select();

      if (response.isNotEmpty) {
        setState(() {
          _exceptions.add(
            ExceptionDay(
              id: response[0]['id'],
              date: date,
              isAvailable: isAvailable,
            ),
          );

          // Sort exceptions by date
          _exceptions.sort((a, b) => a.date.compareTo(b.date));
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${L10n.getTranslatedText(context, 'Successfully marked')} ${DateFormat('MMM d, yyyy').format(date)} ${L10n.getTranslatedText(context, 'as unavailable')}',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${L10n.getTranslatedText(context, 'Error creating exception')}: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteException(String id, DateTime date) async {
    try {
      await _supabase
          .from('therapist_schedule_exceptions')
          .delete()
          .eq('id', id);

      setState(() {
        _exceptions.removeWhere((e) => e.id == id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${L10n.getTranslatedText(context, 'Exception for')} ${DateFormat('MMM d, yyyy').format(date)} ${L10n.getTranslatedText(context, 'removed')}',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${L10n.getTranslatedText(context, 'Error deleting exception')}: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F0),
      appBar: AppBar(
        title: Text(
          L10n.getTranslatedText(context, 'Days Off & Exceptions'),
          style: GoogleFonts.aclonica(color: Colors.black54),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF6FA57C)),
              )
              : Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.02,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.02,
                        horizontal: screenWidth * 0.02,
                      ),
                      child: Text(
                        L10n.getTranslatedText(context, 'Mark specific days when you are unavailable'),
                        style: GoogleFonts.montserrat(
                          fontSize: screenWidth * 0.04,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    Expanded(
                      child:
                          _exceptions.isEmpty
                              ? Center(
                                child: Text(
                                  L10n.getTranslatedText(context, 'No exceptions set'),
                                  style: GoogleFonts.montserrat(
                                    fontSize: screenWidth * 0.045,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                              : ListView.builder(
                                itemCount: _exceptions.length,
                                itemBuilder: (context, index) {
                                  final exception = _exceptions[index];
                                  return _buildExceptionTile(
                                    exception,
                                    screenWidth,
                                    screenHeight,
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addException,
        backgroundColor: const Color(0xFF6FA57C),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildExceptionTile(
    ExceptionDay exception,
    double width,
    double height,
  ) {
    final isExpired = exception.date.isBefore(DateTime.now());

    return Container(
      margin: EdgeInsets.only(bottom: height * 0.015),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: width * 0.04,
          vertical: height * 0.01,
        ),
        title: Text(
          DateFormat('EEEE, MMMM d, yyyy').format(exception.date),
          style: GoogleFonts.montserrat(
            fontSize: width * 0.035,
            fontWeight: FontWeight.w500,
            color: isExpired ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: Text(
          exception.isAvailable ? L10n.getTranslatedText(context, 'Available (Custom)') : L10n.getTranslatedText(context, 'Unavailable'),
          style: GoogleFonts.montserrat(
            fontSize: width * 0.03,
            color:
                exception.isAvailable
                    ? const Color(0xFF6FA57C)
                    : Colors.red[700],
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red[600]),
          onPressed:
              isExpired ? null : () => _showDeleteConfirmationDialog(exception),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(ExceptionDay exception) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(L10n.getTranslatedText(context, 'Remove Exception'), style: GoogleFonts.montserrat()),
            content: Text(
              '${L10n.getTranslatedText(context, 'Are you sure you want to remove the exception for')} ${DateFormat('EEEE, MMMM d, yyyy').format(exception.date)}?',
              style: GoogleFonts.montserrat(),
            ),
            actions: [
              TextButton(
                child: Text(L10n.getTranslatedText(context, 'Cancel'), style: GoogleFonts.montserrat()),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: Text(
                  L10n.getTranslatedText(context, 'Remove'),
                  style: GoogleFonts.montserrat(color: Colors.red[700]),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteException(exception.id, exception.date);
                },
              ),
            ],
          ),
    );
  }
}

class ExceptionDay {
  final String id;
  final DateTime date;
  final bool isAvailable;

  ExceptionDay({
    required this.id,
    required this.date,
    required this.isAvailable,
  });
}
