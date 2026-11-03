/// Cálculo puro del tiempo de preparación de pizzas personalizadas.
class PizzaTiming {
  const PizzaTiming._();

  static int preparationMinutes({
    required List<int> batchMinutes,
    required double ovenWeight,
    required int ovenCapacity,
    required int recoveryMinutes,
    required int baseMinutes,
    required bool measured,
  }) {
    if (batchMinutes.isEmpty) return baseMinutes;
    final capacity = ovenCapacity.clamp(1, 100);
    final batches = (ovenWeight / capacity).ceil().clamp(1, 1000);
    final longest = batchMinutes.reduce((a, b) => a > b ? a : b);
    final custom =
        batches * longest + (batches - 1) * recoveryMinutes.clamp(0, 120);
    final result = custom > baseMinutes ? custom : baseMinutes;
    return measured ? result : result + 5;
  }
}
