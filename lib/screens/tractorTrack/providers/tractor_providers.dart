import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tractor_repository.dart';

final tractorRepositoryProvider = Provider((ref) => TractorRepository());

final tractorStatsProvider = FutureProvider.family<TractorYearlyStats, int>((ref, year) {
  final repo = ref.watch(tractorRepositoryProvider);
  return repo.fetchYearlyStats(year: year);
});
