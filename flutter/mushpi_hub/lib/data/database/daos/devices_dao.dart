import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'devices_dao.g.dart';

@DriftAccessor(tables: [Devices])
class DevicesDao extends DatabaseAccessor<AppDatabase> with _$DevicesDaoMixin {
  DevicesDao(AppDatabase db) : super(db);

  /// Get all devices
  Future<List<Device>> getAllDevices() => select(devices).get();

  /// Get device by ID
  Future<Device?> getDeviceById(String deviceId) {
    return (select(devices)..where((d) => d.deviceId.equals(deviceId)))
        .getSingleOrNull();
  }

  /// Get device by MAC address
  Future<Device?> getDeviceByAddress(String address) {
    return (select(devices)..where((d) => d.address.equals(address)))
        .getSingleOrNull();
  }

  /// Get device by farm ID
  Future<Device?> getDeviceByFarmId(String farmId) {
    return (select(devices)..where((d) => d.farmId.equals(farmId)))
        .getSingleOrNull();
  }

  /// Get all devices linked to farms
  Future<List<Device>> getLinkedDevices() {
    return (select(devices)..where((d) => d.farmId.isNotNull())).get();
  }

  /// Get all devices not linked to any farm
  Future<List<Device>> getUnlinkedDevices() {
    return (select(devices)..where((d) => d.farmId.isNull())).get();
  }

  /// Get recently connected devices
  Future<List<Device>> getRecentlyConnectedDevices(int limit) {
    return (select(devices)
          ..orderBy([(d) => OrderingTerm.desc(d.lastConnected)])
          ..limit(limit))
        .get();
  }

  /// Get devices connected after a specific date
  Future<List<Device>> getDevicesConnectedSince(DateTime since) {
    return (select(devices)
          ..where((d) => d.lastConnected.isBiggerOrEqualValue(since))
          ..orderBy([(d) => OrderingTerm.desc(d.lastConnected)]))
        .get();
  }

  /// Insert a new device
  Future<int> insertDevice(DevicesCompanion device) {
    return into(devices).insert(
      device,
      onConflict: DoUpdate(
        (old) => DevicesCompanion(
          name: device.name,
          address: device.address,
          lastConnected: device.lastConnected,
        ),
      ),
    );
  }

  /// Update an existing device
  Future<bool> updateDevice(Device device) {
    return update(devices).replace(device);
  }

  /// Update device's last connected timestamp
  Future<int> updateLastConnected(String deviceId, DateTime timestamp) {
    return (update(devices)..where((d) => d.deviceId.equals(deviceId)))
        .write(DevicesCompanion(lastConnected: Value(timestamp)));
  }

  /// Link device to a farm
  Future<int> linkDeviceToFarm(String deviceId, String farmId) {
    return (update(devices)..where((d) => d.deviceId.equals(deviceId)))
        .write(DevicesCompanion(farmId: Value(farmId)));
  }

  /// Unlink device from farm
  Future<int> unlinkDeviceFromFarm(String deviceId) {
    return (update(devices)..where((d) => d.deviceId.equals(deviceId)))
        .write(const DevicesCompanion(farmId: Value(null)));
  }

  /// Update device name
  Future<int> updateDeviceName(String deviceId, String name) {
    return (update(devices)..where((d) => d.deviceId.equals(deviceId)))
        .write(DevicesCompanion(name: Value(name)));
  }

  /// Update device MAC address
  Future<int> updateDeviceAddress(String deviceId, String address) {
    return (update(devices)..where((d) => d.deviceId.equals(deviceId)))
        .write(DevicesCompanion(address: Value(address)));
  }

  /// Delete a device
  Future<int> deleteDevice(String deviceId) {
    return (delete(devices)..where((d) => d.deviceId.equals(deviceId))).go();
  }

  /// Delete all devices not linked to farms
  Future<int> deleteUnlinkedDevices() {
    return (delete(devices)..where((d) => d.farmId.isNull())).go();
  }

  /// Check if device exists
  Future<bool> deviceExists(String deviceId) async {
    final device = await getDeviceById(deviceId);
    return device != null;
  }

  /// Check if device is linked to a farm
  Future<bool> isDeviceLinked(String deviceId) async {
    final device = await getDeviceById(deviceId);
    return device?.farmId != null;
  }

  /// Get device count
  Future<int> getDeviceCount() async {
    final query = selectOnly(devices)..addColumns([devices.deviceId.count()]);
    final result = await query.getSingleOrNull();
    return result?.read(devices.deviceId.count()) ?? 0;
  }

  /// Get linked device count
  Future<int> getLinkedDeviceCount() async {
    final query = selectOnly(devices)
      ..addColumns([devices.deviceId.count()])
      ..where(devices.farmId.isNotNull());
    final result = await query.getSingleOrNull();
    return result?.read(devices.deviceId.count()) ?? 0;
  }
}
