import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/device.dart';
import '../../models/reading.dart';
import '../../providers/alert_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/reading_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_widget.dart' as error_widget;
import '../../utils/status_utils.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/glass_container.dart';
import 'widgets/gas_level_gauge.dart';
import 'widgets/quick_stats_card.dart';
import 'widgets/status_indicator.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _initialized = false;
  StreamSubscription<Map<String, dynamic>?>? _deviceStatusSubscription;
  final FirebaseService _firebaseService = FirebaseService();
  ReadingProvider? _readingProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initialize();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _readingProvider ??= context.read<ReadingProvider>();
  }

  Future<void> _initialize() async {
    try {
      final deviceProvider = context.read<DeviceProvider>();
      final readingProvider = context.read<ReadingProvider>();
      final alertProvider = context.read<AlertProvider>();

      await deviceProvider.fetchDevices();
      final device = deviceProvider.selectedDevice;

      if (device != null) {
        print('[Dashboard] Initializing with device: ${device.id} (${device.deviceName})');
        readingProvider.configureAlertContext(
          threshold: device.alertThreshold,
          deviceName: device.deviceName,
        );
        await _loadDeviceData(device);
        
        // Use device.deviceId for Firebase instead of device.id
        final firebaseDeviceId = device.deviceId; // This should be 'kitchen-sensor-001'
        print('[Dashboard] Using Firebase device ID: $firebaseDeviceId');
        _subscribeToDeviceStatus(firebaseDeviceId);
        readingProvider.subscribeToLiveReadings(firebaseDeviceId);
        await alertProvider.fetchUnreadCount();
      }
    } catch (e) {
      print('[Dashboard] Error initializing: $e');
    } finally {
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    }
  }

  void _subscribeToDeviceStatus(String deviceId) {
    _deviceStatusSubscription?.cancel();
    _deviceStatusSubscription = _firebaseService
        .subscribeToDeviceStatus(deviceId)
        .listen((status) {
      if (status != null) {
        print('[Dashboard] Device status update: $status');
        // Handle device status updates here if needed
      }
    }, onError: (error) {
      print('[Dashboard] Error in device status stream: $error');
    });
  }

  Future<void> _loadDeviceData(Device device) async {
    final readingProvider = context.read<ReadingProvider>();
    final alertProvider = context.read<AlertProvider>();

    await Future.wait([
      readingProvider.fetchLatestReading(device.id),
      readingProvider.fetchReadings(device.id),
      readingProvider.fetchStatistics(device.id),
      alertProvider.fetchAlerts(page: 1),
    ].map((future) => future.catchError((_) {})));
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
    
    try {
      final deviceProvider = context.read<DeviceProvider>();
      final readingProvider = context.read<ReadingProvider>();

      deviceProvider.selectDevice(device);
      readingProvider.unsubscribeFromLiveReadings();
      readingProvider.configureAlertContext(
        threshold: device.alertThreshold,
        deviceName: device.deviceName,
      );
      await _loadDeviceData(device);
      
      // Use device.deviceId for Firebase instead of device.id
      final firebaseDeviceId = device.deviceId; // This should be 'kitchen-sensor-001'
      print('[Dashboard] Device changed, subscribing to: $firebaseDeviceId');
      readingProvider.subscribeToLiveReadings(firebaseDeviceId);
    } catch (e) {
      print('[Dashboard] Error changing device: $e');
    }
  }

  @override
  void dispose() {
    _deviceStatusSubscription?.cancel();
    _readingProvider?.unsubscribeFromLiveReadings();
    super.dispose();
  }

  Widget _buildGasChart(List<Reading> readings) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: readings.length.toDouble() - 1,
          minY: 0,
          maxY: readings.map((r) => r.gasLevelPpm.toDouble()).reduce((a, b) => a > b ? a : b) * 1.1,
          lineBarsData: [
            LineChartBarData(
              spots: readings.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), e.value.gasLevelPpm.toDouble());
              }).toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
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
        body: error_widget.ErrorView(
          message: deviceProvider.error!,
          onRetry: _onRefresh,
        ),
      );
    }
    
    if (selectedDevice == null) {
      return const Scaffold(
        body: Center(
          child: Text('No device selected'),
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
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryBackground),
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 360;
                      final dropdown = DropdownButton<Device>(
                        isExpanded: true,
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
                      );

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Device',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            dropdown,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Device',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: dropdown),
                        ],
                      );
                    },
                  ),
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
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    Device device,
    Reading? latestReading,
  ) {
    final reading = latestReading;
    final ppm = reading?.gasLevelPpm ?? 0;
    final status = deriveStatusFromThreshold(
      ppm: ppm,
      alertThreshold: device.alertThreshold,
      deviceOnline: device.isOnline,
    );

    Color _statusColor(String s) {
      switch (s) {
        case 'danger':
          return AppTheme.dangerColor;
        case 'warning':
          return AppTheme.warningColor;
        default:
          return AppTheme.safeColor;
      }
    }

    Widget buildSection(Widget child) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: GlassContainer(child: child),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSection(
          Column(
            children: [
              GasLevelGauge(
                ppm: ppm,
                status: status,
                size: 200,
              ),
              const SizedBox(height: 16),
              StatusIndicator(status: status),
              const SizedBox(height: 8),
              Text(
                device.isOnline ? 'Updated just now' : 'Device offline',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ),
        buildSection(
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 520;
              final cardWidth = isCompact
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 16) / 3;

              Widget buildCard(Widget child) {
                return SizedBox(
                  width: isCompact ? double.infinity : cardWidth,
                  child: child,
                );
              }

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  buildCard(
                    QuickStatsCard(
                      title: 'PPM',
                      value: ppm.toString(),
                      subtitle: 'Current gas level',
                      icon: Icons.speed,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  buildCard(
                    QuickStatsCard(
                      title: 'Status',
                      value: status.toUpperCase(),
                      subtitle:
                          device.isOnline ? 'Device online' : 'Device offline',
                      icon: Icons.info_outline,
                      color: _statusColor(status),
                    ),
                  ),
                  buildCard(
                    QuickStatsCard(
                      title: 'Device',
                      value: device.statusLabel,
                      subtitle: device.location,
                      icon:
                          device.isOnline ? Icons.check_circle : Icons.cloud_off,
                      color: device.isOnline
                          ? AppTheme.successColor
                          : Colors.blueGrey,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        buildSection(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gas Level (last 24h)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Consumer<ReadingProvider>(
                builder: (context, readingProvider, _) {
                  if (readingProvider.isLoading &&
                      readingProvider.readings.isEmpty) {
                    return readingProvider.error != null
                        ? error_widget.ErrorView(
                            message: readingProvider.error!,
                            onRetry: () {
                              final selected =
                                  context.read<DeviceProvider>().selectedDevice;
                              if (selected != null) {
                                _onDeviceChanged(selected);
                              }
                            },
                          )
                        : const LoadingIndicator();
                  }

                  if (readingProvider.error != null &&
                      readingProvider.readings.isEmpty) {
                    return error_widget.ErrorView(
                      message: readingProvider.error!,
                      onRetry: () {
                        final selected =
                            context.read<DeviceProvider>().selectedDevice;
                        if (selected != null) {
                          _onDeviceChanged(selected);
                        }
                      },
                    );
                  }

                  if (readingProvider.readings.isEmpty) {
                    return const EmptyState(
                      title: 'No readings yet',
                      message: 'Historical gas readings will appear here.',
                    );
                  }

                  return _buildGasChart(readingProvider.readings);
                },
              ),
            ],
          ),
        ),
        buildSection(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    return error_widget.ErrorView(
                      message: provider.error!,
                      onRetry: () => provider.fetchAlerts(page: 1),
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
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 4),
                            leading: Icon(
                              a.isDanger
                                  ? Icons.error_outline
                                  : a.isWarning
                                      ? Icons.warning_amber_rounded
                                      : Icons.info_outline,
                              color: a.isDanger
                                  ? AppTheme.dangerColor
                                  : a.isWarning
                                      ? AppTheme.warningColor
                                      : AppTheme.safeColor,
                            ),
                            title: Text(a.alertType.toUpperCase()),
                            subtitle: Text(
                              '${a.deviceName ?? device.deviceName} • ${a.gasLevelPpm} PPM',
                            ),
                            trailing: a.isAcknowledged
                                ? const Icon(
                                    Icons.check_circle,
                                    color: AppTheme.safeColor,
                                  )
                                : const Icon(
                                    Icons.circle,
                                    size: 10,
                                    color: AppTheme.dangerColor,
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
            ],
          ),
        ),
      ],
    );
  }
}
