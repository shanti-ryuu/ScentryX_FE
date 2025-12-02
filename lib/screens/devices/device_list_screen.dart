import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/device_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_indicator.dart';
import 'widgets/device_card.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceProvider>().fetchDevices();
    });
  }

  Future<void> _refresh() async {
    await context.read<DeviceProvider>().fetchDevices();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeviceProvider>();
    final devices = provider.devices;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('My Devices'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.addDevice);
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryBackground,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: Builder(
              builder: (context) {
                if (provider.isLoading && devices.isEmpty) {
                  return const LoadingIndicator(fullscreen: true);
                }

                if (provider.error != null && devices.isEmpty) {
                  return ErrorView(
                    message: provider.error!,
                    onRetry: _refresh,
                  );
                }

                if (devices.isEmpty) {
                  return const EmptyState(
                    title: 'No devices',
                    message:
                        'You have no registered devices yet. Add one to get started.',
                  );
                }

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return DeviceCard(
                      device: device,
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.deviceDetail,
                          arguments: device.id,
                        );
                      },
                      onSettings: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.deviceSettings,
                          arguments: device.id,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
