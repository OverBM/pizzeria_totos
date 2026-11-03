import 'model_utils.dart';

enum SubscriptionStatus {
  active,
  cancelled,
  expired;

  String get label => switch (this) {
    SubscriptionStatus.active => 'Activa',
    SubscriptionStatus.cancelled => 'Cancelada',
    SubscriptionStatus.expired => 'Vencida',
  };
}

/// Suscripción de delivery (`suscripciones/{uid}`).
class Subscription {
  const Subscription({
    required this.uid,
    required this.planId,
    required this.planName,
    required this.priceSoles,
    required this.startAt,
    required this.endAt,
    required this.periodStart,
    this.status = SubscriptionStatus.active,
    this.shipmentsUsed = 0,
    this.cancelledAt,
    this.cancelReason,
    this.autoRenew = false,
  });

  final String uid;
  final String planId;
  final String planName;
  final double priceSoles;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime periodStart;
  final SubscriptionStatus status;
  final int shipmentsUsed;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final bool autoRenew;

  bool isActiveAt(DateTime limaWallClock) =>
      status != SubscriptionStatus.expired &&
      !limaWallClock.isAfter(endAt);

  bool get isCancelled => status == SubscriptionStatus.cancelled;

  int daysRemainingAt(DateTime limaWallClock) {
    if (!isActiveAt(limaWallClock)) return 0;
    return endAt.difference(limaWallClock).inDays + 1;
  }

  bool canRefundAt(DateTime limaWallClock) =>
      shipmentsUsed == 0 &&
      limaWallClock.difference(periodStart).inHours < 24;

  bool get renewalWarningDue {
    final now = DateTime.now();
    return autoRenew && endAt.difference(now).inHours <= 48;
  }

  factory Subscription.fromMap(Map<String, dynamic> json) {
    final start = ModelUtils.asDateTime(json['inicio'] ?? json['startAt']) ??
        DateTime.now();
    final end = ModelUtils.asDateTime(json['vence'] ?? json['endAt']) ??
        start;
    final period = ModelUtils.asDateTime(
          json['periodoInicio'] ?? json['periodStart'],
        ) ??
        start;
    final statusName = ModelUtils.asString(
      json['estado'] ?? json['status'],
      fallback: 'activa',
    );
    return Subscription(
      uid: ModelUtils.asString(json['uid']),
      planId: ModelUtils.asString(json['planId']),
      planName: ModelUtils.asString(json['planNombre'] ?? json['planName']),
      priceSoles: ModelUtils.asMoney(
        json,
        'precio',
        centsKey: 'priceCents',
      ),
      startAt: start,
      endAt: end,
      periodStart: period,
      status: switch (statusName) {
        'cancelada' || 'cancelled' => SubscriptionStatus.cancelled,
        'vencida' || 'expired' => SubscriptionStatus.expired,
        _ => SubscriptionStatus.active,
      },
      shipmentsUsed: ModelUtils.asInt(
        json['enviosUsados'] ?? json['shipmentsUsed'],
      ),
      cancelledAt: ModelUtils.asDateTime(
        json['canceladaEn'] ?? json['cancelledAt'],
      ),
      cancelReason: ModelUtils.asStringOrNull(
        json['motivoCancelacion'] ?? json['cancelReason'],
      ),
      autoRenew: ModelUtils.asBool(
        json['renuevaAutomatico'] ?? json['autoRenew'],
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'planId': planId,
    'planNombre': planName,
    'precio': priceSoles,
    'inicio': startAt.toIso8601String(),
    'vence': endAt.toIso8601String(),
    'periodoInicio': periodStart.toIso8601String(),
    'estado': switch (status) {
      SubscriptionStatus.active => 'activa',
      SubscriptionStatus.cancelled => 'cancelada',
      SubscriptionStatus.expired => 'vencida',
    },
    'enviosUsados': shipmentsUsed,
    if (cancelledAt != null) 'canceladaEn': cancelledAt!.toIso8601String(),
    if (cancelReason != null) 'motivoCancelacion': cancelReason,
    'renuevaAutomatico': autoRenew,
  };

  Subscription copyWith({
    String? planId,
    String? planName,
    double? priceSoles,
    DateTime? startAt,
    DateTime? endAt,
    DateTime? periodStart,
    SubscriptionStatus? status,
    int? shipmentsUsed,
    DateTime? cancelledAt,
    String? cancelReason,
    bool? autoRenew,
  }) => Subscription(
    uid: uid,
    planId: planId ?? this.planId,
    planName: planName ?? this.planName,
    priceSoles: priceSoles ?? this.priceSoles,
    startAt: startAt ?? this.startAt,
    endAt: endAt ?? this.endAt,
    periodStart: periodStart ?? this.periodStart,
    status: status ?? this.status,
    shipmentsUsed: shipmentsUsed ?? this.shipmentsUsed,
    cancelledAt: cancelledAt ?? this.cancelledAt,
    cancelReason: cancelReason ?? this.cancelReason,
    autoRenew: autoRenew ?? this.autoRenew,
  );
}
