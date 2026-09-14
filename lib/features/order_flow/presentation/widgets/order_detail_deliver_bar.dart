part of '../imports/order_flow_imports.dart';

/// The order's two outcomes, side by side, **directly under the map**.
///
/// They used to sit a screen apart: «تم التسليم» pinned to the footer and
/// «لم يتم التسليم» outlined halfway down the scroll, above the timeline. They
/// are the two answers to a single question — *did this order reach the
/// customer?* — so they belong in one row.
///
/// **They ride the page now, not the footer** (the courier's ask, 14 Sep
/// 2026): the row sits straight after `_AddressSection`, so the decision
/// follows *where am I going* and lands above the fold on open, ahead of the
/// items and the timeline. It scrolls with the page like everything else —
/// there is no sticky bar on this screen any more, and the footer slot holds
/// only the tab bar.
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
  const _OutcomeBar({super.key, this.onDeliver, required this.onFail});
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
    // No fill, no rule, no side padding: the scroll column already carries the
    // page's 20pt gutter, and a white strip behind the row would be the old
    // footer's chrome stranded mid-page.
    return SizedBox(
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
                      style: const TextStyle().setWhite.s14.semiBold.road(road),
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
    );
  }
}

/// The «تم التسليم» button pinned back to the footer, shown **only once the
/// inline [_OutcomeBar] has scrolled off the top**.
///
/// The two outcomes live under the map now, which puts them above the fold on
/// open but lets them scroll away while the courier reads the items or the
/// timeline. This is the primary action coming back within a thumb's reach —
/// and only the primary: a failure is a decision the courier stops and makes,
/// so it stays in the page where the context is. It carries the old footer's
/// chrome (white surface, top hairline, the page's 20pt gutter) because here
/// it *is* a footer, and it sits in the same bottom slot as [BottomNav], so
/// the body's own MediaQuery reports both heights to
/// [BottomNav.reservedHeight].
class _PinnedDeliverBar extends StatelessWidget {
  const _PinnedDeliverBar({required this.shown, this.onDeliver});

  /// Whether the inline row has scrolled past.
  final bool shown;
  final VoidCallback? onDeliver;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RoadMode.instance,
      builder: (_, _) => _build(context, RoadMode.instance.on),
    );
  }

  Widget _build(BuildContext context, bool road) {
    // A bar that pops in mid-scroll reads as a glitch; it grows out of the
    // bottom edge instead. Reduce Motion jumps to both ends.
    final duration = AppMotion.reduced(context)
        ? Duration.zero
        : AppMotion.stamp;
    return AnimatedSize(
      duration: duration,
      curve: AppMotion.ease,
      alignment: Alignment.topCenter,
      child: !shown
          ? const SizedBox(width: double.infinity)
          : Container(
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
              child: Container(
                // 64 on the road — a gloved thumb's target.
                height: road ? AppSize.sH64 : AppSize.sH56,
                decoration: BoxDecoration(
                  color: AppColors.inkFill,
                  borderRadius: BorderRadius.circular(AppCircular.r15),
                ),
                alignment: Alignment.center,
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
                    Text(
                      LocaleKeys.orderDetailDeliver.tr(),
                      style: const TextStyle().setWhite.s14.semiBold.road(road),
                    ),
                  ],
                ),
              ).onClick(onTap: onDeliver),
            ),
    );
  }
}
