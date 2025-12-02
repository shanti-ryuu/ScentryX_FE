import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/device.dart';
import '../../../widgets/glass_container.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback? onTap;
  final VoidCallback? onSettings;

  const DeviceCard({
    super.key,
    required this.device,
    this.onTap,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = device.isOnline
        ? AppTheme.successColor
        : Colors.blueGrey.shade400;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        opacity: 0.3,
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withOpacity(0.9),
                        statusColor.withOpacity(0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    device.isOnline ? Icons.sensors : Icons.sensors_off,
                    color: Colors.white,
                    size: 22,
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
                              device.deviceName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black.withOpacity(0.85),
                                  ),
                            ),
                          ),
                          if (onSettings != null)
                            IconButton(
                              icon: const Icon(Icons.more_vert),
                              onPressed: onSettings,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device.location.isNotEmpty
                            ? device.location
                            : 'Location unknown',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.black.withOpacity(0.6)),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildChip(
                            context,
                            label: device.isOnline ? 'Online' : 'Offline',
                            icon: device.isOnline
                                ? Icons.check_circle
                                : Icons.cloud_off,
                            color: statusColor,
                          ),
                          _buildChip(
                            context,
                            label: 'Threshold ${device.alertThreshold} ppm',
                            icon: Icons.speed,
                            color: AppTheme.warningColor,
                          ),
                          if (device.lastSeen != null)
                            _buildChip(
                              context,
                              label:
                                  'Last seen ${device.lastSeen!.toLocal().toString().split(".").first}',
                              icon: Icons.schedule,
                              color: Colors.tealAccent.shade700,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(
                  color: Colors.black.withOpacity(0.75),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
