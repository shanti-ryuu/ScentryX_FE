import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/alert_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_indicator.dart';
import 'widgets/alert_card.dart';

class AlertListScreen extends StatefulWidget {
  const AlertListScreen({super.key});

  @override
  State<AlertListScreen> createState() => _AlertListScreenState();
}

class _AlertListScreenState extends State<AlertListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    final provider = context.read<AlertProvider>();
    await provider.fetchAlerts();
    if (!mounted) return;
    await provider.fetchUnreadCount();
  }

  Future<void> _refresh() async {
    await _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Danger'),
            Tab(text: 'Warning'),
            Tab(text: 'Today'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTab(context, provider, null),
            _buildTab(context, provider, 'danger'),
            _buildTab(context, provider, 'warning'),
            _buildTab(context, provider, 'today'),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    AlertProvider provider,
    String? filter,
  ) {
    final alerts = provider.alerts.where((a) {
      if (filter == null) return true;
      if (filter == 'danger') return a.isDanger;
      if (filter == 'warning') return a.isWarning;
      if (filter == 'today') {
        final now = DateTime.now();
        return a.timestamp.year == now.year &&
            a.timestamp.month == now.month &&
            a.timestamp.day == now.day;
      }
      return true;
    }).toList();

    if (provider.isLoading && alerts.isEmpty) {
      return const LoadingIndicator(fullscreen: true);
    }

    if (provider.error != null && alerts.isEmpty) {
      return ErrorView(
        message: provider.error!,
        onRetry: _refresh,
      );
    }

    if (alerts.isEmpty) {
      return const EmptyState(
        title: 'No alerts',
        message: 'No alerts found for this filter.',
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return AlertCard(
          alert: alert,
          onTap: () {
            Navigator.of(context).pushNamed(
              '/alert-detail',
              arguments: alert.id,
            );
          },
          onAcknowledge: alert.isAcknowledged
              ? null
              : () async {
                  await provider.acknowledgeAlert(alert.id);
                },
        );
      },
    );
  }
}
