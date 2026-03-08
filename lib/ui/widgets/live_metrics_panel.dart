import 'package:flutter/material.dart';

/// Panel displaying live metrics and basic controls.
class LiveMetricsPanel extends StatelessWidget {
  final double? averageQueueLength;
  final double? averageDelayMinutes;
  final int? diversions;
  final int? cancellations;
  final double? runwayUtilization;
  final bool isPaused;
  final double speedMultiplier;
  final VoidCallback onTogglePause;
  final VoidCallback onBack;

  const LiveMetricsPanel({
    super.key,
    this.averageQueueLength,
    this.averageDelayMinutes,
    this.diversions,
    this.cancellations,
    this.runwayUtilization,
    required this.isPaused,
    required this.speedMultiplier,
    required this.onTogglePause,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusText = isPaused
        ? 'Paused'
        : 'Running at ${speedMultiplier.toStringAsFixed(1)}x';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Live Metrics & Controls',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onTogglePause,
                    icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                    label: Text(isPaused ? 'Resume' : 'Pause'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _MetricRow(
              icon: Icons.format_list_numbered,
              label: 'Average queue length',
              value: averageQueueLength != null
                  ? averageQueueLength!.toStringAsFixed(1)
                  : '—',
            ),
            const SizedBox(height: 8),
            _MetricRow(
              icon: Icons.schedule,
              label: 'Average delay',
              value: averageDelayMinutes != null
                  ? '${averageDelayMinutes!.toStringAsFixed(1)} min'
                  : '—',
            ),
            const SizedBox(height: 8),
            _MetricRow(
              icon: Icons.flight,
              label: 'Diversions',
              value: diversions?.toString() ?? '—',
            ),
            const SizedBox(height: 8),
            _MetricRow(
              icon: Icons.cancel_outlined,
              label: 'Cancellations',
              value: cancellations?.toString() ?? '—',
            ),
            const SizedBox(height: 8),
            _MetricRow(
              icon: Icons.local_airport,
              label: 'Runway utilization',
              value: runwayUtilization != null
                  ? '${(runwayUtilization! * 100).toStringAsFixed(0)}%'
                  : '—',
            ),
            const Spacer(),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Simulation status',
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Text(
              statusText,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
