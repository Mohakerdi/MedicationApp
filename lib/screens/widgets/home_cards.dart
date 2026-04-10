import 'package:flutter/material.dart';

import '../../models/entities.dart';

class ModernSectionCard extends StatelessWidget {
  const ModernSectionCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withOpacity(0.55),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class MedicationPlanCard extends StatelessWidget {
  const MedicationPlanCard({
    super.key,
    required this.plan,
    required this.onEdit,
    required this.onMarkOneTimePillTaken,
  });

  final MedicationPlan plan;
  final VoidCallback onEdit;
  final VoidCallback onMarkOneTimePillTaken;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final kind = plan.medication.kind;
    final timeText = TimeOfDay(
      hour: plan.schedule.hour,
      minute: plan.schedule.minute,
    ).format(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primaryContainer.withOpacity(0.45),
              scheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.primary.withOpacity(0.12),
                    foregroundColor: scheme.primary,
                    child: const Icon(Icons.medication_outlined),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.medication.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          plan.medication.dosage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(icon: Icons.schedule, label: timeText),
                  _InfoChip(icon: Icons.repeat, label: _kindLabel(kind, plan)),
                ],
              ),
              if (kind == MedicationKind.oneTime) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List<Widget>.generate(plan.medication.totalPills, (index) {
                    final checked = index < plan.medication.takenPills;
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: checked ? null : onMarkOneTimePillTaken,
                      child: Icon(
                        checked ? Icons.check_box : Icons.check_box_outline_blank,
                        size: 22,
                        color: checked ? Colors.green : null,
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _kindLabel(MedicationKind kind, MedicationPlan plan) {
    switch (kind) {
      case MedicationKind.daily:
        return 'Daily';
      case MedicationKind.interval:
        return 'Every ${plan.medication.intervalDays} days';
      case MedicationKind.oneTime:
        return 'One-time';
    }
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.surfaceContainerLow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
