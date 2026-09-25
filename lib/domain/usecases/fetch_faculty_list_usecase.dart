import '../../domain/entities/faculty.dart';
import '../../data/repositories/faculty_repository.dart';

class FetchFacultyListUseCase {
  FetchFacultyListUseCase(this._repository);

  final FacultyRepository _repository;

  Future<List<Faculty>> call() {
    return _repository.fetchFacultyList();
  }
}
