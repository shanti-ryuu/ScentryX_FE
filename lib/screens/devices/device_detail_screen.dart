import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/device.dart';
import '../../models/reading.dart';
import '../../providers/device_provider.dart';
import '../../providers/reading_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/gas_chart.dart';
import '../../widgets/loading_indicator.dart';
import '../home/widgets/gas_level_gauge.dart';
import '../home/widgets/quick_stats_card.dart';
import '../home/widgets/status_indicator.dart';
import '../../config/routes.dart';

class DeviceDetailScreen extends StatefulWidget {
  final String deviceId;

  const DeviceDetailScreen({
    super.key,
    required this.deviceId,
  });

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  Device? _device;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    final deviceProvider = context.read<DeviceProvider>();
    final readingProvider = context.read<ReadingProvider>();

    await deviceProvider.fetchDevices();
    final device = deviceProvider.getDeviceById(widget.deviceId);

    if (device != null) {
      _device = device;
      await readingProvider.fetchLatestReading(device.id);
      await readingProvider.fetchReadings(device.id, page: 1);
      await readingProvider.fetchStatistics(device.id, hours: 24);
      readingProvider.subscribeToLiveReadings(device.id);
    }

    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  Future<void> _refresh() async {
    await _initialize();
  }

  @override
  void dispose() {
    context.read<ReadingProvider>().unsubscribeFromLiveReadings();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readingProvider = context.watch<ReadingProvider>();

    if (!_initialized) {
      return const Scaffold(
        body: Center(child: LoadingIndicator(fullscreen: true)),
      );
    }

    final device = _device;
    if (device == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Device Detail')),
        body: const EmptyState(
          title: 'Device not found',
          message: 'The selected device could not be loaded.',
        ),
      );
    }

    final latestReading = readingProvider.latestReading;

    return Scaffold(
      appBar: AppBar(
        title: Text(device.deviceName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed(
                AppRoutes.deviceSettings,
                arguments: device.id,
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: _buildContent(context, device, latestReading),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Device device,
    Reading? reading,
  ) {
    final status = reading?.status ?? (device.isOnline ? 'safe' : 'offline');
    final ppm = reading?.gasLevelPpm ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: GasLevelGauge(
            ppm: ppm,
            status: status,
            size: 200,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StatusIndicator(status: status),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            device.isOnline ? 'Updated just now' : 'Device offline',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey[600]),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Device Info',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${device.deviceName}'),
                const SizedBox(height: 4),
                Text('Location: ${device.location}'),
                const SizedBox(height: 4),
                Text('Device ID: ${device.deviceId}'),
                const SizedBox(height: 4),
                Text('Type: ${device.deviceType}'),
                const SizedBox(height: 4),
                Text('Status: ${device.statusLabel}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: QuickStatsCard(
                title: 'PPM',
                value: ppm.toString(),
                subtitle: 'Current gas level',
                icon: Icons.speed,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: QuickStatsCard(
                title: 'Threshold',
                value: '${device.alertThreshold} PPM',
                subtitle: 'Alert threshold',
                icon: Icons.auto_graph,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Gas Level History',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Consumer<ReadingProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.readings.isEmpty) {
              return const LoadingIndicator();
            }
            if (provider.error != null && provider.readings.isEmpty) {
              return ErrorView(
                message: provider.error!,
                onRetry: () => provider.fetchReadings(device.id, page: 1),
              );
            }
            if (provider.readings.isEmpty) {
              return const EmptyState(
                title: 'No readings yet',
                message: 'Historical gas readings will appear here.',
              );
            }
            return GasChart(readings: provider.readings);
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
