import 'package:hive/hive.dart';
import '../../domain/entities/academic.dart';

class SubjectModel extends HiveObject {
  String id;
  String code;
  String name;
  String facultyId;
  String? facultyName;
  String description;
  int credits;
  Map<String, int> markScheme;

  SubjectModel({
    required this.id,
    required this.code,
    required this.name,
    required this.facultyId,
    this.facultyName,
    this.description = '',
    this.credits = 3,
    this.markScheme = const {},
  });

  factory SubjectModel.fromEntity(Subject entity) {
    return SubjectModel(
      id: entity.id,
      code: entity.code,
      name: entity.name,
      facultyId: entity.facultyId,
      facultyName: entity.facultyName,
      description: entity.description,
      credits: entity.credits,
      markScheme: entity.markScheme,
    );
  }

  Subject toEntity() {
    return Subject(
      id: id,
      code: code,
      name: name,
      facultyId: facultyId,
      facultyName: facultyName,
      description: description,
      credits: credits,
      markScheme: markScheme,
    );
  }
}

class SubjectModelAdapter extends TypeAdapter<SubjectModel> {
  @override
  final int typeId = 2;

  @override
  SubjectModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubjectModel(
      id: fields[0] as String,
      code: fields[1] as String,
      name: fields[2] as String,
      facultyId: fields[3] as String,
      facultyName: fields[4] as String?,
      description: fields[5] as String,
      credits: fields[6] as int,
      markScheme: (fields[7] as Map).cast<String, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, SubjectModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.code)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.facultyId)
      ..writeByte(4)
      ..write(obj.facultyName)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.credits)
      ..writeByte(7)
      ..write(obj.markScheme);
  }
}

class StudentMarkModel extends HiveObject {
  String id;
  String studentId;
  String studentName;
  String subjectId;
  Map<String, double> scores;
  DateTime? lastUpdated;

  StudentMarkModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.subjectId,
    required this.scores,
    this.lastUpdated,
  });

  factory StudentMarkModel.fromEntity(StudentMark entity) {
    return StudentMarkModel(
      id: entity.id,
      studentId: entity.studentId,
      studentName: entity.studentName,
      subjectId: entity.subjectId,
      scores: entity.scores,
      lastUpdated: entity.lastUpdated,
    );
  }

  StudentMark toEntity() {
    return StudentMark(
      id: id,
      studentId: studentId,
      studentName: studentName,
      subjectId: subjectId,
      scores: scores,
      lastUpdated: lastUpdated,
    );
  }
}

class StudentMarkModelAdapter extends TypeAdapter<StudentMarkModel> {
  @override
  final int typeId = 3;

  @override
  StudentMarkModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudentMarkModel(
      id: fields[0] as String,
      studentId: fields[1] as String,
      studentName: fields[2] as String,
      subjectId: fields[3] as String,
      scores: (fields[4] as Map).cast<String, double>(),
      lastUpdated: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, StudentMarkModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.studentName)
      ..writeByte(3)
      ..write(obj.subjectId)
      ..writeByte(4)
      ..write(obj.scores)
      ..writeByte(5)
      ..write(obj.lastUpdated);
  }
}

class TimetableModel extends HiveObject {
  String id;
  String subjectId;
  String subjectName;
  String facultyId;
  int dayOfWeek;
  String startTime;
  String endTime;
  String room;

  TimetableModel({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.facultyId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.room,
  });

  factory TimetableModel.fromEntity(TimetableEntry entity) {
    return TimetableModel(
      id: entity.id,
      subjectId: entity.subjectId,
      subjectName: entity.subjectName,
      facultyId: entity.facultyId,
      dayOfWeek: entity.dayOfWeek,
      startTime: entity.startTime,
      endTime: entity.endTime,
      room: entity.room,
    );
  }

  TimetableEntry toEntity() {
    return TimetableEntry(
      id: id,
      subjectId: subjectId,
      subjectName: subjectName,
      facultyId: facultyId,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      endTime: endTime,
      room: room,
    );
  }
}

class TimetableModelAdapter extends TypeAdapter<TimetableModel> {
  @override
  final int typeId = 4;

  @override
  TimetableModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimetableModel(
      id: fields[0] as String,
      subjectId: fields[1] as String,
      subjectName: fields[2] as String,
      facultyId: fields[3] as String,
      dayOfWeek: fields[4] as int,
      startTime: fields[5] as String,
      endTime: fields[6] as String,
      room: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TimetableModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.subjectId)
      ..writeByte(2)
      ..write(obj.subjectName)
      ..writeByte(3)
      ..write(obj.facultyId)
      ..writeByte(4)
      ..write(obj.dayOfWeek)
      ..writeByte(5)
      ..write(obj.startTime)
      ..writeByte(6)
      ..write(obj.endTime)
      ..writeByte(7)
      ..write(obj.room);
  }
}
