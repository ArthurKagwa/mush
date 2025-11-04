// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'threshold_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ThresholdProfile _$ThresholdProfileFromJson(Map<String, dynamic> json) {
  return _ThresholdProfile.fromJson(json);
}

/// @nodoc
mixin _$ThresholdProfile {
  double get tempMin => throw _privateConstructorUsedError; // Celsius
  double get tempMax => throw _privateConstructorUsedError; // Celsius
  double get rhMin => throw _privateConstructorUsedError; // Percentage (0-100)
  int get co2Max => throw _privateConstructorUsedError; // PPM
  LightMode get lightMode =>
      throw _privateConstructorUsedError; // OFF, ON, CYCLE
  int get onMinutes => throw _privateConstructorUsedError; // For CYCLE mode
  int get offMinutes => throw _privateConstructorUsedError; // For CYCLE mode
  int get expectedDays => throw _privateConstructorUsedError; // Stage duration
  String? get notes => throw _privateConstructorUsedError;

  /// Serializes this ThresholdProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ThresholdProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ThresholdProfileCopyWith<ThresholdProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ThresholdProfileCopyWith<$Res> {
  factory $ThresholdProfileCopyWith(
          ThresholdProfile value, $Res Function(ThresholdProfile) then) =
      _$ThresholdProfileCopyWithImpl<$Res, ThresholdProfile>;
  @useResult
  $Res call(
      {double tempMin,
      double tempMax,
      double rhMin,
      int co2Max,
      LightMode lightMode,
      int onMinutes,
      int offMinutes,
      int expectedDays,
      String? notes});
}

/// @nodoc
class _$ThresholdProfileCopyWithImpl<$Res, $Val extends ThresholdProfile>
    implements $ThresholdProfileCopyWith<$Res> {
  _$ThresholdProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ThresholdProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tempMin = null,
    Object? tempMax = null,
    Object? rhMin = null,
    Object? co2Max = null,
    Object? lightMode = null,
    Object? onMinutes = null,
    Object? offMinutes = null,
    Object? expectedDays = null,
    Object? notes = freezed,
  }) {
    return _then(_value.copyWith(
      tempMin: null == tempMin
          ? _value.tempMin
          : tempMin // ignore: cast_nullable_to_non_nullable
              as double,
      tempMax: null == tempMax
          ? _value.tempMax
          : tempMax // ignore: cast_nullable_to_non_nullable
              as double,
      rhMin: null == rhMin
          ? _value.rhMin
          : rhMin // ignore: cast_nullable_to_non_nullable
              as double,
      co2Max: null == co2Max
          ? _value.co2Max
          : co2Max // ignore: cast_nullable_to_non_nullable
              as int,
      lightMode: null == lightMode
          ? _value.lightMode
          : lightMode // ignore: cast_nullable_to_non_nullable
              as LightMode,
      onMinutes: null == onMinutes
          ? _value.onMinutes
          : onMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      offMinutes: null == offMinutes
          ? _value.offMinutes
          : offMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      expectedDays: null == expectedDays
          ? _value.expectedDays
          : expectedDays // ignore: cast_nullable_to_non_nullable
              as int,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ThresholdProfileImplCopyWith<$Res>
    implements $ThresholdProfileCopyWith<$Res> {
  factory _$$ThresholdProfileImplCopyWith(_$ThresholdProfileImpl value,
          $Res Function(_$ThresholdProfileImpl) then) =
      __$$ThresholdProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double tempMin,
      double tempMax,
      double rhMin,
      int co2Max,
      LightMode lightMode,
      int onMinutes,
      int offMinutes,
      int expectedDays,
      String? notes});
}

/// @nodoc
class __$$ThresholdProfileImplCopyWithImpl<$Res>
    extends _$ThresholdProfileCopyWithImpl<$Res, _$ThresholdProfileImpl>
    implements _$$ThresholdProfileImplCopyWith<$Res> {
  __$$ThresholdProfileImplCopyWithImpl(_$ThresholdProfileImpl _value,
      $Res Function(_$ThresholdProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of ThresholdProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tempMin = null,
    Object? tempMax = null,
    Object? rhMin = null,
    Object? co2Max = null,
    Object? lightMode = null,
    Object? onMinutes = null,
    Object? offMinutes = null,
    Object? expectedDays = null,
    Object? notes = freezed,
  }) {
    return _then(_$ThresholdProfileImpl(
      tempMin: null == tempMin
          ? _value.tempMin
          : tempMin // ignore: cast_nullable_to_non_nullable
              as double,
      tempMax: null == tempMax
          ? _value.tempMax
          : tempMax // ignore: cast_nullable_to_non_nullable
              as double,
      rhMin: null == rhMin
          ? _value.rhMin
          : rhMin // ignore: cast_nullable_to_non_nullable
              as double,
      co2Max: null == co2Max
          ? _value.co2Max
          : co2Max // ignore: cast_nullable_to_non_nullable
              as int,
      lightMode: null == lightMode
          ? _value.lightMode
          : lightMode // ignore: cast_nullable_to_non_nullable
              as LightMode,
      onMinutes: null == onMinutes
          ? _value.onMinutes
          : onMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      offMinutes: null == offMinutes
          ? _value.offMinutes
          : offMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      expectedDays: null == expectedDays
          ? _value.expectedDays
          : expectedDays // ignore: cast_nullable_to_non_nullable
              as int,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ThresholdProfileImpl implements _ThresholdProfile {
  const _$ThresholdProfileImpl(
      {required this.tempMin,
      required this.tempMax,
      required this.rhMin,
      required this.co2Max,
      required this.lightMode,
      this.onMinutes = 0,
      this.offMinutes = 0,
      this.expectedDays = 0,
      this.notes});

  factory _$ThresholdProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$ThresholdProfileImplFromJson(json);

  @override
  final double tempMin;
// Celsius
  @override
  final double tempMax;
// Celsius
  @override
  final double rhMin;
// Percentage (0-100)
  @override
  final int co2Max;
// PPM
  @override
  final LightMode lightMode;
// OFF, ON, CYCLE
  @override
  @JsonKey()
  final int onMinutes;
// For CYCLE mode
  @override
  @JsonKey()
  final int offMinutes;
// For CYCLE mode
  @override
  @JsonKey()
  final int expectedDays;
// Stage duration
  @override
  final String? notes;

  @override
  String toString() {
    return 'ThresholdProfile(tempMin: $tempMin, tempMax: $tempMax, rhMin: $rhMin, co2Max: $co2Max, lightMode: $lightMode, onMinutes: $onMinutes, offMinutes: $offMinutes, expectedDays: $expectedDays, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ThresholdProfileImpl &&
            (identical(other.tempMin, tempMin) || other.tempMin == tempMin) &&
            (identical(other.tempMax, tempMax) || other.tempMax == tempMax) &&
            (identical(other.rhMin, rhMin) || other.rhMin == rhMin) &&
            (identical(other.co2Max, co2Max) || other.co2Max == co2Max) &&
            (identical(other.lightMode, lightMode) ||
                other.lightMode == lightMode) &&
            (identical(other.onMinutes, onMinutes) ||
                other.onMinutes == onMinutes) &&
            (identical(other.offMinutes, offMinutes) ||
                other.offMinutes == offMinutes) &&
            (identical(other.expectedDays, expectedDays) ||
                other.expectedDays == expectedDays) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, tempMin, tempMax, rhMin, co2Max,
      lightMode, onMinutes, offMinutes, expectedDays, notes);

  /// Create a copy of ThresholdProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ThresholdProfileImplCopyWith<_$ThresholdProfileImpl> get copyWith =>
      __$$ThresholdProfileImplCopyWithImpl<_$ThresholdProfileImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ThresholdProfileImplToJson(
      this,
    );
  }
}

abstract class _ThresholdProfile implements ThresholdProfile {
  const factory _ThresholdProfile(
      {required final double tempMin,
      required final double tempMax,
      required final double rhMin,
      required final int co2Max,
      required final LightMode lightMode,
      final int onMinutes,
      final int offMinutes,
      final int expectedDays,
      final String? notes}) = _$ThresholdProfileImpl;

  factory _ThresholdProfile.fromJson(Map<String, dynamic> json) =
      _$ThresholdProfileImpl.fromJson;

  @override
  double get tempMin; // Celsius
  @override
  double get tempMax; // Celsius
  @override
  double get rhMin; // Percentage (0-100)
  @override
  int get co2Max; // PPM
  @override
  LightMode get lightMode; // OFF, ON, CYCLE
  @override
  int get onMinutes; // For CYCLE mode
  @override
  int get offMinutes; // For CYCLE mode
  @override
  int get expectedDays; // Stage duration
  @override
  String? get notes;

  /// Create a copy of ThresholdProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ThresholdProfileImplCopyWith<_$ThresholdProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FarmThresholds _$FarmThresholdsFromJson(Map<String, dynamic> json) {
  return _FarmThresholds.fromJson(json);
}

/// @nodoc
mixin _$FarmThresholds {
  String get farmId => throw _privateConstructorUsedError;
  Species get species => throw _privateConstructorUsedError;
  Map<GrowthStage, ThresholdProfile> get profiles =>
      throw _privateConstructorUsedError;
  DateTime? get lastModified => throw _privateConstructorUsedError;
  bool? get isCustom => throw _privateConstructorUsedError;

  /// Serializes this FarmThresholds to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FarmThresholds
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FarmThresholdsCopyWith<FarmThresholds> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FarmThresholdsCopyWith<$Res> {
  factory $FarmThresholdsCopyWith(
          FarmThresholds value, $Res Function(FarmThresholds) then) =
      _$FarmThresholdsCopyWithImpl<$Res, FarmThresholds>;
  @useResult
  $Res call(
      {String farmId,
      Species species,
      Map<GrowthStage, ThresholdProfile> profiles,
      DateTime? lastModified,
      bool? isCustom});
}

/// @nodoc
class _$FarmThresholdsCopyWithImpl<$Res, $Val extends FarmThresholds>
    implements $FarmThresholdsCopyWith<$Res> {
  _$FarmThresholdsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FarmThresholds
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? farmId = null,
    Object? species = null,
    Object? profiles = null,
    Object? lastModified = freezed,
    Object? isCustom = freezed,
  }) {
    return _then(_value.copyWith(
      farmId: null == farmId
          ? _value.farmId
          : farmId // ignore: cast_nullable_to_non_nullable
              as String,
      species: null == species
          ? _value.species
          : species // ignore: cast_nullable_to_non_nullable
              as Species,
      profiles: null == profiles
          ? _value.profiles
          : profiles // ignore: cast_nullable_to_non_nullable
              as Map<GrowthStage, ThresholdProfile>,
      lastModified: freezed == lastModified
          ? _value.lastModified
          : lastModified // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isCustom: freezed == isCustom
          ? _value.isCustom
          : isCustom // ignore: cast_nullable_to_non_nullable
              as bool?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FarmThresholdsImplCopyWith<$Res>
    implements $FarmThresholdsCopyWith<$Res> {
  factory _$$FarmThresholdsImplCopyWith(_$FarmThresholdsImpl value,
          $Res Function(_$FarmThresholdsImpl) then) =
      __$$FarmThresholdsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String farmId,
      Species species,
      Map<GrowthStage, ThresholdProfile> profiles,
      DateTime? lastModified,
      bool? isCustom});
}

/// @nodoc
class __$$FarmThresholdsImplCopyWithImpl<$Res>
    extends _$FarmThresholdsCopyWithImpl<$Res, _$FarmThresholdsImpl>
    implements _$$FarmThresholdsImplCopyWith<$Res> {
  __$$FarmThresholdsImplCopyWithImpl(
      _$FarmThresholdsImpl _value, $Res Function(_$FarmThresholdsImpl) _then)
      : super(_value, _then);

  /// Create a copy of FarmThresholds
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? farmId = null,
    Object? species = null,
    Object? profiles = null,
    Object? lastModified = freezed,
    Object? isCustom = freezed,
  }) {
    return _then(_$FarmThresholdsImpl(
      farmId: null == farmId
          ? _value.farmId
          : farmId // ignore: cast_nullable_to_non_nullable
              as String,
      species: null == species
          ? _value.species
          : species // ignore: cast_nullable_to_non_nullable
              as Species,
      profiles: null == profiles
          ? _value._profiles
          : profiles // ignore: cast_nullable_to_non_nullable
              as Map<GrowthStage, ThresholdProfile>,
      lastModified: freezed == lastModified
          ? _value.lastModified
          : lastModified // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isCustom: freezed == isCustom
          ? _value.isCustom
          : isCustom // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FarmThresholdsImpl implements _FarmThresholds {
  const _$FarmThresholdsImpl(
      {required this.farmId,
      required this.species,
      required final Map<GrowthStage, ThresholdProfile> profiles,
      this.lastModified,
      this.isCustom = false})
      : _profiles = profiles;

  factory _$FarmThresholdsImpl.fromJson(Map<String, dynamic> json) =>
      _$$FarmThresholdsImplFromJson(json);

  @override
  final String farmId;
  @override
  final Species species;
  final Map<GrowthStage, ThresholdProfile> _profiles;
  @override
  Map<GrowthStage, ThresholdProfile> get profiles {
    if (_profiles is EqualUnmodifiableMapView) return _profiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_profiles);
  }

  @override
  final DateTime? lastModified;
  @override
  @JsonKey()
  final bool? isCustom;

  @override
  String toString() {
    return 'FarmThresholds(farmId: $farmId, species: $species, profiles: $profiles, lastModified: $lastModified, isCustom: $isCustom)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FarmThresholdsImpl &&
            (identical(other.farmId, farmId) || other.farmId == farmId) &&
            (identical(other.species, species) || other.species == species) &&
            const DeepCollectionEquality().equals(other._profiles, _profiles) &&
            (identical(other.lastModified, lastModified) ||
                other.lastModified == lastModified) &&
            (identical(other.isCustom, isCustom) ||
                other.isCustom == isCustom));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, farmId, species,
      const DeepCollectionEquality().hash(_profiles), lastModified, isCustom);

  /// Create a copy of FarmThresholds
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FarmThresholdsImplCopyWith<_$FarmThresholdsImpl> get copyWith =>
      __$$FarmThresholdsImplCopyWithImpl<_$FarmThresholdsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FarmThresholdsImplToJson(
      this,
    );
  }
}

abstract class _FarmThresholds implements FarmThresholds {
  const factory _FarmThresholds(
      {required final String farmId,
      required final Species species,
      required final Map<GrowthStage, ThresholdProfile> profiles,
      final DateTime? lastModified,
      final bool? isCustom}) = _$FarmThresholdsImpl;

  factory _FarmThresholds.fromJson(Map<String, dynamic> json) =
      _$FarmThresholdsImpl.fromJson;

  @override
  String get farmId;
  @override
  Species get species;
  @override
  Map<GrowthStage, ThresholdProfile> get profiles;
  @override
  DateTime? get lastModified;
  @override
  bool? get isCustom;

  /// Create a copy of FarmThresholds
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FarmThresholdsImplCopyWith<_$FarmThresholdsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EnvironmentalData _$EnvironmentalDataFromJson(Map<String, dynamic> json) {
  return _EnvironmentalData.fromJson(json);
}

/// @nodoc
mixin _$EnvironmentalData {
  int get co2Ppm => throw _privateConstructorUsedError;
  double get temperatureC => throw _privateConstructorUsedError;
  double get relativeHumidity => throw _privateConstructorUsedError;
  int get lightRaw => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Serializes this EnvironmentalData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EnvironmentalData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EnvironmentalDataCopyWith<EnvironmentalData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EnvironmentalDataCopyWith<$Res> {
  factory $EnvironmentalDataCopyWith(
          EnvironmentalData value, $Res Function(EnvironmentalData) then) =
      _$EnvironmentalDataCopyWithImpl<$Res, EnvironmentalData>;
  @useResult
  $Res call(
      {int co2Ppm,
      double temperatureC,
      double relativeHumidity,
      int lightRaw,
      DateTime timestamp});
}

/// @nodoc
class _$EnvironmentalDataCopyWithImpl<$Res, $Val extends EnvironmentalData>
    implements $EnvironmentalDataCopyWith<$Res> {
  _$EnvironmentalDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EnvironmentalData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? co2Ppm = null,
    Object? temperatureC = null,
    Object? relativeHumidity = null,
    Object? lightRaw = null,
    Object? timestamp = null,
  }) {
    return _then(_value.copyWith(
      co2Ppm: null == co2Ppm
          ? _value.co2Ppm
          : co2Ppm // ignore: cast_nullable_to_non_nullable
              as int,
      temperatureC: null == temperatureC
          ? _value.temperatureC
          : temperatureC // ignore: cast_nullable_to_non_nullable
              as double,
      relativeHumidity: null == relativeHumidity
          ? _value.relativeHumidity
          : relativeHumidity // ignore: cast_nullable_to_non_nullable
              as double,
      lightRaw: null == lightRaw
          ? _value.lightRaw
          : lightRaw // ignore: cast_nullable_to_non_nullable
              as int,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EnvironmentalDataImplCopyWith<$Res>
    implements $EnvironmentalDataCopyWith<$Res> {
  factory _$$EnvironmentalDataImplCopyWith(_$EnvironmentalDataImpl value,
          $Res Function(_$EnvironmentalDataImpl) then) =
      __$$EnvironmentalDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int co2Ppm,
      double temperatureC,
      double relativeHumidity,
      int lightRaw,
      DateTime timestamp});
}

/// @nodoc
class __$$EnvironmentalDataImplCopyWithImpl<$Res>
    extends _$EnvironmentalDataCopyWithImpl<$Res, _$EnvironmentalDataImpl>
    implements _$$EnvironmentalDataImplCopyWith<$Res> {
  __$$EnvironmentalDataImplCopyWithImpl(_$EnvironmentalDataImpl _value,
      $Res Function(_$EnvironmentalDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of EnvironmentalData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? co2Ppm = null,
    Object? temperatureC = null,
    Object? relativeHumidity = null,
    Object? lightRaw = null,
    Object? timestamp = null,
  }) {
    return _then(_$EnvironmentalDataImpl(
      co2Ppm: null == co2Ppm
          ? _value.co2Ppm
          : co2Ppm // ignore: cast_nullable_to_non_nullable
              as int,
      temperatureC: null == temperatureC
          ? _value.temperatureC
          : temperatureC // ignore: cast_nullable_to_non_nullable
              as double,
      relativeHumidity: null == relativeHumidity
          ? _value.relativeHumidity
          : relativeHumidity // ignore: cast_nullable_to_non_nullable
              as double,
      lightRaw: null == lightRaw
          ? _value.lightRaw
          : lightRaw // ignore: cast_nullable_to_non_nullable
              as int,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EnvironmentalDataImpl implements _EnvironmentalData {
  const _$EnvironmentalDataImpl(
      {required this.co2Ppm,
      required this.temperatureC,
      required this.relativeHumidity,
      required this.lightRaw,
      required this.timestamp});

  factory _$EnvironmentalDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$EnvironmentalDataImplFromJson(json);

  @override
  final int co2Ppm;
  @override
  final double temperatureC;
  @override
  final double relativeHumidity;
  @override
  final int lightRaw;
  @override
  final DateTime timestamp;

  @override
  String toString() {
    return 'EnvironmentalData(co2Ppm: $co2Ppm, temperatureC: $temperatureC, relativeHumidity: $relativeHumidity, lightRaw: $lightRaw, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EnvironmentalDataImpl &&
            (identical(other.co2Ppm, co2Ppm) || other.co2Ppm == co2Ppm) &&
            (identical(other.temperatureC, temperatureC) ||
                other.temperatureC == temperatureC) &&
            (identical(other.relativeHumidity, relativeHumidity) ||
                other.relativeHumidity == relativeHumidity) &&
            (identical(other.lightRaw, lightRaw) ||
                other.lightRaw == lightRaw) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, co2Ppm, temperatureC, relativeHumidity, lightRaw, timestamp);

  /// Create a copy of EnvironmentalData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EnvironmentalDataImplCopyWith<_$EnvironmentalDataImpl> get copyWith =>
      __$$EnvironmentalDataImplCopyWithImpl<_$EnvironmentalDataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EnvironmentalDataImplToJson(
      this,
    );
  }
}

abstract class _EnvironmentalData implements EnvironmentalData {
  const factory _EnvironmentalData(
      {required final int co2Ppm,
      required final double temperatureC,
      required final double relativeHumidity,
      required final int lightRaw,
      required final DateTime timestamp}) = _$EnvironmentalDataImpl;

  factory _EnvironmentalData.fromJson(Map<String, dynamic> json) =
      _$EnvironmentalDataImpl.fromJson;

  @override
  int get co2Ppm;
  @override
  double get temperatureC;
  @override
  double get relativeHumidity;
  @override
  int get lightRaw;
  @override
  DateTime get timestamp;

  /// Create a copy of EnvironmentalData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EnvironmentalDataImplCopyWith<_$EnvironmentalDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ControlTargets _$ControlTargetsFromJson(Map<String, dynamic> json) {
  return _ControlTargets.fromJson(json);
}

/// @nodoc
mixin _$ControlTargets {
  double get tempMin => throw _privateConstructorUsedError;
  double get tempMax => throw _privateConstructorUsedError;
  double get rhMin => throw _privateConstructorUsedError;
  int get co2Max => throw _privateConstructorUsedError;
  LightMode get lightMode => throw _privateConstructorUsedError;
  int get onMinutes => throw _privateConstructorUsedError;
  int get offMinutes => throw _privateConstructorUsedError;

  /// Serializes this ControlTargets to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ControlTargets
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ControlTargetsCopyWith<ControlTargets> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ControlTargetsCopyWith<$Res> {
  factory $ControlTargetsCopyWith(
          ControlTargets value, $Res Function(ControlTargets) then) =
      _$ControlTargetsCopyWithImpl<$Res, ControlTargets>;
  @useResult
  $Res call(
      {double tempMin,
      double tempMax,
      double rhMin,
      int co2Max,
      LightMode lightMode,
      int onMinutes,
      int offMinutes});
}

/// @nodoc
class _$ControlTargetsCopyWithImpl<$Res, $Val extends ControlTargets>
    implements $ControlTargetsCopyWith<$Res> {
  _$ControlTargetsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ControlTargets
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tempMin = null,
    Object? tempMax = null,
    Object? rhMin = null,
    Object? co2Max = null,
    Object? lightMode = null,
    Object? onMinutes = null,
    Object? offMinutes = null,
  }) {
    return _then(_value.copyWith(
      tempMin: null == tempMin
          ? _value.tempMin
          : tempMin // ignore: cast_nullable_to_non_nullable
              as double,
      tempMax: null == tempMax
          ? _value.tempMax
          : tempMax // ignore: cast_nullable_to_non_nullable
              as double,
      rhMin: null == rhMin
          ? _value.rhMin
          : rhMin // ignore: cast_nullable_to_non_nullable
              as double,
      co2Max: null == co2Max
          ? _value.co2Max
          : co2Max // ignore: cast_nullable_to_non_nullable
              as int,
      lightMode: null == lightMode
          ? _value.lightMode
          : lightMode // ignore: cast_nullable_to_non_nullable
              as LightMode,
      onMinutes: null == onMinutes
          ? _value.onMinutes
          : onMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      offMinutes: null == offMinutes
          ? _value.offMinutes
          : offMinutes // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ControlTargetsImplCopyWith<$Res>
    implements $ControlTargetsCopyWith<$Res> {
  factory _$$ControlTargetsImplCopyWith(_$ControlTargetsImpl value,
          $Res Function(_$ControlTargetsImpl) then) =
      __$$ControlTargetsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double tempMin,
      double tempMax,
      double rhMin,
      int co2Max,
      LightMode lightMode,
      int onMinutes,
      int offMinutes});
}

/// @nodoc
class __$$ControlTargetsImplCopyWithImpl<$Res>
    extends _$ControlTargetsCopyWithImpl<$Res, _$ControlTargetsImpl>
    implements _$$ControlTargetsImplCopyWith<$Res> {
  __$$ControlTargetsImplCopyWithImpl(
      _$ControlTargetsImpl _value, $Res Function(_$ControlTargetsImpl) _then)
      : super(_value, _then);

  /// Create a copy of ControlTargets
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tempMin = null,
    Object? tempMax = null,
    Object? rhMin = null,
    Object? co2Max = null,
    Object? lightMode = null,
    Object? onMinutes = null,
    Object? offMinutes = null,
  }) {
    return _then(_$ControlTargetsImpl(
      tempMin: null == tempMin
          ? _value.tempMin
          : tempMin // ignore: cast_nullable_to_non_nullable
              as double,
      tempMax: null == tempMax
          ? _value.tempMax
          : tempMax // ignore: cast_nullable_to_non_nullable
              as double,
      rhMin: null == rhMin
          ? _value.rhMin
          : rhMin // ignore: cast_nullable_to_non_nullable
              as double,
      co2Max: null == co2Max
          ? _value.co2Max
          : co2Max // ignore: cast_nullable_to_non_nullable
              as int,
      lightMode: null == lightMode
          ? _value.lightMode
          : lightMode // ignore: cast_nullable_to_non_nullable
              as LightMode,
      onMinutes: null == onMinutes
          ? _value.onMinutes
          : onMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      offMinutes: null == offMinutes
          ? _value.offMinutes
          : offMinutes // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ControlTargetsImpl implements _ControlTargets {
  const _$ControlTargetsImpl(
      {required this.tempMin,
      required this.tempMax,
      required this.rhMin,
      required this.co2Max,
      required this.lightMode,
      required this.onMinutes,
      required this.offMinutes});

  factory _$ControlTargetsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ControlTargetsImplFromJson(json);

  @override
  final double tempMin;
  @override
  final double tempMax;
  @override
  final double rhMin;
  @override
  final int co2Max;
  @override
  final LightMode lightMode;
  @override
  final int onMinutes;
  @override
  final int offMinutes;

  @override
  String toString() {
    return 'ControlTargets(tempMin: $tempMin, tempMax: $tempMax, rhMin: $rhMin, co2Max: $co2Max, lightMode: $lightMode, onMinutes: $onMinutes, offMinutes: $offMinutes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ControlTargetsImpl &&
            (identical(other.tempMin, tempMin) || other.tempMin == tempMin) &&
            (identical(other.tempMax, tempMax) || other.tempMax == tempMax) &&
            (identical(other.rhMin, rhMin) || other.rhMin == rhMin) &&
            (identical(other.co2Max, co2Max) || other.co2Max == co2Max) &&
            (identical(other.lightMode, lightMode) ||
                other.lightMode == lightMode) &&
            (identical(other.onMinutes, onMinutes) ||
                other.onMinutes == onMinutes) &&
            (identical(other.offMinutes, offMinutes) ||
                other.offMinutes == offMinutes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, tempMin, tempMax, rhMin, co2Max,
      lightMode, onMinutes, offMinutes);

  /// Create a copy of ControlTargets
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ControlTargetsImplCopyWith<_$ControlTargetsImpl> get copyWith =>
      __$$ControlTargetsImplCopyWithImpl<_$ControlTargetsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ControlTargetsImplToJson(
      this,
    );
  }
}

abstract class _ControlTargets implements ControlTargets {
  const factory _ControlTargets(
      {required final double tempMin,
      required final double tempMax,
      required final double rhMin,
      required final int co2Max,
      required final LightMode lightMode,
      required final int onMinutes,
      required final int offMinutes}) = _$ControlTargetsImpl;

  factory _ControlTargets.fromJson(Map<String, dynamic> json) =
      _$ControlTargetsImpl.fromJson;

  @override
  double get tempMin;
  @override
  double get tempMax;
  @override
  double get rhMin;
  @override
  int get co2Max;
  @override
  LightMode get lightMode;
  @override
  int get onMinutes;
  @override
  int get offMinutes;

  /// Create a copy of ControlTargets
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ControlTargetsImplCopyWith<_$ControlTargetsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StageState _$StageStateFromJson(Map<String, dynamic> json) {
  return _StageState.fromJson(json);
}

/// @nodoc
mixin _$StageState {
  ControlMode get mode => throw _privateConstructorUsedError;
  Species get species => throw _privateConstructorUsedError;
  GrowthStage get stage => throw _privateConstructorUsedError;
  DateTime get stageStartTime => throw _privateConstructorUsedError;
  int get expectedDays => throw _privateConstructorUsedError;

  /// Serializes this StageState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StageState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StageStateCopyWith<StageState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StageStateCopyWith<$Res> {
  factory $StageStateCopyWith(
          StageState value, $Res Function(StageState) then) =
      _$StageStateCopyWithImpl<$Res, StageState>;
  @useResult
  $Res call(
      {ControlMode mode,
      Species species,
      GrowthStage stage,
      DateTime stageStartTime,
      int expectedDays});
}

/// @nodoc
class _$StageStateCopyWithImpl<$Res, $Val extends StageState>
    implements $StageStateCopyWith<$Res> {
  _$StageStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StageState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mode = null,
    Object? species = null,
    Object? stage = null,
    Object? stageStartTime = null,
    Object? expectedDays = null,
  }) {
    return _then(_value.copyWith(
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as ControlMode,
      species: null == species
          ? _value.species
          : species // ignore: cast_nullable_to_non_nullable
              as Species,
      stage: null == stage
          ? _value.stage
          : stage // ignore: cast_nullable_to_non_nullable
              as GrowthStage,
      stageStartTime: null == stageStartTime
          ? _value.stageStartTime
          : stageStartTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      expectedDays: null == expectedDays
          ? _value.expectedDays
          : expectedDays // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StageStateImplCopyWith<$Res>
    implements $StageStateCopyWith<$Res> {
  factory _$$StageStateImplCopyWith(
          _$StageStateImpl value, $Res Function(_$StageStateImpl) then) =
      __$$StageStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ControlMode mode,
      Species species,
      GrowthStage stage,
      DateTime stageStartTime,
      int expectedDays});
}

/// @nodoc
class __$$StageStateImplCopyWithImpl<$Res>
    extends _$StageStateCopyWithImpl<$Res, _$StageStateImpl>
    implements _$$StageStateImplCopyWith<$Res> {
  __$$StageStateImplCopyWithImpl(
      _$StageStateImpl _value, $Res Function(_$StageStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of StageState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mode = null,
    Object? species = null,
    Object? stage = null,
    Object? stageStartTime = null,
    Object? expectedDays = null,
  }) {
    return _then(_$StageStateImpl(
      mode: null == mode
          ? _value.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as ControlMode,
      species: null == species
          ? _value.species
          : species // ignore: cast_nullable_to_non_nullable
              as Species,
      stage: null == stage
          ? _value.stage
          : stage // ignore: cast_nullable_to_non_nullable
              as GrowthStage,
      stageStartTime: null == stageStartTime
          ? _value.stageStartTime
          : stageStartTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      expectedDays: null == expectedDays
          ? _value.expectedDays
          : expectedDays // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StageStateImpl implements _StageState {
  const _$StageStateImpl(
      {required this.mode,
      required this.species,
      required this.stage,
      required this.stageStartTime,
      required this.expectedDays});

  factory _$StageStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$StageStateImplFromJson(json);

  @override
  final ControlMode mode;
  @override
  final Species species;
  @override
  final GrowthStage stage;
  @override
  final DateTime stageStartTime;
  @override
  final int expectedDays;

  @override
  String toString() {
    return 'StageState(mode: $mode, species: $species, stage: $stage, stageStartTime: $stageStartTime, expectedDays: $expectedDays)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StageStateImpl &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.species, species) || other.species == species) &&
            (identical(other.stage, stage) || other.stage == stage) &&
            (identical(other.stageStartTime, stageStartTime) ||
                other.stageStartTime == stageStartTime) &&
            (identical(other.expectedDays, expectedDays) ||
                other.expectedDays == expectedDays));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, mode, species, stage, stageStartTime, expectedDays);

  /// Create a copy of StageState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StageStateImplCopyWith<_$StageStateImpl> get copyWith =>
      __$$StageStateImplCopyWithImpl<_$StageStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StageStateImplToJson(
      this,
    );
  }
}

abstract class _StageState implements StageState {
  const factory _StageState(
      {required final ControlMode mode,
      required final Species species,
      required final GrowthStage stage,
      required final DateTime stageStartTime,
      required final int expectedDays}) = _$StageStateImpl;

  factory _StageState.fromJson(Map<String, dynamic> json) =
      _$StageStateImpl.fromJson;

  @override
  ControlMode get mode;
  @override
  Species get species;
  @override
  GrowthStage get stage;
  @override
  DateTime get stageStartTime;
  @override
  int get expectedDays;

  /// Create a copy of StageState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StageStateImplCopyWith<_$StageStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
