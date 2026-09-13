part of '../imports/home_imports.dart';

/// The day's numbers as one strip under the hero: the cash the courier is
/// carrying FIRST, then in progress and delivered.
///
/// The cash leads because it is the one figure that outlives the batch — a
/// failed count zeroes the moment the courier hands the returns back at the
/// branch, which made it a misleading day-metric, so it was dropped from the
/// strip entirely (failures still live on the Orders tab and the settlement).
/// The cash in hand is what the courier is answerable for at any moment, so
/// it takes the reading start and the widest cell.
///
/// Each cell taps through to what it summarises (an Orders filter, or the
/// settlement). The cash cell is slate, like every money surface, and turns
/// red when the cash in hand is over the branch's limit — the strip is the
/// only place on Home that alarm shows, because the figure itself going red
/// says it without a banner repeating it.
class _HomeStatRow extends StatelessWidget {
  const _HomeStatRow({this.onOpenOrdersFilter, this.onOpenSettlement});

  final void Function(QueueFilter)? onOpenOrdersFilter;
  final VoidCallback? onOpenSettlement;

  /// Whether the strip has anything to report yet — one of its own
  /// numbers off zero.
  ///
  /// On a brand-new day it would read «00 · 00» with an empty cash cell:
  /// cells all saying "nothing has happened" on a screen whose only
  /// message is already "nothing has happened". So it does not render at all
  /// until the day has actually started moving.
  static bool hasAnyMetric(ShiftController shift) =>
      shift.inProgress > 0 || shift.deliveredCount > 0 || shift.cashInHand > 0;

  static String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final shift = ShiftController.instance;
    final over = shift.overCashLimit;
    final road = RoadMode.instance.on;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppCircular.r16), // from the design frame
        border: road
            ? Border.all(color: AppColors.borderDefault, width: 2)
            : Border.all(color: AppColors.borderCardFaint),
        boxShadow: AppShadows.statStrip,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The cash leads the strip — the most important figure of the
            // day, at the reading start and in the widest cell.
            Expanded(
              flex: 5,
              child: _StatCell(
                // Cash IN HAND, the same figure the header states — not the
                // day's gross. They diverge the moment the branch settles a
                // batch, and two different money totals on one screen read as
                // a bug whichever one you trust.
                value: formatThousands(shift.cashInHand),
                suffix: LocaleKeys.homeEgp.tr(),
                label: over
                    ? LocaleKeys.homeStatOverLimit.tr()
                    : LocaleKeys.homeStatCashOnYou.tr(),
                // Slate for money; the one non-failure red in the app when
                // the courier is carrying more than the branch allows.
                background: over
                    ? AppColors.failedText
                    : AppColors.paymentCardBg,
                valueColor: AppColors.surface,
                labelColor: over
                    ? AppColors.overLimitLabel
                    : AppColors.paymentLabel,
                road: road,
                onTap: onOpenSettlement,
              ),
            ),
            Expanded(
              flex: 3,
              child: _StatCell(
                value: _pad(shift.inProgress),
                label: LocaleKeys.filterTransit.tr(),
                road: road,
                onTap: () => onOpenOrdersFilter?.call(QueueFilter.transit),
              ),
            ),
            const _CellRule(),
            Expanded(
              flex: 3,
              child: _StatCell(
                value: _pad(shift.deliveredCount),
                label: LocaleKeys.filterDelivered.tr(),
                road: road,
                onTap: () => onOpenOrdersFilter?.call(QueueFilter.delivered),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One cell: the number, its unit when it is money, the label under it.
class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    this.suffix,
    this.background,
    this.valueColor = AppColors.textPrimary,
    this.labelColor,
    this.road = false,
    this.onTap,
  });

  final String value;
  final String label;
  final String? suffix;
  final Color? background;
  final Color valueColor;

  /// Null picks the default label colour: secondary, or tertiary (darker,
  /// 7.6:1) on the road.
  final Color? labelColor;

  /// Road mode: number and label one step up.
  final bool road;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final labelColor =
        this.labelColor ??
        (road ? AppColors.textTertiary : AppColors.textSecondary);
    return Semantics(
      button: onTap != null,
      label: '$value ${suffix ?? ''} $label'.trim(),
      child: AnimatedContainer(
        duration: AppMotion.fill,
        curve: AppMotion.ease,
        color: background,
        padding: EdgeInsets.symmetric(
          horizontal: AppPadding.pW4,
          vertical: AppPadding.pH12,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text.rich(
              TextSpan(
                text: value,
                style: const TextStyle()
                    .setColor(valueColor)
                    .s18
                    .bold
                    .tabular
                    .road(road)
                    .withHeight(1),
                children: suffix == null
                    ? null
                    : [
                        TextSpan(
                          text: ' $suffix',
                          style: const TextStyle()
                              .setColor(valueColor)
                              .s12
                              .semiBold
                              .road(road),
                        ),
                      ],
              ),
              // RTL so the «جنيه» suffix lands to the LEFT of the figure.
              textDirection: TextDirection.rtl,
              maxLines: 1,
            ),
            6.szH,
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle()
                  .setColor(labelColor)
                  // Stays 12 on the road: four cells across 328pt leave no
                  // room for «في الطريق» at 14. The darker colour does the work.
                  .s12
                  .medium,
            ),
          ],
        ),
      ).onClick(onTap: onTap),
    );
  }
}

/// Hairline between the count cells.
class _CellRule extends StatelessWidget {
  const _CellRule();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.w,
      margin: EdgeInsets.symmetric(vertical: AppMargin.mH12),
      color: AppColors.borderHeader,
    );
  }
}
