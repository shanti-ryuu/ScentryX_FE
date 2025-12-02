import 'package:flutter/material.dart';

class GasLevelGauge extends StatelessWidget {
  final int ppm;
  final String status;
  final double size;

  const GasLevelGauge({
    super.key,
    required this.ppm,
    required this.status,
    this.size = 200,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'danger':
        return const Color(0xFFE53935);
      case 'warning':
        return const Color(0xFFFFB300);
      case 'safe':
        return const Color(0xFF2E7D32);
      default:
        return Colors.blueGrey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'danger':
        return 'Danger';
      case 'warning':
        return 'Warning';
      case 'safe':
        return 'Safe';
      case 'offline':
        return 'Offline';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      color.withOpacity(0.15),
                      color,
                      color.withOpacity(0.15),
                    ],
                  ),
                ),
              ),
              Container(
                width: size - 40,
                height: size - 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$ppm',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PPM',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.blueGrey,
                            letterSpacing: 1.5,
                          ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Text(
                    _getStatusLabel(status),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _InfoChip(
                label: 'Status',
                value: _getStatusLabel(status),
                color: color,
              ),
              _InfoChip(
                label: 'Trend',
                value: ppm >= 0 ? 'Live' : 'N/A',
                color: Colors.blueGrey,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.blueGrey,
                letterSpacing: 0.6,
              ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
