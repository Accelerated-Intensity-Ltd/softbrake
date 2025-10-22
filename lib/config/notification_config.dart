import 'package:flutter/material.dart';

enum NotificationType { disabled, oneTime, countdown, recurring }

class NotificationSettings {
  final NotificationType type;
  final String title;
  final String body;
  final DateTime? scheduleTime;
  final Duration? countdownDuration;
  final List<int>? recurringDays; // 1-7 for Monday-Sunday
  final TimeOfDay? recurringTime;

  const NotificationSettings({
    this.type = NotificationType.disabled,
    this.title = 'Gentle reminder',
    this.body = 'Is it time to apply the brake?',
    this.scheduleTime,
    this.countdownDuration,
    this.recurringDays,
    this.recurringTime,
  });

  NotificationSettings copyWith({
    NotificationType? type,
    String? title,
    String? body,
    DateTime? scheduleTime,
    Duration? countdownDuration,
    List<int>? recurringDays,
    TimeOfDay? recurringTime,
  }) {
    return NotificationSettings(
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      scheduleTime: scheduleTime ?? this.scheduleTime,
      countdownDuration: countdownDuration ?? this.countdownDuration,
      recurringDays: recurringDays ?? this.recurringDays,
      recurringTime: recurringTime ?? this.recurringTime,
    );
  }

  static const NotificationSettings defaultSettings = NotificationSettings();
}

class NotificationConfigDialog extends StatefulWidget {
  final NotificationSettings initialSettings;
  final Function(NotificationSettings settings) onSave;
  final Function() onDefaults;

  const NotificationConfigDialog({
    super.key,
    required this.initialSettings,
    required this.onSave,
    required this.onDefaults,
  });

  @override
  State<NotificationConfigDialog> createState() => _NotificationConfigDialogState();
}

class _NotificationConfigDialogState extends State<NotificationConfigDialog> {
  late NotificationType _selectedType;
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  DateTime? _selectedDateTime;
  Duration? _selectedCountdown;
  TimeOfDay? _selectedRecurringTime;
  Set<int> _selectedDays = {};

  // Predefined countdown durations
  static const List<Duration> _presetDurations = [
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(hours: 1),
    Duration(hours: 2),
    Duration(hours: 4),
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialSettings.type;
    _titleController = TextEditingController(text: widget.initialSettings.title);
    _bodyController = TextEditingController(text: widget.initialSettings.body);
    _selectedDateTime = widget.initialSettings.scheduleTime;
    _selectedCountdown = widget.initialSettings.countdownDuration;
    _selectedRecurringTime = widget.initialSettings.recurringTime;
    _selectedDays = widget.initialSettings.recurringDays?.toSet() ?? {};

    _titleController.addListener(() => setState(() {}));
    _bodyController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  bool _hasChanges() {
    final current = _buildCurrentSettings();
    return current.type != widget.initialSettings.type ||
           current.title != widget.initialSettings.title ||
           current.body != widget.initialSettings.body ||
           current.scheduleTime != widget.initialSettings.scheduleTime ||
           current.countdownDuration != widget.initialSettings.countdownDuration ||
           !_listsEqual(current.recurringDays, widget.initialSettings.recurringDays) ||
           current.recurringTime != widget.initialSettings.recurringTime;
  }

  bool _listsEqual(List<int>? a, List<int>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  NotificationSettings _buildCurrentSettings() {
    return NotificationSettings(
      type: _selectedType,
      title: _titleController.text.trim().isEmpty ? 'Gentle reminder' : _titleController.text.trim(),
      body: _bodyController.text.trim().isEmpty ? 'Is it time to apply the brake?' : _bodyController.text.trim(),
      scheduleTime: _selectedType == NotificationType.oneTime ? _selectedDateTime : null,
      countdownDuration: _selectedType == NotificationType.countdown ? _selectedCountdown : null,
      recurringDays: _selectedType == NotificationType.recurring ? (_selectedDays.toList()..sort()) : null,
      recurringTime: _selectedType == NotificationType.recurring ? _selectedRecurringTime : null,
    );
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Colors.black,
              surface: Colors.black,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now().add(const Duration(hours: 1))),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Colors.white,
                onPrimary: Colors.black,
                surface: Colors.black,
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _selectRecurringTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedRecurringTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Colors.black,
              surface: Colors.black,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        _selectedRecurringTime = time;
      });
    }
  }

  Widget _buildTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notification Type',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 10),
        ...NotificationType.values.map((type) {
          String label;
          switch (type) {
            case NotificationType.disabled:
              label = 'Disabled';
              break;
            case NotificationType.oneTime:
              label = 'One-time';
              break;
            case NotificationType.countdown:
              label = 'Countdown';
              break;
            case NotificationType.recurring:
              label = 'Recurring';
              break;
          }

          return RadioListTile<NotificationType>(
            title: Text(label, style: const TextStyle(color: Colors.white)),
            value: type,
            groupValue: _selectedType,
            onChanged: (NotificationType? value) {
              setState(() {
                _selectedType = value!;
              });
            },
            activeColor: Colors.white,
            contentPadding: EdgeInsets.zero,
          );
        }),
      ],
    );
  }

  Widget _buildTextFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Title', style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          maxLength: 50,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Gentle reminder',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            border: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            counterStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        ),
        const SizedBox(height: 15),
        const Text('Message', style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: _bodyController,
          maxLength: 100,
          maxLines: 3,
          minLines: 1,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Is it time to apply the brake?',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            border: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            counterStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        ),
      ],
    );
  }

  Widget _buildOneTimeConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Schedule', style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _selectDateTime,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[700],
            foregroundColor: Colors.white,
          ),
          child: Text(
            _selectedDateTime != null
                ? '${_selectedDateTime!.day}/${_selectedDateTime!.month}/${_selectedDateTime!.year} at ${_selectedDateTime!.hour.toString().padLeft(2, '0')}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}'
                : 'Select date & time',
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Countdown Duration', style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._presetDurations.map((duration) {
              String label;
              if (duration.inHours > 0) {
                label = '${duration.inHours}h';
              } else {
                label = '${duration.inMinutes}m';
              }

              return ChoiceChip(
                label: Text(label),
                selected: _selectedCountdown == duration,
                onSelected: (selected) {
                  setState(() {
                    _selectedCountdown = selected ? duration : null;
                  });
                },
                backgroundColor: Colors.grey[800],
                selectedColor: Colors.grey[600],
                labelStyle: const TextStyle(color: Colors.white),
              );
            }),
            ElevatedButton(
              onPressed: () {
                // TODO: Show custom duration picker
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Custom duration picker not implemented yet')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Custom'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecurringConfig() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Days', style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: List.generate(7, (index) {
            final dayNum = index + 1;
            return ChoiceChip(
              label: Text(days[index]),
              selected: _selectedDays.contains(dayNum),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedDays.add(dayNum);
                  } else {
                    _selectedDays.remove(dayNum);
                  }
                });
              },
              backgroundColor: Colors.grey[800],
              selectedColor: Colors.grey[600],
              labelStyle: const TextStyle(color: Colors.white),
            );
          }),
        ),
        const SizedBox(height: 15),
        const Text('Time', style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _selectRecurringTime,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[700],
            foregroundColor: Colors.white,
          ),
          child: Text(
            _selectedRecurringTime != null
                ? '${_selectedRecurringTime!.hour.toString().padLeft(2, '0')}:${_selectedRecurringTime!.minute.toString().padLeft(2, '0')}'
                : 'Select time',
          ),
        ),
      ],
    );
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
              const Center(
                child: Text(
                  'Notification Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              _buildTypeSelection(),
              if (_selectedType != NotificationType.disabled) ...[
                const SizedBox(height: 20),
                _buildTextFields(),
                const SizedBox(height: 20),
                if (_selectedType == NotificationType.oneTime) _buildOneTimeConfig(),
                if (_selectedType == NotificationType.countdown) _buildCountdownConfig(),
                if (_selectedType == NotificationType.recurring) _buildRecurringConfig(),
              ],
              const SizedBox(height: 25),
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
                      final settings = _buildCurrentSettings();
                      widget.onSave(settings);
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