import '../core/format/money.dart';
import 'model_utils.dart';

/// Horario de una sede (hora local `America/Lima`).
///
/// En Firestore se guarda como `{ abre, cierra, dias }`.
class BranchHours {
  const BranchHours({
    required this.open,
    required this.close,
    required this.days,
  });

  /// Hora de apertura `HH:mm`.
  final String open;

  /// Hora de cierre `HH:mm`.
  final String close;

  /// Días de atención (1 = lunes … 7 = domingo).
  final List<int> days;

  static const BranchHours fallback = BranchHours(
    open: '12:45',
    close: '21:30',
    days: [1, 2, 3, 4, 5, 6, 7],
  );

  factory BranchHours.fromMap(Map<String, dynamic> json) {
    final dias = ModelUtils.asIntList(json['dias'] ?? json['days']);
    return BranchHours(
      open: ModelUtils.asString(
        json['abre'] ?? json['open'],
        fallback: fallback.open,
      ),
      close: ModelUtils.asString(
        json['cierra'] ?? json['close'],
        fallback: fallback.close,
      ),
      days: dias.isEmpty ? fallback.days : dias,
    );
  }

  bool attendsDay(int weekday) => days.contains(weekday);

  /// Minutos desde medianoche de una hora `HH:mm`, o `null` si es inválida.
  static int? minutesOf(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hours = int.tryParse(parts[0]);
    final mins = int.tryParse(parts[1]);
    if (hours == null || mins == null) return null;
    return hours * 60 + mins;
  }

  /// ¿La sede atiende en [instant] (hora de Lima)?
  ///
  /// Tolerante a horarios inválidos: si no se pueden interpretar, se asume
  /// abierta para no bloquear el pedido por un dato mal cargado.
  bool isOpenAt(DateTime instant) {
    if (!attendsDay(instant.weekday)) return false;
    final open = minutesOf(this.open);
    final close = minutesOf(this.close);
    if (open == null || close == null) return true;
    final now = instant.hour * 60 + instant.minute;
    return now >= open && now <= close;
  }

  /// Rango legible para la UI (p. ej. `12:45 – 21:30`).
  String get rangeLabel => '$open – $close';

  Map<String, dynamic> toMap() => {'abre': open, 'cierra': close, 'dias': days};
}

/// Sede de TOTO'S. En Firestore vive en `sedes/{id}`.
class Branch {
  const Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.delivers,
    required this.hours,
    this.district = '',
    this.province = 'Huancayo',
    this.city = 'Huancayo',
    this.deliveryFeeSoles = 0,
    this.phone = '',
    this.whatsapp = '',
    this.image,
    this.sortOrder = 0,
    this.active = true,
    this.closedDates = const [],
  });

  final String id;
  final String name;
  final String address;
  final String district;
  final String province;
  final String city;
  final double lat;
  final double lng;
  final bool delivers;
  final double deliveryFeeSoles;
  final BranchHours hours;
  final String phone;
  final String whatsapp;
  final String? image;
  final int sortOrder;
  final bool active;

  /// Fechas de cierre excepcional en formato `yyyy-MM-dd`.
  final List<String> closedDates;

  /// ¿La sede está abierta en [instant] (se espera hora de Lima) y no está en
  /// [closedDates]?
  ///
  /// El modelo no conoce la zona horaria: el controlador le pasa el instante
  /// ya convertido, para mantener `models/` sin dependencias de `core/`.
  bool isOpenAt(DateTime instant) {
    final today =
        '${instant.year.toString().padLeft(4, '0')}-'
        '${instant.month.toString().padLeft(2, '0')}-'
        '${instant.day.toString().padLeft(2, '0')}';
    if (closedDates.contains(today)) return false;
    return hours.isOpenAt(instant);
  }

  /// Solo se listan sedes activas de la provincia de Huancayo.
  bool get isVisible => active && province.toUpperCase() == 'HUANCAYO';

  factory Branch.fromMap(Map<String, dynamic> json) => Branch(
    id: ModelUtils.asString(json['id']),
    name: ModelUtils.asString(json['nombre'] ?? json['name']),
    address: ModelUtils.asString(json['direccion'] ?? json['address']),
    district: ModelUtils.asString(json['distrito'] ?? json['district']),
    province: ModelUtils.asString(
      json['provincia'] ?? json['province'],
      fallback: 'Huancayo',
    ),
    city: ModelUtils.asString(json['ciudad'] ?? json['city'], fallback: 'Huancayo'),
    lat: ModelUtils.asDouble(json['lat']),
    lng: ModelUtils.asDouble(json['lng']),
    delivers: ModelUtils.asBool(
      json['haceDelivery'] ?? json['delivers'],
      fallback: true,
    ),
    deliveryFeeSoles: ModelUtils.asMoney(
      json,
      'costoDelivery',
      centsKey: 'deliveryFeeCents',
    ),
    hours: BranchHours.fromMap(
      ModelUtils.asMap(json['horario'] ?? json['hours']),
    ),
    phone: ModelUtils.asString(json['telefono'] ?? json['phone']),
    whatsapp: ModelUtils.asString(json['whatsapp']),
    image: ModelUtils.asStringOrNull(json['imagen'] ?? json['image']),
    sortOrder: ModelUtils.asInt(json['orden'] ?? json['sortOrder']),
    active: ModelUtils.asBool(json['activa'] ?? json['active'], fallback: true),
    closedDates: ModelUtils.asStringList(
      json['fechasCerradas'] ?? json['closedDates'],
    ),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': name,
    'direccion': address,
    'distrito': district,
    'provincia': province,
    'ciudad': city,
    'lat': lat,
    'lng': lng,
    'haceDelivery': delivers,
    'costoDelivery': Money.round(deliveryFeeSoles),
    'horario': hours.toMap(),
    'telefono': phone,
    'whatsapp': whatsapp,
    if (image != null) 'imagen': image,
    'orden': sortOrder,
    'activa': active,
    'fechasCerradas': closedDates,
  };
}
