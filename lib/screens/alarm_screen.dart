import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medecation_app/l10n/app_localizations.dart';

import '../models/app_settings.dart';
import '../models/entities.dart';
import '../services/alarm_sound_service.dart';
import '../viewmodels/alarm_view_model.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({
    super.key,
    required this.alarm,
    required this.onTakeNow,
    required this.onSnooze,
    required this.onSkip,
    required this.alarmSound,
  });

  final AlarmWithMedication alarm;
  final Future<void> Function() onTakeNow;
  final Future<void> Function() onSnooze;
  final Future<void> Function() onSkip;
  final AppAlarmSound alarmSound;

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  Timer? _fallbackBeepTimer;
  final AlarmSoundService _soundService = AlarmSoundService();
  final AlarmViewModel _viewModel = AlarmViewModel();

  @override
  void initState() {
    super.initState();
    _soundService.playLoop(widget.alarmSound).catchError((_) {
      _fallbackBeepTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        SystemSound.play(SystemSoundType.alert);
      });
    });
  }

  @override
  void dispose() {
    _fallbackBeepTimer?.cancel();
    _soundService.stop();
    _soundService.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    await _viewModel.run(action);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final medication = widget.alarm.medication;

    return PopScope(
      canPop: false,
      child: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) => Scaffold(
          backgroundColor: Colors.red.shade900,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  const Icon(Icons.alarm, size: 72, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    l10n.alarmScreenTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    medication.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    medication.dosage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _viewModel.busy ? null : () => _run(widget.onTakeNow),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 72),
                      backgroundColor: Colors.green.shade600,
                    ),
                    child: Text(l10n.takeNow, style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _viewModel.busy ? null : () => _run(widget.onSnooze),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 72),
                      backgroundColor: Colors.orange.shade700,
                    ),
                    child: Text(l10n.snoozeTen, style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _viewModel.busy ? null : () => _run(widget.onSkip),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 72),
                      side: const BorderSide(color: Colors.white70, width: 2),
                    ),
                    child: Text(
                      l10n.skip,
                      style: const TextStyle(fontSize: 24, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
