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

/// The order detail's whole bottom slot: the floating [BottomNav], and — **only
/// once the inline [_OutcomeBar] has scrolled off the top** — «تم التسليم»
/// pinned above it.
///
/// The two outcomes live under the map now, which puts them above the fold on
/// open but lets them scroll away while the courier reads the items or the
/// timeline. This brings the primary action back within a thumb's reach — and
/// only the primary: a failure is a decision the courier stops and makes, so it
/// stays in the page where the context is.
///
/// **The white runs the whole slot, behind the tab bar too**, which is why it is
/// painted here and not on the button's own container. The tab bar floats with
/// ~96pt of transparent page around it ([BottomNav.reservedHeight]), so a white
/// strip that stopped at the button's lower edge left the page scrolling
/// through underneath and the footer read as two unrelated pieces. With the
/// fill on the slot, the pinned button and the bar sit on one surface.
/// Unpinned, the slot is fully transparent again and the bar floats over the
/// page the way it does everywhere else.
class _PinnedFooter extends StatelessWidget {
  const _PinnedFooter({
    required this.shown,
    required this.navBar,
    this.onDeliver,
  });

  /// Whether the inline outcome row has scrolled past the top.
  final bool shown;

  /// The floating tab bar, which shares this slot and sits under the button.
  final Widget navBar;

  final VoidCallback? onDeliver;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RoadMode.instance,
      builder: (_, _) => _build(context, RoadMode.instance.on),
    );
  }

  Widget _build(BuildContext context, bool road) {
    // A footer that pops in mid-scroll reads as a glitch: the surface fades up
    // while the button grows out of the bottom edge. Reduce Motion jumps.
    final duration = AppMotion.reduced(context)
        ? Duration.zero
        : AppMotion.stamp;
    return AnimatedContainer(
      duration: duration,
      curve: AppMotion.ease,
      decoration: BoxDecoration(
        color: shown ? AppColors.surface : _clear(AppColors.surface),
        border: Border(
          top: BorderSide(
            color: shown
                ? AppColors.borderHeader
                : _clear(AppColors.borderHeader),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: duration,
            curve: AppMotion.ease,
            alignment: Alignment.topCenter,
            child: shown
                ? _button(road).paddingOnly(
                    left: AppPadding.pW20,
                    right: AppPadding.pW20,
                    top: AppPadding.pH12,
                    bottom: AppPadding.pH8,
                  )
                : const SizedBox(width: double.infinity),
          ),
          navBar,
        ],
      ),
    );
  }

  /// The same ink primary the inline row carries, full width down here.
  Widget _button(bool road) => Container(
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
  ).onClick(onTap: onDeliver);

  static Color _clear(Color c) => c.withAlpha(0);
}
