import 'model_utils.dart';

/// Estado de un reclamo.
///
/// El canal interno tiene un único estado visible: «Enviado».
enum ClaimStatus {
  enviado;

  String get name => 'enviado';

  String get label => 'ENVIADO';

  static ClaimStatus fromName(String? name) => ClaimStatus.enviado;
}

/// Motivo de reclamo (catálogo en `configuracion/app.motivosReclamo`).
class ClaimReason {
  const ClaimReason({required this.id, required this.label});

  final String id;
  final String label;

  static const List<ClaimReason> fallback = [
    ClaimReason(id: 'pedido', label: 'Problema con mi pedido'),
    ClaimReason(id: 'producto', label: 'Calidad del producto'),
    ClaimReason(id: 'entrega', label: 'Demora o entrega'),
    ClaimReason(id: 'atencion', label: 'Atención al cliente'),
    ClaimReason(id: 'otro', label: 'Otro motivo'),
  ];

  factory ClaimReason.fromMap(Map<String, dynamic> json) => ClaimReason(
    id: ModelUtils.asString(json['id']),
    label: ModelUtils.asString(json['etiqueta'] ?? json['label']),
  );

  Map<String, dynamic> toMap() => {'id': id, 'etiqueta': label};
}

/// Reclamo creado por una cuenta (`reclamos/{id}`).
class Claim {
  const Claim({
    required this.id,
    required this.code,
    required this.uid,
    required this.categoryId,
    required this.categoryLabel,
    required this.message,
    required this.createdAt,
    required this.updatedAt,
    this.orderId,
    this.branchId,
    this.branchName,
    this.status = ClaimStatus.enviado,
  });

  final String id;

  /// Código legible (p. ej. `REC-20261016-4821`).
  final String code;
  final String uid;
  final String? orderId;
  final String? branchId;
  final String? branchName;
  final String categoryId;
  final String categoryLabel;
  final String message;
  final ClaimStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Claim.fromMap(Map<String, dynamic> json, {String? id}) => Claim(
    id: id ?? ModelUtils.asString(json['id']),
    code: ModelUtils.asString(json['codigo'] ?? json['code']),
    uid: ModelUtils.asString(json['uid']),
    orderId: ModelUtils.asStringOrNull(json['pedidoId'] ?? json['orderId']),
    branchId: ModelUtils.asStringOrNull(json['sedeId'] ?? json['branchId']),
    branchName: ModelUtils.asStringOrNull(
      json['sedeNombre'] ?? json['branchName'],
    ),
    categoryId: ModelUtils.asString(
      json['motivoId'] ?? json['category'],
      fallback: 'otro',
    ),
    categoryLabel: ModelUtils.asString(
      json['motivoEtiqueta'] ?? json['categoryLabel'],
      fallback: 'Otro motivo',
    ),
    message: ModelUtils.asString(json['mensaje'] ?? json['message']),
    status: ClaimStatus.fromName(
      ModelUtils.asStringOrNull(json['estado'] ?? json['status']),
    ),
    createdAt: ModelUtils.asDateTime(json['createdAt']) ?? DateTime(2000),
    updatedAt: ModelUtils.asDateTime(json['updatedAt']) ?? DateTime(2000),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'codigo': code,
    'uid': uid,
    if (orderId != null) 'pedidoId': orderId,
    if (branchId != null) 'sedeId': branchId,
    if (branchName != null) 'sedeNombre': branchName,
    'motivoId': categoryId,
    'motivoEtiqueta': categoryLabel,
    'mensaje': message,
    'estado': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
