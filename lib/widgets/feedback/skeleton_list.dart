part of '../widgets.dart';


/// Esqueleto de lista durante la carga.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.count = 4,
    this.height = 151,
    this.padding = const EdgeInsets.all(Brand.s16),
  });

  final int count;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: Brand.s12),
      itemBuilder: (context, _) => ShimmerBox(height: height),
    );
  }
}
