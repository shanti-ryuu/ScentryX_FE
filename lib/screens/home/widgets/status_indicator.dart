import 'package:flutter/material.dart';

class StatusIndicator extends StatelessWidget {
  final String status;
  final bool showIcon;

  const StatusIndicator({
    super.key,
    required this.status,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.18),
            color.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
          ],
          Text(
            status.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'safe':
        return const Color(0xFF2E7D32);
      case 'warning':
        return const Color(0xFFFFB300);
      case 'danger':
        return const Color(0xFFE53935);
      case 'offline':
        return Colors.blueGrey;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'safe':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'danger':
        return Icons.error_outline;
      case 'offline':
        return Icons.cloud_off;
      default:
        return Icons.help_outline;
    }
  }
}
