// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'farm.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FarmImpl _$$FarmImplFromJson(Map<String, dynamic> json) => _$FarmImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      deviceId: json['deviceId'] as String,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActive: json['lastActive'] == null
          ? null
          : DateTime.parse(json['lastActive'] as String),
      totalHarvests: (json['totalHarvests'] as num?)?.toInt() ?? 0,
      totalYieldKg: (json['totalYieldKg'] as num?)?.toDouble() ?? 0.0,
      primarySpecies:
          $enumDecodeNullable(_$SpeciesEnumMap, json['primarySpecies']),
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$FarmImplToJson(_$FarmImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'deviceId': instance.deviceId,
      'location': instance.location,
      'notes': instance.notes,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastActive': instance.lastActive?.toIso8601String(),
      'totalHarvests': instance.totalHarvests,
      'totalYieldKg': instance.totalYieldKg,
      'primarySpecies': _$SpeciesEnumMap[instance.primarySpecies],
      'imageUrl': instance.imageUrl,
      'isActive': instance.isActive,
      'metadata': instance.metadata,
    };

const _$SpeciesEnumMap = {
  Species.oyster: 'oyster',
  Species.shiitake: 'shiitake',
  Species.lionsMane: 'lionsMane',
  Species.custom: 'custom',
};

_$FarmAnalyticsImpl _$$FarmAnalyticsImplFromJson(Map<String, dynamic> json) =>
    _$FarmAnalyticsImpl(
      farmId: json['farmId'] as String,
      farmName: json['farmName'] as String,
      avgTemperature: (json['avgTemperature'] as num).toDouble(),
      avgHumidity: (json['avgHumidity'] as num).toDouble(),
      avgCO2: (json['avgCO2'] as num).toDouble(),
      tempCompliancePercent: (json['tempCompliancePercent'] as num).toDouble(),
      humidityCompliancePercent:
          (json['humidityCompliancePercent'] as num).toDouble(),
      co2CompliancePercent: (json['co2CompliancePercent'] as num).toDouble(),
      harvestCount: (json['harvestCount'] as num).toInt(),
      totalYieldKg: (json['totalYieldKg'] as num).toDouble(),
      avgYieldPerHarvest: (json['avgYieldPerHarvest'] as num).toDouble(),
      daysInProduction: (json['daysInProduction'] as num).toInt(),
      yieldPerDay: (json['yieldPerDay'] as num).toDouble(),
      currentStage:
          $enumDecodeNullable(_$GrowthStageEnumMap, json['currentStage']),
      daysInCurrentStage: (json['daysInCurrentStage'] as num).toInt(),
      stageTransitions: (json['stageTransitions'] as num).toInt(),
      totalAlerts: (json['totalAlerts'] as num).toInt(),
      criticalAlerts: (json['criticalAlerts'] as num).toInt(),
      uptimePercent: (json['uptimePercent'] as num).toDouble(),
      lastConnection: json['lastConnection'] == null
          ? null
          : DateTime.parse(json['lastConnection'] as String),
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
    );

Map<String, dynamic> _$$FarmAnalyticsImplToJson(_$FarmAnalyticsImpl instance) =>
    <String, dynamic>{
      'farmId': instance.farmId,
      'farmName': instance.farmName,
      'avgTemperature': instance.avgTemperature,
      'avgHumidity': instance.avgHumidity,
      'avgCO2': instance.avgCO2,
      'tempCompliancePercent': instance.tempCompliancePercent,
      'humidityCompliancePercent': instance.humidityCompliancePercent,
      'co2CompliancePercent': instance.co2CompliancePercent,
      'harvestCount': instance.harvestCount,
      'totalYieldKg': instance.totalYieldKg,
      'avgYieldPerHarvest': instance.avgYieldPerHarvest,
      'daysInProduction': instance.daysInProduction,
      'yieldPerDay': instance.yieldPerDay,
      'currentStage': _$GrowthStageEnumMap[instance.currentStage],
      'daysInCurrentStage': instance.daysInCurrentStage,
      'stageTransitions': instance.stageTransitions,
      'totalAlerts': instance.totalAlerts,
      'criticalAlerts': instance.criticalAlerts,
      'uptimePercent': instance.uptimePercent,
      'lastConnection': instance.lastConnection?.toIso8601String(),
      'periodStart': instance.periodStart.toIso8601String(),
      'periodEnd': instance.periodEnd.toIso8601String(),
    };

const _$GrowthStageEnumMap = {
  GrowthStage.incubation: 'incubation',
  GrowthStage.pinning: 'pinning',
  GrowthStage.fruiting: 'fruiting',
};

_$HarvestRecordImpl _$$HarvestRecordImplFromJson(Map<String, dynamic> json) =>
    _$HarvestRecordImpl(
      id: json['id'] as String,
      farmId: json['farmId'] as String,
      harvestDate: DateTime.parse(json['harvestDate'] as String),
      species: $enumDecode(_$SpeciesEnumMap, json['species']),
      stage: $enumDecode(_$GrowthStageEnumMap, json['stage']),
      yieldKg: (json['yieldKg'] as num).toDouble(),
      flushNumber: (json['flushNumber'] as num?)?.toInt(),
      qualityScore: (json['qualityScore'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      photoUrls: (json['photoUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$HarvestRecordImplToJson(_$HarvestRecordImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'farmId': instance.farmId,
      'harvestDate': instance.harvestDate.toIso8601String(),
      'species': _$SpeciesEnumMap[instance.species]!,
      'stage': _$GrowthStageEnumMap[instance.stage]!,
      'yieldKg': instance.yieldKg,
      'flushNumber': instance.flushNumber,
      'qualityScore': instance.qualityScore,
      'notes': instance.notes,
      'photoUrls': instance.photoUrls,
      'metadata': instance.metadata,
    };

_$CrossFarmComparisonImpl _$$CrossFarmComparisonImplFromJson(
        Map<String, dynamic> json) =>
    _$CrossFarmComparisonImpl(
      farms: (json['farms'] as List<dynamic>)
          .map((e) => FarmAnalytics.fromJson(e as Map<String, dynamic>))
          .toList(),
      averages:
          FarmAnalytics.fromJson(json['averages'] as Map<String, dynamic>),
      topPerformer:
          FarmAnalytics.fromJson(json['topPerformer'] as Map<String, dynamic>),
      bottomPerformer: FarmAnalytics.fromJson(
          json['bottomPerformer'] as Map<String, dynamic>),
      speciesBreakdown: (json['speciesBreakdown'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      stageDistribution:
          Map<String, int>.from(json['stageDistribution'] as Map),
    );

Map<String, dynamic> _$$CrossFarmComparisonImplToJson(
        _$CrossFarmComparisonImpl instance) =>
    <String, dynamic>{
      'farms': instance.farms,
      'averages': instance.averages,
      'topPerformer': instance.topPerformer,
      'bottomPerformer': instance.bottomPerformer,
      'speciesBreakdown': instance.speciesBreakdown,
      'stageDistribution': instance.stageDistribution,
    };

_$DeviceInfoImpl _$$DeviceInfoImplFromJson(Map<String, dynamic> json) =>
    _$DeviceInfoImpl(
      deviceId: json['deviceId'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      farmId: json['farmId'] as String?,
      lastConnected: json['lastConnected'] == null
          ? null
          : DateTime.parse(json['lastConnected'] as String),
    );

Map<String, dynamic> _$$DeviceInfoImplToJson(_$DeviceInfoImpl instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'name': instance.name,
      'address': instance.address,
      'farmId': instance.farmId,
      'lastConnected': instance.lastConnected?.toIso8601String(),
    };
