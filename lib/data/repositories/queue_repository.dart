import '../../domain/entities/queue_entry.dart';
import '../models/queue_entry_model.dart';
import '../services/queue_service.dart';

class QueueRepository {
  QueueRepository(this._service);

  final QueueService _service;

  Future<List<QueueEntryModel>> fetchQueueForFaculty(String facultyId) {
    return _service.fetchQueueForFaculty(facultyId);
  }

  Stream<List<QueueEntryModel>> watchQueueForFaculty(String facultyId) {
    return _service.watchQueueForFaculty(facultyId);
  }

  Stream<List<QueueEntryModel>> watchQueueForStudent(String studentId) {
    return _service.watchQueueForStudent(studentId);
  }

  Future<QueueEntryModel> joinQueue({
    required String facultyId,
    required String studentId,
  }) {
    return _service.joinQueue(facultyId: facultyId, studentId: studentId);
  }

  Future<QueueEntryModel> updateQueueStatus({
    required String queueEntryId,
    required QueueEntryStatus status,
  }) {
    return _service.updateQueueStatus(
      queueEntryId: queueEntryId,
      status: status,
    );
  }

  Future<QueueEntryModel?> callNextStudent(String facultyId) {
    return _service.callNextStudent(facultyId);
  }
}
