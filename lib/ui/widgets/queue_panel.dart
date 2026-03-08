import 'package:flutter/material.dart';

/// Panel showing inbound/outbound queue counts and sample queues.
class QueuePanel extends StatelessWidget {
  final int inboundCount;
  final int outboundCount;
  final List<String> inboundFlights;
  final List<String> outboundFlights;

  const QueuePanel({
    super.key,
    required this.inboundCount,
    required this.outboundCount,
    required this.inboundFlights,
    required this.outboundFlights,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Queues',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QueueCountChip(
                    label: 'Inbound',
                    count: inboundCount,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QueueCountChip(
                    label: 'Outbound',
                    count: outboundCount,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Expanded(
                  child: _VerticalQueueLabel(text: 'Holding Pattern'),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _VerticalQueueLabel(text: 'Take-Off Queue'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Queued aircraft',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _QueueColumnHeader(
                        label: 'Inbound',
                        count: inboundCount,
                      ),
                      const SizedBox(height: 4),
                      _QueueListView(
                        flights: inboundFlights,
                        icon: Icons.flight_land,
                        emptyLabel: 'No inbound aircraft waiting',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _QueueColumnHeader(
                        label: 'Outbound',
                        count: outboundCount,
                      ),
                      const SizedBox(height: 4),
                      _QueueListView(
                        flights: outboundFlights,
                        icon: Icons.flight_takeoff,
                        emptyLabel: 'No outbound aircraft waiting',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueCountChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _QueueCountChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              letterSpacing: 0.8,
            ),
          ),
          Text(
            count.toString(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalQueueLabel extends StatelessWidget {
  final String text;

  const _VerticalQueueLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Align(
          alignment: Alignment.topCenter,
          child: Text(
            text,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _QueueColumnHeader extends StatelessWidget {
  final String label;
  final int count;

  const _QueueColumnHeader({
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          count.toString(),
          style: theme.textTheme.labelMedium,
        ),
      ],
    );
  }
}

class _QueueListView extends StatelessWidget {
  final List<String> flights;
  final IconData icon;
  final String emptyLabel;

  const _QueueListView({
    required this.flights,
    required this.icon,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (flights.isEmpty) {
      return Center(
        child: Text(
          emptyLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const rowHeight = 40.0;
        final neededHeight = flights.length * rowHeight;
        final canFit = neededHeight <= constraints.maxHeight;

        final tiles = flights.map((flight) {
          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              icon,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              flight,
              style: theme.textTheme.bodyMedium,
            ),
          );
        }).toList();

        if (canFit) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: tiles,
          );
        }

        return ListView(
          children: tiles,
        );
      },
    );
  }
}
