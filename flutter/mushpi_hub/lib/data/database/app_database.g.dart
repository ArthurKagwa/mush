// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $FarmsTable extends Farms with TableInfo<$FarmsTable, Farm> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FarmsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _locationMeta =
      const VerificationMeta('location');
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
      'location', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastActiveMeta =
      const VerificationMeta('lastActive');
  @override
  late final GeneratedColumn<DateTime> lastActive = GeneratedColumn<DateTime>(
      'last_active', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _totalHarvestsMeta =
      const VerificationMeta('totalHarvests');
  @override
  late final GeneratedColumn<int> totalHarvests = GeneratedColumn<int>(
      'total_harvests', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalYieldKgMeta =
      const VerificationMeta('totalYieldKg');
  @override
  late final GeneratedColumn<double> totalYieldKg = GeneratedColumn<double>(
      'total_yield_kg', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _primarySpeciesMeta =
      const VerificationMeta('primarySpecies');
  @override
  late final GeneratedColumn<int> primarySpecies = GeneratedColumn<int>(
      'primary_species', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _imageUrlMeta =
      const VerificationMeta('imageUrl');
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
      'image_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _metadataMeta =
      const VerificationMeta('metadata');
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
      'metadata', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
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
        metadata
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'farms';
  @override
  VerificationContext validateIntegrity(Insertable<Farm> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('location')) {
      context.handle(_locationMeta,
          location.isAcceptableOrUnknown(data['location']!, _locationMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_active')) {
      context.handle(
          _lastActiveMeta,
          lastActive.isAcceptableOrUnknown(
              data['last_active']!, _lastActiveMeta));
    }
    if (data.containsKey('total_harvests')) {
      context.handle(
          _totalHarvestsMeta,
          totalHarvests.isAcceptableOrUnknown(
              data['total_harvests']!, _totalHarvestsMeta));
    }
    if (data.containsKey('total_yield_kg')) {
      context.handle(
          _totalYieldKgMeta,
          totalYieldKg.isAcceptableOrUnknown(
              data['total_yield_kg']!, _totalYieldKgMeta));
    }
    if (data.containsKey('primary_species')) {
      context.handle(
          _primarySpeciesMeta,
          primarySpecies.isAcceptableOrUnknown(
              data['primary_species']!, _primarySpeciesMeta));
    }
    if (data.containsKey('image_url')) {
      context.handle(_imageUrlMeta,
          imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('metadata')) {
      context.handle(_metadataMeta,
          metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Farm map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Farm(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      location: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastActive: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_active']),
      totalHarvests: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_harvests'])!,
      totalYieldKg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_yield_kg'])!,
      primarySpecies: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}primary_species']),
      imageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_url']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      metadata: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata']),
    );
  }

  @override
  $FarmsTable createAlias(String alias) {
    return $FarmsTable(attachedDatabase, alias);
  }
}

class Farm extends DataClass implements Insertable<Farm> {
  final String id;
  final String name;
  final String deviceId;
  final String? location;
  final String? notes;
  final DateTime createdAt;
  final DateTime? lastActive;
  final int totalHarvests;
  final double totalYieldKg;
  final int? primarySpecies;
  final String? imageUrl;
  final bool isActive;
  final String? metadata;
  const Farm(
      {required this.id,
      required this.name,
      required this.deviceId,
      this.location,
      this.notes,
      required this.createdAt,
      this.lastActive,
      required this.totalHarvests,
      required this.totalYieldKg,
      this.primarySpecies,
      this.imageUrl,
      required this.isActive,
      this.metadata});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastActive != null) {
      map['last_active'] = Variable<DateTime>(lastActive);
    }
    map['total_harvests'] = Variable<int>(totalHarvests);
    map['total_yield_kg'] = Variable<double>(totalYieldKg);
    if (!nullToAbsent || primarySpecies != null) {
      map['primary_species'] = Variable<int>(primarySpecies);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    return map;
  }

  FarmsCompanion toCompanion(bool nullToAbsent) {
    return FarmsCompanion(
      id: Value(id),
      name: Value(name),
      deviceId: Value(deviceId),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      lastActive: lastActive == null && nullToAbsent
          ? const Value.absent()
          : Value(lastActive),
      totalHarvests: Value(totalHarvests),
      totalYieldKg: Value(totalYieldKg),
      primarySpecies: primarySpecies == null && nullToAbsent
          ? const Value.absent()
          : Value(primarySpecies),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      isActive: Value(isActive),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
    );
  }

  factory Farm.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Farm(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      location: serializer.fromJson<String?>(json['location']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastActive: serializer.fromJson<DateTime?>(json['lastActive']),
      totalHarvests: serializer.fromJson<int>(json['totalHarvests']),
      totalYieldKg: serializer.fromJson<double>(json['totalYieldKg']),
      primarySpecies: serializer.fromJson<int?>(json['primarySpecies']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      metadata: serializer.fromJson<String?>(json['metadata']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'deviceId': serializer.toJson<String>(deviceId),
      'location': serializer.toJson<String?>(location),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastActive': serializer.toJson<DateTime?>(lastActive),
      'totalHarvests': serializer.toJson<int>(totalHarvests),
      'totalYieldKg': serializer.toJson<double>(totalYieldKg),
      'primarySpecies': serializer.toJson<int?>(primarySpecies),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'isActive': serializer.toJson<bool>(isActive),
      'metadata': serializer.toJson<String?>(metadata),
    };
  }

  Farm copyWith(
          {String? id,
          String? name,
          String? deviceId,
          Value<String?> location = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> lastActive = const Value.absent(),
          int? totalHarvests,
          double? totalYieldKg,
          Value<int?> primarySpecies = const Value.absent(),
          Value<String?> imageUrl = const Value.absent(),
          bool? isActive,
          Value<String?> metadata = const Value.absent()}) =>
      Farm(
        id: id ?? this.id,
        name: name ?? this.name,
        deviceId: deviceId ?? this.deviceId,
        location: location.present ? location.value : this.location,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        lastActive: lastActive.present ? lastActive.value : this.lastActive,
        totalHarvests: totalHarvests ?? this.totalHarvests,
        totalYieldKg: totalYieldKg ?? this.totalYieldKg,
        primarySpecies:
            primarySpecies.present ? primarySpecies.value : this.primarySpecies,
        imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
        isActive: isActive ?? this.isActive,
        metadata: metadata.present ? metadata.value : this.metadata,
      );
  Farm copyWithCompanion(FarmsCompanion data) {
    return Farm(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      location: data.location.present ? data.location.value : this.location,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastActive:
          data.lastActive.present ? data.lastActive.value : this.lastActive,
      totalHarvests: data.totalHarvests.present
          ? data.totalHarvests.value
          : this.totalHarvests,
      totalYieldKg: data.totalYieldKg.present
          ? data.totalYieldKg.value
          : this.totalYieldKg,
      primarySpecies: data.primarySpecies.present
          ? data.primarySpecies.value
          : this.primarySpecies,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Farm(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('deviceId: $deviceId, ')
          ..write('location: $location, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastActive: $lastActive, ')
          ..write('totalHarvests: $totalHarvests, ')
          ..write('totalYieldKg: $totalYieldKg, ')
          ..write('primarySpecies: $primarySpecies, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('isActive: $isActive, ')
          ..write('metadata: $metadata')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
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
      metadata);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Farm &&
          other.id == this.id &&
          other.name == this.name &&
          other.deviceId == this.deviceId &&
          other.location == this.location &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.lastActive == this.lastActive &&
          other.totalHarvests == this.totalHarvests &&
          other.totalYieldKg == this.totalYieldKg &&
          other.primarySpecies == this.primarySpecies &&
          other.imageUrl == this.imageUrl &&
          other.isActive == this.isActive &&
          other.metadata == this.metadata);
}

class FarmsCompanion extends UpdateCompanion<Farm> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> deviceId;
  final Value<String?> location;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastActive;
  final Value<int> totalHarvests;
  final Value<double> totalYieldKg;
  final Value<int?> primarySpecies;
  final Value<String?> imageUrl;
  final Value<bool> isActive;
  final Value<String?> metadata;
  final Value<int> rowid;
  const FarmsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.location = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastActive = const Value.absent(),
    this.totalHarvests = const Value.absent(),
    this.totalYieldKg = const Value.absent(),
    this.primarySpecies = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.isActive = const Value.absent(),
    this.metadata = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FarmsCompanion.insert({
    required String id,
    required String name,
    required String deviceId,
    this.location = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    this.lastActive = const Value.absent(),
    this.totalHarvests = const Value.absent(),
    this.totalYieldKg = const Value.absent(),
    this.primarySpecies = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.isActive = const Value.absent(),
    this.metadata = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        deviceId = Value(deviceId),
        createdAt = Value(createdAt);
  static Insertable<Farm> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? deviceId,
    Expression<String>? location,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastActive,
    Expression<int>? totalHarvests,
    Expression<double>? totalYieldKg,
    Expression<int>? primarySpecies,
    Expression<String>? imageUrl,
    Expression<bool>? isActive,
    Expression<String>? metadata,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (deviceId != null) 'device_id': deviceId,
      if (location != null) 'location': location,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (lastActive != null) 'last_active': lastActive,
      if (totalHarvests != null) 'total_harvests': totalHarvests,
      if (totalYieldKg != null) 'total_yield_kg': totalYieldKg,
      if (primarySpecies != null) 'primary_species': primarySpecies,
      if (imageUrl != null) 'image_url': imageUrl,
      if (isActive != null) 'is_active': isActive,
      if (metadata != null) 'metadata': metadata,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FarmsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? deviceId,
      Value<String?>? location,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime?>? lastActive,
      Value<int>? totalHarvests,
      Value<double>? totalYieldKg,
      Value<int?>? primarySpecies,
      Value<String?>? imageUrl,
      Value<bool>? isActive,
      Value<String?>? metadata,
      Value<int>? rowid}) {
    return FarmsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      deviceId: deviceId ?? this.deviceId,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      totalHarvests: totalHarvests ?? this.totalHarvests,
      totalYieldKg: totalYieldKg ?? this.totalYieldKg,
      primarySpecies: primarySpecies ?? this.primarySpecies,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastActive.present) {
      map['last_active'] = Variable<DateTime>(lastActive.value);
    }
    if (totalHarvests.present) {
      map['total_harvests'] = Variable<int>(totalHarvests.value);
    }
    if (totalYieldKg.present) {
      map['total_yield_kg'] = Variable<double>(totalYieldKg.value);
    }
    if (primarySpecies.present) {
      map['primary_species'] = Variable<int>(primarySpecies.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FarmsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('deviceId: $deviceId, ')
          ..write('location: $location, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastActive: $lastActive, ')
          ..write('totalHarvests: $totalHarvests, ')
          ..write('totalYieldKg: $totalYieldKg, ')
          ..write('primarySpecies: $primarySpecies, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('isActive: $isActive, ')
          ..write('metadata: $metadata, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HarvestsTable extends Harvests with TableInfo<$HarvestsTable, Harvest> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HarvestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _farmIdMeta = const VerificationMeta('farmId');
  @override
  late final GeneratedColumn<String> farmId = GeneratedColumn<String>(
      'farm_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES farms (id)'));
  static const VerificationMeta _harvestDateMeta =
      const VerificationMeta('harvestDate');
  @override
  late final GeneratedColumn<DateTime> harvestDate = GeneratedColumn<DateTime>(
      'harvest_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _speciesMeta =
      const VerificationMeta('species');
  @override
  late final GeneratedColumn<int> species = GeneratedColumn<int>(
      'species', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  @override
  late final GeneratedColumn<int> stage = GeneratedColumn<int>(
      'stage', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _yieldKgMeta =
      const VerificationMeta('yieldKg');
  @override
  late final GeneratedColumn<double> yieldKg = GeneratedColumn<double>(
      'yield_kg', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _flushNumberMeta =
      const VerificationMeta('flushNumber');
  @override
  late final GeneratedColumn<int> flushNumber = GeneratedColumn<int>(
      'flush_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _qualityScoreMeta =
      const VerificationMeta('qualityScore');
  @override
  late final GeneratedColumn<double> qualityScore = GeneratedColumn<double>(
      'quality_score', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _photoUrlsMeta =
      const VerificationMeta('photoUrls');
  @override
  late final GeneratedColumn<String> photoUrls = GeneratedColumn<String>(
      'photo_urls', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _metadataMeta =
      const VerificationMeta('metadata');
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
      'metadata', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        farmId,
        harvestDate,
        species,
        stage,
        yieldKg,
        flushNumber,
        qualityScore,
        notes,
        photoUrls,
        metadata
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'harvests';
  @override
  VerificationContext validateIntegrity(Insertable<Harvest> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('farm_id')) {
      context.handle(_farmIdMeta,
          farmId.isAcceptableOrUnknown(data['farm_id']!, _farmIdMeta));
    } else if (isInserting) {
      context.missing(_farmIdMeta);
    }
    if (data.containsKey('harvest_date')) {
      context.handle(
          _harvestDateMeta,
          harvestDate.isAcceptableOrUnknown(
              data['harvest_date']!, _harvestDateMeta));
    } else if (isInserting) {
      context.missing(_harvestDateMeta);
    }
    if (data.containsKey('species')) {
      context.handle(_speciesMeta,
          species.isAcceptableOrUnknown(data['species']!, _speciesMeta));
    } else if (isInserting) {
      context.missing(_speciesMeta);
    }
    if (data.containsKey('stage')) {
      context.handle(
          _stageMeta, stage.isAcceptableOrUnknown(data['stage']!, _stageMeta));
    } else if (isInserting) {
      context.missing(_stageMeta);
    }
    if (data.containsKey('yield_kg')) {
      context.handle(_yieldKgMeta,
          yieldKg.isAcceptableOrUnknown(data['yield_kg']!, _yieldKgMeta));
    } else if (isInserting) {
      context.missing(_yieldKgMeta);
    }
    if (data.containsKey('flush_number')) {
      context.handle(
          _flushNumberMeta,
          flushNumber.isAcceptableOrUnknown(
              data['flush_number']!, _flushNumberMeta));
    }
    if (data.containsKey('quality_score')) {
      context.handle(
          _qualityScoreMeta,
          qualityScore.isAcceptableOrUnknown(
              data['quality_score']!, _qualityScoreMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('photo_urls')) {
      context.handle(_photoUrlsMeta,
          photoUrls.isAcceptableOrUnknown(data['photo_urls']!, _photoUrlsMeta));
    }
    if (data.containsKey('metadata')) {
      context.handle(_metadataMeta,
          metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Harvest map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Harvest(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      farmId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}farm_id'])!,
      harvestDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}harvest_date'])!,
      species: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}species'])!,
      stage: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stage'])!,
      yieldKg: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}yield_kg'])!,
      flushNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}flush_number']),
      qualityScore: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quality_score']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      photoUrls: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_urls']),
      metadata: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata']),
    );
  }

  @override
  $HarvestsTable createAlias(String alias) {
    return $HarvestsTable(attachedDatabase, alias);
  }
}

class Harvest extends DataClass implements Insertable<Harvest> {
  final String id;
  final String farmId;
  final DateTime harvestDate;
  final int species;
  final int stage;
  final double yieldKg;
  final int? flushNumber;
  final double? qualityScore;
  final String? notes;
  final String? photoUrls;
  final String? metadata;
  const Harvest(
      {required this.id,
      required this.farmId,
      required this.harvestDate,
      required this.species,
      required this.stage,
      required this.yieldKg,
      this.flushNumber,
      this.qualityScore,
      this.notes,
      this.photoUrls,
      this.metadata});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['farm_id'] = Variable<String>(farmId);
    map['harvest_date'] = Variable<DateTime>(harvestDate);
    map['species'] = Variable<int>(species);
    map['stage'] = Variable<int>(stage);
    map['yield_kg'] = Variable<double>(yieldKg);
    if (!nullToAbsent || flushNumber != null) {
      map['flush_number'] = Variable<int>(flushNumber);
    }
    if (!nullToAbsent || qualityScore != null) {
      map['quality_score'] = Variable<double>(qualityScore);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || photoUrls != null) {
      map['photo_urls'] = Variable<String>(photoUrls);
    }
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    return map;
  }

  HarvestsCompanion toCompanion(bool nullToAbsent) {
    return HarvestsCompanion(
      id: Value(id),
      farmId: Value(farmId),
      harvestDate: Value(harvestDate),
      species: Value(species),
      stage: Value(stage),
      yieldKg: Value(yieldKg),
      flushNumber: flushNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(flushNumber),
      qualityScore: qualityScore == null && nullToAbsent
          ? const Value.absent()
          : Value(qualityScore),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      photoUrls: photoUrls == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrls),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
    );
  }

  factory Harvest.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Harvest(
      id: serializer.fromJson<String>(json['id']),
      farmId: serializer.fromJson<String>(json['farmId']),
      harvestDate: serializer.fromJson<DateTime>(json['harvestDate']),
      species: serializer.fromJson<int>(json['species']),
      stage: serializer.fromJson<int>(json['stage']),
      yieldKg: serializer.fromJson<double>(json['yieldKg']),
      flushNumber: serializer.fromJson<int?>(json['flushNumber']),
      qualityScore: serializer.fromJson<double?>(json['qualityScore']),
      notes: serializer.fromJson<String?>(json['notes']),
      photoUrls: serializer.fromJson<String?>(json['photoUrls']),
      metadata: serializer.fromJson<String?>(json['metadata']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'farmId': serializer.toJson<String>(farmId),
      'harvestDate': serializer.toJson<DateTime>(harvestDate),
      'species': serializer.toJson<int>(species),
      'stage': serializer.toJson<int>(stage),
      'yieldKg': serializer.toJson<double>(yieldKg),
      'flushNumber': serializer.toJson<int?>(flushNumber),
      'qualityScore': serializer.toJson<double?>(qualityScore),
      'notes': serializer.toJson<String?>(notes),
      'photoUrls': serializer.toJson<String?>(photoUrls),
      'metadata': serializer.toJson<String?>(metadata),
    };
  }

  Harvest copyWith(
          {String? id,
          String? farmId,
          DateTime? harvestDate,
          int? species,
          int? stage,
          double? yieldKg,
          Value<int?> flushNumber = const Value.absent(),
          Value<double?> qualityScore = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          Value<String?> photoUrls = const Value.absent(),
          Value<String?> metadata = const Value.absent()}) =>
      Harvest(
        id: id ?? this.id,
        farmId: farmId ?? this.farmId,
        harvestDate: harvestDate ?? this.harvestDate,
        species: species ?? this.species,
        stage: stage ?? this.stage,
        yieldKg: yieldKg ?? this.yieldKg,
        flushNumber: flushNumber.present ? flushNumber.value : this.flushNumber,
        qualityScore:
            qualityScore.present ? qualityScore.value : this.qualityScore,
        notes: notes.present ? notes.value : this.notes,
        photoUrls: photoUrls.present ? photoUrls.value : this.photoUrls,
        metadata: metadata.present ? metadata.value : this.metadata,
      );
  Harvest copyWithCompanion(HarvestsCompanion data) {
    return Harvest(
      id: data.id.present ? data.id.value : this.id,
      farmId: data.farmId.present ? data.farmId.value : this.farmId,
      harvestDate:
          data.harvestDate.present ? data.harvestDate.value : this.harvestDate,
      species: data.species.present ? data.species.value : this.species,
      stage: data.stage.present ? data.stage.value : this.stage,
      yieldKg: data.yieldKg.present ? data.yieldKg.value : this.yieldKg,
      flushNumber:
          data.flushNumber.present ? data.flushNumber.value : this.flushNumber,
      qualityScore: data.qualityScore.present
          ? data.qualityScore.value
          : this.qualityScore,
      notes: data.notes.present ? data.notes.value : this.notes,
      photoUrls: data.photoUrls.present ? data.photoUrls.value : this.photoUrls,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Harvest(')
          ..write('id: $id, ')
          ..write('farmId: $farmId, ')
          ..write('harvestDate: $harvestDate, ')
          ..write('species: $species, ')
          ..write('stage: $stage, ')
          ..write('yieldKg: $yieldKg, ')
          ..write('flushNumber: $flushNumber, ')
          ..write('qualityScore: $qualityScore, ')
          ..write('notes: $notes, ')
          ..write('photoUrls: $photoUrls, ')
          ..write('metadata: $metadata')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, farmId, harvestDate, species, stage,
      yieldKg, flushNumber, qualityScore, notes, photoUrls, metadata);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Harvest &&
          other.id == this.id &&
          other.farmId == this.farmId &&
          other.harvestDate == this.harvestDate &&
          other.species == this.species &&
          other.stage == this.stage &&
          other.yieldKg == this.yieldKg &&
          other.flushNumber == this.flushNumber &&
          other.qualityScore == this.qualityScore &&
          other.notes == this.notes &&
          other.photoUrls == this.photoUrls &&
          other.metadata == this.metadata);
}

class HarvestsCompanion extends UpdateCompanion<Harvest> {
  final Value<String> id;
  final Value<String> farmId;
  final Value<DateTime> harvestDate;
  final Value<int> species;
  final Value<int> stage;
  final Value<double> yieldKg;
  final Value<int?> flushNumber;
  final Value<double?> qualityScore;
  final Value<String?> notes;
  final Value<String?> photoUrls;
  final Value<String?> metadata;
  final Value<int> rowid;
  const HarvestsCompanion({
    this.id = const Value.absent(),
    this.farmId = const Value.absent(),
    this.harvestDate = const Value.absent(),
    this.species = const Value.absent(),
    this.stage = const Value.absent(),
    this.yieldKg = const Value.absent(),
    this.flushNumber = const Value.absent(),
    this.qualityScore = const Value.absent(),
    this.notes = const Value.absent(),
    this.photoUrls = const Value.absent(),
    this.metadata = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HarvestsCompanion.insert({
    required String id,
    required String farmId,
    required DateTime harvestDate,
    required int species,
    required int stage,
    required double yieldKg,
    this.flushNumber = const Value.absent(),
    this.qualityScore = const Value.absent(),
    this.notes = const Value.absent(),
    this.photoUrls = const Value.absent(),
    this.metadata = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        farmId = Value(farmId),
        harvestDate = Value(harvestDate),
        species = Value(species),
        stage = Value(stage),
        yieldKg = Value(yieldKg);
  static Insertable<Harvest> custom({
    Expression<String>? id,
    Expression<String>? farmId,
    Expression<DateTime>? harvestDate,
    Expression<int>? species,
    Expression<int>? stage,
    Expression<double>? yieldKg,
    Expression<int>? flushNumber,
    Expression<double>? qualityScore,
    Expression<String>? notes,
    Expression<String>? photoUrls,
    Expression<String>? metadata,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (farmId != null) 'farm_id': farmId,
      if (harvestDate != null) 'harvest_date': harvestDate,
      if (species != null) 'species': species,
      if (stage != null) 'stage': stage,
      if (yieldKg != null) 'yield_kg': yieldKg,
      if (flushNumber != null) 'flush_number': flushNumber,
      if (qualityScore != null) 'quality_score': qualityScore,
      if (notes != null) 'notes': notes,
      if (photoUrls != null) 'photo_urls': photoUrls,
      if (metadata != null) 'metadata': metadata,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HarvestsCompanion copyWith(
      {Value<String>? id,
      Value<String>? farmId,
      Value<DateTime>? harvestDate,
      Value<int>? species,
      Value<int>? stage,
      Value<double>? yieldKg,
      Value<int?>? flushNumber,
      Value<double?>? qualityScore,
      Value<String?>? notes,
      Value<String?>? photoUrls,
      Value<String?>? metadata,
      Value<int>? rowid}) {
    return HarvestsCompanion(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      harvestDate: harvestDate ?? this.harvestDate,
      species: species ?? this.species,
      stage: stage ?? this.stage,
      yieldKg: yieldKg ?? this.yieldKg,
      flushNumber: flushNumber ?? this.flushNumber,
      qualityScore: qualityScore ?? this.qualityScore,
      notes: notes ?? this.notes,
      photoUrls: photoUrls ?? this.photoUrls,
      metadata: metadata ?? this.metadata,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (farmId.present) {
      map['farm_id'] = Variable<String>(farmId.value);
    }
    if (harvestDate.present) {
      map['harvest_date'] = Variable<DateTime>(harvestDate.value);
    }
    if (species.present) {
      map['species'] = Variable<int>(species.value);
    }
    if (stage.present) {
      map['stage'] = Variable<int>(stage.value);
    }
    if (yieldKg.present) {
      map['yield_kg'] = Variable<double>(yieldKg.value);
    }
    if (flushNumber.present) {
      map['flush_number'] = Variable<int>(flushNumber.value);
    }
    if (qualityScore.present) {
      map['quality_score'] = Variable<double>(qualityScore.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (photoUrls.present) {
      map['photo_urls'] = Variable<String>(photoUrls.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HarvestsCompanion(')
          ..write('id: $id, ')
          ..write('farmId: $farmId, ')
          ..write('harvestDate: $harvestDate, ')
          ..write('species: $species, ')
          ..write('stage: $stage, ')
          ..write('yieldKg: $yieldKg, ')
          ..write('flushNumber: $flushNumber, ')
          ..write('qualityScore: $qualityScore, ')
          ..write('notes: $notes, ')
          ..write('photoUrls: $photoUrls, ')
          ..write('metadata: $metadata, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DevicesTable extends Devices with TableInfo<$DevicesTable, Device> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _farmIdMeta = const VerificationMeta('farmId');
  @override
  late final GeneratedColumn<String> farmId = GeneratedColumn<String>(
      'farm_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES farms (id)'));
  static const VerificationMeta _lastConnectedMeta =
      const VerificationMeta('lastConnected');
  @override
  late final GeneratedColumn<DateTime> lastConnected =
      GeneratedColumn<DateTime>('last_connected', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [deviceId, name, address, farmId, lastConnected];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'devices';
  @override
  VerificationContext validateIntegrity(Insertable<Device> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('farm_id')) {
      context.handle(_farmIdMeta,
          farmId.isAcceptableOrUnknown(data['farm_id']!, _farmIdMeta));
    }
    if (data.containsKey('last_connected')) {
      context.handle(
          _lastConnectedMeta,
          lastConnected.isAcceptableOrUnknown(
              data['last_connected']!, _lastConnectedMeta));
    } else if (isInserting) {
      context.missing(_lastConnectedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  Device map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Device(
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address'])!,
      farmId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}farm_id']),
      lastConnected: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_connected'])!,
    );
  }

  @override
  $DevicesTable createAlias(String alias) {
    return $DevicesTable(attachedDatabase, alias);
  }
}

class Device extends DataClass implements Insertable<Device> {
  final String deviceId;
  final String name;
  final String address;
  final String? farmId;
  final DateTime lastConnected;
  const Device(
      {required this.deviceId,
      required this.name,
      required this.address,
      this.farmId,
      required this.lastConnected});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['name'] = Variable<String>(name);
    map['address'] = Variable<String>(address);
    if (!nullToAbsent || farmId != null) {
      map['farm_id'] = Variable<String>(farmId);
    }
    map['last_connected'] = Variable<DateTime>(lastConnected);
    return map;
  }

  DevicesCompanion toCompanion(bool nullToAbsent) {
    return DevicesCompanion(
      deviceId: Value(deviceId),
      name: Value(name),
      address: Value(address),
      farmId:
          farmId == null && nullToAbsent ? const Value.absent() : Value(farmId),
      lastConnected: Value(lastConnected),
    );
  }

  factory Device.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Device(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String>(json['address']),
      farmId: serializer.fromJson<String?>(json['farmId']),
      lastConnected: serializer.fromJson<DateTime>(json['lastConnected']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String>(address),
      'farmId': serializer.toJson<String?>(farmId),
      'lastConnected': serializer.toJson<DateTime>(lastConnected),
    };
  }

  Device copyWith(
          {String? deviceId,
          String? name,
          String? address,
          Value<String?> farmId = const Value.absent(),
          DateTime? lastConnected}) =>
      Device(
        deviceId: deviceId ?? this.deviceId,
        name: name ?? this.name,
        address: address ?? this.address,
        farmId: farmId.present ? farmId.value : this.farmId,
        lastConnected: lastConnected ?? this.lastConnected,
      );
  Device copyWithCompanion(DevicesCompanion data) {
    return Device(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      name: data.name.present ? data.name.value : this.name,
      address: data.address.present ? data.address.value : this.address,
      farmId: data.farmId.present ? data.farmId.value : this.farmId,
      lastConnected: data.lastConnected.present
          ? data.lastConnected.value
          : this.lastConnected,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Device(')
          ..write('deviceId: $deviceId, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('farmId: $farmId, ')
          ..write('lastConnected: $lastConnected')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(deviceId, name, address, farmId, lastConnected);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Device &&
          other.deviceId == this.deviceId &&
          other.name == this.name &&
          other.address == this.address &&
          other.farmId == this.farmId &&
          other.lastConnected == this.lastConnected);
}

class DevicesCompanion extends UpdateCompanion<Device> {
  final Value<String> deviceId;
  final Value<String> name;
  final Value<String> address;
  final Value<String?> farmId;
  final Value<DateTime> lastConnected;
  final Value<int> rowid;
  const DevicesCompanion({
    this.deviceId = const Value.absent(),
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.farmId = const Value.absent(),
    this.lastConnected = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DevicesCompanion.insert({
    required String deviceId,
    required String name,
    required String address,
    this.farmId = const Value.absent(),
    required DateTime lastConnected,
    this.rowid = const Value.absent(),
  })  : deviceId = Value(deviceId),
        name = Value(name),
        address = Value(address),
        lastConnected = Value(lastConnected);
  static Insertable<Device> custom({
    Expression<String>? deviceId,
    Expression<String>? name,
    Expression<String>? address,
    Expression<String>? farmId,
    Expression<DateTime>? lastConnected,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (farmId != null) 'farm_id': farmId,
      if (lastConnected != null) 'last_connected': lastConnected,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DevicesCompanion copyWith(
      {Value<String>? deviceId,
      Value<String>? name,
      Value<String>? address,
      Value<String?>? farmId,
      Value<DateTime>? lastConnected,
      Value<int>? rowid}) {
    return DevicesCompanion(
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      address: address ?? this.address,
      farmId: farmId ?? this.farmId,
      lastConnected: lastConnected ?? this.lastConnected,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (farmId.present) {
      map['farm_id'] = Variable<String>(farmId.value);
    }
    if (lastConnected.present) {
      map['last_connected'] = Variable<DateTime>(lastConnected.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DevicesCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('farmId: $farmId, ')
          ..write('lastConnected: $lastConnected, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingsTable extends Readings with TableInfo<$ReadingsTable, Reading> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _farmIdMeta = const VerificationMeta('farmId');
  @override
  late final GeneratedColumn<String> farmId = GeneratedColumn<String>(
      'farm_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES farms (id)'));
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _co2PpmMeta = const VerificationMeta('co2Ppm');
  @override
  late final GeneratedColumn<int> co2Ppm = GeneratedColumn<int>(
      'co2_ppm', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _temperatureCMeta =
      const VerificationMeta('temperatureC');
  @override
  late final GeneratedColumn<double> temperatureC = GeneratedColumn<double>(
      'temperature_c', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _relativeHumidityMeta =
      const VerificationMeta('relativeHumidity');
  @override
  late final GeneratedColumn<double> relativeHumidity = GeneratedColumn<double>(
      'relative_humidity', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _lightRawMeta =
      const VerificationMeta('lightRaw');
  @override
  late final GeneratedColumn<int> lightRaw = GeneratedColumn<int>(
      'light_raw', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, farmId, timestamp, co2Ppm, temperatureC, relativeHumidity, lightRaw];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'readings';
  @override
  VerificationContext validateIntegrity(Insertable<Reading> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('farm_id')) {
      context.handle(_farmIdMeta,
          farmId.isAcceptableOrUnknown(data['farm_id']!, _farmIdMeta));
    } else if (isInserting) {
      context.missing(_farmIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('co2_ppm')) {
      context.handle(_co2PpmMeta,
          co2Ppm.isAcceptableOrUnknown(data['co2_ppm']!, _co2PpmMeta));
    } else if (isInserting) {
      context.missing(_co2PpmMeta);
    }
    if (data.containsKey('temperature_c')) {
      context.handle(
          _temperatureCMeta,
          temperatureC.isAcceptableOrUnknown(
              data['temperature_c']!, _temperatureCMeta));
    } else if (isInserting) {
      context.missing(_temperatureCMeta);
    }
    if (data.containsKey('relative_humidity')) {
      context.handle(
          _relativeHumidityMeta,
          relativeHumidity.isAcceptableOrUnknown(
              data['relative_humidity']!, _relativeHumidityMeta));
    } else if (isInserting) {
      context.missing(_relativeHumidityMeta);
    }
    if (data.containsKey('light_raw')) {
      context.handle(_lightRawMeta,
          lightRaw.isAcceptableOrUnknown(data['light_raw']!, _lightRawMeta));
    } else if (isInserting) {
      context.missing(_lightRawMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reading map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reading(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      farmId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}farm_id'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      co2Ppm: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}co2_ppm'])!,
      temperatureC: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}temperature_c'])!,
      relativeHumidity: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}relative_humidity'])!,
      lightRaw: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}light_raw'])!,
    );
  }

  @override
  $ReadingsTable createAlias(String alias) {
    return $ReadingsTable(attachedDatabase, alias);
  }
}

class Reading extends DataClass implements Insertable<Reading> {
  final int id;
  final String farmId;
  final DateTime timestamp;
  final int co2Ppm;
  final double temperatureC;
  final double relativeHumidity;
  final int lightRaw;
  const Reading(
      {required this.id,
      required this.farmId,
      required this.timestamp,
      required this.co2Ppm,
      required this.temperatureC,
      required this.relativeHumidity,
      required this.lightRaw});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['farm_id'] = Variable<String>(farmId);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['co2_ppm'] = Variable<int>(co2Ppm);
    map['temperature_c'] = Variable<double>(temperatureC);
    map['relative_humidity'] = Variable<double>(relativeHumidity);
    map['light_raw'] = Variable<int>(lightRaw);
    return map;
  }

  ReadingsCompanion toCompanion(bool nullToAbsent) {
    return ReadingsCompanion(
      id: Value(id),
      farmId: Value(farmId),
      timestamp: Value(timestamp),
      co2Ppm: Value(co2Ppm),
      temperatureC: Value(temperatureC),
      relativeHumidity: Value(relativeHumidity),
      lightRaw: Value(lightRaw),
    );
  }

  factory Reading.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reading(
      id: serializer.fromJson<int>(json['id']),
      farmId: serializer.fromJson<String>(json['farmId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      co2Ppm: serializer.fromJson<int>(json['co2Ppm']),
      temperatureC: serializer.fromJson<double>(json['temperatureC']),
      relativeHumidity: serializer.fromJson<double>(json['relativeHumidity']),
      lightRaw: serializer.fromJson<int>(json['lightRaw']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'farmId': serializer.toJson<String>(farmId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'co2Ppm': serializer.toJson<int>(co2Ppm),
      'temperatureC': serializer.toJson<double>(temperatureC),
      'relativeHumidity': serializer.toJson<double>(relativeHumidity),
      'lightRaw': serializer.toJson<int>(lightRaw),
    };
  }

  Reading copyWith(
          {int? id,
          String? farmId,
          DateTime? timestamp,
          int? co2Ppm,
          double? temperatureC,
          double? relativeHumidity,
          int? lightRaw}) =>
      Reading(
        id: id ?? this.id,
        farmId: farmId ?? this.farmId,
        timestamp: timestamp ?? this.timestamp,
        co2Ppm: co2Ppm ?? this.co2Ppm,
        temperatureC: temperatureC ?? this.temperatureC,
        relativeHumidity: relativeHumidity ?? this.relativeHumidity,
        lightRaw: lightRaw ?? this.lightRaw,
      );
  Reading copyWithCompanion(ReadingsCompanion data) {
    return Reading(
      id: data.id.present ? data.id.value : this.id,
      farmId: data.farmId.present ? data.farmId.value : this.farmId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      co2Ppm: data.co2Ppm.present ? data.co2Ppm.value : this.co2Ppm,
      temperatureC: data.temperatureC.present
          ? data.temperatureC.value
          : this.temperatureC,
      relativeHumidity: data.relativeHumidity.present
          ? data.relativeHumidity.value
          : this.relativeHumidity,
      lightRaw: data.lightRaw.present ? data.lightRaw.value : this.lightRaw,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reading(')
          ..write('id: $id, ')
          ..write('farmId: $farmId, ')
          ..write('timestamp: $timestamp, ')
          ..write('co2Ppm: $co2Ppm, ')
          ..write('temperatureC: $temperatureC, ')
          ..write('relativeHumidity: $relativeHumidity, ')
          ..write('lightRaw: $lightRaw')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, farmId, timestamp, co2Ppm, temperatureC, relativeHumidity, lightRaw);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reading &&
          other.id == this.id &&
          other.farmId == this.farmId &&
          other.timestamp == this.timestamp &&
          other.co2Ppm == this.co2Ppm &&
          other.temperatureC == this.temperatureC &&
          other.relativeHumidity == this.relativeHumidity &&
          other.lightRaw == this.lightRaw);
}

class ReadingsCompanion extends UpdateCompanion<Reading> {
  final Value<int> id;
  final Value<String> farmId;
  final Value<DateTime> timestamp;
  final Value<int> co2Ppm;
  final Value<double> temperatureC;
  final Value<double> relativeHumidity;
  final Value<int> lightRaw;
  const ReadingsCompanion({
    this.id = const Value.absent(),
    this.farmId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.co2Ppm = const Value.absent(),
    this.temperatureC = const Value.absent(),
    this.relativeHumidity = const Value.absent(),
    this.lightRaw = const Value.absent(),
  });
  ReadingsCompanion.insert({
    this.id = const Value.absent(),
    required String farmId,
    required DateTime timestamp,
    required int co2Ppm,
    required double temperatureC,
    required double relativeHumidity,
    required int lightRaw,
  })  : farmId = Value(farmId),
        timestamp = Value(timestamp),
        co2Ppm = Value(co2Ppm),
        temperatureC = Value(temperatureC),
        relativeHumidity = Value(relativeHumidity),
        lightRaw = Value(lightRaw);
  static Insertable<Reading> custom({
    Expression<int>? id,
    Expression<String>? farmId,
    Expression<DateTime>? timestamp,
    Expression<int>? co2Ppm,
    Expression<double>? temperatureC,
    Expression<double>? relativeHumidity,
    Expression<int>? lightRaw,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (farmId != null) 'farm_id': farmId,
      if (timestamp != null) 'timestamp': timestamp,
      if (co2Ppm != null) 'co2_ppm': co2Ppm,
      if (temperatureC != null) 'temperature_c': temperatureC,
      if (relativeHumidity != null) 'relative_humidity': relativeHumidity,
      if (lightRaw != null) 'light_raw': lightRaw,
    });
  }

  ReadingsCompanion copyWith(
      {Value<int>? id,
      Value<String>? farmId,
      Value<DateTime>? timestamp,
      Value<int>? co2Ppm,
      Value<double>? temperatureC,
      Value<double>? relativeHumidity,
      Value<int>? lightRaw}) {
    return ReadingsCompanion(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      timestamp: timestamp ?? this.timestamp,
      co2Ppm: co2Ppm ?? this.co2Ppm,
      temperatureC: temperatureC ?? this.temperatureC,
      relativeHumidity: relativeHumidity ?? this.relativeHumidity,
      lightRaw: lightRaw ?? this.lightRaw,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (farmId.present) {
      map['farm_id'] = Variable<String>(farmId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (co2Ppm.present) {
      map['co2_ppm'] = Variable<int>(co2Ppm.value);
    }
    if (temperatureC.present) {
      map['temperature_c'] = Variable<double>(temperatureC.value);
    }
    if (relativeHumidity.present) {
      map['relative_humidity'] = Variable<double>(relativeHumidity.value);
    }
    if (lightRaw.present) {
      map['light_raw'] = Variable<int>(lightRaw.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingsCompanion(')
          ..write('id: $id, ')
          ..write('farmId: $farmId, ')
          ..write('timestamp: $timestamp, ')
          ..write('co2Ppm: $co2Ppm, ')
          ..write('temperatureC: $temperatureC, ')
          ..write('relativeHumidity: $relativeHumidity, ')
          ..write('lightRaw: $lightRaw')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<Setting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const Setting(
      {required this.key, required this.value, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory Setting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Setting copyWith({String? key, String? value, DateTime? updatedAt}) =>
      Setting(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value),
        updatedAt = Value(updatedAt);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith(
      {Value<String>? key,
      Value<String>? value,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FarmsTable farms = $FarmsTable(this);
  late final $HarvestsTable harvests = $HarvestsTable(this);
  late final $DevicesTable devices = $DevicesTable(this);
  late final $ReadingsTable readings = $ReadingsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final FarmsDao farmsDao = FarmsDao(this as AppDatabase);
  late final HarvestsDao harvestsDao = HarvestsDao(this as AppDatabase);
  late final ReadingsDao readingsDao = ReadingsDao(this as AppDatabase);
  late final DevicesDao devicesDao = DevicesDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [farms, harvests, devices, readings, settings];
}

typedef $$FarmsTableCreateCompanionBuilder = FarmsCompanion Function({
  required String id,
  required String name,
  required String deviceId,
  Value<String?> location,
  Value<String?> notes,
  required DateTime createdAt,
  Value<DateTime?> lastActive,
  Value<int> totalHarvests,
  Value<double> totalYieldKg,
  Value<int?> primarySpecies,
  Value<String?> imageUrl,
  Value<bool> isActive,
  Value<String?> metadata,
  Value<int> rowid,
});
typedef $$FarmsTableUpdateCompanionBuilder = FarmsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> deviceId,
  Value<String?> location,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime?> lastActive,
  Value<int> totalHarvests,
  Value<double> totalYieldKg,
  Value<int?> primarySpecies,
  Value<String?> imageUrl,
  Value<bool> isActive,
  Value<String?> metadata,
  Value<int> rowid,
});

final class $$FarmsTableReferences
    extends BaseReferences<_$AppDatabase, $FarmsTable, Farm> {
  $$FarmsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$HarvestsTable, List<Harvest>> _harvestsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.harvests,
          aliasName: $_aliasNameGenerator(db.farms.id, db.harvests.farmId));

  $$HarvestsTableProcessedTableManager get harvestsRefs {
    final manager = $$HarvestsTableTableManager($_db, $_db.harvests)
        .filter((f) => f.farmId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_harvestsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$DevicesTable, List<Device>> _devicesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.devices,
          aliasName: $_aliasNameGenerator(db.farms.id, db.devices.farmId));

  $$DevicesTableProcessedTableManager get devicesRefs {
    final manager = $$DevicesTableTableManager($_db, $_db.devices)
        .filter((f) => f.farmId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_devicesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ReadingsTable, List<Reading>> _readingsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.readings,
          aliasName: $_aliasNameGenerator(db.farms.id, db.readings.farmId));

  $$ReadingsTableProcessedTableManager get readingsRefs {
    final manager = $$ReadingsTableTableManager($_db, $_db.readings)
        .filter((f) => f.farmId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_readingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$FarmsTableFilterComposer extends Composer<_$AppDatabase, $FarmsTable> {
  $$FarmsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastActive => $composableBuilder(
      column: $table.lastActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalHarvests => $composableBuilder(
      column: $table.totalHarvests, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalYieldKg => $composableBuilder(
      column: $table.totalYieldKg, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get primarySpecies => $composableBuilder(
      column: $table.primarySpecies,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnFilters(column));

  Expression<bool> harvestsRefs(
      Expression<bool> Function($$HarvestsTableFilterComposer f) f) {
    final $$HarvestsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.harvests,
        getReferencedColumn: (t) => t.farmId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HarvestsTableFilterComposer(
              $db: $db,
              $table: $db.harvests,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> devicesRefs(
      Expression<bool> Function($$DevicesTableFilterComposer f) f) {
    final $$DevicesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.devices,
        getReferencedColumn: (t) => t.farmId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DevicesTableFilterComposer(
              $db: $db,
              $table: $db.devices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> readingsRefs(
      Expression<bool> Function($$ReadingsTableFilterComposer f) f) {
    final $$ReadingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.readings,
        getReferencedColumn: (t) => t.farmId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReadingsTableFilterComposer(
              $db: $db,
              $table: $db.readings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$FarmsTableOrderingComposer
    extends Composer<_$AppDatabase, $FarmsTable> {
  $$FarmsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastActive => $composableBuilder(
      column: $table.lastActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalHarvests => $composableBuilder(
      column: $table.totalHarvests,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalYieldKg => $composableBuilder(
      column: $table.totalYieldKg,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get primarySpecies => $composableBuilder(
      column: $table.primarySpecies,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnOrderings(column));
}

class $$FarmsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FarmsTable> {
  $$FarmsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastActive => $composableBuilder(
      column: $table.lastActive, builder: (column) => column);

  GeneratedColumn<int> get totalHarvests => $composableBuilder(
      column: $table.totalHarvests, builder: (column) => column);

  GeneratedColumn<double> get totalYieldKg => $composableBuilder(
      column: $table.totalYieldKg, builder: (column) => column);

  GeneratedColumn<int> get primarySpecies => $composableBuilder(
      column: $table.primarySpecies, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  Expression<T> harvestsRefs<T extends Object>(
      Expression<T> Function($$HarvestsTableAnnotationComposer a) f) {
    final $$HarvestsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.harvests,
        getReferencedColumn: (t) => t.farmId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$HarvestsTableAnnotationComposer(
              $db: $db,
              $table: $db.harvests,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> devicesRefs<T extends Object>(
      Expression<T> Function($$DevicesTableAnnotationComposer a) f) {
    final $$DevicesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.devices,
        getReferencedColumn: (t) => t.farmId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DevicesTableAnnotationComposer(
              $db: $db,
              $table: $db.devices,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> readingsRefs<T extends Object>(
      Expression<T> Function($$ReadingsTableAnnotationComposer a) f) {
    final $$ReadingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.readings,
        getReferencedColumn: (t) => t.farmId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReadingsTableAnnotationComposer(
              $db: $db,
              $table: $db.readings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$FarmsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FarmsTable,
    Farm,
    $$FarmsTableFilterComposer,
    $$FarmsTableOrderingComposer,
    $$FarmsTableAnnotationComposer,
    $$FarmsTableCreateCompanionBuilder,
    $$FarmsTableUpdateCompanionBuilder,
    (Farm, $$FarmsTableReferences),
    Farm,
    PrefetchHooks Function(
        {bool harvestsRefs, bool devicesRefs, bool readingsRefs})> {
  $$FarmsTableTableManager(_$AppDatabase db, $FarmsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FarmsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FarmsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FarmsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<String?> location = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> lastActive = const Value.absent(),
            Value<int> totalHarvests = const Value.absent(),
            Value<double> totalYieldKg = const Value.absent(),
            Value<int?> primarySpecies = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FarmsCompanion(
            id: id,
            name: name,
            deviceId: deviceId,
            location: location,
            notes: notes,
            createdAt: createdAt,
            lastActive: lastActive,
            totalHarvests: totalHarvests,
            totalYieldKg: totalYieldKg,
            primarySpecies: primarySpecies,
            imageUrl: imageUrl,
            isActive: isActive,
            metadata: metadata,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String deviceId,
            Value<String?> location = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> lastActive = const Value.absent(),
            Value<int> totalHarvests = const Value.absent(),
            Value<double> totalYieldKg = const Value.absent(),
            Value<int?> primarySpecies = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FarmsCompanion.insert(
            id: id,
            name: name,
            deviceId: deviceId,
            location: location,
            notes: notes,
            createdAt: createdAt,
            lastActive: lastActive,
            totalHarvests: totalHarvests,
            totalYieldKg: totalYieldKg,
            primarySpecies: primarySpecies,
            imageUrl: imageUrl,
            isActive: isActive,
            metadata: metadata,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$FarmsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {harvestsRefs = false,
              devicesRefs = false,
              readingsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (harvestsRefs) db.harvests,
                if (devicesRefs) db.devices,
                if (readingsRefs) db.readings
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (harvestsRefs)
                    await $_getPrefetchedData<Farm, $FarmsTable, Harvest>(
                        currentTable: table,
                        referencedTable:
                            $$FarmsTableReferences._harvestsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FarmsTableReferences(db, table, p0).harvestsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.farmId == item.id),
                        typedResults: items),
                  if (devicesRefs)
                    await $_getPrefetchedData<Farm, $FarmsTable, Device>(
                        currentTable: table,
                        referencedTable:
                            $$FarmsTableReferences._devicesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FarmsTableReferences(db, table, p0).devicesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.farmId == item.id),
                        typedResults: items),
                  if (readingsRefs)
                    await $_getPrefetchedData<Farm, $FarmsTable, Reading>(
                        currentTable: table,
                        referencedTable:
                            $$FarmsTableReferences._readingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FarmsTableReferences(db, table, p0).readingsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.farmId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$FarmsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FarmsTable,
    Farm,
    $$FarmsTableFilterComposer,
    $$FarmsTableOrderingComposer,
    $$FarmsTableAnnotationComposer,
    $$FarmsTableCreateCompanionBuilder,
    $$FarmsTableUpdateCompanionBuilder,
    (Farm, $$FarmsTableReferences),
    Farm,
    PrefetchHooks Function(
        {bool harvestsRefs, bool devicesRefs, bool readingsRefs})>;
typedef $$HarvestsTableCreateCompanionBuilder = HarvestsCompanion Function({
  required String id,
  required String farmId,
  required DateTime harvestDate,
  required int species,
  required int stage,
  required double yieldKg,
  Value<int?> flushNumber,
  Value<double?> qualityScore,
  Value<String?> notes,
  Value<String?> photoUrls,
  Value<String?> metadata,
  Value<int> rowid,
});
typedef $$HarvestsTableUpdateCompanionBuilder = HarvestsCompanion Function({
  Value<String> id,
  Value<String> farmId,
  Value<DateTime> harvestDate,
  Value<int> species,
  Value<int> stage,
  Value<double> yieldKg,
  Value<int?> flushNumber,
  Value<double?> qualityScore,
  Value<String?> notes,
  Value<String?> photoUrls,
  Value<String?> metadata,
  Value<int> rowid,
});

final class $$HarvestsTableReferences
    extends BaseReferences<_$AppDatabase, $HarvestsTable, Harvest> {
  $$HarvestsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FarmsTable _farmIdTable(_$AppDatabase db) => db.farms
      .createAlias($_aliasNameGenerator(db.harvests.farmId, db.farms.id));

  $$FarmsTableProcessedTableManager get farmId {
    final $_column = $_itemColumn<String>('farm_id')!;

    final manager = $$FarmsTableTableManager($_db, $_db.farms)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_farmIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$HarvestsTableFilterComposer
    extends Composer<_$AppDatabase, $HarvestsTable> {
  $$HarvestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get harvestDate => $composableBuilder(
      column: $table.harvestDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get species => $composableBuilder(
      column: $table.species, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get stage => $composableBuilder(
      column: $table.stage, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get yieldKg => $composableBuilder(
      column: $table.yieldKg, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get flushNumber => $composableBuilder(
      column: $table.flushNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get qualityScore => $composableBuilder(
      column: $table.qualityScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoUrls => $composableBuilder(
      column: $table.photoUrls, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnFilters(column));

  $$FarmsTableFilterComposer get farmId {
    final $$FarmsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.farmId,
        referencedTable: $db.farms,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FarmsTableFilterComposer(
              $db: $db,
              $table: $db.farms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$HarvestsTableOrderingComposer
    extends Composer<_$AppDatabase, $HarvestsTable> {
  $$HarvestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get harvestDate => $composableBuilder(
      column: $table.harvestDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get species => $composableBuilder(
      column: $table.species, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get stage => $composableBuilder(
      column: $table.stage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get yieldKg => $composableBuilder(
      column: $table.yieldKg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get flushNumber => $composableBuilder(
      column: $table.flushNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get qualityScore => $composableBuilder(
      column: $table.qualityScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoUrls => $composableBuilder(
      column: $table.photoUrls, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnOrderings(column));

  $$FarmsTableOrderingComposer get farmId {
    final $$FarmsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.farmId,
        referencedTable: $db.farms,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FarmsTableOrderingComposer(
              $db: $db,
              $table: $db.farms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$HarvestsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HarvestsTable> {
  $$HarvestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get harvestDate => $composableBuilder(
      column: $table.harvestDate, builder: (column) => column);

  GeneratedColumn<int> get species =>
      $composableBuilder(column: $table.species, builder: (column) => column);

  GeneratedColumn<int> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);

  GeneratedColumn<double> get yieldKg =>
      $composableBuilder(column: $table.yieldKg, builder: (column) => column);

  GeneratedColumn<int> get flushNumber => $composableBuilder(
      column: $table.flushNumber, builder: (column) => column);

  GeneratedColumn<double> get qualityScore => $composableBuilder(
      column: $table.qualityScore, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get photoUrls =>
      $composableBuilder(column: $table.photoUrls, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  $$FarmsTableAnnotationComposer get farmId {
    final $$FarmsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.farmId,
        referencedTable: $db.farms,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FarmsTableAnnotationComposer(
              $db: $db,
              $table: $db.farms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$HarvestsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $HarvestsTable,
    Harvest,
    $$HarvestsTableFilterComposer,
    $$HarvestsTableOrderingComposer,
    $$HarvestsTableAnnotationComposer,
    $$HarvestsTableCreateCompanionBuilder,
    $$HarvestsTableUpdateCompanionBuilder,
    (Harvest, $$HarvestsTableReferences),
    Harvest,
    PrefetchHooks Function({bool farmId})> {
  $$HarvestsTableTableManager(_$AppDatabase db, $HarvestsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HarvestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HarvestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HarvestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> farmId = const Value.absent(),
            Value<DateTime> harvestDate = const Value.absent(),
            Value<int> species = const Value.absent(),
            Value<int> stage = const Value.absent(),
            Value<double> yieldKg = const Value.absent(),
            Value<int?> flushNumber = const Value.absent(),
            Value<double?> qualityScore = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> photoUrls = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HarvestsCompanion(
            id: id,
            farmId: farmId,
            harvestDate: harvestDate,
            species: species,
            stage: stage,
            yieldKg: yieldKg,
            flushNumber: flushNumber,
            qualityScore: qualityScore,
            notes: notes,
            photoUrls: photoUrls,
            metadata: metadata,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String farmId,
            required DateTime harvestDate,
            required int species,
            required int stage,
            required double yieldKg,
            Value<int?> flushNumber = const Value.absent(),
            Value<double?> qualityScore = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> photoUrls = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              HarvestsCompanion.insert(
            id: id,
            farmId: farmId,
            harvestDate: harvestDate,
            species: species,
            stage: stage,
            yieldKg: yieldKg,
            flushNumber: flushNumber,
            qualityScore: qualityScore,
            notes: notes,
            photoUrls: photoUrls,
            metadata: metadata,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$HarvestsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({farmId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (farmId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.farmId,
                    referencedTable: $$HarvestsTableReferences._farmIdTable(db),
                    referencedColumn:
                        $$HarvestsTableReferences._farmIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$HarvestsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $HarvestsTable,
    Harvest,
    $$HarvestsTableFilterComposer,
    $$HarvestsTableOrderingComposer,
    $$HarvestsTableAnnotationComposer,
    $$HarvestsTableCreateCompanionBuilder,
    $$HarvestsTableUpdateCompanionBuilder,
    (Harvest, $$HarvestsTableReferences),
    Harvest,
    PrefetchHooks Function({bool farmId})>;
typedef $$DevicesTableCreateCompanionBuilder = DevicesCompanion Function({
  required String deviceId,
  required String name,
  required String address,
  Value<String?> farmId,
  required DateTime lastConnected,
  Value<int> rowid,
});
typedef $$DevicesTableUpdateCompanionBuilder = DevicesCompanion Function({
  Value<String> deviceId,
  Value<String> name,
  Value<String> address,
  Value<String?> farmId,
  Value<DateTime> lastConnected,
  Value<int> rowid,
});

final class $$DevicesTableReferences
    extends BaseReferences<_$AppDatabase, $DevicesTable, Device> {
  $$DevicesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FarmsTable _farmIdTable(_$AppDatabase db) => db.farms
      .createAlias($_aliasNameGenerator(db.devices.farmId, db.farms.id));

  $$FarmsTableProcessedTableManager? get farmId {
    final $_column = $_itemColumn<String>('farm_id');
    if ($_column == null) return null;
    final manager = $$FarmsTableTableManager($_db, $_db.farms)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_farmIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$DevicesTableFilterComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastConnected => $composableBuilder(
      column: $table.lastConnected, builder: (column) => ColumnFilters(column));

  $$FarmsTableFilterComposer get farmId {
    final $$FarmsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.farmId,
        referencedTable: $db.farms,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FarmsTableFilterComposer(
              $db: $db,
              $table: $db.farms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DevicesTableOrderingComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastConnected => $composableBuilder(
      column: $table.lastConnected,
      builder: (column) => ColumnOrderings(column));

  $$FarmsTableOrderingComposer get farmId {
    final $$FarmsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.farmId,
        referencedTable: $db.farms,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FarmsTableOrderingComposer(
              $db: $db,
              $table: $db.farms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DevicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DevicesTable> {
  $$DevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<DateTime> get lastConnected => $composableBuilder(
      column: $table.lastConnected, builder: (column) => column);

  $$FarmsTableAnnotationComposer get farmId {
    final $$FarmsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.farmId,
        referencedTable: $db.farms,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FarmsTableAnnotationComposer(
              $db: $db,
              $table: $db.farms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DevicesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DevicesTable,
    Device,
    $$DevicesTableFilterComposer,
    $$DevicesTableOrderingComposer,
    $$DevicesTableAnnotationComposer,
    $$DevicesTableCreateCompanionBuilder,
    $$DevicesTableUpdateCompanionBuilder,
    (Device, $$DevicesTableReferences),
    Device,
    PrefetchHooks Function({bool farmId})> {
  $$DevicesTableTableManager(_$AppDatabase db, $DevicesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> deviceId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> address = const Value.absent(),
            Value<String?> farmId = const Value.absent(),
            Value<DateTime> lastConnected = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DevicesCompanion(
            deviceId: deviceId,
            name: name,
            address: address,
            farmId: farmId,
            lastConnected: lastConnected,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String deviceId,
            required String name,
            required String address,
            Value<String?> farmId = const Value.absent(),
            required DateTime lastConnected,
            Value<int> rowid = const Value.absent(),
          }) =>
              DevicesCompanion.insert(
            deviceId: deviceId,
            name: name,
            address: address,
            farmId: farmId,
            lastConnected: lastConnected,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$DevicesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({farmId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (farmId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.farmId,
                    referencedTable: $$DevicesTableReferences._farmIdTable(db),
                    referencedColumn:
                        $$DevicesTableReferences._farmIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$DevicesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DevicesTable,
    Device,
    $$DevicesTableFilterComposer,
    $$DevicesTableOrderingComposer,
    $$DevicesTableAnnotationComposer,
    $$DevicesTableCreateCompanionBuilder,
    $$DevicesTableUpdateCompanionBuilder,
    (Device, $$DevicesTableReferences),
    Device,
    PrefetchHooks Function({bool farmId})>;
typedef $$ReadingsTableCreateCompanionBuilder = ReadingsCompanion Function({
  Value<int> id,
  required String farmId,
  required DateTime timestamp,
  required int co2Ppm,
  required double temperatureC,
  required double relativeHumidity,
  required int lightRaw,
});
typedef $$ReadingsTableUpdateCompanionBuilder = ReadingsCompanion Function({
  Value<int> id,
  Value<String> farmId,
  Value<DateTime> timestamp,
  Value<int> co2Ppm,
  Value<double> temperatureC,
  Value<double> relativeHumidity,
  Value<int> lightRaw,
});

final class $$ReadingsTableReferences
    extends BaseReferences<_$AppDatabase, $ReadingsTable, Reading> {
  $$ReadingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $FarmsTable _farmIdTable(_$AppDatabase db) => db.farms
      .createAlias($_aliasNameGenerator(db.readings.farmId, db.farms.id));

  $$FarmsTableProcessedTableManager get farmId {
    final $_column = $_itemColumn<String>('farm_id')!;

    final manager = $$FarmsTableTableManager($_db, $_db.farms)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_farmIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ReadingsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingsTable> {
  $$ReadingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get co2Ppm => $composableBuilder(
      column: $table.co2Ppm, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get temperatureC => $composableBuilder(
      column: $table.temperatureC, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get relativeHumidity => $composableBuilder(
      column: $table.relativeHumidity,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lightRaw => $composableBuilder(
      column: $table.lightRaw, builder: (column) => ColumnFilters(column));

  $$FarmsTableFilterComposer get farmId {
    final $$FarmsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.farmId,
        referencedTable: $db.farms,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FarmsTableFilterComposer(
              $db: $db,
              $table: $db.farms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReadingsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingsTable> {
  $$ReadingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get co2Ppm => $composableBuilder(
      column: $table.co2Ppm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get temperatureC => $composableBuilder(
      column: $table.temperatureC,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get relativeHumidity => $composableBuilder(
      column: $table.relativeHumidity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lightRaw => $composableBuilder(
      column: $table.lightRaw, builder: (column) => ColumnOrderings(column));

  $$FarmsTableOrderingComposer get farmId {
    final $$FarmsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.farmId,
        referencedTable: $db.farms,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FarmsTableOrderingComposer(
              $db: $db,
              $table: $db.farms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReadingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingsTable> {
  $$ReadingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get co2Ppm =>
      $composableBuilder(column: $table.co2Ppm, builder: (column) => column);

  GeneratedColumn<double> get temperatureC => $composableBuilder(
      column: $table.temperatureC, builder: (column) => column);

  GeneratedColumn<double> get relativeHumidity => $composableBuilder(
      column: $table.relativeHumidity, builder: (column) => column);

  GeneratedColumn<int> get lightRaw =>
      $composableBuilder(column: $table.lightRaw, builder: (column) => column);

  $$FarmsTableAnnotationComposer get farmId {
    final $$FarmsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.farmId,
        referencedTable: $db.farms,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$FarmsTableAnnotationComposer(
              $db: $db,
              $table: $db.farms,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReadingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReadingsTable,
    Reading,
    $$ReadingsTableFilterComposer,
    $$ReadingsTableOrderingComposer,
    $$ReadingsTableAnnotationComposer,
    $$ReadingsTableCreateCompanionBuilder,
    $$ReadingsTableUpdateCompanionBuilder,
    (Reading, $$ReadingsTableReferences),
    Reading,
    PrefetchHooks Function({bool farmId})> {
  $$ReadingsTableTableManager(_$AppDatabase db, $ReadingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> farmId = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<int> co2Ppm = const Value.absent(),
            Value<double> temperatureC = const Value.absent(),
            Value<double> relativeHumidity = const Value.absent(),
            Value<int> lightRaw = const Value.absent(),
          }) =>
              ReadingsCompanion(
            id: id,
            farmId: farmId,
            timestamp: timestamp,
            co2Ppm: co2Ppm,
            temperatureC: temperatureC,
            relativeHumidity: relativeHumidity,
            lightRaw: lightRaw,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String farmId,
            required DateTime timestamp,
            required int co2Ppm,
            required double temperatureC,
            required double relativeHumidity,
            required int lightRaw,
          }) =>
              ReadingsCompanion.insert(
            id: id,
            farmId: farmId,
            timestamp: timestamp,
            co2Ppm: co2Ppm,
            temperatureC: temperatureC,
            relativeHumidity: relativeHumidity,
            lightRaw: lightRaw,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ReadingsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({farmId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (farmId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.farmId,
                    referencedTable: $$ReadingsTableReferences._farmIdTable(db),
                    referencedColumn:
                        $$ReadingsTableReferences._farmIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ReadingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReadingsTable,
    Reading,
    $$ReadingsTableFilterComposer,
    $$ReadingsTableOrderingComposer,
    $$ReadingsTableAnnotationComposer,
    $$ReadingsTableCreateCompanionBuilder,
    $$ReadingsTableUpdateCompanionBuilder,
    (Reading, $$ReadingsTableReferences),
    Reading,
    PrefetchHooks Function({bool farmId})>;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()> {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion(
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SettingsCompanion.insert(
            key: key,
            value: value,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsTable,
    Setting,
    $$SettingsTableFilterComposer,
    $$SettingsTableOrderingComposer,
    $$SettingsTableAnnotationComposer,
    $$SettingsTableCreateCompanionBuilder,
    $$SettingsTableUpdateCompanionBuilder,
    (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
    Setting,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FarmsTableTableManager get farms =>
      $$FarmsTableTableManager(_db, _db.farms);
  $$HarvestsTableTableManager get harvests =>
      $$HarvestsTableTableManager(_db, _db.harvests);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db, _db.devices);
  $$ReadingsTableTableManager get readings =>
      $$ReadingsTableTableManager(_db, _db.readings);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
