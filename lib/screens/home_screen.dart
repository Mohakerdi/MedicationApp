import 'dart:async';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../data/app_database.dart';
import '../services/alarm_scheduler.dart';
import '../services/csv_alarm_transfer_service.dart';
import '../services/notification_service.dart';
import '../viewmodels/home_view_model.dart';
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
  static const _defaultHour = 8;
  static const _defaultMinute = 0;

  late final HomeViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: _defaultHour, minute: _defaultMinute);
  StreamSubscription<int>? _selectionSubscription;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(
      database: widget.database,
      scheduler: widget.scheduler,
      notifications: widget.notifications,
      csvService: CsvAlarmTransferService(),
    );
    _viewModel.load();
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
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _addMedication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await _viewModel.addMedication(
      name: _nameController.text,
      dosage: _dosageController.text,
      hour: _time.hour,
      minute: _time.minute,
    );
    _nameController.clear();
    _dosageController.clear();
    if (mounted) {
      setState(
        () => _time = const TimeOfDay(
          hour: _defaultHour,
          minute: _defaultMinute,
        ),
      );
    }
  }

  Future<void> _openAlarmById(int alarmId) async {
    final alarm = await _viewModel.getAlarmById(alarmId);
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

    await _viewModel.load();
  }

  Future<void> _requestAlarmPermissions() async {
    await _viewModel.requestAlarmPermissions();
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

  Future<void> _exportCsv() async {
    final l10n = AppLocalizations.of(context)!;
    final path = await _viewModel.exportAsCsv(
      headers: [
        l10n.csvHeaderMedicationName,
        l10n.csvHeaderDosage,
        l10n.csvHeaderHour,
        l10n.csvHeaderMinute,
        l10n.csvHeaderTimezone,
      ],
    );
    if (!mounted) {
      return;
    }
    if (path != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.csvExportedAt(path))));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.exportUnsupported)));
    }
  }

  Future<void> _importCsv() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      withData: true,
    );
    if (!mounted) {
      return;
    }

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    String? csv;
    if (kIsWeb && file.bytes != null) {
      csv = String.fromCharCodes(file.bytes!);
    } else if (file.path != null) {
      csv = await File(file.path!).readAsString();
    }

    if (csv == null || csv.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.csvImportInvalid)));
      return;
    }

    final count = await _viewModel.importFromCsv(csv);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.csvImportDone(count))));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(l10n.appTitle),
          actions: [
            IconButton(
              onPressed: _exportCsv,
              icon: const Icon(Icons.upload_file),
              tooltip: l10n.exportCsv,
            ),
            IconButton(
              onPressed: _importCsv,
              icon: const Icon(Icons.download_for_offline_outlined),
              tooltip: l10n.importCsv,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: _viewModel.exactAlarmGranted
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _viewModel.exactAlarmGranted
                          ? l10n.exactAlarmsEnabled
                          : l10n.exactAlarmsDisabled,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: _requestAlarmPermissions,
                          child: Text(l10n.grantAlarmPermissions),
                        ),
                        if (defaultTargetPlatform == TargetPlatform.android)
                          OutlinedButton(
                            onPressed: _openExactAlarmSettings,
                            child: Text(l10n.exactAlarmSettings),
                          ),
                        if (defaultTargetPlatform == TargetPlatform.android)
                          OutlinedButton(
                            onPressed: _openBatteryOptimizationSettings,
                            child: Text(l10n.batteryOptimization),
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
                        l10n.addMedicationSchedule,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(labelText: l10n.medicationName),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.requiredField;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _dosageController,
                        decoration: InputDecoration(labelText: l10n.dosageHint),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.requiredField;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(l10n.timeLabel(_time.format(context))),
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
                            child: Text(l10n.pickTime),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _addMedication,
                        child: Text(l10n.saveSchedule),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.activeSchedules,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_viewModel.plans.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(l10n.noMedicationsYet),
                ),
              ),
            for (final plan in _viewModel.plans)
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
      ),
    );
  }
}
