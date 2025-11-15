import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../models/device.dart';
import '../../models/reading.dart';
import '../../providers/alert_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/reading_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/gas_chart.dart';
import '../../widgets/loading_indicator.dart';
import 'widgets/gas_level_gauge.dart';
import 'widgets/quick_stats_card.dart';
import 'widgets/status_indicator.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
    final alertProvider = context.read<AlertProvider>();

    await deviceProvider.fetchDevices();
    final device = deviceProvider.selectedDevice;

    if (device != null) {
      await _loadDeviceData(device);
      readingProvider.subscribeToLiveReadings(device.id);
      await alertProvider.fetchUnreadCount();
    }

    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  Future<void> _loadDeviceData(Device device) async {
    final readingProvider = context.read<ReadingProvider>();
    final alertProvider = context.read<AlertProvider>();

    await Future.wait([
      readingProvider.fetchLatestReading(device.id),
      readingProvider.fetchReadings(device.id, page: 1),
      readingProvider.fetchStatistics(device.id, hours: 24),
      alertProvider.fetchAlerts(deviceId: device.id, page: 1),
    ]);
  }

  Future<void> _onRefresh() async {
    final deviceProvider = context.read<DeviceProvider>();
    await deviceProvider.fetchDevices();
    final device = deviceProvider.selectedDevice;
    if (device != null) {
      await _loadDeviceData(device);
    }
  }

  Future<void> _onDeviceChanged(Device? device) async {
    if (device == null) return;
    final deviceProvider = context.read<DeviceProvider>();
    final readingProvider = context.read<ReadingProvider>();

    deviceProvider.selectDevice(device);
    readingProvider.unsubscribeFromLiveReadings();
    await _loadDeviceData(device);
    readingProvider.subscribeToLiveReadings(device.id);
  }

  @override
  void dispose() {
    context.read<ReadingProvider>().unsubscribeFromLiveReadings();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final readingProvider = context.watch<ReadingProvider>();
    final alertProvider = context.watch<AlertProvider>();

    final devices = deviceProvider.devices;
    final selectedDevice = deviceProvider.selectedDevice;
    final latestReading = readingProvider.latestReading;

    if (!_initialized || (deviceProvider.isLoading && devices.isEmpty)) {
      return const Scaffold(
        body: Center(child: LoadingIndicator(fullscreen: true)),
      );
    }

    if (deviceProvider.error != null && devices.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('ScentryX')),
        body: ErrorView(
          message: deviceProvider.error!,
          onRetry: _onRefresh,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ScentryX'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.alertList);
                },
              ),
              if (alertProvider.unreadCount > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      alertProvider.unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.settings);
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.of(context).pushNamed(AppRoutes.deviceList);
              break;
            case 2:
              Navigator.of(context).pushNamed(AppRoutes.alertList);
              break;
            case 3:
              Navigator.of(context).pushNamed(AppRoutes.profile);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sensors),
            label: 'Devices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Device',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  DropdownButton<Device>(
                    value: selectedDevice,
                    hint: const Text('Select device'),
                    items: devices
                        .map(
                          (d) => DropdownMenuItem<Device>(
                            value: d,
                            child: Text(d.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: (device) {
                      _onDeviceChanged(device);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (selectedDevice == null)
                const EmptyState(
                  title: 'No devices',
                  message: 'Add a device to start monitoring gas levels.',
                  actionLabel: 'Add Device',
                )
              else
                _buildDashboardContent(
                  context,
                  selectedDevice,
                  latestReading,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    Device device,
    Reading? latestReading,
  ) {
    final reading = latestReading;
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
        Row(
          children: [
            Expanded(
              child: QuickStatsCard(
                title: 'PPM',
                value: ppm.toString(),
                subtitle: 'Current gas level',
                icon: Icons.speed,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: QuickStatsCard(
                title: 'Status',
                value: status.toUpperCase(),
                subtitle: device.isOnline ? 'Device online' : 'Device offline',
                icon: Icons.info_outline,
                color: status == 'danger'
                    ? Colors.red
                    : status == 'warning'
                        ? Colors.orange
                        : Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: QuickStatsCard(
                title: 'Device',
                value: device.statusLabel,
                subtitle: device.location,
                icon: device.isOnline
                    ? Icons.check_circle
                    : Icons.cloud_off,
                color: device.isOnline ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Gas Level (last 24h)',
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
            return GasChart(
              readings: provider.readings,
            );
          },
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Alerts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.alertList);
              },
              child: const Text('View All'),
            ),
          ],
        ),
        Consumer<AlertProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.alerts.isEmpty) {
              return const LoadingIndicator();
            }
            if (provider.error != null && provider.alerts.isEmpty) {
              return ErrorView(
                message: provider.error!,
                onRetry: () => provider.fetchAlerts(deviceId: device.id),
              );
            }
            if (provider.alerts.isEmpty) {
              return const EmptyState(
                title: 'No alerts',
                message: 'Any gas alerts will show up here.',
              );
            }
            final alerts = provider.alerts.take(3).toList();
            return Column(
              children: alerts
                  .map(
                    (a) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        a.isDanger
                            ? Icons.error_outline
                            : a.isWarning
                                ? Icons.warning_amber_rounded
                                : Icons.info_outline,
                        color: a.isDanger
                            ? Colors.red
                            : a.isWarning
                                ? Colors.orange
                                : Colors.green,
                      ),
                      title: Text(a.alertType.toUpperCase()),
                      subtitle: Text(
                        '${a.deviceName ?? device.deviceName} • ${a.gasLevelPpm} PPM',
                      ),
                      trailing: a.isAcknowledged
                          ? const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            )
                          : const Icon(
                              Icons.circle,
                              size: 10,
                              color: Colors.red,
                            ),
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.alertDetail,
                          arguments: a.id,
                        );
                      },
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
