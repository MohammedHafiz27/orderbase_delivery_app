part of '../imports/home_imports.dart';

/// «عودة للفرع ~5:40 م» — the return half of the trip line.
///
/// Both halves still come from the one `home_return_line` string, which
/// composes them around the app's «·». Rendering it without the distance and
/// taking the part before the separator leaves the wording — and every
/// translation of it — owned by the json, while letting each fact carry its
/// own glyph. Shared by the stacked line ([_HomeBatchLine], still used by the
/// returning card) and the split layout the hero now uses.
String homeReturnText(String returnEta) => LocaleKeys.homeReturnLine
    .tr(namedArgs: {'time': returnEta, 'km': ''})
    .split('·')
    .first
    .trim();

/// The hero's first line — the batch and how its trip ends.
///
/// Leading: «تشغيلة #7877 · الطلب 5 من 8». Beneath it the trip row — two facts, each
/// behind its own glyph: 🕐 «عودة للفرع ~5:40 م» and ➤ «34 كم», with a small ⓘ
/// on the distance. Tapping ⓘ floats a tooltip above it explaining what the two
/// figures mean: the time is the ride back to the branch after the last order,
/// not counting stops and handoffs; the kilometres are the whole batch trip
/// from the branch and back. Both are estimates from the orders' leg distances
/// until the backend gives real ones, and the tooltip is how the courier is
/// told not to read them as promises.
class _HomeBatchLine extends StatelessWidget {
  const _HomeBatchLine({
    required this.batch,
    required this.current,
    required this.total,
    required this.returnEta,
    required this.routeKm,
    this.done = false,
    this.showTrip = true,
  });

  final OrderBatch batch;

  /// 1-based stop the courier is on, and the batch's stop count.
  final int current;
  final int total;

  /// "5:40 م" — when they are expected back at the branch.
  final String returnEta;
  final double routeKm;

  /// The batch is complete: the count reads «اكتملت 8 من 8».
  final bool done;

  /// Show the «عودة للفرع ~5:40 م · 34 كم» row and its ⓘ. Off once the batch
  /// is closed: the ride back is no longer an estimate about the route, it is
  /// the one thing the card is about, and it is stated there instead.
  final bool showTrip;

  /// «عودة للفرع ~5:40 م» — the return half of the trip line.
  ///
  /// Both halves still come from the one `home_return_line` string, which
  /// composes them around the app's «·». Rendering it without the distance and
  /// taking the part before the separator leaves the wording — and every
  /// translation of it — owned by the json, while letting each fact carry its
  /// own glyph here. The distance half is [formatKmArabic], which is where it
  /// was coming from anyway.
  String _returnText() => homeReturnText(returnEta);

  @override
  Widget build(BuildContext context) {
    final road = RoadMode.instance.on;
    final quiet = const TextStyle().setSecondaryColor.s14.semiBold.road(road);
    final count = done
        ? LocaleKeys.homeBatchDone.tr(
            namedArgs: {
              'done': englishDigits(total),
              'total': englishDigits(total),
            },
          )
        : LocaleKeys.homeStopCount.tr(
            namedArgs: {
              'current': englishDigits(current),
              'total': englishDigits(total),
            },
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            style: quiet,
            children: [
              // The ID keeps its own span so «تشغيلة #7877» stays one unit — the
              // Arabic letter rightmost, the «#7877» block to its left.
              TextSpan(
                text: batch.id,
                style: const TextStyle().setMainTextColor.s14.bold.tabular.road(
                  road,
                ),
              ),
              TextSpan(text: ' · $count'),
            ],
          ),
          textDirection: TextDirection.rtl,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (showTrip) ...[
          4.szH,
          Row(
            children: [
              Flexible(
                child: _HomeTripFact(
                  icon: AppAssets.svg.clock,
                  text: _returnText(),
                  road: road,
                ),
              ),
              12.szW,
              _HomeTripFact(
                icon: AppAssets.svg.nav,
                text: formatKmArabic(routeKm),
                road: road,
              ),
              // The ⓘ covers both figures but hangs off the distance — the end
              // of the line, and the fact a courier is least likely to read as
              // a promise without it.
              _HintDot(
                message: LocaleKeys.homeTripTooltip.tr(),
                label: LocaleKeys.homeTripTooltipLabel.tr(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// One fact on the trip row: a glyph, then the figure.
///
/// The glyph is what makes the two halves readable at a glance now that the
/// «·» between them is gone — a clock for the time the courier is due back, a
/// navigation arrow for the kilometres the batch runs. It is set in the line's
/// supporting colour rather than its black: the figures are what is read, the
/// glyph only says which figure it is.
class _HomeTripFact extends StatelessWidget {
  const _HomeTripFact({required this.icon, required this.text, this.road = false});

  final String icon;
  final String text;

  /// Road mode: the glyph grows a step with the line's type.
  final bool road;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSize.sW4,
      children: [
        // The glyph takes the colour AND the box of the line beside it: same
        // ink, and a square the height of the text's line so the two share a
        // baseline instead of the icon floating small inside the row.
        IconWidget(
          icon: icon,
          color: AppColors.textPrimary,
          height: AppSize.sH20,
          width: AppSize.sW20,
        ),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            // Black, like the batch id above it: this is the line the courier
            // plans the rest of the batch around.
            style: const TextStyle().setMainTextColor.s14.medium.tabular
                .road(road)
                // 1.4 — the frame's line height, and the glyph's box.
                .withHeight(1.4),
          ),
        ),
      ],
    );
  }
}
