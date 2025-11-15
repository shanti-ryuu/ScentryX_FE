import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/alert.dart';
import '../../providers/alert_provider.dart';
import '../../widgets/loading_indicator.dart';

class AlertDetailScreen extends StatefulWidget {
  final String alertId;

  const AlertDetailScreen({
    super.key,
    required this.alertId,
  });

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  Alert? _alert;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    final provider = context.read<AlertProvider>();
    await provider.fetchAlerts();
    final alert = provider.alerts.firstWhere(
      (a) => a.id == widget.alertId,
      orElse: () =>
          Alert(
            id: widget.alertId,
            deviceId: '',
            alertType: 'Unknown',
            gasLevelPpm: 0,
            message: 'Alert not found',
            isAcknowledged: false,
            timestamp: DateTime.now(),
          ),
    );
    if (mounted) {
      setState(() {
        _alert = alert;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertProvider>();
    final alert = _alert;

    if (alert == null && provider.isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator(fullscreen: true)),
      );
    }

    if (alert == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Alert Detail')),
        body: const Center(child: Text('Alert not found')),
      );
    }

    final color = alert.isDanger
        ? Colors.red
        : alert.isWarning
            ? Colors.orange
            : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert Detail'),
        actions: [
          if (!alert.isAcknowledged)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: () async {
                await provider.acknowledgeAlert(alert.id);
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  alert.isDanger
                      ? Icons.error_outline
                      : alert.isWarning
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline,
                  color: color,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  alert.alertType.toUpperCase(),
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              alert.message,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Device: ${alert.deviceName ?? alert.deviceId}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (alert.location != null) ...[
              const SizedBox(height: 4),
              Text(
                'Location: ${alert.location}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Gas level: ${alert.gasLevelPpm} PPM',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${alert.isAcknowledged ? 'Acknowledged' : 'Pending'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
