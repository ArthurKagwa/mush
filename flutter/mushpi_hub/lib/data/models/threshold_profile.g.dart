// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'threshold_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ThresholdProfileImpl _$$ThresholdProfileImplFromJson(
        Map<String, dynamic> json) =>
    _$ThresholdProfileImpl(
      tempMin: (json['tempMin'] as num).toDouble(),
      tempMax: (json['tempMax'] as num).toDouble(),
      rhMin: (json['rhMin'] as num).toDouble(),
      co2Max: (json['co2Max'] as num).toInt(),
      lightMode: $enumDecode(_$LightModeEnumMap, json['lightMode']),
      onMinutes: (json['onMinutes'] as num?)?.toInt() ?? 0,
      offMinutes: (json['offMinutes'] as num?)?.toInt() ?? 0,
      expectedDays: (json['expectedDays'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$$ThresholdProfileImplToJson(
        _$ThresholdProfileImpl instance) =>
    <String, dynamic>{
      'tempMin': instance.tempMin,
      'tempMax': instance.tempMax,
      'rhMin': instance.rhMin,
      'co2Max': instance.co2Max,
      'lightMode': _$LightModeEnumMap[instance.lightMode]!,
      'onMinutes': instance.onMinutes,
      'offMinutes': instance.offMinutes,
      'expectedDays': instance.expectedDays,
      'notes': instance.notes,
    };

const _$LightModeEnumMap = {
  LightMode.off: 'off',
  LightMode.on: 'on',
  LightMode.cycle: 'cycle',
};

_$FarmThresholdsImpl _$$FarmThresholdsImplFromJson(Map<String, dynamic> json) =>
    _$FarmThresholdsImpl(
      farmId: json['farmId'] as String,
      species: $enumDecode(_$SpeciesEnumMap, json['species']),
      profiles: (json['profiles'] as Map<String, dynamic>).map(
        (k, e) => MapEntry($enumDecode(_$GrowthStageEnumMap, k),
            ThresholdProfile.fromJson(e as Map<String, dynamic>)),
      ),
      lastModified: json['lastModified'] == null
          ? null
          : DateTime.parse(json['lastModified'] as String),
      isCustom: json['isCustom'] as bool? ?? false,
    );

Map<String, dynamic> _$$FarmThresholdsImplToJson(
        _$FarmThresholdsImpl instance) =>
    <String, dynamic>{
      'farmId': instance.farmId,
      'species': _$SpeciesEnumMap[instance.species]!,
      'profiles': instance.profiles
          .map((k, e) => MapEntry(_$GrowthStageEnumMap[k]!, e)),
      'lastModified': instance.lastModified?.toIso8601String(),
      'isCustom': instance.isCustom,
    };

const _$SpeciesEnumMap = {
  Species.oyster: 'oyster',
  Species.shiitake: 'shiitake',
  Species.lionsMane: 'lionsMane',
  Species.custom: 'custom',
};

const _$GrowthStageEnumMap = {
  GrowthStage.incubation: 'incubation',
  GrowthStage.pinning: 'pinning',
  GrowthStage.fruiting: 'fruiting',
};

_$EnvironmentalDataImpl _$$EnvironmentalDataImplFromJson(
        Map<String, dynamic> json) =>
    _$EnvironmentalDataImpl(
      co2Ppm: (json['co2Ppm'] as num).toInt(),
      temperatureC: (json['temperatureC'] as num).toDouble(),
      relativeHumidity: (json['relativeHumidity'] as num).toDouble(),
      lightRaw: (json['lightRaw'] as num).toInt(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$$EnvironmentalDataImplToJson(
        _$EnvironmentalDataImpl instance) =>
    <String, dynamic>{
      'co2Ppm': instance.co2Ppm,
      'temperatureC': instance.temperatureC,
      'relativeHumidity': instance.relativeHumidity,
      'lightRaw': instance.lightRaw,
      'timestamp': instance.timestamp.toIso8601String(),
    };

_$ControlTargetsImpl _$$ControlTargetsImplFromJson(Map<String, dynamic> json) =>
    _$ControlTargetsImpl(
      tempMin: (json['tempMin'] as num).toDouble(),
      tempMax: (json['tempMax'] as num).toDouble(),
      rhMin: (json['rhMin'] as num).toDouble(),
      co2Max: (json['co2Max'] as num).toInt(),
      lightMode: $enumDecode(_$LightModeEnumMap, json['lightMode']),
      onMinutes: (json['onMinutes'] as num).toInt(),
      offMinutes: (json['offMinutes'] as num).toInt(),
    );

Map<String, dynamic> _$$ControlTargetsImplToJson(
        _$ControlTargetsImpl instance) =>
    <String, dynamic>{
      'tempMin': instance.tempMin,
      'tempMax': instance.tempMax,
      'rhMin': instance.rhMin,
      'co2Max': instance.co2Max,
      'lightMode': _$LightModeEnumMap[instance.lightMode]!,
      'onMinutes': instance.onMinutes,
      'offMinutes': instance.offMinutes,
    };

_$StageStateImpl _$$StageStateImplFromJson(Map<String, dynamic> json) =>
    _$StageStateImpl(
      mode: $enumDecode(_$ControlModeEnumMap, json['mode']),
      species: $enumDecode(_$SpeciesEnumMap, json['species']),
      stage: $enumDecode(_$GrowthStageEnumMap, json['stage']),
      stageStartTime: DateTime.parse(json['stageStartTime'] as String),
      expectedDays: (json['expectedDays'] as num).toInt(),
    );

Map<String, dynamic> _$$StageStateImplToJson(_$StageStateImpl instance) =>
    <String, dynamic>{
      'mode': _$ControlModeEnumMap[instance.mode]!,
      'species': _$SpeciesEnumMap[instance.species]!,
      'stage': _$GrowthStageEnumMap[instance.stage]!,
      'stageStartTime': instance.stageStartTime.toIso8601String(),
      'expectedDays': instance.expectedDays,
    };

const _$ControlModeEnumMap = {
  ControlMode.full: 'full',
  ControlMode.semi: 'semi',
  ControlMode.manual: 'manual',
};
