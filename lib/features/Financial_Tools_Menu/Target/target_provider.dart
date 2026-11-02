import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/target_model.dart';
import 'target_repository.dart';

final targetRepositoryProvider = Provider<TargetRepository>((ref) {
  return TargetRepository(Supabase.instance.client);
});

final targetsProvider = FutureProvider.autoDispose<List<TargetModel>>((
  ref,
) async {
  final repository = ref.watch(targetRepositoryProvider);
  return repository.fetchTargets();
});
