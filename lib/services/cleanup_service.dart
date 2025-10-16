import '../data/todo_repository.dart';

class CleanupService {
  final TodoRepository repo;
  CleanupService(this.repo);

  Future<void> purgeOldTrash() => repo.purgeExpiredTrash();
}
