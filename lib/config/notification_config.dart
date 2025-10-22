import 'dart:io';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

enum NotificationType { disabled, oneTime, countdown }

class NotificationSettings {
  final NotificationType type;
  final String title;
  final String body;
  final DateTime? scheduleTime;
  final Duration? countdownDuration;
  final bool isDaily;

  const NotificationSettings({
    this.type = NotificationType.oneTime,
    this.title = 'Gentle reminder',
    this.body = 'Is it time to apply the brake?',
    this.scheduleTime,
    this.countdownDuration,
    this.isDaily = false,
  });

  NotificationSettings copyWith({
    NotificationType? type,
    String? title,
    String? body,
    DateTime? scheduleTime,
    Duration? countdownDuration,
    bool? isDaily,
  }) {
    return NotificationSettings(
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      scheduleTime: scheduleTime ?? this.scheduleTime,
      countdownDuration: countdownDuration ?? this.countdownDuration,
      isDaily: isDaily ?? this.isDaily,
    );
  }

  static const NotificationSettings defaultSettings = NotificationSettings(
    type: NotificationType.oneTime,
  );
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
  bool _isDaily = false;
  bool _hasRequiredPermissions = true;

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
    _isDaily = widget.initialSettings.isDaily;

    _titleController.addListener(() => setState(() {}));
    _bodyController.addListener(() => setState(() {}));

    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      final hasPermissions = await NotificationService().hasRequiredPermissions();
      if (mounted) {
        setState(() {
          _hasRequiredPermissions = hasPermissions;
        });
      }
    }
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
           current.isDaily != widget.initialSettings.isDaily;
  }


  NotificationSettings _buildCurrentSettings() {
    return NotificationSettings(
      type: _selectedType,
      title: _titleController.text.trim().isEmpty ? 'Gentle reminder' : _titleController.text.trim(),
      body: _bodyController.text.trim().isEmpty ? 'Is it time to apply the brake?' : _bodyController.text.trim(),
      scheduleTime: _selectedType == NotificationType.oneTime ? _selectedDateTime : null,
      countdownDuration: _selectedType == NotificationType.countdown ? _selectedCountdown : null,
      isDaily: _selectedType == NotificationType.oneTime ? _isDaily : false,
    );
  }

  Future<void> _selectDateTime() async {
    final now = DateTime.now();

    // Ensure initial date is not in the past
    DateTime initialDate;
    if (_selectedDateTime != null && _selectedDateTime!.isAfter(now)) {
      initialDate = _selectedDateTime!;
    } else {
      initialDate = now.add(const Duration(hours: 1));
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
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
      // Calculate default time for the time picker
      TimeOfDay defaultTime;
      if (_selectedDateTime != null && _selectedDateTime!.isAfter(now)) {
        defaultTime = TimeOfDay.fromDateTime(_selectedDateTime!);
      } else {
        defaultTime = TimeOfDay.fromDateTime(now.add(const Duration(hours: 1)));
      }

      final time = await showTimePicker(
        context: context,
        initialTime: defaultTime,
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


  String _formatCustomDuration(Duration duration) {
    if (duration.inHours > 0) {
      final minutes = duration.inMinutes % 60;
      if (minutes > 0) {
        return '${duration.inHours}h ${minutes}m';
      } else {
        return '${duration.inHours}h';
      }
    } else {
      return '${duration.inMinutes}m';
    }
  }

  Future<void> _showCustomDurationDialog() async {
    int hours = 0;
    int minutes = 5;

    // If there's a current custom duration, pre-populate the fields
    if (_selectedCountdown != null && !_presetDurations.contains(_selectedCountdown)) {
      hours = _selectedCountdown!.inHours;
      minutes = _selectedCountdown!.inMinutes % 60;
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.black,
              title: const Text(
                'Custom Duration',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Hours', style: TextStyle(color: Colors.white)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: hours,
                                  dropdownColor: Colors.black,
                                  style: const TextStyle(color: Colors.white),
                                  items: List.generate(24, (index) {
                                    return DropdownMenuItem(
                                      value: index,
                                      child: Text('$index'),
                                    );
                                  }),
                                  onChanged: (value) {
                                    setDialogState(() {
                                      hours = value!;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Minutes', style: TextStyle(color: Colors.white)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: minutes,
                                  dropdownColor: Colors.black,
                                  style: const TextStyle(color: Colors.white),
                                  items: List.generate(60, (index) {
                                    return DropdownMenuItem(
                                      value: index,
                                      child: Text('$index'),
                                    );
                                  }),
                                  onChanged: (value) {
                                    setDialogState(() {
                                      minutes = value!;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Total: ${hours > 0 ? '${hours}h ' : ''}${minutes}m',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (hours == 0 && minutes == 0) ? null : () {
                    final customDuration = Duration(hours: hours, minutes: minutes);
                    setState(() {
                      _selectedCountdown = customDuration;
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (hours == 0 && minutes == 0) ? Colors.grey[700] : Colors.green[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Set'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notification Type',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        ...NotificationType.values.map((type) {
          String label;
          switch (type) {
            case NotificationType.disabled:
              label = 'Disabled';
              break;
            case NotificationType.oneTime:
              label = 'Schedule';
              break;
            case NotificationType.countdown:
              label = 'Countdown';
              break;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            child: RadioListTile<NotificationType>(
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
              dense: true,
            ),
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
        const SizedBox(height: 6),
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
        const SizedBox(height: 10),
        const Text('Message', style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 6),
        TextField(
          controller: _bodyController,
          maxLength: 100,
          maxLines: 2,
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
        const SizedBox(height: 8),
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
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: _isDaily,
              onChanged: (bool? value) {
                setState(() {
                  _isDaily = value ?? false;
                });
              },
              activeColor: Colors.white,
              checkColor: Colors.black,
              side: const BorderSide(color: Colors.grey, width: 1.5),
            ),
            const SizedBox(width: 8),
            const Text(
              'Daily',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCountdownConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Countdown Duration', style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
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
            // Show custom duration chip if a custom duration is selected
            if (_selectedCountdown != null && !_presetDurations.contains(_selectedCountdown!))
              ChoiceChip(
                label: Text(_formatCustomDuration(_selectedCountdown!)),
                selected: true,
                onSelected: (selected) {
                  if (!selected) {
                    setState(() {
                      _selectedCountdown = null;
                    });
                  }
                },
                backgroundColor: Colors.grey[800],
                selectedColor: Colors.blue[600],
                labelStyle: const TextStyle(color: Colors.white),
              ),
            ElevatedButton(
              onPressed: _showCustomDurationDialog,
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


  Widget _buildPermissionWarning() {
    if (_hasRequiredPermissions || _selectedType == NotificationType.disabled) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        border: Border.all(color: Colors.orange, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                'Permission Required',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Notifications require "Alarms & reminders" permission. Please enable it in Android Settings > Apps > Soft Brake > Permissions.',
            style: TextStyle(color: Colors.orange.shade300, fontSize: 12),
          ),
          const SizedBox(height: 6),
          ElevatedButton(
            onPressed: () async {
              await NotificationService().requestPermissions();
              await _checkPermissions();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text('Request Permission', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      child: Container(
        padding: const EdgeInsets.all(16),
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
              const SizedBox(height: 16),
              _buildPermissionWarning(),
              if (_selectedType != NotificationType.disabled) ...[
                _buildTextFields(),
                const SizedBox(height: 12),
              ],
              _buildTypeSelection(),
              if (_selectedType != NotificationType.disabled) ...[
                const SizedBox(height: 12),
                if (_selectedType == NotificationType.oneTime) _buildOneTimeConfig(),
                if (_selectedType == NotificationType.countdown) _buildCountdownConfig(),
              ],
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await widget.onDefaults();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        child: const Text('Defaults'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          side: BorderSide(color: Colors.grey[600]!, width: 1),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _hasChanges() ? () {
                          final settings = _buildCurrentSettings();
                          widget.onSave(settings);
                          Navigator.of(context).pop();
                        } : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasChanges() ? Colors.green[600] : Colors.grey[700],
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}