import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../models/alert.dart';
import '../../../widgets/glass_container.dart';

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
        ? AppTheme.dangerColor
        : alert.isWarning
            ? AppTheme.warningColor
            : AppTheme.safeColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        opacity: 0.28,
        tint: Colors.white,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.9), color.withOpacity(0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    alert.isDanger
                        ? Icons.error_outline
                        : alert.isWarning
                            ? Icons.warning_amber_rounded
                            : Icons.info_outline,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              alert.alertType.toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black.withOpacity(0.85),
                                  ),
                            ),
                          ),
                          _statusPill(color),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        alert.deviceName ?? alert.deviceId,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.black.withOpacity(0.85),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gas level: ${alert.gasLevelPpm} PPM',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.black.withOpacity(0.7)),
                      ),
                      if (alert.location != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          alert.location!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.black45),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            alert.isAcknowledged
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 16,
                            color: alert.isAcknowledged
                                ? AppTheme.safeColor
                                : AppTheme.dangerColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            alert.isAcknowledged
                                ? 'Acknowledged'
                                : 'Requires action',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.black.withOpacity(0.75)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!alert.isAcknowledged && onAcknowledge != null) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: onAcknowledge,
                    child: const Text('Acknowledge'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusPill(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        alert.isDanger
            ? 'Danger'
            : alert.isWarning
                ? 'Warning'
                : 'Safe',
        style: TextStyle(
          color: Colors.black.withOpacity(0.7),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
