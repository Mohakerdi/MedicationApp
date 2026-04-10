import 'dart:async';

import 'package:android_intent_plus/android_intent.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:medecation_app/l10n/app_localizations.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../data/app_database.dart';
import '../models/entities.dart';
import '../services/alarm_scheduler.dart';
import '../services/csv_alarm_transfer_service.dart';
import '../services/notification_service.dart';
import '../viewmodels/app_settings_view_model.dart';
import '../viewmodels/home_view_model.dart';
import 'alarm_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.database,
    required this.scheduler,
    required this.notifications,
    required this.settingsViewModel,
    this.initialAlarmId,
  });

  final AppDatabase database;
  final AlarmScheduler scheduler;
  final NotificationService notifications;
  final AppSettingsViewModel settingsViewModel;
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
  final _pillCountController = TextEditingController(text: '1');
  final _addCardKey = GlobalKey();
  final _saveButtonKey = GlobalKey();
  final _optionsTabKey = GlobalKey();
  List<TimeOfDay> _times = const [
    TimeOfDay(hour: _defaultHour, minute: _defaultMinute),
  ];
  int _doseCount = 1;
  MedicationKind _medicationKind = MedicationKind.daily;
  int _intervalDays = 2;
  StreamSubscription<int>? _selectionSubscription;
  int _tabIndex = 0;
  bool _tutorialPresented = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _showTutorialIfNeeded());
  }

  @override
  void dispose() {
    _selectionSubscription?.cancel();
    _nameController.dispose();
    _dosageController.dispose();
    _pillCountController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _showTutorialIfNeeded() async {
    final supportsTutorialOverlay =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (!supportsTutorialOverlay) {
      return;
    }
    if (!mounted || _tutorialPresented || !widget.settingsViewModel.shouldShowHomeTutorial) {
      return;
    }
    _tutorialPresented = true;
    final l10n = AppLocalizations.of(context)!;
    final targets = [
      TargetFocus(
        identify: 'add_medication',
        keyTarget: _addCardKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Text(
              l10n.tutorialAddMedication,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'save_schedule',
        keyTarget: _saveButtonKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Text(
              l10n.tutorialSaveSchedule,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'options_tab',
        keyTarget: _optionsTabKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Text(
              l10n.tutorialOptionsTab,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      hideSkip: false,
      textSkip: l10n.skip,
      onFinish: () => widget.settingsViewModel.markHomeTutorialSeen(),
      onSkip: () {
        widget.settingsViewModel.markHomeTutorialSeen();
        return true;
      },
    ).show(context: context);
  }

  Future<void> _addMedication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final totalPills = int.tryParse(_pillCountController.text.trim()) ?? 0;
    if (_medicationKind == MedicationKind.oneTime && totalPills < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pill count should be at least 1')),
      );
      return;
    }

    await _viewModel.addMedication(
      name: _nameController.text,
      dosage: _dosageController.text,
      times: _times
          .take(_medicationKind == MedicationKind.daily ? _doseCount : 1)
          .map((time) => (hour: time.hour, minute: time.minute))
          .toList(),
      kind: _medicationKind,
      intervalDays: _medicationKind == MedicationKind.interval ? _intervalDays : 1,
      totalPills: _medicationKind == MedicationKind.oneTime ? totalPills : 0,
    );
    _nameController.clear();
    _dosageController.clear();
    _pillCountController.text = '1';
    if (mounted) {
      setState(
        () {
          _times = const [TimeOfDay(hour: _defaultHour, minute: _defaultMinute)];
          _doseCount = 1;
          _medicationKind = MedicationKind.daily;
          _intervalDays = 2;
        },
      );
    }
  }

  Future<void> _pickDoseTime(int index) async {
    final initial = index < _times.length ? _times[index] : _times.last;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) {
      return;
    }
    setState(() {
      final next = [..._times];
      while (next.length <= index) {
        next.add(next.last);
      }
      next[index] = picked;
      _times = next;
    });
  }

  Future<void> _editSchedule(MedicationPlan plan) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: plan.schedule.hour, minute: plan.schedule.minute),
    );
    if (picked == null) {
      return;
    }
    await _viewModel.editScheduleTime(
      plan: plan,
      hour: picked.hour,
      minute: picked.minute,
    );
  }

  String _kindLabel(MedicationKind kind) {
    switch (kind) {
      case MedicationKind.daily:
        return 'Daily';
      case MedicationKind.interval:
        return 'Interval schedule';
      case MedicationKind.oneTime:
        return 'One-time';
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
          alarmSound: widget.settingsViewModel.selectedSound,
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
    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    final bytes = file.bytes;
    final csv = bytes == null ? null : String.fromCharCodes(bytes);

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

  Future<void> _pickDeviceSound() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'wav', 'm4a', 'aac', 'ogg'],
    );
    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }
    final path = result.files.first.path;
    if (path == null || path.isEmpty) {
      return;
    }
    await widget.settingsViewModel.setSelectedDeviceSoundPath(path);
  }

  Future<void> _confirmDeleteAll() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAll),
        content: Text(l10n.deleteAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _viewModel.deleteAllData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.deleteAllDone)));
      }
    }
  }

  Widget _buildSchedulesTab(AppLocalizations l10n) {
    return ListView(
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
            key: _addCardKey,
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
                  DropdownButtonFormField<MedicationKind>(
                    value: _medicationKind,
                    decoration: const InputDecoration(labelText: 'Medication type'),
                    items: MedicationKind.values
                        .map(
                          (kind) => DropdownMenuItem<MedicationKind>(
                            value: kind,
                            child: Text(_kindLabel(kind)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => _medicationKind = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  if (_medicationKind == MedicationKind.daily)
                    DropdownButtonFormField<int>(
                      value: _doseCount,
                      decoration: const InputDecoration(labelText: 'Doses per day'),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1 dose')),
                        DropdownMenuItem(value: 2, child: Text('2 doses')),
                        DropdownMenuItem(value: 3, child: Text('3 doses')),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _doseCount = value;
                          final next = [..._times];
                          while (next.length < value) {
                            next.add(next.last);
                          }
                          _times = next;
                        });
                      },
                    ),
                  if (_medicationKind == MedicationKind.interval)
                    DropdownButtonFormField<int>(
                      value: _intervalDays,
                      decoration: const InputDecoration(labelText: 'Repeat every'),
                      items: const [
                        DropdownMenuItem(value: 2, child: Text('Every 2 days')),
                        DropdownMenuItem(value: 3, child: Text('Every 3 days')),
                        DropdownMenuItem(value: 7, child: Text('Every week')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _intervalDays = value);
                        }
                      },
                    ),
                  if (_medicationKind == MedicationKind.oneTime)
                    TextFormField(
                      controller: _pillCountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Exact number of pills',
                      ),
                      validator: (value) {
                        if (_medicationKind != MedicationKind.oneTime) {
                          return null;
                        }
                        final parsed = int.tryParse((value ?? '').trim());
                        if (parsed == null || parsed < 1) {
                          return l10n.requiredField;
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < (_medicationKind == MedicationKind.daily ? _doseCount : 1); i++)
                    Builder(
                      builder: (context) {
                        final doseTime = i < _times.length ? _times[i] : _times.last;
                        return Row(
                          children: [
                            Text('Dose ${i + 1}: ${doseTime.format(context)}'),
                            const Spacer(),
                            TextButton(
                              onPressed: () => _pickDoseTime(i),
                              child: Text(l10n.pickTime),
                            ),
                          ],
                        );
                      },
                    ),
                  if (_medicationKind == MedicationKind.interval) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Interval alarms use the selected time and repeat every $_intervalDays days.',
                    ),
                  ],
                  if (_medicationKind == MedicationKind.oneTime) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'One-time medication tracks each pill with check marks.',
                    ),
                  ],
                  const SizedBox(height: 8),
                  ElevatedButton(
                    key: _saveButtonKey,
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
          Dismissible(
            key: ValueKey('plan-${plan.schedule.id}'),
            background: Container(
              color: Colors.red.shade400,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => _viewModel.dismissScheduleBySwipe(plan),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.medication),
                title: Text(plan.medication.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${plan.medication.dosage} • ${plan.schedule.hour.toString().padLeft(2, '0')}:${plan.schedule.minute.toString().padLeft(2, '0')} (${plan.schedule.timezoneName})',
                    ),
                    if (plan.medication.kind == MedicationKind.interval)
                      Text('Every ${plan.medication.intervalDays} days'),
                    if (plan.medication.kind == MedicationKind.oneTime)
                      Wrap(
                        spacing: 6,
                        children: List<Widget>.generate(plan.medication.totalPills, (
                          index,
                        ) {
                          final checked = index < plan.medication.takenPills;
                          return InkWell(
                            onTap: checked
                                ? null
                                : () => _viewModel.markOneTimePillTaken(
                                    plan.medication.id,
                                  ),
                            child: Icon(
                              checked
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              size: 20,
                              color: checked ? Colors.green : null,
                            ),
                          );
                        }),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editSchedule(plan),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOptionsTab(AppLocalizations l10n) {
    final selectedLocaleCode = widget.settingsViewModel.settings.localeCode;
    final selectedSound = widget.settingsViewModel.selectedSound;
    final soundItems = [
      if (!selectedSound.isAsset) selectedSound,
      ...widget.settingsViewModel.soundOptions,
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            title: Text(l10n.themeMode),
            subtitle: DropdownButton<ThemeMode>(
              value: widget.settingsViewModel.themeMode,
              isExpanded: true,
              onChanged: (value) {
                if (value != null) {
                  widget.settingsViewModel.setThemeMode(value);
                }
              },
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(l10n.themeSystem),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(l10n.themeLight),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(l10n.themeDark),
                ),
              ],
            ),
          ),
        ),
        Card(
          child: ListTile(
            title: Text(l10n.language),
            subtitle: DropdownButton<String?>(
              value: selectedLocaleCode,
              isExpanded: true,
              onChanged: (value) => widget.settingsViewModel.setLocaleCode(value),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.languageSystem),
                ),
                DropdownMenuItem<String?>(
                  value: 'en',
                  child: Text(l10n.languageEnglish),
                ),
                DropdownMenuItem<String?>(
                  value: 'ar',
                  child: Text(l10n.languageArabic),
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.alarmSound,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: selectedSound.id,
                  isExpanded: true,
                  onChanged: (value) {
                    if (value != null) {
                      widget.settingsViewModel.setSelectedAssetSound(value);
                    }
                  },
                  items: soundItems
                      .map(
                        (sound) => DropdownMenuItem<String>(
                          value: sound.id,
                          child: Text(sound.label),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),
                Text('${l10n.currentSound}: ${selectedSound.label}'),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _pickDeviceSound,
                  icon: const Icon(Icons.library_music),
                  label: Text(l10n.chooseSoundFromDevice),
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: Text(l10n.exportCsv),
                onTap: _exportCsv,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.download_for_offline_outlined),
                title: Text(l10n.importCsv),
                onTap: _importCsv,
              ),
            ],
          ),
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.delete_forever),
                title: Text(l10n.deleteAll),
                onTap: _confirmDeleteAll,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.aboutUs),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: l10n.appTitle,
                  applicationVersion: '1.0.0',
                  children: [Text(l10n.aboutUsBody)],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: Text(l10n.help),
                onTap: () => _showInfoDialog(l10n.help, l10n.helpBody),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.support_agent),
                title: Text(l10n.support),
                onTap: () => _showInfoDialog(l10n.support, l10n.supportBody),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showInfoDialog(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: Listenable.merge([_viewModel, widget.settingsViewModel]),
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.appTitle)),
        body: _tabIndex == 0 ? _buildSchedulesTab(l10n) : _buildOptionsTab(l10n),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _tabIndex,
          onTap: (index) => setState(() => _tabIndex = index),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: l10n.homeTab,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.tune, key: _optionsTabKey),
              activeIcon: const Icon(Icons.tune),
              label: l10n.optionsTab,
            ),
          ],
        ),
      ),
    );
  }
}
