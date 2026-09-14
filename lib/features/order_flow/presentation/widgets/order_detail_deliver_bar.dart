part of '../imports/order_flow_imports.dart';

/// Sticky bottom bar — the order's two outcomes, side by side.
///
/// They used to sit a screen apart: «تم التسليم» pinned to the footer and
/// «لم يتم التسليم» outlined halfway down the scroll, above the timeline. They
/// are the two answers to a single question — *did this order reach the
/// customer?* — so they belong in one row, answered without scrolling.
///
/// **Two buttons, not one segmented control** (the courier's ask, 14 Sep
/// 2026): they briefly shared a silhouette, and a joined pair reads as one
/// control with a mode rather than as two things that can each be pressed.
/// An 8pt gap and a full radius each says what they are. They still keep one
/// height and one baseline: «تم التسليم» black and `Expanded` at the reading
/// start — it is the normal outcome and must stay the loud one — and
/// «لم يتم التسليم» white and red-outlined, sized to its own label, at the
/// far end.
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
    final radius = BorderRadius.circular(AppCircular.r15); // mockup radius
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
          // Both buttons fill the bar's height — a Row centres its children by
          // default, which left them at their own intrinsic sizes and the pair
          // reading as one tall box beside one short one.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The delivered button: expanded, so the one that carries the
            // day's normal ending is always the wider of the two.
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.inkFill,
                  borderRadius: radius,
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
            8.szW,
            // The failure button: white, sized to its own label, outlined in
            // red, and standing on its own.
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: radius,
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
