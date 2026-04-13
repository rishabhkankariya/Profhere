import 'package:hive/hive.dart';
import '../../domain/entities/faculty.dart';

class FacultyModel extends HiveObject {
  String id;
  String name;
  String email;
  String department;
  String building;
  String cabinId;
  int statusIndex;
  String? zone;
  String? specialization;
  String? bio;
  String? avatarUrl;
  String? phoneNumber;
  int publicationsCount;
  double rating;
  int consultationCount;
  DateTime lastUpdated;
  DateTime? expectedReturnAt;
  DateTime? manualOverrideUntil;
  String? activeContext;

  FacultyModel({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.building,
    required this.cabinId,
    required this.statusIndex,
    this.zone,
    this.specialization,
    this.bio,
    this.avatarUrl,
    this.phoneNumber,
    this.publicationsCount = 0,
    this.rating = 0.0,
    this.consultationCount = 0,
    required this.lastUpdated,
    this.expectedReturnAt,
    this.manualOverrideUntil,
    this.activeContext,
  });

  FacultyStatus get status => FacultyStatus.values[statusIndex];

  factory FacultyModel.fromEntity(Faculty faculty) {
    return FacultyModel(
      id: faculty.id,
      name: faculty.name,
      email: faculty.email,
      department: faculty.department,
      building: faculty.building,
      cabinId: faculty.cabinId,
      statusIndex: faculty.status.index,
      zone: faculty.zone,
      specialization: faculty.specialization,
      bio: faculty.bio,
      avatarUrl: faculty.avatarUrl,
      phoneNumber: faculty.phoneNumber,
      publicationsCount: faculty.publicationsCount,
      rating: faculty.rating,
      consultationCount: faculty.consultationCount,
      lastUpdated: faculty.lastUpdated,
      expectedReturnAt: faculty.expectedReturnAt,
      manualOverrideUntil: faculty.manualOverrideUntil,
      activeContext: faculty.activeContext,
    );
  }

  Faculty toEntity() {
    return Faculty(
      id: id,
      name: name,
      email: email,
      department: department,
      building: building,
      cabinId: cabinId,
      status: status,
      zone: zone,
      specialization: specialization,
      bio: bio,
      avatarUrl: avatarUrl,
      phoneNumber: phoneNumber,
      publicationsCount: publicationsCount,
      rating: rating,
      consultationCount: consultationCount,
      lastUpdated: lastUpdated,
      expectedReturnAt: expectedReturnAt,
      manualOverrideUntil: manualOverrideUntil,
      activeContext: activeContext,
    );
  }

  FacultyModel copyWith({
    String? id,
    String? name,
    String? email,
    String? department,
    String? building,
    String? cabinId,
    int? statusIndex,
    String? zone,
    String? specialization,
    String? bio,
    String? avatarUrl,
    String? phoneNumber,
    int? publicationsCount,
    double? rating,
    int? consultationCount,
    DateTime? lastUpdated,
    DateTime? expectedReturnAt,
    DateTime? manualOverrideUntil,
    String? activeContext,
  }) {
    return FacultyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      building: building ?? this.building,
      cabinId: cabinId ?? this.cabinId,
      statusIndex: statusIndex ?? this.statusIndex,
      zone: zone ?? this.zone,
      specialization: specialization ?? this.specialization,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      publicationsCount: publicationsCount ?? this.publicationsCount,
      rating: rating ?? this.rating,
      consultationCount: consultationCount ?? this.consultationCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      expectedReturnAt: expectedReturnAt ?? this.expectedReturnAt,
      manualOverrideUntil: manualOverrideUntil ?? this.manualOverrideUntil,
      activeContext: activeContext ?? this.activeContext,
    );
  }
}

class FacultyModelAdapter extends TypeAdapter<FacultyModel> {
  @override
  final int typeId = 1;

  @override
  FacultyModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FacultyModel(
      id: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String,
      department: fields[3] as String,
      building: fields[4] as String,
      cabinId: fields[5] as String,
      statusIndex: fields[6] as int,
      zone: fields[7] as String?,
      specialization: fields[8] as String?,
      bio: fields[9] as String?,
      avatarUrl: fields[10] as String?,
      phoneNumber: fields[11] as String?,
      publicationsCount: fields[12] as int? ?? 0,
      rating: fields[13] as double? ?? 0.0,
      consultationCount: fields[14] as int? ?? 0,
      lastUpdated: fields[15] as DateTime,
      expectedReturnAt: fields[16] as DateTime?,
      manualOverrideUntil: fields[17] as DateTime?,
      activeContext: fields[18] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FacultyModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.department)
      ..writeByte(4)
      ..write(obj.building)
      ..writeByte(5)
      ..write(obj.cabinId)
      ..writeByte(6)
      ..write(obj.statusIndex)
      ..writeByte(7)
      ..write(obj.zone)
      ..writeByte(8)
      ..write(obj.specialization)
      ..writeByte(9)
      ..write(obj.bio)
      ..writeByte(10)
      ..write(obj.avatarUrl)
      ..writeByte(11)
      ..write(obj.phoneNumber)
      ..writeByte(12)
      ..write(obj.publicationsCount)
      ..writeByte(13)
      ..write(obj.rating)
      ..writeByte(14)
      ..write(obj.consultationCount)
      ..writeByte(15)
      ..write(obj.lastUpdated)
      ..writeByte(16)
      ..write(obj.expectedReturnAt)
      ..writeByte(17)
      ..write(obj.manualOverrideUntil)
      ..writeByte(18)
      ..write(obj.activeContext);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FacultyModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
