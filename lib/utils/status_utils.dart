import 'dart:math';

String deriveStatusFromThreshold({
  required int ppm,
  required int alertThreshold,
  bool deviceOnline = true,
  double warningRatio = 0.8,
}) {
  if (!deviceOnline) {
    return 'offline';
  }

  final sanitizedThreshold = max(alertThreshold, 1);
  final clampedRatio = warningRatio.clamp(0.0, 1.0);
  final warningThreshold = max(1, (sanitizedThreshold * clampedRatio).round());

  if (ppm >= sanitizedThreshold) {
    return 'danger';
  }
  if (ppm >= warningThreshold) {
    return 'warning';
  }
  return 'safe';
}
