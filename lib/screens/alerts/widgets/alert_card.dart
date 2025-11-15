import 'package:flutter/material.dart';

import '../../../models/alert.dart';

class AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback? onTap;
  final VoidCallback? onAcknowledge;

  const AlertCard({
    super.key,
    required this.alert,
    this.onTap,
    this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final color = alert.isDanger
        ? Colors.red
        : alert.isWarning
            ? Colors.orange
            : Colors.green;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                alert.isDanger
                    ? Icons.error_outline
                    : alert.isWarning
                        ? Icons.warning_amber_rounded
                        : Icons.info_outline,
                color: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.alertType.toUpperCase(),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.deviceName ?? alert.deviceId,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Gas level: ${alert.gasLevelPpm} PPM',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[700]),
                    ),
                    if (alert.location != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        alert.location!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      alert.isAcknowledged
                          ? 'Acknowledged'
                          : 'Not acknowledged',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: alert.isAcknowledged
                                ? Colors.green
                                : Colors.red,
                          ),
                    ),
                  ],
                ),
              ),
              if (!alert.isAcknowledged && onAcknowledge != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onAcknowledge,
                  child: const Text('Acknowledge'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
