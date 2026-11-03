import '../core/format/money.dart';
import 'media_ref.dart';
import 'model_utils.dart';

/// Plan pago de delivery (`planesDelivery/{id}`).
class DeliveryPlan {
  const DeliveryPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.priceSoles,
    required this.days,
    required this.minimumOrderSoles,
    this.longDescription = '',
    this.savingsSoles,
    this.label = '',
    this.benefits = const [],
    this.image,
    this.iconSvg = 'calendar',
    this.active = true,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String description;
  final String longDescription;
  final double priceSoles;
  final int days;
  final double minimumOrderSoles;
  final double? savingsSoles;
  final String label;
  final List<String> benefits;
  final MediaRef? image;
  final String iconSvg;
  final bool active;
  final int sortOrder;

  factory DeliveryPlan.fromMap(Map<String, dynamic> json) => DeliveryPlan(
    id: ModelUtils.asString(json['id']),
    name: ModelUtils.asString(json['nombre'] ?? json['name']),
    description: ModelUtils.asString(
      json['descripcion'] ?? json['description'],
    ),
    longDescription: ModelUtils.asString(
      json['descripcionLarga'] ?? json['longDescription'],
    ),
    priceSoles: ModelUtils.asMoney(
      json,
      'precio',
      centsKey: 'priceCents',
    ),
    days: ModelUtils.asInt(json['dias'] ?? json['days']),
    minimumOrderSoles: ModelUtils.asMoney(
      json,
      'compraMinimaEnvioGratis',
      centsKey: 'minimumOrderCents',
      fallback: 40,
    ),
    savingsSoles: ModelUtils.asMoneyOrNull(
      json,
      'ahorroSoles',
      centsKey: 'savingsCents',
    ),
    label: ModelUtils.asString(json['etiqueta'] ?? json['label']),
    benefits: ModelUtils.asStringList(
      json['beneficios'] ?? json['benefits'],
    ),
    image: MediaRef.fromValue(json['imagen'] ?? json['image']),
    iconSvg: ModelUtils.asString(
      json['iconoSvg'] ?? json['iconSvg'],
      fallback: 'calendar',
    ),
    active: ModelUtils.asBool(
      json['activo'] ?? json['active'],
      fallback: true,
    ),
    sortOrder: ModelUtils.asInt(json['orden'] ?? json['sortOrder']),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': name,
    'descripcion': description,
    'descripcionLarga': longDescription,
    'precio': Money.round(priceSoles),
    'dias': days,
    'compraMinimaEnvioGratis': Money.round(minimumOrderSoles),
    if (savingsSoles != null) 'ahorroSoles': Money.round(savingsSoles!),
    'etiqueta': label,
    'beneficios': benefits,
    if (image != null) 'imagen': image!.toMap(),
    'iconoSvg': iconSvg,
    'activo': active,
    'orden': sortOrder,
  };

  String get priceLabel => Money.format(priceSoles);
  String get durationLabel => '$days días';
  String get savingsLabel =>
      savingsSoles == null ? '' : 'Ahorras ${Money.format(savingsSoles!)}';
}

/// Copy e imagen del estado sin suscripción (no es un plan contratable).
class PlanBase {
  const PlanBase({
    required this.name,
    required this.description,
    this.longDescription = '',
    this.image,
    this.iconSvg = 'base_plan',
  });

  static const PlanBase fallback = PlanBase(
    name: 'El Antojo',
    description: 'Sin suscripción · Sin envío gratis',
    iconSvg: 'base_plan',
  );

  final String name;
  final String description;
  final String longDescription;
  final MediaRef? image;
  final String iconSvg;

  factory PlanBase.fromMap(Map<String, dynamic> json) => PlanBase(
    name: ModelUtils.asString(
      json['nombre'] ?? json['name'],
      fallback: fallback.name,
    ),
    description: ModelUtils.asString(
      json['descripcion'] ?? json['description'],
      fallback: fallback.description,
    ),
    longDescription: ModelUtils.asString(
      json['descripcionLarga'] ?? json['longDescription'],
    ),
    image: MediaRef.fromValue(json['imagen'] ?? json['image']),
    iconSvg: ModelUtils.asString(
      json['iconoSvg'] ?? json['iconSvg'],
      fallback: 'base_plan',
    ),
  );
}
