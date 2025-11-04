// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'farm.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Farm _$FarmFromJson(Map<String, dynamic> json) {
  return _Farm.fromJson(json);
}

/// @nodoc
mixin _$Farm {
  String get id => throw _privateConstructorUsedError; // Unique farm ID (UUID)
  String get name => throw _privateConstructorUsedError; // User-defined name
  String get deviceId =>
      throw _privateConstructorUsedError; // Linked MushPi device ID (one-to-one)
  String? get location =>
      throw _privateConstructorUsedError; // Optional location
  String? get notes =>
      throw _privateConstructorUsedError; // Farm notes/description
  DateTime get createdAt =>
      throw _privateConstructorUsedError; // Farm creation date
  DateTime? get lastActive =>
      throw _privateConstructorUsedError; // Last time device connected
  int get totalHarvests =>
      throw _privateConstructorUsedError; // Total number of harvests
  double get totalYieldKg =>
      throw _privateConstructorUsedError; // Total yield in kilograms
  Species? get primarySpecies =>
      throw _privateConstructorUsedError; // Primary mushroom species grown
  String? get imageUrl =>
      throw _privateConstructorUsedError; // Farm photo (local path)
  bool get isActive =>
      throw _privateConstructorUsedError; // Farm status (active/archived)
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  /// Serializes this Farm to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Farm
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FarmCopyWith<Farm> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FarmCopyWith<$Res> {
  factory $FarmCopyWith(Farm value, $Res Function(Farm) then) =
      _$FarmCopyWithImpl<$Res, Farm>;
  @useResult
  $Res call(
      {String id,
      String name,
      String deviceId,
      String? location,
      String? notes,
      DateTime createdAt,
      DateTime? lastActive,
      int totalHarvests,
      double totalYieldKg,
      Species? primarySpecies,
      String? imageUrl,
      bool isActive,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class _$FarmCopyWithImpl<$Res, $Val extends Farm>
    implements $FarmCopyWith<$Res> {
  _$FarmCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Farm
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? deviceId = null,
    Object? location = freezed,
    Object? notes = freezed,
    Object? createdAt = null,
    Object? lastActive = freezed,
    Object? totalHarvests = null,
    Object? totalYieldKg = null,
    Object? primarySpecies = freezed,
    Object? imageUrl = freezed,
    Object? isActive = null,
    Object? metadata = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      deviceId: null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      lastActive: freezed == lastActive
          ? _value.lastActive
          : lastActive // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      totalHarvests: null == totalHarvests
          ? _value.totalHarvests
          : totalHarvests // ignore: cast_nullable_to_non_nullable
              as int,
      totalYieldKg: null == totalYieldKg
          ? _value.totalYieldKg
          : totalYieldKg // ignore: cast_nullable_to_non_nullable
              as double,
      primarySpecies: freezed == primarySpecies
          ? _value.primarySpecies
          : primarySpecies // ignore: cast_nullable_to_non_nullable
              as Species?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FarmImplCopyWith<$Res> implements $FarmCopyWith<$Res> {
  factory _$$FarmImplCopyWith(
          _$FarmImpl value, $Res Function(_$FarmImpl) then) =
      __$$FarmImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String deviceId,
      String? location,
      String? notes,
      DateTime createdAt,
      DateTime? lastActive,
      int totalHarvests,
      double totalYieldKg,
      Species? primarySpecies,
      String? imageUrl,
      bool isActive,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class __$$FarmImplCopyWithImpl<$Res>
    extends _$FarmCopyWithImpl<$Res, _$FarmImpl>
    implements _$$FarmImplCopyWith<$Res> {
  __$$FarmImplCopyWithImpl(_$FarmImpl _value, $Res Function(_$FarmImpl) _then)
      : super(_value, _then);

  /// Create a copy of Farm
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? deviceId = null,
    Object? location = freezed,
    Object? notes = freezed,
    Object? createdAt = null,
    Object? lastActive = freezed,
    Object? totalHarvests = null,
    Object? totalYieldKg = null,
    Object? primarySpecies = freezed,
    Object? imageUrl = freezed,
    Object? isActive = null,
    Object? metadata = freezed,
  }) {
    return _then(_$FarmImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      deviceId: null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      lastActive: freezed == lastActive
          ? _value.lastActive
          : lastActive // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      totalHarvests: null == totalHarvests
          ? _value.totalHarvests
          : totalHarvests // ignore: cast_nullable_to_non_nullable
              as int,
      totalYieldKg: null == totalYieldKg
          ? _value.totalYieldKg
          : totalYieldKg // ignore: cast_nullable_to_non_nullable
              as double,
      primarySpecies: freezed == primarySpecies
          ? _value.primarySpecies
          : primarySpecies // ignore: cast_nullable_to_non_nullable
              as Species?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FarmImpl implements _Farm {
  const _$FarmImpl(
      {required this.id,
      required this.name,
      required this.deviceId,
      this.location,
      this.notes,
      required this.createdAt,
      this.lastActive,
      this.totalHarvests = 0,
      this.totalYieldKg = 0.0,
      this.primarySpecies,
      this.imageUrl,
      this.isActive = true,
      final Map<String, dynamic>? metadata})
      : _metadata = metadata;

  factory _$FarmImpl.fromJson(Map<String, dynamic> json) =>
      _$$FarmImplFromJson(json);

  @override
  final String id;
// Unique farm ID (UUID)
  @override
  final String name;
// User-defined name
  @override
  final String deviceId;
// Linked MushPi device ID (one-to-one)
  @override
  final String? location;
// Optional location
  @override
  final String? notes;
// Farm notes/description
  @override
  final DateTime createdAt;
// Farm creation date
  @override
  final DateTime? lastActive;
// Last time device connected
  @override
  @JsonKey()
  final int totalHarvests;
// Total number of harvests
  @override
  @JsonKey()
  final double totalYieldKg;
// Total yield in kilograms
  @override
  final Species? primarySpecies;
// Primary mushroom species grown
  @override
  final String? imageUrl;
// Farm photo (local path)
  @override
  @JsonKey()
  final bool isActive;
// Farm status (active/archived)
  final Map<String, dynamic>? _metadata;
// Farm status (active/archived)
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'Farm(id: $id, name: $name, deviceId: $deviceId, location: $location, notes: $notes, createdAt: $createdAt, lastActive: $lastActive, totalHarvests: $totalHarvests, totalYieldKg: $totalYieldKg, primarySpecies: $primarySpecies, imageUrl: $imageUrl, isActive: $isActive, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FarmImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.lastActive, lastActive) ||
                other.lastActive == lastActive) &&
            (identical(other.totalHarvests, totalHarvests) ||
                other.totalHarvests == totalHarvests) &&
            (identical(other.totalYieldKg, totalYieldKg) ||
                other.totalYieldKg == totalYieldKg) &&
            (identical(other.primarySpecies, primarySpecies) ||
                other.primarySpecies == primarySpecies) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      deviceId,
      location,
      notes,
      createdAt,
      lastActive,
      totalHarvests,
      totalYieldKg,
      primarySpecies,
      imageUrl,
      isActive,
      const DeepCollectionEquality().hash(_metadata));

  /// Create a copy of Farm
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FarmImplCopyWith<_$FarmImpl> get copyWith =>
      __$$FarmImplCopyWithImpl<_$FarmImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FarmImplToJson(
      this,
    );
  }
}

abstract class _Farm implements Farm {
  const factory _Farm(
      {required final String id,
      required final String name,
      required final String deviceId,
      final String? location,
      final String? notes,
      required final DateTime createdAt,
      final DateTime? lastActive,
      final int totalHarvests,
      final double totalYieldKg,
      final Species? primarySpecies,
      final String? imageUrl,
      final bool isActive,
      final Map<String, dynamic>? metadata}) = _$FarmImpl;

  factory _Farm.fromJson(Map<String, dynamic> json) = _$FarmImpl.fromJson;

  @override
  String get id; // Unique farm ID (UUID)
  @override
  String get name; // User-defined name
  @override
  String get deviceId; // Linked MushPi device ID (one-to-one)
  @override
  String? get location; // Optional location
  @override
  String? get notes; // Farm notes/description
  @override
  DateTime get createdAt; // Farm creation date
  @override
  DateTime? get lastActive; // Last time device connected
  @override
  int get totalHarvests; // Total number of harvests
  @override
  double get totalYieldKg; // Total yield in kilograms
  @override
  Species? get primarySpecies; // Primary mushroom species grown
  @override
  String? get imageUrl; // Farm photo (local path)
  @override
  bool get isActive; // Farm status (active/archived)
  @override
  Map<String, dynamic>? get metadata;

  /// Create a copy of Farm
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FarmImplCopyWith<_$FarmImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FarmAnalytics _$FarmAnalyticsFromJson(Map<String, dynamic> json) {
  return _FarmAnalytics.fromJson(json);
}

/// @nodoc
mixin _$FarmAnalytics {
  String get farmId => throw _privateConstructorUsedError;
  String get farmName =>
      throw _privateConstructorUsedError; // Environmental performance
  double get avgTemperature => throw _privateConstructorUsedError;
  double get avgHumidity => throw _privateConstructorUsedError;
  double get avgCO2 => throw _privateConstructorUsedError;
  double get tempCompliancePercent => throw _privateConstructorUsedError;
  double get humidityCompliancePercent => throw _privateConstructorUsedError;
  double get co2CompliancePercent =>
      throw _privateConstructorUsedError; // Production metrics
  int get harvestCount => throw _privateConstructorUsedError;
  double get totalYieldKg => throw _privateConstructorUsedError;
  double get avgYieldPerHarvest => throw _privateConstructorUsedError;
  int get daysInProduction => throw _privateConstructorUsedError;
  double get yieldPerDay =>
      throw _privateConstructorUsedError; // Stage tracking
  GrowthStage? get currentStage => throw _privateConstructorUsedError;
  int get daysInCurrentStage => throw _privateConstructorUsedError;
  int get stageTransitions =>
      throw _privateConstructorUsedError; // System health
  int get totalAlerts => throw _privateConstructorUsedError;
  int get criticalAlerts => throw _privateConstructorUsedError;
  double get uptimePercent => throw _privateConstructorUsedError;
  DateTime? get lastConnection =>
      throw _privateConstructorUsedError; // Time period
  DateTime get periodStart => throw _privateConstructorUsedError;
  DateTime get periodEnd => throw _privateConstructorUsedError;

  /// Serializes this FarmAnalytics to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FarmAnalytics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FarmAnalyticsCopyWith<FarmAnalytics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FarmAnalyticsCopyWith<$Res> {
  factory $FarmAnalyticsCopyWith(
          FarmAnalytics value, $Res Function(FarmAnalytics) then) =
      _$FarmAnalyticsCopyWithImpl<$Res, FarmAnalytics>;
  @useResult
  $Res call(
      {String farmId,
      String farmName,
      double avgTemperature,
      double avgHumidity,
      double avgCO2,
      double tempCompliancePercent,
      double humidityCompliancePercent,
      double co2CompliancePercent,
      int harvestCount,
      double totalYieldKg,
      double avgYieldPerHarvest,
      int daysInProduction,
      double yieldPerDay,
      GrowthStage? currentStage,
      int daysInCurrentStage,
      int stageTransitions,
      int totalAlerts,
      int criticalAlerts,
      double uptimePercent,
      DateTime? lastConnection,
      DateTime periodStart,
      DateTime periodEnd});
}

/// @nodoc
class _$FarmAnalyticsCopyWithImpl<$Res, $Val extends FarmAnalytics>
    implements $FarmAnalyticsCopyWith<$Res> {
  _$FarmAnalyticsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FarmAnalytics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? farmId = null,
    Object? farmName = null,
    Object? avgTemperature = null,
    Object? avgHumidity = null,
    Object? avgCO2 = null,
    Object? tempCompliancePercent = null,
    Object? humidityCompliancePercent = null,
    Object? co2CompliancePercent = null,
    Object? harvestCount = null,
    Object? totalYieldKg = null,
    Object? avgYieldPerHarvest = null,
    Object? daysInProduction = null,
    Object? yieldPerDay = null,
    Object? currentStage = freezed,
    Object? daysInCurrentStage = null,
    Object? stageTransitions = null,
    Object? totalAlerts = null,
    Object? criticalAlerts = null,
    Object? uptimePercent = null,
    Object? lastConnection = freezed,
    Object? periodStart = null,
    Object? periodEnd = null,
  }) {
    return _then(_value.copyWith(
      farmId: null == farmId
          ? _value.farmId
          : farmId // ignore: cast_nullable_to_non_nullable
              as String,
      farmName: null == farmName
          ? _value.farmName
          : farmName // ignore: cast_nullable_to_non_nullable
              as String,
      avgTemperature: null == avgTemperature
          ? _value.avgTemperature
          : avgTemperature // ignore: cast_nullable_to_non_nullable
              as double,
      avgHumidity: null == avgHumidity
          ? _value.avgHumidity
          : avgHumidity // ignore: cast_nullable_to_non_nullable
              as double,
      avgCO2: null == avgCO2
          ? _value.avgCO2
          : avgCO2 // ignore: cast_nullable_to_non_nullable
              as double,
      tempCompliancePercent: null == tempCompliancePercent
          ? _value.tempCompliancePercent
          : tempCompliancePercent // ignore: cast_nullable_to_non_nullable
              as double,
      humidityCompliancePercent: null == humidityCompliancePercent
          ? _value.humidityCompliancePercent
          : humidityCompliancePercent // ignore: cast_nullable_to_non_nullable
              as double,
      co2CompliancePercent: null == co2CompliancePercent
          ? _value.co2CompliancePercent
          : co2CompliancePercent // ignore: cast_nullable_to_non_nullable
              as double,
      harvestCount: null == harvestCount
          ? _value.harvestCount
          : harvestCount // ignore: cast_nullable_to_non_nullable
              as int,
      totalYieldKg: null == totalYieldKg
          ? _value.totalYieldKg
          : totalYieldKg // ignore: cast_nullable_to_non_nullable
              as double,
      avgYieldPerHarvest: null == avgYieldPerHarvest
          ? _value.avgYieldPerHarvest
          : avgYieldPerHarvest // ignore: cast_nullable_to_non_nullable
              as double,
      daysInProduction: null == daysInProduction
          ? _value.daysInProduction
          : daysInProduction // ignore: cast_nullable_to_non_nullable
              as int,
      yieldPerDay: null == yieldPerDay
          ? _value.yieldPerDay
          : yieldPerDay // ignore: cast_nullable_to_non_nullable
              as double,
      currentStage: freezed == currentStage
          ? _value.currentStage
          : currentStage // ignore: cast_nullable_to_non_nullable
              as GrowthStage?,
      daysInCurrentStage: null == daysInCurrentStage
          ? _value.daysInCurrentStage
          : daysInCurrentStage // ignore: cast_nullable_to_non_nullable
              as int,
      stageTransitions: null == stageTransitions
          ? _value.stageTransitions
          : stageTransitions // ignore: cast_nullable_to_non_nullable
              as int,
      totalAlerts: null == totalAlerts
          ? _value.totalAlerts
          : totalAlerts // ignore: cast_nullable_to_non_nullable
              as int,
      criticalAlerts: null == criticalAlerts
          ? _value.criticalAlerts
          : criticalAlerts // ignore: cast_nullable_to_non_nullable
              as int,
      uptimePercent: null == uptimePercent
          ? _value.uptimePercent
          : uptimePercent // ignore: cast_nullable_to_non_nullable
              as double,
      lastConnection: freezed == lastConnection
          ? _value.lastConnection
          : lastConnection // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      periodStart: null == periodStart
          ? _value.periodStart
          : periodStart // ignore: cast_nullable_to_non_nullable
              as DateTime,
      periodEnd: null == periodEnd
          ? _value.periodEnd
          : periodEnd // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FarmAnalyticsImplCopyWith<$Res>
    implements $FarmAnalyticsCopyWith<$Res> {
  factory _$$FarmAnalyticsImplCopyWith(
          _$FarmAnalyticsImpl value, $Res Function(_$FarmAnalyticsImpl) then) =
      __$$FarmAnalyticsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String farmId,
      String farmName,
      double avgTemperature,
      double avgHumidity,
      double avgCO2,
      double tempCompliancePercent,
      double humidityCompliancePercent,
      double co2CompliancePercent,
      int harvestCount,
      double totalYieldKg,
      double avgYieldPerHarvest,
      int daysInProduction,
      double yieldPerDay,
      GrowthStage? currentStage,
      int daysInCurrentStage,
      int stageTransitions,
      int totalAlerts,
      int criticalAlerts,
      double uptimePercent,
      DateTime? lastConnection,
      DateTime periodStart,
      DateTime periodEnd});
}

/// @nodoc
class __$$FarmAnalyticsImplCopyWithImpl<$Res>
    extends _$FarmAnalyticsCopyWithImpl<$Res, _$FarmAnalyticsImpl>
    implements _$$FarmAnalyticsImplCopyWith<$Res> {
  __$$FarmAnalyticsImplCopyWithImpl(
      _$FarmAnalyticsImpl _value, $Res Function(_$FarmAnalyticsImpl) _then)
      : super(_value, _then);

  /// Create a copy of FarmAnalytics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? farmId = null,
    Object? farmName = null,
    Object? avgTemperature = null,
    Object? avgHumidity = null,
    Object? avgCO2 = null,
    Object? tempCompliancePercent = null,
    Object? humidityCompliancePercent = null,
    Object? co2CompliancePercent = null,
    Object? harvestCount = null,
    Object? totalYieldKg = null,
    Object? avgYieldPerHarvest = null,
    Object? daysInProduction = null,
    Object? yieldPerDay = null,
    Object? currentStage = freezed,
    Object? daysInCurrentStage = null,
    Object? stageTransitions = null,
    Object? totalAlerts = null,
    Object? criticalAlerts = null,
    Object? uptimePercent = null,
    Object? lastConnection = freezed,
    Object? periodStart = null,
    Object? periodEnd = null,
  }) {
    return _then(_$FarmAnalyticsImpl(
      farmId: null == farmId
          ? _value.farmId
          : farmId // ignore: cast_nullable_to_non_nullable
              as String,
      farmName: null == farmName
          ? _value.farmName
          : farmName // ignore: cast_nullable_to_non_nullable
              as String,
      avgTemperature: null == avgTemperature
          ? _value.avgTemperature
          : avgTemperature // ignore: cast_nullable_to_non_nullable
              as double,
      avgHumidity: null == avgHumidity
          ? _value.avgHumidity
          : avgHumidity // ignore: cast_nullable_to_non_nullable
              as double,
      avgCO2: null == avgCO2
          ? _value.avgCO2
          : avgCO2 // ignore: cast_nullable_to_non_nullable
              as double,
      tempCompliancePercent: null == tempCompliancePercent
          ? _value.tempCompliancePercent
          : tempCompliancePercent // ignore: cast_nullable_to_non_nullable
              as double,
      humidityCompliancePercent: null == humidityCompliancePercent
          ? _value.humidityCompliancePercent
          : humidityCompliancePercent // ignore: cast_nullable_to_non_nullable
              as double,
      co2CompliancePercent: null == co2CompliancePercent
          ? _value.co2CompliancePercent
          : co2CompliancePercent // ignore: cast_nullable_to_non_nullable
              as double,
      harvestCount: null == harvestCount
          ? _value.harvestCount
          : harvestCount // ignore: cast_nullable_to_non_nullable
              as int,
      totalYieldKg: null == totalYieldKg
          ? _value.totalYieldKg
          : totalYieldKg // ignore: cast_nullable_to_non_nullable
              as double,
      avgYieldPerHarvest: null == avgYieldPerHarvest
          ? _value.avgYieldPerHarvest
          : avgYieldPerHarvest // ignore: cast_nullable_to_non_nullable
              as double,
      daysInProduction: null == daysInProduction
          ? _value.daysInProduction
          : daysInProduction // ignore: cast_nullable_to_non_nullable
              as int,
      yieldPerDay: null == yieldPerDay
          ? _value.yieldPerDay
          : yieldPerDay // ignore: cast_nullable_to_non_nullable
              as double,
      currentStage: freezed == currentStage
          ? _value.currentStage
          : currentStage // ignore: cast_nullable_to_non_nullable
              as GrowthStage?,
      daysInCurrentStage: null == daysInCurrentStage
          ? _value.daysInCurrentStage
          : daysInCurrentStage // ignore: cast_nullable_to_non_nullable
              as int,
      stageTransitions: null == stageTransitions
          ? _value.stageTransitions
          : stageTransitions // ignore: cast_nullable_to_non_nullable
              as int,
      totalAlerts: null == totalAlerts
          ? _value.totalAlerts
          : totalAlerts // ignore: cast_nullable_to_non_nullable
              as int,
      criticalAlerts: null == criticalAlerts
          ? _value.criticalAlerts
          : criticalAlerts // ignore: cast_nullable_to_non_nullable
              as int,
      uptimePercent: null == uptimePercent
          ? _value.uptimePercent
          : uptimePercent // ignore: cast_nullable_to_non_nullable
              as double,
      lastConnection: freezed == lastConnection
          ? _value.lastConnection
          : lastConnection // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      periodStart: null == periodStart
          ? _value.periodStart
          : periodStart // ignore: cast_nullable_to_non_nullable
              as DateTime,
      periodEnd: null == periodEnd
          ? _value.periodEnd
          : periodEnd // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FarmAnalyticsImpl implements _FarmAnalytics {
  const _$FarmAnalyticsImpl(
      {required this.farmId,
      required this.farmName,
      required this.avgTemperature,
      required this.avgHumidity,
      required this.avgCO2,
      required this.tempCompliancePercent,
      required this.humidityCompliancePercent,
      required this.co2CompliancePercent,
      required this.harvestCount,
      required this.totalYieldKg,
      required this.avgYieldPerHarvest,
      required this.daysInProduction,
      required this.yieldPerDay,
      this.currentStage,
      required this.daysInCurrentStage,
      required this.stageTransitions,
      required this.totalAlerts,
      required this.criticalAlerts,
      required this.uptimePercent,
      this.lastConnection,
      required this.periodStart,
      required this.periodEnd});

  factory _$FarmAnalyticsImpl.fromJson(Map<String, dynamic> json) =>
      _$$FarmAnalyticsImplFromJson(json);

  @override
  final String farmId;
  @override
  final String farmName;
// Environmental performance
  @override
  final double avgTemperature;
  @override
  final double avgHumidity;
  @override
  final double avgCO2;
  @override
  final double tempCompliancePercent;
  @override
  final double humidityCompliancePercent;
  @override
  final double co2CompliancePercent;
// Production metrics
  @override
  final int harvestCount;
  @override
  final double totalYieldKg;
  @override
  final double avgYieldPerHarvest;
  @override
  final int daysInProduction;
  @override
  final double yieldPerDay;
// Stage tracking
  @override
  final GrowthStage? currentStage;
  @override
  final int daysInCurrentStage;
  @override
  final int stageTransitions;
// System health
  @override
  final int totalAlerts;
  @override
  final int criticalAlerts;
  @override
  final double uptimePercent;
  @override
  final DateTime? lastConnection;
// Time period
  @override
  final DateTime periodStart;
  @override
  final DateTime periodEnd;

  @override
  String toString() {
    return 'FarmAnalytics(farmId: $farmId, farmName: $farmName, avgTemperature: $avgTemperature, avgHumidity: $avgHumidity, avgCO2: $avgCO2, tempCompliancePercent: $tempCompliancePercent, humidityCompliancePercent: $humidityCompliancePercent, co2CompliancePercent: $co2CompliancePercent, harvestCount: $harvestCount, totalYieldKg: $totalYieldKg, avgYieldPerHarvest: $avgYieldPerHarvest, daysInProduction: $daysInProduction, yieldPerDay: $yieldPerDay, currentStage: $currentStage, daysInCurrentStage: $daysInCurrentStage, stageTransitions: $stageTransitions, totalAlerts: $totalAlerts, criticalAlerts: $criticalAlerts, uptimePercent: $uptimePercent, lastConnection: $lastConnection, periodStart: $periodStart, periodEnd: $periodEnd)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FarmAnalyticsImpl &&
            (identical(other.farmId, farmId) || other.farmId == farmId) &&
            (identical(other.farmName, farmName) ||
                other.farmName == farmName) &&
            (identical(other.avgTemperature, avgTemperature) ||
                other.avgTemperature == avgTemperature) &&
            (identical(other.avgHumidity, avgHumidity) ||
                other.avgHumidity == avgHumidity) &&
            (identical(other.avgCO2, avgCO2) || other.avgCO2 == avgCO2) &&
            (identical(other.tempCompliancePercent, tempCompliancePercent) ||
                other.tempCompliancePercent == tempCompliancePercent) &&
            (identical(other.humidityCompliancePercent,
                    humidityCompliancePercent) ||
                other.humidityCompliancePercent == humidityCompliancePercent) &&
            (identical(other.co2CompliancePercent, co2CompliancePercent) ||
                other.co2CompliancePercent == co2CompliancePercent) &&
            (identical(other.harvestCount, harvestCount) ||
                other.harvestCount == harvestCount) &&
            (identical(other.totalYieldKg, totalYieldKg) ||
                other.totalYieldKg == totalYieldKg) &&
            (identical(other.avgYieldPerHarvest, avgYieldPerHarvest) ||
                other.avgYieldPerHarvest == avgYieldPerHarvest) &&
            (identical(other.daysInProduction, daysInProduction) ||
                other.daysInProduction == daysInProduction) &&
            (identical(other.yieldPerDay, yieldPerDay) ||
                other.yieldPerDay == yieldPerDay) &&
            (identical(other.currentStage, currentStage) ||
                other.currentStage == currentStage) &&
            (identical(other.daysInCurrentStage, daysInCurrentStage) ||
                other.daysInCurrentStage == daysInCurrentStage) &&
            (identical(other.stageTransitions, stageTransitions) ||
                other.stageTransitions == stageTransitions) &&
            (identical(other.totalAlerts, totalAlerts) ||
                other.totalAlerts == totalAlerts) &&
            (identical(other.criticalAlerts, criticalAlerts) ||
                other.criticalAlerts == criticalAlerts) &&
            (identical(other.uptimePercent, uptimePercent) ||
                other.uptimePercent == uptimePercent) &&
            (identical(other.lastConnection, lastConnection) ||
                other.lastConnection == lastConnection) &&
            (identical(other.periodStart, periodStart) ||
                other.periodStart == periodStart) &&
            (identical(other.periodEnd, periodEnd) ||
                other.periodEnd == periodEnd));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        farmId,
        farmName,
        avgTemperature,
        avgHumidity,
        avgCO2,
        tempCompliancePercent,
        humidityCompliancePercent,
        co2CompliancePercent,
        harvestCount,
        totalYieldKg,
        avgYieldPerHarvest,
        daysInProduction,
        yieldPerDay,
        currentStage,
        daysInCurrentStage,
        stageTransitions,
        totalAlerts,
        criticalAlerts,
        uptimePercent,
        lastConnection,
        periodStart,
        periodEnd
      ]);

  /// Create a copy of FarmAnalytics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FarmAnalyticsImplCopyWith<_$FarmAnalyticsImpl> get copyWith =>
      __$$FarmAnalyticsImplCopyWithImpl<_$FarmAnalyticsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FarmAnalyticsImplToJson(
      this,
    );
  }
}

abstract class _FarmAnalytics implements FarmAnalytics {
  const factory _FarmAnalytics(
      {required final String farmId,
      required final String farmName,
      required final double avgTemperature,
      required final double avgHumidity,
      required final double avgCO2,
      required final double tempCompliancePercent,
      required final double humidityCompliancePercent,
      required final double co2CompliancePercent,
      required final int harvestCount,
      required final double totalYieldKg,
      required final double avgYieldPerHarvest,
      required final int daysInProduction,
      required final double yieldPerDay,
      final GrowthStage? currentStage,
      required final int daysInCurrentStage,
      required final int stageTransitions,
      required final int totalAlerts,
      required final int criticalAlerts,
      required final double uptimePercent,
      final DateTime? lastConnection,
      required final DateTime periodStart,
      required final DateTime periodEnd}) = _$FarmAnalyticsImpl;

  factory _FarmAnalytics.fromJson(Map<String, dynamic> json) =
      _$FarmAnalyticsImpl.fromJson;

  @override
  String get farmId;
  @override
  String get farmName; // Environmental performance
  @override
  double get avgTemperature;
  @override
  double get avgHumidity;
  @override
  double get avgCO2;
  @override
  double get tempCompliancePercent;
  @override
  double get humidityCompliancePercent;
  @override
  double get co2CompliancePercent; // Production metrics
  @override
  int get harvestCount;
  @override
  double get totalYieldKg;
  @override
  double get avgYieldPerHarvest;
  @override
  int get daysInProduction;
  @override
  double get yieldPerDay; // Stage tracking
  @override
  GrowthStage? get currentStage;
  @override
  int get daysInCurrentStage;
  @override
  int get stageTransitions; // System health
  @override
  int get totalAlerts;
  @override
  int get criticalAlerts;
  @override
  double get uptimePercent;
  @override
  DateTime? get lastConnection; // Time period
  @override
  DateTime get periodStart;
  @override
  DateTime get periodEnd;

  /// Create a copy of FarmAnalytics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FarmAnalyticsImplCopyWith<_$FarmAnalyticsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HarvestRecord _$HarvestRecordFromJson(Map<String, dynamic> json) {
  return _HarvestRecord.fromJson(json);
}

/// @nodoc
mixin _$HarvestRecord {
  String get id => throw _privateConstructorUsedError;
  String get farmId => throw _privateConstructorUsedError;
  DateTime get harvestDate => throw _privateConstructorUsedError;
  Species get species => throw _privateConstructorUsedError;
  GrowthStage get stage => throw _privateConstructorUsedError;
  double get yieldKg => throw _privateConstructorUsedError;
  int? get flushNumber =>
      throw _privateConstructorUsedError; // Which flush (1st, 2nd, etc.)
  double? get qualityScore =>
      throw _privateConstructorUsedError; // 0-10 quality rating
  String? get notes => throw _privateConstructorUsedError;
  List<String>? get photoUrls =>
      throw _privateConstructorUsedError; // Harvest photos
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  /// Serializes this HarvestRecord to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HarvestRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HarvestRecordCopyWith<HarvestRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HarvestRecordCopyWith<$Res> {
  factory $HarvestRecordCopyWith(
          HarvestRecord value, $Res Function(HarvestRecord) then) =
      _$HarvestRecordCopyWithImpl<$Res, HarvestRecord>;
  @useResult
  $Res call(
      {String id,
      String farmId,
      DateTime harvestDate,
      Species species,
      GrowthStage stage,
      double yieldKg,
      int? flushNumber,
      double? qualityScore,
      String? notes,
      List<String>? photoUrls,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class _$HarvestRecordCopyWithImpl<$Res, $Val extends HarvestRecord>
    implements $HarvestRecordCopyWith<$Res> {
  _$HarvestRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HarvestRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? farmId = null,
    Object? harvestDate = null,
    Object? species = null,
    Object? stage = null,
    Object? yieldKg = null,
    Object? flushNumber = freezed,
    Object? qualityScore = freezed,
    Object? notes = freezed,
    Object? photoUrls = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      farmId: null == farmId
          ? _value.farmId
          : farmId // ignore: cast_nullable_to_non_nullable
              as String,
      harvestDate: null == harvestDate
          ? _value.harvestDate
          : harvestDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      species: null == species
          ? _value.species
          : species // ignore: cast_nullable_to_non_nullable
              as Species,
      stage: null == stage
          ? _value.stage
          : stage // ignore: cast_nullable_to_non_nullable
              as GrowthStage,
      yieldKg: null == yieldKg
          ? _value.yieldKg
          : yieldKg // ignore: cast_nullable_to_non_nullable
              as double,
      flushNumber: freezed == flushNumber
          ? _value.flushNumber
          : flushNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      qualityScore: freezed == qualityScore
          ? _value.qualityScore
          : qualityScore // ignore: cast_nullable_to_non_nullable
              as double?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      photoUrls: freezed == photoUrls
          ? _value.photoUrls
          : photoUrls // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HarvestRecordImplCopyWith<$Res>
    implements $HarvestRecordCopyWith<$Res> {
  factory _$$HarvestRecordImplCopyWith(
          _$HarvestRecordImpl value, $Res Function(_$HarvestRecordImpl) then) =
      __$$HarvestRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String farmId,
      DateTime harvestDate,
      Species species,
      GrowthStage stage,
      double yieldKg,
      int? flushNumber,
      double? qualityScore,
      String? notes,
      List<String>? photoUrls,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class __$$HarvestRecordImplCopyWithImpl<$Res>
    extends _$HarvestRecordCopyWithImpl<$Res, _$HarvestRecordImpl>
    implements _$$HarvestRecordImplCopyWith<$Res> {
  __$$HarvestRecordImplCopyWithImpl(
      _$HarvestRecordImpl _value, $Res Function(_$HarvestRecordImpl) _then)
      : super(_value, _then);

  /// Create a copy of HarvestRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? farmId = null,
    Object? harvestDate = null,
    Object? species = null,
    Object? stage = null,
    Object? yieldKg = null,
    Object? flushNumber = freezed,
    Object? qualityScore = freezed,
    Object? notes = freezed,
    Object? photoUrls = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_$HarvestRecordImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      farmId: null == farmId
          ? _value.farmId
          : farmId // ignore: cast_nullable_to_non_nullable
              as String,
      harvestDate: null == harvestDate
          ? _value.harvestDate
          : harvestDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      species: null == species
          ? _value.species
          : species // ignore: cast_nullable_to_non_nullable
              as Species,
      stage: null == stage
          ? _value.stage
          : stage // ignore: cast_nullable_to_non_nullable
              as GrowthStage,
      yieldKg: null == yieldKg
          ? _value.yieldKg
          : yieldKg // ignore: cast_nullable_to_non_nullable
              as double,
      flushNumber: freezed == flushNumber
          ? _value.flushNumber
          : flushNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      qualityScore: freezed == qualityScore
          ? _value.qualityScore
          : qualityScore // ignore: cast_nullable_to_non_nullable
              as double?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      photoUrls: freezed == photoUrls
          ? _value._photoUrls
          : photoUrls // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HarvestRecordImpl implements _HarvestRecord {
  const _$HarvestRecordImpl(
      {required this.id,
      required this.farmId,
      required this.harvestDate,
      required this.species,
      required this.stage,
      required this.yieldKg,
      this.flushNumber,
      this.qualityScore,
      this.notes,
      final List<String>? photoUrls,
      final Map<String, dynamic>? metadata})
      : _photoUrls = photoUrls,
        _metadata = metadata;

  factory _$HarvestRecordImpl.fromJson(Map<String, dynamic> json) =>
      _$$HarvestRecordImplFromJson(json);

  @override
  final String id;
  @override
  final String farmId;
  @override
  final DateTime harvestDate;
  @override
  final Species species;
  @override
  final GrowthStage stage;
  @override
  final double yieldKg;
  @override
  final int? flushNumber;
// Which flush (1st, 2nd, etc.)
  @override
  final double? qualityScore;
// 0-10 quality rating
  @override
  final String? notes;
  final List<String>? _photoUrls;
  @override
  List<String>? get photoUrls {
    final value = _photoUrls;
    if (value == null) return null;
    if (_photoUrls is EqualUnmodifiableListView) return _photoUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

// Harvest photos
  final Map<String, dynamic>? _metadata;
// Harvest photos
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'HarvestRecord(id: $id, farmId: $farmId, harvestDate: $harvestDate, species: $species, stage: $stage, yieldKg: $yieldKg, flushNumber: $flushNumber, qualityScore: $qualityScore, notes: $notes, photoUrls: $photoUrls, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HarvestRecordImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.farmId, farmId) || other.farmId == farmId) &&
            (identical(other.harvestDate, harvestDate) ||
                other.harvestDate == harvestDate) &&
            (identical(other.species, species) || other.species == species) &&
            (identical(other.stage, stage) || other.stage == stage) &&
            (identical(other.yieldKg, yieldKg) || other.yieldKg == yieldKg) &&
            (identical(other.flushNumber, flushNumber) ||
                other.flushNumber == flushNumber) &&
            (identical(other.qualityScore, qualityScore) ||
                other.qualityScore == qualityScore) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            const DeepCollectionEquality()
                .equals(other._photoUrls, _photoUrls) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      farmId,
      harvestDate,
      species,
      stage,
      yieldKg,
      flushNumber,
      qualityScore,
      notes,
      const DeepCollectionEquality().hash(_photoUrls),
      const DeepCollectionEquality().hash(_metadata));

  /// Create a copy of HarvestRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HarvestRecordImplCopyWith<_$HarvestRecordImpl> get copyWith =>
      __$$HarvestRecordImplCopyWithImpl<_$HarvestRecordImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HarvestRecordImplToJson(
      this,
    );
  }
}

abstract class _HarvestRecord implements HarvestRecord {
  const factory _HarvestRecord(
      {required final String id,
      required final String farmId,
      required final DateTime harvestDate,
      required final Species species,
      required final GrowthStage stage,
      required final double yieldKg,
      final int? flushNumber,
      final double? qualityScore,
      final String? notes,
      final List<String>? photoUrls,
      final Map<String, dynamic>? metadata}) = _$HarvestRecordImpl;

  factory _HarvestRecord.fromJson(Map<String, dynamic> json) =
      _$HarvestRecordImpl.fromJson;

  @override
  String get id;
  @override
  String get farmId;
  @override
  DateTime get harvestDate;
  @override
  Species get species;
  @override
  GrowthStage get stage;
  @override
  double get yieldKg;
  @override
  int? get flushNumber; // Which flush (1st, 2nd, etc.)
  @override
  double? get qualityScore; // 0-10 quality rating
  @override
  String? get notes;
  @override
  List<String>? get photoUrls; // Harvest photos
  @override
  Map<String, dynamic>? get metadata;

  /// Create a copy of HarvestRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HarvestRecordImplCopyWith<_$HarvestRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CrossFarmComparison _$CrossFarmComparisonFromJson(Map<String, dynamic> json) {
  return _CrossFarmComparison.fromJson(json);
}

/// @nodoc
mixin _$CrossFarmComparison {
  List<FarmAnalytics> get farms => throw _privateConstructorUsedError;
  FarmAnalytics get averages => throw _privateConstructorUsedError;
  FarmAnalytics get topPerformer => throw _privateConstructorUsedError;
  FarmAnalytics get bottomPerformer => throw _privateConstructorUsedError;
  Map<String, double> get speciesBreakdown =>
      throw _privateConstructorUsedError;
  Map<String, int> get stageDistribution => throw _privateConstructorUsedError;

  /// Serializes this CrossFarmComparison to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CrossFarmComparison
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CrossFarmComparisonCopyWith<CrossFarmComparison> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CrossFarmComparisonCopyWith<$Res> {
  factory $CrossFarmComparisonCopyWith(
          CrossFarmComparison value, $Res Function(CrossFarmComparison) then) =
      _$CrossFarmComparisonCopyWithImpl<$Res, CrossFarmComparison>;
  @useResult
  $Res call(
      {List<FarmAnalytics> farms,
      FarmAnalytics averages,
      FarmAnalytics topPerformer,
      FarmAnalytics bottomPerformer,
      Map<String, double> speciesBreakdown,
      Map<String, int> stageDistribution});

  $FarmAnalyticsCopyWith<$Res> get averages;
  $FarmAnalyticsCopyWith<$Res> get topPerformer;
  $FarmAnalyticsCopyWith<$Res> get bottomPerformer;
}

/// @nodoc
class _$CrossFarmComparisonCopyWithImpl<$Res, $Val extends CrossFarmComparison>
    implements $CrossFarmComparisonCopyWith<$Res> {
  _$CrossFarmComparisonCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CrossFarmComparison
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? farms = null,
    Object? averages = null,
    Object? topPerformer = null,
    Object? bottomPerformer = null,
    Object? speciesBreakdown = null,
    Object? stageDistribution = null,
  }) {
    return _then(_value.copyWith(
      farms: null == farms
          ? _value.farms
          : farms // ignore: cast_nullable_to_non_nullable
              as List<FarmAnalytics>,
      averages: null == averages
          ? _value.averages
          : averages // ignore: cast_nullable_to_non_nullable
              as FarmAnalytics,
      topPerformer: null == topPerformer
          ? _value.topPerformer
          : topPerformer // ignore: cast_nullable_to_non_nullable
              as FarmAnalytics,
      bottomPerformer: null == bottomPerformer
          ? _value.bottomPerformer
          : bottomPerformer // ignore: cast_nullable_to_non_nullable
              as FarmAnalytics,
      speciesBreakdown: null == speciesBreakdown
          ? _value.speciesBreakdown
          : speciesBreakdown // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
      stageDistribution: null == stageDistribution
          ? _value.stageDistribution
          : stageDistribution // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
    ) as $Val);
  }

  /// Create a copy of CrossFarmComparison
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FarmAnalyticsCopyWith<$Res> get averages {
    return $FarmAnalyticsCopyWith<$Res>(_value.averages, (value) {
      return _then(_value.copyWith(averages: value) as $Val);
    });
  }

  /// Create a copy of CrossFarmComparison
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FarmAnalyticsCopyWith<$Res> get topPerformer {
    return $FarmAnalyticsCopyWith<$Res>(_value.topPerformer, (value) {
      return _then(_value.copyWith(topPerformer: value) as $Val);
    });
  }

  /// Create a copy of CrossFarmComparison
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FarmAnalyticsCopyWith<$Res> get bottomPerformer {
    return $FarmAnalyticsCopyWith<$Res>(_value.bottomPerformer, (value) {
      return _then(_value.copyWith(bottomPerformer: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CrossFarmComparisonImplCopyWith<$Res>
    implements $CrossFarmComparisonCopyWith<$Res> {
  factory _$$CrossFarmComparisonImplCopyWith(_$CrossFarmComparisonImpl value,
          $Res Function(_$CrossFarmComparisonImpl) then) =
      __$$CrossFarmComparisonImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<FarmAnalytics> farms,
      FarmAnalytics averages,
      FarmAnalytics topPerformer,
      FarmAnalytics bottomPerformer,
      Map<String, double> speciesBreakdown,
      Map<String, int> stageDistribution});

  @override
  $FarmAnalyticsCopyWith<$Res> get averages;
  @override
  $FarmAnalyticsCopyWith<$Res> get topPerformer;
  @override
  $FarmAnalyticsCopyWith<$Res> get bottomPerformer;
}

/// @nodoc
class __$$CrossFarmComparisonImplCopyWithImpl<$Res>
    extends _$CrossFarmComparisonCopyWithImpl<$Res, _$CrossFarmComparisonImpl>
    implements _$$CrossFarmComparisonImplCopyWith<$Res> {
  __$$CrossFarmComparisonImplCopyWithImpl(_$CrossFarmComparisonImpl _value,
      $Res Function(_$CrossFarmComparisonImpl) _then)
      : super(_value, _then);

  /// Create a copy of CrossFarmComparison
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? farms = null,
    Object? averages = null,
    Object? topPerformer = null,
    Object? bottomPerformer = null,
    Object? speciesBreakdown = null,
    Object? stageDistribution = null,
  }) {
    return _then(_$CrossFarmComparisonImpl(
      farms: null == farms
          ? _value._farms
          : farms // ignore: cast_nullable_to_non_nullable
              as List<FarmAnalytics>,
      averages: null == averages
          ? _value.averages
          : averages // ignore: cast_nullable_to_non_nullable
              as FarmAnalytics,
      topPerformer: null == topPerformer
          ? _value.topPerformer
          : topPerformer // ignore: cast_nullable_to_non_nullable
              as FarmAnalytics,
      bottomPerformer: null == bottomPerformer
          ? _value.bottomPerformer
          : bottomPerformer // ignore: cast_nullable_to_non_nullable
              as FarmAnalytics,
      speciesBreakdown: null == speciesBreakdown
          ? _value._speciesBreakdown
          : speciesBreakdown // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
      stageDistribution: null == stageDistribution
          ? _value._stageDistribution
          : stageDistribution // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CrossFarmComparisonImpl implements _CrossFarmComparison {
  const _$CrossFarmComparisonImpl(
      {required final List<FarmAnalytics> farms,
      required this.averages,
      required this.topPerformer,
      required this.bottomPerformer,
      required final Map<String, double> speciesBreakdown,
      required final Map<String, int> stageDistribution})
      : _farms = farms,
        _speciesBreakdown = speciesBreakdown,
        _stageDistribution = stageDistribution;

  factory _$CrossFarmComparisonImpl.fromJson(Map<String, dynamic> json) =>
      _$$CrossFarmComparisonImplFromJson(json);

  final List<FarmAnalytics> _farms;
  @override
  List<FarmAnalytics> get farms {
    if (_farms is EqualUnmodifiableListView) return _farms;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_farms);
  }

  @override
  final FarmAnalytics averages;
  @override
  final FarmAnalytics topPerformer;
  @override
  final FarmAnalytics bottomPerformer;
  final Map<String, double> _speciesBreakdown;
  @override
  Map<String, double> get speciesBreakdown {
    if (_speciesBreakdown is EqualUnmodifiableMapView) return _speciesBreakdown;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_speciesBreakdown);
  }

  final Map<String, int> _stageDistribution;
  @override
  Map<String, int> get stageDistribution {
    if (_stageDistribution is EqualUnmodifiableMapView)
      return _stageDistribution;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_stageDistribution);
  }

  @override
  String toString() {
    return 'CrossFarmComparison(farms: $farms, averages: $averages, topPerformer: $topPerformer, bottomPerformer: $bottomPerformer, speciesBreakdown: $speciesBreakdown, stageDistribution: $stageDistribution)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CrossFarmComparisonImpl &&
            const DeepCollectionEquality().equals(other._farms, _farms) &&
            (identical(other.averages, averages) ||
                other.averages == averages) &&
            (identical(other.topPerformer, topPerformer) ||
                other.topPerformer == topPerformer) &&
            (identical(other.bottomPerformer, bottomPerformer) ||
                other.bottomPerformer == bottomPerformer) &&
            const DeepCollectionEquality()
                .equals(other._speciesBreakdown, _speciesBreakdown) &&
            const DeepCollectionEquality()
                .equals(other._stageDistribution, _stageDistribution));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_farms),
      averages,
      topPerformer,
      bottomPerformer,
      const DeepCollectionEquality().hash(_speciesBreakdown),
      const DeepCollectionEquality().hash(_stageDistribution));

  /// Create a copy of CrossFarmComparison
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CrossFarmComparisonImplCopyWith<_$CrossFarmComparisonImpl> get copyWith =>
      __$$CrossFarmComparisonImplCopyWithImpl<_$CrossFarmComparisonImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CrossFarmComparisonImplToJson(
      this,
    );
  }
}

abstract class _CrossFarmComparison implements CrossFarmComparison {
  const factory _CrossFarmComparison(
          {required final List<FarmAnalytics> farms,
          required final FarmAnalytics averages,
          required final FarmAnalytics topPerformer,
          required final FarmAnalytics bottomPerformer,
          required final Map<String, double> speciesBreakdown,
          required final Map<String, int> stageDistribution}) =
      _$CrossFarmComparisonImpl;

  factory _CrossFarmComparison.fromJson(Map<String, dynamic> json) =
      _$CrossFarmComparisonImpl.fromJson;

  @override
  List<FarmAnalytics> get farms;
  @override
  FarmAnalytics get averages;
  @override
  FarmAnalytics get topPerformer;
  @override
  FarmAnalytics get bottomPerformer;
  @override
  Map<String, double> get speciesBreakdown;
  @override
  Map<String, int> get stageDistribution;

  /// Create a copy of CrossFarmComparison
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CrossFarmComparisonImplCopyWith<_$CrossFarmComparisonImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DeviceInfo _$DeviceInfoFromJson(Map<String, dynamic> json) {
  return _DeviceInfo.fromJson(json);
}

/// @nodoc
mixin _$DeviceInfo {
  String get deviceId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;
  String? get farmId => throw _privateConstructorUsedError;
  DateTime? get lastConnected => throw _privateConstructorUsedError;

  /// Serializes this DeviceInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DeviceInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeviceInfoCopyWith<DeviceInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeviceInfoCopyWith<$Res> {
  factory $DeviceInfoCopyWith(
          DeviceInfo value, $Res Function(DeviceInfo) then) =
      _$DeviceInfoCopyWithImpl<$Res, DeviceInfo>;
  @useResult
  $Res call(
      {String deviceId,
      String name,
      String address,
      String? farmId,
      DateTime? lastConnected});
}

/// @nodoc
class _$DeviceInfoCopyWithImpl<$Res, $Val extends DeviceInfo>
    implements $DeviceInfoCopyWith<$Res> {
  _$DeviceInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeviceInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deviceId = null,
    Object? name = null,
    Object? address = null,
    Object? farmId = freezed,
    Object? lastConnected = freezed,
  }) {
    return _then(_value.copyWith(
      deviceId: null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      farmId: freezed == farmId
          ? _value.farmId
          : farmId // ignore: cast_nullable_to_non_nullable
              as String?,
      lastConnected: freezed == lastConnected
          ? _value.lastConnected
          : lastConnected // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DeviceInfoImplCopyWith<$Res>
    implements $DeviceInfoCopyWith<$Res> {
  factory _$$DeviceInfoImplCopyWith(
          _$DeviceInfoImpl value, $Res Function(_$DeviceInfoImpl) then) =
      __$$DeviceInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String deviceId,
      String name,
      String address,
      String? farmId,
      DateTime? lastConnected});
}

/// @nodoc
class __$$DeviceInfoImplCopyWithImpl<$Res>
    extends _$DeviceInfoCopyWithImpl<$Res, _$DeviceInfoImpl>
    implements _$$DeviceInfoImplCopyWith<$Res> {
  __$$DeviceInfoImplCopyWithImpl(
      _$DeviceInfoImpl _value, $Res Function(_$DeviceInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of DeviceInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? deviceId = null,
    Object? name = null,
    Object? address = null,
    Object? farmId = freezed,
    Object? lastConnected = freezed,
  }) {
    return _then(_$DeviceInfoImpl(
      deviceId: null == deviceId
          ? _value.deviceId
          : deviceId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      farmId: freezed == farmId
          ? _value.farmId
          : farmId // ignore: cast_nullable_to_non_nullable
              as String?,
      lastConnected: freezed == lastConnected
          ? _value.lastConnected
          : lastConnected // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DeviceInfoImpl implements _DeviceInfo {
  const _$DeviceInfoImpl(
      {required this.deviceId,
      required this.name,
      required this.address,
      this.farmId,
      this.lastConnected});

  factory _$DeviceInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeviceInfoImplFromJson(json);

  @override
  final String deviceId;
  @override
  final String name;
  @override
  final String address;
  @override
  final String? farmId;
  @override
  final DateTime? lastConnected;

  @override
  String toString() {
    return 'DeviceInfo(deviceId: $deviceId, name: $name, address: $address, farmId: $farmId, lastConnected: $lastConnected)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeviceInfoImpl &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.farmId, farmId) || other.farmId == farmId) &&
            (identical(other.lastConnected, lastConnected) ||
                other.lastConnected == lastConnected));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, deviceId, name, address, farmId, lastConnected);

  /// Create a copy of DeviceInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeviceInfoImplCopyWith<_$DeviceInfoImpl> get copyWith =>
      __$$DeviceInfoImplCopyWithImpl<_$DeviceInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DeviceInfoImplToJson(
      this,
    );
  }
}

abstract class _DeviceInfo implements DeviceInfo {
  const factory _DeviceInfo(
      {required final String deviceId,
      required final String name,
      required final String address,
      final String? farmId,
      final DateTime? lastConnected}) = _$DeviceInfoImpl;

  factory _DeviceInfo.fromJson(Map<String, dynamic> json) =
      _$DeviceInfoImpl.fromJson;

  @override
  String get deviceId;
  @override
  String get name;
  @override
  String get address;
  @override
  String? get farmId;
  @override
  DateTime? get lastConnected;

  /// Create a copy of DeviceInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeviceInfoImplCopyWith<_$DeviceInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
