import 'claim.dart';
import 'delivery_config.dart';
import 'media_ref.dart';
import 'model_utils.dart';
import 'payment_method.dart';

/// Configuración global del negocio (`configuracion/app`).
class AppSettings {
  const AppSettings({
    required this.whatsapp,
    required this.phone,
    this.phoneDisplay = '',
    this.driveFolderUrl,
    this.heroImage,
    this.paymentMethods = const [],
    this.claimReasons = const [],
    this.delivery = DeliveryConfig.fallback,
    this.updatedAt,
  });

  /// Placeholder de la beta hasta que el negocio confirme el número real.
  static const String placeholderWhatsapp = '51900000000';

  static const AppSettings fallback = AppSettings(
    whatsapp: placeholderWhatsapp,
    phone: '',
    phoneDisplay: '',
    paymentMethods: PaymentMethod.fallback,
    claimReasons: ClaimReason.fallback,
    delivery: DeliveryConfig.fallback,
  );

  final String whatsapp;
  final String phone;
  final String phoneDisplay;

  /// Carpeta pública de Drive donde el negocio sube las fotos.
  final String? driveFolderUrl;
  final MediaRef? heroImage;
  final List<PaymentMethod> paymentMethods;
  final List<ClaimReason> claimReasons;
  final DeliveryConfig delivery;
  final DateTime? updatedAt;

  String get effectiveWhatsapp =>
      whatsapp.trim().isEmpty ? placeholderWhatsapp : whatsapp.trim();

  List<PaymentMethod> get activePaymentMethods {
    final active = paymentMethods.where((p) => p.active).toList();
    return active.isEmpty ? PaymentMethod.fallback : active;
  }

  List<ClaimReason> get activeClaimReasons {
    final active = claimReasons;
    return active.isEmpty ? ClaimReason.fallback : active;
  }

  factory AppSettings.fromMap(Map<String, dynamic> json) => AppSettings(
    whatsapp: ModelUtils.asString(
      json['whatsapp'],
      fallback: placeholderWhatsapp,
    ),
    phone: ModelUtils.asString(json['telefono'] ?? json['phone']),
    phoneDisplay: ModelUtils.asString(
      json['telefonoVisible'] ?? json['phoneDisplay'],
    ),
    driveFolderUrl: ModelUtils.asStringOrNull(
      json['carpetaDrive'] ?? json['driveFolderUrl'],
    ),
    heroImage: MediaRef.fromValue(json['imagenHero'] ?? json['heroImage']),
    paymentMethods: ModelUtils.asMapList(
      json['mediosPago'] ?? json['paymentMethods'],
    ).map(PaymentMethod.fromMap).toList(),
    claimReasons: ModelUtils.asMapList(
      json['motivosReclamo'] ?? json['claimReasons'],
    ).map(ClaimReason.fromMap).toList(),
    delivery: DeliveryConfig.fromMap(ModelUtils.asMap(json['delivery'])),
    updatedAt: ModelUtils.asDateTime(json['updatedAt']),
  );

  Map<String, dynamic> toMap() => {
    'whatsapp': whatsapp,
    'telefono': phone,
    'telefonoVisible': phoneDisplay,
    if (driveFolderUrl != null) 'carpetaDrive': driveFolderUrl,
    if (heroImage != null) 'imagenHero': heroImage!.toMap(),
    'mediosPago': paymentMethods.map((p) => p.toMap()).toList(),
    'motivosReclamo': claimReasons.map((c) => c.toMap()).toList(),
    'delivery': delivery.toMap(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };
}
