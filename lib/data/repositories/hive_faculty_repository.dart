import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../domain/entities/faculty.dart';
import '../../domain/repositories/faculty_repository.dart';
import '../datasources/local/hive_service.dart';
import '../models/faculty_model.dart';

class HiveFacultyRepository implements FacultyRepository {
  static const _uuid = Uuid();
  final _facultyController = StreamController<List<Faculty>>.broadcast();

  void _notifyListeners() {
    getFacultiesOnce().then((faculties) => _facultyController.add(faculties));
  }

  @override
  Future<List<Faculty>> getFacultiesOnce() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return HiveService.faculty.values.map((m) => m.toEntity()).toList();
  }

  @override
  Stream<List<Faculty>> getFaculties() async* {
    yield await getFacultiesOnce();
    yield* _facultyController.stream;
  }

  @override
  Future<Faculty?> getFacultyById(String id) async {
    final model = HiveService.faculty.get(id);
    return model?.toEntity();
  }

  @override
  Future<void> updateFacultyStatus(
    String id,
    FacultyStatus status, {
    String? activeContext,
    DateTime? expectedReturnAt,
    DateTime? manualOverrideUntil,
  }) async {
    final model = HiveService.faculty.get(id);
    if (model == null) return;

    final updated = model.copyWith(
      statusIndex: status.index,
      activeContext: activeContext,
      expectedReturnAt: expectedReturnAt,
      manualOverrideUntil: manualOverrideUntil,
      lastUpdated: DateTime.now(),
    );

    await HiveService.faculty.put(id, updated);
    _notifyListeners();
  }

  @override
  Future<void> addFaculty(Faculty faculty) async {
    final model = FacultyModel.fromEntity(
      faculty.copyWith(
        id: faculty.id.isEmpty ? _uuid.v4() : faculty.id,
        lastUpdated: DateTime.now(),
      ),
    );

    await HiveService.faculty.put(model.id, model);
    _notifyListeners();
  }

  @override
  Future<void> updateFaculty(Faculty faculty) async {
    final model = FacultyModel.fromEntity(faculty);
    await HiveService.faculty.put(faculty.id, model);
    _notifyListeners();
  }

  @override
  Future<void> deleteFaculty(String id) async {
    await HiveService.faculty.delete(id);
    _notifyListeners();
  }

  void dispose() {
    _facultyController.close();
  }
}
