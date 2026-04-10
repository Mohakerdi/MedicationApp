import 'dart:async';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/app_database.dart';
import '../models/entities.dart';
import '../services/alarm_scheduler.dart';
import '../services/notification_service.dart';
import 'alarm_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.database,
    required this.scheduler,
    required this.notifications,
    this.initialAlarmId,
  });

  final AppDatabase database;
  final AlarmScheduler scheduler;
  final NotificationService notifications;
  final int? initialAlarmId;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  List<MedicationPlan> _plans = const [];
  bool _exactAlarmGranted = true;
  StreamSubscription<int>? _selectionSubscription;

  @override
  void initState() {
    super.initState();
    _load();
    _selectionSubscription = widget.notifications.alarmSelectionStream.listen(
      _openAlarmById,
    );
    if (widget.initialAlarmId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openAlarmById(widget.initialAlarmId!);
      });
    }
  }

  @override
  void dispose() {
    _selectionSubscription?.cancel();
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await widget.scheduler.reconcileOnStartup();
    final plans = await widget.database.getMedicationPlans();
    final exact = await widget.notifications.canScheduleExactAlarms();
    if (!mounted) {
      return;
    }
    setState(() {
      _plans = plans;
      _exactAlarmGranted = exact;
    });
  }

  Future<void> _addMedication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final timezoneName = tz.local.name;
    final plan = await widget.database.createMedicationPlan(
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim(),
      hour: _time.hour,
      minute: _time.minute,
      timezoneName: timezoneName,
    );

    await widget.scheduler.seedForPlan(plan);

    _nameController.clear();
    _dosageController.clear();
    await _load();
  }

  Future<void> _openAlarmById(int alarmId) async {
    final alarm = await widget.database.getAlarmWithMedication(alarmId);
    if (!mounted || alarm == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => AlarmScreen(
          alarm: alarm,
          onTakeNow: () => widget.scheduler.markTaken(alarmId),
          onSnooze: () => widget.scheduler.snooze(alarmId: alarmId),
          onSkip: () => widget.scheduler.markSkipped(alarmId),
        ),
      ),
    );

    await _load();
  }

  Future<void> _requestAlarmPermissions() async {
    await widget.notifications.requestUserPermissions();
    await _load();
  }

  Future<void> _openExactAlarmSettings() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    const intent =
        AndroidIntent(action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM');
    await intent.launch();
  }

  Future<void> _openBatteryOptimizationSettings() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    const intent = AndroidIntent(
      action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
    );
    await intent.launch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Alarm'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: _exactAlarmGranted ? Colors.green.shade50 : Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _exactAlarmGranted
                        ? 'Exact alarms enabled'
                        : 'Exact alarms not enabled',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: _requestAlarmPermissions,
                        child: const Text('Grant Alarm Permissions'),
                      ),
                      if (defaultTargetPlatform == TargetPlatform.android)
                        OutlinedButton(
                          onPressed: _openExactAlarmSettings,
                          child: const Text('Exact Alarm Settings'),
                        ),
                      if (defaultTargetPlatform == TargetPlatform.android)
                        OutlinedButton(
                          onPressed: _openBatteryOptimizationSettings,
                          child: const Text('Battery Optimization'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add medication schedule',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Medication name',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Dosage (e.g. 2mg)',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Time: ${_time.format(context)}'),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _time,
                            );
                            if (picked != null) {
                              setState(() => _time = picked);
                            }
                          },
                          child: const Text('Pick time'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _addMedication,
                      child: const Text('Save schedule'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Active schedules', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_plans.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('No medications yet.'),
              ),
            ),
          for (final plan in _plans)
            Card(
              child: ListTile(
                leading: const Icon(Icons.medication),
                title: Text(plan.medication.name),
                subtitle: Text(
                  '${plan.medication.dosage} • ${plan.schedule.hour.toString().padLeft(2, '0')}:${plan.schedule.minute.toString().padLeft(2, '0')} (${plan.schedule.timezoneName})',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
