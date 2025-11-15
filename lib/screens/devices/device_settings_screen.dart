import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/device.dart';
import '../../providers/device_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_indicator.dart';

class DeviceSettingsScreen extends StatefulWidget {
  final String deviceId;

  const DeviceSettingsScreen({
    super.key,
    required this.deviceId,
  });

  @override
  State<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  double _threshold = 500;
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
    final provider = context.read<DeviceProvider>();
    await provider.fetchDevices();
    final device = provider.getDeviceById(widget.deviceId);
    if (device != null) {
      _device = device;
      _nameController.text = device.deviceName;
      _locationController.text = device.location;
      _threshold = device.alertThreshold.toDouble();
    }
    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Device name is required';
    }
    return null;
  }

  Future<void> _save() async {
    final provider = context.read<DeviceProvider>();
    final device = _device;
    if (device == null) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final data = <String, dynamic>{
      'deviceName': _nameController.text.trim(),
      'location': _locationController.text.trim(),
      'alertThreshold': _threshold.toInt(),
    };

    await provider.updateDevice(device.id, data);
    if (!mounted) return;

    if (provider.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device updated')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!)),
      );
    }
  }

  Future<void> _delete() async {
    final provider = context.read<DeviceProvider>();
    final device = _device;
    if (device == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Device'),
          content: const Text(
            'Are you sure you want to delete this device? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await provider.deleteDevice(device.id);
    if (!mounted) return;

    if (provider.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device deleted')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeviceProvider>();

    if (!_initialized || (provider.isLoading && _device == null)) {
      return const Scaffold(
        body: Center(child: LoadingIndicator(fullscreen: true)),
      );
    }

    final device = _device;
    if (device == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Device Settings')),
        body: const Center(child: Text('Device not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  device.deviceName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  device.deviceId,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  controller: _nameController,
                  label: 'Device Name',
                  hintText: 'Kitchen Sensor',
                  validator: _validateName,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _locationController,
                  label: 'Location',
                  hintText: 'Main Kitchen',
                ),
                const SizedBox(height: 24),
                Text(
                  'Alert Threshold: ${_threshold.toInt()} PPM',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Slider(
                  value: _threshold,
                  min: 100,
                  max: 1000,
                  divisions: 18,
                  label: _threshold.toInt().toString(),
                  onChanged: (value) {
                    setState(() {
                      _threshold = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                if (provider.isLoading)
                  const LoadingIndicator()
                else
                  PrimaryButton(
                    label: 'SAVE CHANGES',
                    onPressed: _save,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
