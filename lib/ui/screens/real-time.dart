import 'package:flutter/material.dart';
import '../models/runway_config_ui.dart';
import '../widgets/live_metrics_panel.dart';
import '../widgets/queue_panel.dart';
import '../widgets/speed_slider.dart';

class RealTimeScreenArguments {
  final List<RunwayConfigUI> runways;
  final String scenarioId;

  const RealTimeScreenArguments({
    required this.runways,
    required this.scenarioId,
  });
}

enum RunwayMode { landing, takeOff, mixed }

enum RunwayOperationalStatus {
  open,
  inspection,
  maintenance,
  closure,
  snowClearance,
}

extension RunwayModeLabel on RunwayMode {
  String get label {
    switch (this) {
      case RunwayMode.landing:
        return 'Landing';
      case RunwayMode.takeOff:
        return 'Take-Off';
      case RunwayMode.mixed:
        return 'Mixed';
    }
  }
}

extension RunwayStatusProperties on RunwayOperationalStatus {
  String get label {
    switch (this) {
      case RunwayOperationalStatus.open:
        return 'Open';
      case RunwayOperationalStatus.inspection:
        return 'Inspection';
      case RunwayOperationalStatus.maintenance:
        return 'Maintenance';
      case RunwayOperationalStatus.closure:
        return 'Closure';
      case RunwayOperationalStatus.snowClearance:
        return 'Snow clearance';
    }
  }

  Color get color {
    switch (this) {
      case RunwayOperationalStatus.open:
        return Colors.green;
      case RunwayOperationalStatus.inspection:
        return Colors.amber;
      case RunwayOperationalStatus.maintenance:
        return Colors.orange;
      case RunwayOperationalStatus.closure:
        return Colors.red;
      case RunwayOperationalStatus.snowClearance:
        return Colors.lightBlue;
    }
  }
}

class _RunwayState {
  _RunwayState({
    required this.id,
    required this.mode,
    required this.status,
    this.occupied = false,
  });

  final String id;
  RunwayMode mode;
  RunwayOperationalStatus status;
  bool occupied;
}

class RealTimeScreen extends StatefulWidget {
  final RealTimeScreenArguments? config;

  const RealTimeScreen({super.key, this.config});

  @override
  State<RealTimeScreen> createState() => _RealTimeScreenState();
}

class _RealTimeScreenState extends State<RealTimeScreen> {
  // Empty by default – should be filled from real configuration / backend.
  late final List<_RunwayState> _runways;

  // Empty queues – to be driven by real-time data.
  final List<String> _inboundQueue = [];
  final List<String> _outboundQueue = [];

  double _speedMultiplier = 1.0;
  bool _isPaused = false;

  // Derived from the actual queues (no hard-coded values).
  double get _averageQueueLength =>
      (_inboundQueue.length + _outboundQueue.length) / 2;

  // Initial metrics are zero; hook these up to real stats later.
  double get _averageDelayMinutes => 0;
  int get _diversions => 0;
  int get _cancellations => 0;
  double get _runwayUtilization => 0;

  @override
  void initState() {
    super.initState();
    _initialiseRunwaysFromConfig();
  }

  void _initialiseRunwaysFromConfig() {
    final args = widget.config;
    if (args == null || args.runways.isEmpty) {
      _runways = <_RunwayState>[];
      return;
    }

    _runways = List<_RunwayState>.generate(args.runways.length, (index) {
      final ui = args.runways[index];
      final idText = ui.runwayIdController.text.trim();
      final id = idText.isNotEmpty ? idText : 'RWY ${index + 1}';
      final mode = _modeFromString(ui.mode);
      return _RunwayState(
        id: id,
        mode: mode,
        status: RunwayOperationalStatus.open,
        occupied: false,
      );
    });
  }

  RunwayMode _modeFromString(String value) {
    switch (value) {
      case 'TakeOff':
      case 'Take-Off':
        return RunwayMode.takeOff;
      case 'Mixed':
        return RunwayMode.mixed;
      case 'Landing':
      default:
        return RunwayMode.landing;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-Time Simulation'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          if (isWide) {
            return _buildWideLayout();
          } else {
            return _buildNarrowLayout();
          }
        },
      ),
    );
  }

  Widget _buildWideLayout() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SpeedSlider(
                value: _speedMultiplier,
                onChanged: (value) {
                  setState(() {
                    _speedMultiplier = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  flex: 3,
                  child: QueuePanel(
                    inboundCount: _inboundQueue.length,
                    outboundCount: _outboundQueue.length,
                    inboundFlights: _inboundQueue,
                    outboundFlights: _outboundQueue,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  flex: 5,
                  child: _RunwaysPanel(
                    runways: _runways,
                    onRunwayTap: _onRunwayTap,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  flex: 3,
                  child: LiveMetricsPanel(
                    averageQueueLength: _averageQueueLength,
                    averageDelayMinutes: _averageDelayMinutes,
                    diversions: _diversions,
                    cancellations: _cancellations,
                    runwayUtilization: _runwayUtilization,
                    isPaused: _isPaused,
                    speedMultiplier: _speedMultiplier,
                    onTogglePause: _togglePause,
                    onBack: _handleBack,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SpeedSlider(
              value: _speedMultiplier,
              onChanged: (value) {
                setState(() {
                  _speedMultiplier = value;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        QueuePanel(
          inboundCount: _inboundQueue.length,
          outboundCount: _outboundQueue.length,
          inboundFlights: _inboundQueue,
          outboundFlights: _outboundQueue,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 360,
          child: _RunwaysPanel(
            runways: _runways,
            onRunwayTap: _onRunwayTap,
          ),
        ),
        const SizedBox(height: 16),
        LiveMetricsPanel(
          averageQueueLength: _averageQueueLength,
          averageDelayMinutes: _averageDelayMinutes,
          diversions: _diversions,
          cancellations: _cancellations,
          runwayUtilization: _runwayUtilization,
          isPaused: _isPaused,
          speedMultiplier: _speedMultiplier,
          onTogglePause: _togglePause,
          onBack: _handleBack,
        ),
      ],
    );
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _handleBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed('/');
    }
  }

  void _onRunwayTap(_RunwayState runway) {
    var tempMode = runway.mode;
    var tempStatus = runway.status;
    var tempOccupied = runway.occupied;

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit runway ${runway.id}'),
          content: StatefulBuilder(
            builder: (context, setInnerState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<RunwayMode>(
                      value: tempMode,
                      decoration: const InputDecoration(
                        labelText: 'Mode',
                        border: OutlineInputBorder(),
                      ),
                      items: RunwayMode.values
                          .map(
                            (mode) => DropdownMenuItem(
                              value: mode,
                              child: Text(mode.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setInnerState(() {
                          tempMode = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<RunwayOperationalStatus>(
                      value: tempStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: RunwayOperationalStatus.values
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setInnerState(() {
                          tempStatus = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Occupied'),
                      subtitle:
                          const Text('Mark runway as currently in use'),
                      value: tempOccupied,
                      onChanged: (value) {
                        setInnerState(() {
                          tempOccupied = value;
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  runway.mode = tempMode;
                  runway.status = tempStatus;
                  runway.occupied = tempOccupied;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _RunwaysPanel extends StatelessWidget {
  final List<_RunwayState> runways;
  final ValueChanged<_RunwayState> onRunwayTap;

  const _RunwaysPanel({
    required this.runways,
    required this.onRunwayTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Runways',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                  return GridView.builder(
                    itemCount: runways.length,
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 3 / 4,
                    ),
                    itemBuilder: (context, index) {
                      final runway = runways[index];
                      return _RunwayStatusCard(
                        runway: runway,
                        onTap: () => onRunwayTap(runway),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunwayStatusCard extends StatelessWidget {
  final _RunwayState runway;
  final VoidCallback onTap;

  const _RunwayStatusCard({
    required this.runway,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = runway.status.color;

    return Material(
      color: theme.colorScheme.surfaceVariant,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    runway.id,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    runway.occupied
                        ? Icons.flight
                        : Icons.flight_takeoff_outlined,
                    color: runway.occupied
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildChip(
                    context,
                    label: runway.mode.label,
                    icon: Icons.swap_calls,
                  ),
                  _buildChip(
                    context,
                    label: runway.status.label,
                    icon: Icons.info_outline,
                    backgroundColor: statusColor.withOpacity(0.15),
                    textColor: statusColor,
                  ),
                  _buildChip(
                    context,
                    label: runway.occupied ? 'Occupied' : 'Free',
                    icon: runway.occupied
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    backgroundColor: runway.occupied
                        ? theme.colorScheme.error.withOpacity(0.12)
                        : Colors.green.withOpacity(0.12),
                    textColor: runway.occupied
                        ? theme.colorScheme.error
                        : Colors.green.shade700,
                  ),
                ],
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'Tap to edit',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    Color? backgroundColor,
    Color? textColor,
  }) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: textColor ?? theme.colorScheme.onSurface,
        ),
      ),
      avatar: Icon(
        icon,
        size: 16,
        color: textColor ?? theme.colorScheme.primary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      backgroundColor:
          backgroundColor ?? theme.colorScheme.surface.withOpacity(0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
