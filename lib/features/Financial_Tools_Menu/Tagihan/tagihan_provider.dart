import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/bill_model.dart';
import 'tagihan_repository.dart';

final billsRepositoryProvider = Provider<RepositoryTagihan>((ref) {
  return RepositoryTagihan(Supabase.instance.client);
});

final billsProvider = FutureProvider.autoDispose<List<BillModel>>((ref) async {
  final repository = ref.watch(billsRepositoryProvider);
  return repository.fetchBills();
});
