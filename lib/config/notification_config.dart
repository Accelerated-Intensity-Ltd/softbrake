import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationConfigDialog extends StatefulWidget {
  final NotificationPreferences initialPreferences;
  final Function(NotificationPreferences preferences) onSave;
  final Function() onDefaults;

  const NotificationConfigDialog({
    super.key,
    required this.initialPreferences,
    required this.onSave,
    required this.onDefaults,
  });

  @override
  State<NotificationConfigDialog> createState() => _NotificationConfigDialogState();
}

class _NotificationConfigDialogState extends State<NotificationConfigDialog> {
  late bool _isEnabled;
  late NotificationMode _selectedMode;
  late TimeOfDay _selectedTime;
  late bool _isRecurring;
  late CountdownInterval _selectedCountdown;
  late int _customMinutes;
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  late TextEditingController _customMinutesController;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.initialPreferences.isEnabled;
    _selectedMode = widget.initialPreferences.mode;
    _selectedTime = widget.initialPreferences.scheduledTime ?? const TimeOfDay(hour: 21, minute: 0);
    _isRecurring = widget.initialPreferences.isRecurring;
    _selectedCountdown = widget.initialPreferences.countdownInterval ?? CountdownInterval.thirtyMinutes;
    _customMinutes = widget.initialPreferences.customMinutes ?? 60;
    _titleController = TextEditingController(text: widget.initialPreferences.title);
    _bodyController = TextEditingController(text: widget.initialPreferences.body);
    _customMinutesController = TextEditingController(text: _customMinutes.toString());

    // Listen to text changes
    _titleController.addListener(() => setState(() {}));
    _bodyController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _customMinutesController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.grey,
              onPrimary: Colors.white,
              surface: Colors.black,
              onSurface: Colors.white,
            ),
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: Colors.black,
              hourMinuteTextColor: Colors.white,
              dialHandColor: Colors.grey,
              dialTextColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _updateCustomMinutes(String value) {
    final minutes = int.tryParse(value);
    if (minutes != null && minutes > 0 && minutes <= 1440) { // Max 24 hours
      setState(() {
        _customMinutes = minutes;
      });
    }
  }

  String _getCountdownDisplayText(CountdownInterval interval) {
    switch (interval) {
      case CountdownInterval.tenMinutes:
        return '10 minutes';
      case CountdownInterval.thirtyMinutes:
        return '30 minutes';
      case CountdownInterval.oneHour:
        return '1 hour';
      case CountdownInterval.twoHours:
        return '2 hours';
      case CountdownInterval.custom:
        return 'Custom duration';
    }
  }

  String? _getNextNotificationInfo() {
    if (!_isEnabled) return null;

    final now = DateTime.now();
    DateTime nextNotification;

    if (_selectedMode == NotificationMode.scheduledTime) {
      nextNotification = DateTime(
        now.year,
        now.month,
        now.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // If time has passed today, schedule for tomorrow
      if (nextNotification.isBefore(now)) {
        nextNotification = nextNotification.add(const Duration(days: 1));
      }

      final timeString = _selectedTime.toFormattedString();
      if (_isRecurring) {
        return 'Daily at $timeString';
      } else {
        final today = DateTime.now();
        final isToday = nextNotification.year == today.year &&
                        nextNotification.month == today.month &&
                        nextNotification.day == today.day;
        return isToday ? 'Today at $timeString' : 'Tomorrow at $timeString';
      }
    } else {
      int minutes;
      switch (_selectedCountdown) {
        case CountdownInterval.tenMinutes:
          minutes = 10;
          break;
        case CountdownInterval.thirtyMinutes:
          minutes = 30;
          break;
        case CountdownInterval.oneHour:
          minutes = 60;
          break;
        case CountdownInterval.twoHours:
          minutes = 120;
          break;
        case CountdownInterval.custom:
          minutes = _customMinutes;
          break;
      }
      return 'In $minutes minute${minutes != 1 ? 's' : ''}';
    }
  }

  bool _hasChanges() {
    final initial = widget.initialPreferences;
    return _isEnabled != initial.isEnabled ||
           _selectedMode != initial.mode ||
           _selectedTime != (initial.scheduledTime ?? const TimeOfDay(hour: 21, minute: 0)) ||
           _isRecurring != initial.isRecurring ||
           _selectedCountdown != (initial.countdownInterval ?? CountdownInterval.thirtyMinutes) ||
           _customMinutes != (initial.customMinutes ?? 60) ||
           _titleController.text.trim() != initial.title ||
           _bodyController.text.trim() != initial.body;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: Colors.grey, width: 1),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notification Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 25),

              // Enable/Disable Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Enable Notifications',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Switch(
                    value: _isEnabled,
                    onChanged: (value) {
                      setState(() {
                        _isEnabled = value;
                      });
                    },
                    activeColor: Colors.white,
                    activeTrackColor: Colors.green,
                  ),
                ],
              ),

              if (_isEnabled) ...[
                const SizedBox(height: 25),

                // Mode Selection
                const Text(
                  'Notification Mode',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Radio<NotificationMode>(
                            value: NotificationMode.scheduledTime,
                            groupValue: _selectedMode,
                            onChanged: (NotificationMode? value) {
                              setState(() {
                                _selectedMode = value!;
                              });
                            },
                            activeColor: Colors.white,
                          ),
                          const Text(
                            'Scheduled Time',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Radio<NotificationMode>(
                            value: NotificationMode.countdown,
                            groupValue: _selectedMode,
                            onChanged: (NotificationMode? value) {
                              setState(() {
                                _selectedMode = value!;
                              });
                            },
                            activeColor: Colors.white,
                          ),
                          const Text(
                            'Countdown',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Scheduled Time Configuration
                if (_selectedMode == NotificationMode.scheduledTime) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Time',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      GestureDetector(
                        onTap: _selectTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _selectedTime.toFormattedString(),
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Recurring Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Daily Recurring',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Switch(
                        value: _isRecurring,
                        onChanged: (value) {
                          setState(() {
                            _isRecurring = value;
                          });
                        },
                        activeColor: Colors.white,
                        activeTrackColor: Colors.green,
                      ),
                    ],
                  ),
                ],

                // Countdown Configuration
                if (_selectedMode == NotificationMode.countdown) ...[
                  const Text(
                    'Countdown Interval',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  ...CountdownInterval.values.map((interval) => RadioListTile<CountdownInterval>(
                    title: Text(
                      _getCountdownDisplayText(interval),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    value: interval,
                    groupValue: _selectedCountdown,
                    onChanged: (CountdownInterval? value) {
                      setState(() {
                        _selectedCountdown = value!;
                      });
                    },
                    activeColor: Colors.white,
                  )),

                  // Custom minutes input
                  if (_selectedCountdown == CountdownInterval.custom) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text(
                          'Minutes: ',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _customMinutesController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: _updateCustomMinutes,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],

                const SizedBox(height: 25),

                // Custom Message Section
                const Text(
                  'Notification Message',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _bodyController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    labelStyle: TextStyle(color: Colors.grey),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 20),

                // Next Notification Info
                if (_getNextNotificationInfo() != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[600]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Next: ${_getNextNotificationInfo()}',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 25),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await widget.onDefaults();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(60, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Defaults'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(60, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      side: BorderSide(color: Colors.grey[600]!, width: 1),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _hasChanges() ? () {
                      final preferences = NotificationPreferences(
                        isEnabled: _isEnabled,
                        mode: _selectedMode,
                        scheduledTime: _selectedMode == NotificationMode.scheduledTime ? _selectedTime : null,
                        isRecurring: _isRecurring,
                        countdownInterval: _selectedMode == NotificationMode.countdown ? _selectedCountdown : null,
                        customMinutes: _selectedCountdown == CountdownInterval.custom ? _customMinutes : null,
                        title: _titleController.text.trim().isEmpty ? 'A Gentle Reminder' : _titleController.text.trim(),
                        body: _bodyController.text.trim().isEmpty ? 'Is it time to apply a soft brake?' : _bodyController.text.trim(),
                      );

                      widget.onSave(preferences);
                      Navigator.of(context).pop();
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasChanges() ? Colors.green[600] : Colors.grey[700],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(60, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}