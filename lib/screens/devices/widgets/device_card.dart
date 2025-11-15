import 'package:flutter/material.dart';
import '../../../models/device.dart';

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
    final statusColor = device.isOnline ? Colors.green : Colors.grey;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell
(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
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
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (onSettings != null)
                          IconButton(
                            icon: const Icon(
                              Icons.more_vert,
                              size: 20,
                            ),
                            onPressed: onSettings,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.location,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.isOnline
                          ? '${device.status} • Online'
                          : 'Offline',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      device.lastSeen != null
                          ? 'Last seen: ${device.lastSeen}'
                          : 'Last seen: N/A',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
