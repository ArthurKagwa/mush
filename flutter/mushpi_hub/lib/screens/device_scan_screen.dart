import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/ble_constants.dart';
import '../core/utils/permission_handler.dart';
import '../providers/ble_provider.dart';
import '../providers/farms_provider.dart';

const _uuid = Uuid();

/// Device scan screen for discovering and linking MushPi devices.
///
/// Features:
/// - BLE device scanning with permission handling
/// - Device list with signal strength indicators
/// - Farm creation wizard with species auto-detection
/// - Filters for MushPi devices only
class DeviceScanScreen extends ConsumerStatefulWidget {
  const DeviceScanScreen({super.key});

  @override
  ConsumerState<DeviceScanScreen> createState() => _DeviceScanScreenState();
}

class _DeviceScanScreenState extends ConsumerState<DeviceScanScreen> {
  bool _isScanning = false;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  @override
  void initState() {
    super.initState();
    _startScanning();
  }

  @override
  void dispose() {
    _adapterStateSubscription?.cancel();
    _stopScanning();
    super.dispose();
  }

  /// Start BLE scanning for MushPi devices
  Future<void> _startScanning() async {
    try {
      developer.log('Checking BLE permissions...', name: 'device_scan');
      
      // Check and request BLE permissions
      final hasPermissions = await BLEPermissionHandler.ensurePermissions(context);
      if (!hasPermissions) {
        developer.log('BLE permissions denied', name: 'device_scan', level: 900);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bluetooth permissions are required to scan for devices'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      developer.log('BLE permissions granted, starting scan...', name: 'device_scan');

      // Start scanning via provider
      setState(() => _isScanning = true);
      await ref.read(bleScanStateProvider.notifier).startScan();

      developer.log('BLE scanning started successfully', name: 'device_scan');
    } catch (e, stackTrace) {
      developer.log(
        'Failed to start scanning',
        name: 'device_scan',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start scanning: $e')),
        );
      }
    }
  }

  /// Stop BLE scanning
  Future<void> _stopScanning() async {
    try {
      setState(() => _isScanning = false);
      await ref.read(bleScanStateProvider.notifier).stopScan();
      developer.log('Stopped BLE scanning', name: 'device_scan');
    } catch (e) {
      developer.log('Failed to stop scanning', name: 'device_scan', error: e);
    }
  }

  /// Show farm creation dialog for selected device
  Future<void> _onDeviceSelected(ScanResult result) async {
    // Stop scanning while creating farm
    await _stopScanning();

    // Detect species from advertising name
    final deviceName = result.device.platformName;
    final detectedSpecies = _detectSpeciesFromName(deviceName);

    if (!mounted) return;

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => _FarmCreationDialog(
        device: result.device,
        detectedSpecies: detectedSpecies,
      ),
    );

    // Resume scanning if farm wasn't created
    if (created != true && mounted) {
      await _startScanning();
    } else if (created == true && mounted) {
      // Navigate back to home on success
      context.go('/home');
    }
  }

  /// Detect mushroom species from device advertising name
  /// Format: MushPi-<species><stage> (e.g., MushPi-OysterPinning)
  Species? _detectSpeciesFromName(String name) {
    if (name.contains('Oyster')) return Species.oyster;
    if (name.contains('Shiitake')) return Species.shiitake;
    if (name.contains('Lion')) return Species.lionsMane;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(bleScanStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan for Devices'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Scan toggle button
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.refresh),
            tooltip: _isScanning ? 'Stop Scanning' : 'Refresh',
            onPressed: _isScanning ? _stopScanning : _startScanning,
          ),
        ],
      ),
      body: scanState.when(
        data: (results) => _buildDeviceList(results),
        loading: () => _buildScanningState(),
        error: (error, stack) => _buildErrorState(error),
      ),
    );
  }

  /// Build device list view
  Widget _buildDeviceList(List<ScanResult> results) {
    developer.log(
      'Displaying ${results.length} scan results',
      name: 'device_scan',
    );

    // Log all devices for debugging
    for (final result in results) {
      final name = result.device.platformName;
      final hasUuid = result.advertisementData.serviceUuids
          .any((uuid) => uuid.toString() == BLEConstants.serviceUUID);
      
      developer.log(
        'Device: ${name.isEmpty ? "Unknown" : name} '
        '(${result.device.remoteId}) '
        'RSSI: ${result.rssi} '
        'UUIDs: ${result.advertisementData.serviceUuids.length} '
        'HasMushPiUUID: $hasUuid',
        name: 'device_scan',
      );
    }

    if (results.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return _DeviceListItem(
          result: result,
          onTap: () => _onDeviceSelected(result),
        );
      },
    );
  }

  /// Build scanning state
  Widget _buildScanningState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_searching,
              size: 120,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Scanning for MushPi Devices',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Make sure your MushPi device is powered on and nearby.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  /// Build empty state (no devices found)
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_disabled,
              size: 120,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No MushPi Devices Found',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Make sure your device is:\n• Powered on\n• Within range\n• Not already connected',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _startScanning,
              icon: const Icon(Icons.refresh),
              label: const Text('Scan Again'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 120,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Scanning Error',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _startScanning,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Device list item widget
class _DeviceListItem extends StatelessWidget {
  final ScanResult result;
  final VoidCallback onTap;

  const _DeviceListItem({
    required this.result,
    required this.onTap,
  });

  /// Get signal strength icon and color based on RSSI
  (IconData, Color) _getSignalStrengthInfo(BuildContext context, int rssi) {
    if (rssi >= -60) {
      return (Icons.signal_cellular_alt, Colors.green);
    } else if (rssi >= -75) {
      return (Icons.signal_cellular_alt_2_bar, Colors.orange);
    } else {
      return (Icons.signal_cellular_alt_1_bar, Colors.red);
    }
  }

  /// Parse species from device name
  String _getSpeciesDisplay() {
    final name = result.device.platformName;
    if (name.contains('Oyster')) return '🍄 Oyster';
    if (name.contains('Shiitake')) return '🍄 Shiitake';
    if (name.contains('Lion')) return '🍄 Lion\'s Mane';
    return '🍄 Unknown';
  }

  /// Parse stage from device name
  String? _getStageDisplay() {
    final name = result.device.platformName;
    if (name.contains('Incub')) return 'Incubation';
    if (name.contains('Pinning')) return 'Pinning';
    if (name.contains('Fruit')) return 'Fruiting';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final (signalIcon, signalColor) = _getSignalStrengthInfo(
      context,
      result.rssi,
    );
    final species = _getSpeciesDisplay();
    final stage = _getStageDisplay();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.bluetooth,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          result.device.platformName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(species),
            if (stage != null) ...[
              const SizedBox(height: 2),
              Text(
                'Stage: $stage',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(signalIcon, size: 16, color: signalColor),
                const SizedBox(width: 4),
                Text(
                  '${result.rssi} dBm',
                  style: TextStyle(
                    fontSize: 12,
                    color: signalColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

/// Farm creation dialog
class _FarmCreationDialog extends ConsumerStatefulWidget {
  final BluetoothDevice device;
  final Species? detectedSpecies;

  const _FarmCreationDialog({
    required this.device,
    this.detectedSpecies,
  });

  @override
  ConsumerState<_FarmCreationDialog> createState() => _FarmCreationDialogState();
}

class _FarmCreationDialogState extends ConsumerState<_FarmCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  late Species _selectedSpecies;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _selectedSpecies = widget.detectedSpecies ?? Species.oyster;
    
    // Default farm name from species and device
    _nameController.text = '${_selectedSpecies.displayName} Farm';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// Create new farm and link device
  Future<void> _createFarm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final operations = ref.read(farmOperationsProvider);
      final farmId = _uuid.v4();

      developer.log(
        '🏗️ [_FarmCreationDialog] Creating farm...\n'
        '  ID: $farmId\n'
        '  Name: ${_nameController.text.trim()}\n'
        '  Device: ${widget.device.remoteId.str}\n'
        '  Species: ${_selectedSpecies.displayName}\n'
        '  Location: ${_locationController.text.trim()}',
        name: 'device_scan',
      );

      // Create farm with generated UUID
      final createdFarmId = await operations.createFarm(
        id: farmId,
        name: _nameController.text.trim(),
        deviceId: widget.device.remoteId.str,
        location: _locationController.text.trim().isEmpty 
            ? null 
            : _locationController.text.trim(),
        primarySpecies: _selectedSpecies,
      );

      developer.log(
        '✅ [_FarmCreationDialog] Farm created successfully!\n'
        '  ID: $createdFarmId\n'
        '  Device: ${widget.device.platformName}',
        name: 'device_scan',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Farm "${_nameController.text}" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        developer.log(
          '🚀 [_FarmCreationDialog] Closing dialog and returning success',
          name: 'device_scan',
        );
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ [_FarmCreationDialog] Failed to create farm',
        name: 'device_scan',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create farm: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Farm'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device info
              Text(
                'Device: ${widget.device.platformName}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),

              // Farm name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Farm Name *',
                  hintText: 'e.g., Basement Farm',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a farm name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Species selector
              Text(
                'Mushroom Species *',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SpeciesChip(
                    species: Species.oyster,
                    isSelected: _selectedSpecies == Species.oyster,
                    onSelected: () => setState(() => _selectedSpecies = Species.oyster),
                  ),
                  _SpeciesChip(
                    species: Species.shiitake,
                    isSelected: _selectedSpecies == Species.shiitake,
                    onSelected: () => setState(() => _selectedSpecies = Species.shiitake),
                  ),
                  _SpeciesChip(
                    species: Species.lionsMane,
                    isSelected: _selectedSpecies == Species.lionsMane,
                    onSelected: () => setState(() => _selectedSpecies = Species.lionsMane),
                  ),
                  _SpeciesChip(
                    species: Species.custom,
                    isSelected: _selectedSpecies == Species.custom,
                    onSelected: () => setState(() => _selectedSpecies = Species.custom),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Location (optional)
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (optional)',
                  hintText: 'e.g., Portland, OR',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),

              // Info text
              if (widget.detectedSpecies != null)
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${_selectedSpecies.displayName} auto-detected from device',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isCreating ? null : _createFarm,
          child: _isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Farm'),
        ),
      ],
    );
  }
}

/// Species selection chip
class _SpeciesChip extends StatelessWidget {
  final Species species;
  final bool isSelected;
  final VoidCallback onSelected;

  const _SpeciesChip({
    required this.species,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text('${species.icon} ${species.displayName}'),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
    );
  }
}
