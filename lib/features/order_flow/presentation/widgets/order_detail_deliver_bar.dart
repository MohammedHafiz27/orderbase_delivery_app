part of '../imports/order_flow_imports.dart';

/// Sticky bottom bar — the order's two outcomes as **one segmented control**.
///
/// They used to sit a screen apart: «تم التسليم» pinned to the footer and
/// «لم يتم التسليم» outlined halfway down the scroll, above the timeline. But
/// they are the two answers to a single question — *did this order reach the
/// customer?* — so they belong in one control, side by side, answered without
/// scrolling. One 56pt silhouette, one radius: the primary takes whatever
/// width is left over (it is the normal outcome and must stay the loud one),
/// the failure segment sizes to its own label at the far end, marked by a red
/// hairline rather than by weight.
class _OutcomeBar extends StatelessWidget {
  const _OutcomeBar({this.onDeliver, required this.onFail});
  final VoidCallback? onDeliver;
  final VoidCallback onFail;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RoadMode.instance,
      builder: (_, _) => _build(RoadMode.instance.on),
    );
  }

  Widget _build(bool road) {
    // 64 on the road — a gloved thumb's target.
    final double height = road ? AppSize.sH64 : AppSize.sH56;
    final radius = Radius.circular(AppCircular.r15); // mockup radius
    return Container(
      padding: EdgeInsets.only(
        left: AppPadding.pW20,
        right: AppPadding.pW20,
        top: AppPadding.pH12,
        bottom: AppPadding.pH8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderHeader)),
      ),
      child: SizedBox(
        height: height,
        child: Row(
          // Both halves fill the bar's height — a Row centres its children by
          // default, which left the two segments at their own intrinsic sizes
          // and the pair reading as one tall box beside one short one.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The delivered half: expanded, so the segment that carries the
            // day's normal ending is always the wider of the two.
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.inkFill,
                  borderRadius: BorderRadiusDirectional.horizontal(
                    start: radius,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconWidget(
                      icon: AppAssets.svg.check,
                      color: AppColors.surface,
                      height: AppSize.sH18,
                      width: AppSize.sW18,
                    ),
                    8.szW,
                    Flexible(
                      child: Text(
                        LocaleKeys.orderDetailDeliver.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle()
                            .setWhite
                            .s14
                            .semiBold
                            .road(road),
                      ),
                    ),
                  ],
                ).paddingSymmetric(horizontal: AppPadding.pW12),
              ).onClick(onTap: onDeliver),
            ),
            // The failure half: white, sized to its own label, and outlined in
            // red — its border on the shared edge is the rule between the two.
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadiusDirectional.horizontal(end: radius),
                border: Border.all(color: AppColors.failedBorder, width: 1.5),
              ),
              child: Center(
                child: Text(
                  LocaleKeys.orderDetailNotDelivered.tr(),
                  maxLines: 1,
                  style: const TextStyle()
                      .setColor(AppColors.dangerAccent)
                      .s14
                      .semiBold
                      .road(road),
                ),
              ).paddingSymmetric(horizontal: AppPadding.pW16),
            ).onClick(onTap: onFail),
          ],
        ),
      ),
    );
  }
}
