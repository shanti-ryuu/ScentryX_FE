import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/device_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_indicator.dart';

class AddDeviceScreen extends StatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _macController = TextEditingController();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  double _threshold = 500;

  @override
  void dispose() {
    _macController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String? _validateMac(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'MAC address is required';
    }
    if (value.length < 8) {
      return 'Enter a valid MAC address';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Device name is required';
    }
    return null;
  }

  Future<void> _submit() async {
    final provider = context.read<DeviceProvider>();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final data = <String, dynamic>{
      'deviceId': _macController.text.trim(),
      'deviceName': _nameController.text.trim(),
      'location': _locationController.text.trim(),
      'alertThreshold': _threshold.toInt(),
    };

    final device = await provider.registerDevice(data);
    if (!mounted) return;

    if (device != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device registered successfully')),
      );
      Navigator.of(context).pop();
    } else {
      final message = provider.error ?? 'Failed to register device';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeviceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Device'),
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
                  'Register your device',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Power on your device\n'
                  '2. Enter MAC address below\n'
                  '3. Configure WiFi on the device\n'
                  '4. Set alert threshold',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  controller: _macController,
                  label: 'Device MAC Address',
                  hintText: 'A4:CF:12:34:56:78',
                  validator: _validateMac,
                ),
                const SizedBox(height: 16),
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
                    label: 'REGISTER DEVICE',
                    onPressed: _submit,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
