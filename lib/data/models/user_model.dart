import 'package:hive/hive.dart';
import '../../domain/entities/user.dart';

class UserModel extends HiveObject {
  String id;
  String name;
  String email;
  String? avatarUrl;
  int roleIndex;
  String? studentCode;
  String? department;
  DateTime createdAt;
  DateTime? lastLoginAt;
  String password;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.roleIndex,
    this.studentCode,
    this.department,
    required this.createdAt,
    this.lastLoginAt,
    required this.password,
  });

  UserRole get role => UserRole.values[roleIndex];

  factory UserModel.fromEntity(User user, {String password = ''}) {
    return UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      avatarUrl: user.avatarUrl,
      roleIndex: user.role.index,
      studentCode: user.studentCode,
      department: user.department,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
      password: password,
    );
  }

  User toEntity() {
    return User(
      id: id,
      name: name,
      email: email,
      avatarUrl: avatarUrl,
      role: role,
      studentCode: studentCode,
      department: department,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    int? roleIndex,
    String? studentCode,
    String? department,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? password,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      roleIndex: roleIndex ?? this.roleIndex,
      studentCode: studentCode ?? this.studentCode,
      department: department ?? this.department,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      password: password ?? this.password,
    );
  }
}

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String,
      avatarUrl: fields[3] as String?,
      roleIndex: fields[4] as int,
      studentCode: fields[5] as String?,
      department: fields[6] as String?,
      createdAt: fields[7] as DateTime,
      lastLoginAt: fields[8] as DateTime?,
      password: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.avatarUrl)
      ..writeByte(4)
      ..write(obj.roleIndex)
      ..writeByte(5)
      ..write(obj.studentCode)
      ..writeByte(6)
      ..write(obj.department)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.lastLoginAt)
      ..writeByte(9)
      ..write(obj.password);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
