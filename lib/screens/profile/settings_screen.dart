import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/loading_indicator.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  bool _loading = true;

  static const String _notifKey = 'notifications_enabled';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPreferences();
    });
  }

  Future<void> _loadPreferences() async {
    final storage = await StorageService.getInstance();
    final themeMode = storage.getThemeMode();
    final prefs = await SharedPreferences.getInstance();
    final notif = prefs.getBool(_notifKey) ?? true;

    if (!mounted) return;

    setState(() {
      _darkMode = themeMode == ThemeMode.dark;
      _notificationsEnabled = notif;
      _loading = false;
    });
  }

  Future<void> _toggleTheme(bool value) async {
    final storage = await StorageService.getInstance();
    setState(() {
      _darkMode = value;
    });
    await storage.saveThemeMode(
      _darkMode ? ThemeMode.dark : ThemeMode.light,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Theme preference saved. It will apply on next launch.'),
      ),
    );
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifKey, value);
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _loading
          ? const Center(child: LoadingIndicator(fullscreen: true))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Appearance',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Use dark theme throughout the app'),
                  value: _darkMode,
                  onChanged: _toggleTheme,
                ),
                const SizedBox(height: 24),
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Gas Alerts'),
                  subtitle:
                      const Text('Receive push notifications for gas alerts'),
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                ),
                const SizedBox(height: 24),
                Text(
                  'About',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('App Information'),
                  subtitle: Text('ScentryX • Version 1.0.0'),
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Logged in as'),
                  subtitle: Text(auth.user?.email ?? ''),
                ),
              ],
            ),
    );
  }
}
