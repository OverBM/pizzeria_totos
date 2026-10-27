import '../models/promotion.dart';

/// Contrato de promociones.
abstract interface class PromotionRepository {
  Future<List<Promotion>> fetchPromotions();

  Stream<List<Promotion>> watchPromotions();
}
