import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/entities.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({
    super.key,
    required this.alarm,
    required this.onTakeNow,
    required this.onSnooze,
    required this.onSkip,
  });

  final AlarmWithMedication alarm;
  final Future<void> Function() onTakeNow;
  final Future<void> Function() onSnooze;
  final Future<void> Function() onSkip;

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  Timer? _beepTimer;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _beepTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      SystemSound.play(SystemSoundType.alert);
    });
  }

  @override
  void dispose() {
    _beepTimer?.cancel();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final medication = widget.alarm.medication;

    return PopScope(
      canPop: false,
      child: Scaffold(
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
                const Text(
                  'Medication Alarm',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
                  onPressed: _busy ? null : () => _run(widget.onTakeNow),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 72),
                    backgroundColor: Colors.green.shade600,
                  ),
                  child: const Text('TAKE NOW', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _busy ? null : () => _run(widget.onSnooze),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 72),
                    backgroundColor: Colors.orange.shade700,
                  ),
                  child: const Text('SNOOZE 10 MIN', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _busy ? null : () => _run(widget.onSkip),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 72),
                    side: const BorderSide(color: Colors.white70, width: 2),
                  ),
                  child: const Text(
                    'SKIP',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
