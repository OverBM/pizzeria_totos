import 'model_utils.dart';

/// Dirección de entrega guardada en el perfil.
class Address {
  const Address({
    required this.id,
    required this.line,
    this.label = '',
    this.reference,
    this.createdAt,
  });

  final String id;

  /// Etiqueta corta (p. ej. «Casa», «Trabajo»).
  final String label;

  /// Dirección completa.
  final String line;
  final String? reference;
  final DateTime? createdAt;

  factory Address.fromMap(Map<String, dynamic> json) => Address(
    id: ModelUtils.asString(json['id']),
    label: ModelUtils.asString(json['etiqueta'] ?? json['label']),
    line: ModelUtils.asString(json['linea'] ?? json['line']),
    reference: ModelUtils.asStringOrNull(
      json['referencia'] ?? json['reference'],
    ),
    createdAt: ModelUtils.asDateTime(json['createdAt']),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'etiqueta': label,
    'linea': line,
    if (reference != null) 'referencia': reference,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };

  String get title => label.isEmpty ? 'Dirección' : label;

  Address copyWith({String? label, String? line, String? reference}) => Address(
    id: id,
    label: label ?? this.label,
    line: line ?? this.line,
    reference: reference ?? this.reference,
    createdAt: createdAt,
  );
}

/// Perfil del usuario autenticado en Firestore (`usuarios/{uid}`).
///
/// No existe campo de rol: la app no tiene panel de administración.
class Account {
  const Account({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.addresses = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final List<Address> addresses;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Datos mínimos para confirmar un pedido con delivery.
  bool get hasPhone => phone.trim().isNotEmpty;
  bool get hasAddress => addresses.any((a) => a.line.trim().isNotEmpty);

  bool get isComplete => hasPhone && hasAddress;

  Address? get defaultAddress => addresses.isEmpty ? null : addresses.first;

  factory Account.fromMap(Map<String, dynamic> json, {String? uid}) => Account(
    uid: uid ?? ModelUtils.asString(json['uid']),
    name: ModelUtils.asString(json['nombre'] ?? json['name']),
    email: ModelUtils.asString(json['email']),
    phone: ModelUtils.asString(json['telefono'] ?? json['phone']),
    addresses: ModelUtils.asMapList(
      json['direcciones'] ?? json['addresses'],
    ).map(Address.fromMap).toList(),
    createdAt: ModelUtils.asDateTime(json['createdAt']),
    updatedAt: ModelUtils.asDateTime(json['updatedAt']),
  );

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'nombre': name,
    'email': email,
    'telefono': phone,
    'direcciones': addresses.map((a) => a.toMap()).toList(),
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  Account copyWith({
    String? name,
    String? email,
    String? phone,
    List<Address>? addresses,
    DateTime? updatedAt,
  }) => Account(
    uid: uid,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    addresses: addresses ?? this.addresses,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Account withAddress(Address address) {
    final exists = addresses.any((a) => a.id == address.id);
    final next = exists
        ? addresses.map((a) => a.id == address.id ? address : a).toList()
        : [...addresses, address];
    return copyWith(addresses: next);
  }

  Account withoutAddress(String addressId) =>
      copyWith(addresses: addresses.where((a) => a.id != addressId).toList());
}
