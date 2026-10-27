import '../models/branch.dart';

/// Contrato de sedes.
abstract interface class BranchRepository {
  Future<List<Branch>> fetchBranches();

  Stream<List<Branch>> watchBranches();
}
