part of '../imports/home_imports.dart';

/// Deliver and call — the hero card's own action row, at its foot.
///
/// They live inside the banner (the designer's call): the card describes the
/// stop and closes with what to do about it. Both buttons handle their own
/// taps, so they win the gesture arena over the card's open-the-order tap.
class _HomeStopActions extends StatelessWidget {
  const _HomeStopActions({this.onDeliver, this.onCall});

  final VoidCallback? onDeliver;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    // Road mode: taller controls, one type step up. See [RoadMode].
    final road = RoadMode.instance.on;
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: road ? AppSize.sH64 : AppSize.sH52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.inkFill,
                borderRadius: BorderRadius.circular(
                  AppCircular.r15,
                ), // radii exempt
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
                      LocaleKeys.homeDeliver.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle().setWhite.s14.bold.road(road),
                    ),
                  ),
                ],
              ),
            ),
          ).onClick(onTap: onDeliver),
        ),
        12.szW,
        // Neutral tile (ink glyph, white fill, hairline) matching the header
        // actions — kept off the status hues so call never reads as the
        // failed-red / delivered-green states.
        Semantics(
          button: true,
          label: LocaleKeys.orderDetailCall.tr(),
          child: _HomeSquareIconButton(
            icon: AppAssets.svg.phone,
            iconColor: AppColors.textPrimary,
            size: road ? AppSize.sH64 : AppSize.sH52,
            iconSize: road ? AppSize.sH24 : 21.h, // mockup glyph 21px
            radius: AppCircular.r15,
            background: AppColors.surface,
            border: AppColors.iconButtonBorder,
          ).onClick(onTap: onCall),
        ),
      ],
    );
  }
}
