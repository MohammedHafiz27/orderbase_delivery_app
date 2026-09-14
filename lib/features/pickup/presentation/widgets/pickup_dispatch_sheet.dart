part of '../imports/pickup_imports.dart';

/// Announce a freshly dispatched batch *without forcing the courier to act on
/// it*. Raised mid-flight by the shell the moment the branch dispatches: it
/// names the batch, sizes it up (orders · cash · km) and lists the waiting
/// orders as compact rows. It closes on one «تمام» — the announcement is the
/// whole point, and the batch is not going anywhere: the Orders badge and
/// Home's collect row keep pointing at it. (It used to offer «عرض التشغيلة
/// في الطلبات» over a «لاحقًا» link; two ways out of a sheet that only
/// informs was one too many.) Still dismissible by scrim tap and drag.
Future<void> showPickupDispatchSheet(
  BuildContext context, {
  required OrderBatch batch,
  required String branch,
}) {
  // The knock lands with the sheet: this is the one event in the day the
  // courier did not cause, so it must be felt and heard, not only seen.
  AppHaptics.attention();
  return showAppSheet<void>(
    context,
    child: _PickupDispatchSheet(batch: batch, branch: branch),
  );
}

class _PickupDispatchSheet extends StatelessWidget {
  const _PickupDispatchSheet({required this.batch, required this.branch});
  final OrderBatch batch;
  final String branch;

  @override
  Widget build(BuildContext context) {
    final orders = batch.orders.map(orderToFlow).toList();
    return SheetShell(
      title: LocaleKeys.pickupDispatchTitle.tr(namedArgs: {'id': batch.id}),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                LocaleKeys.pickupDispatchCount.tr(
                  namedArgs: {'count': englishDigits(batch.count)},
                ),
                style: const TextStyle()
                    .setColor(AppColors.textBody)
                    .s16
                    .semiBold,
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.heroCodPillBg,
                  borderRadius: BorderRadius.circular(AppCircular.r7),
                ),
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: AppPadding.pW8,
                  vertical: AppPadding.pH4,
                ),
                child: Text(
                  LocaleKeys.amountEgp.tr(
                    namedArgs: {'amount': formatThousands(batch.codTotal)},
                  ),
                  style: const TextStyle()
                      .setColor(AppColors.postponedText)
                      .s14
                      .bold,
                ),
              ),
            ],
          ),
          12.szH,
          // The waiting orders as compact rows — the batch list in miniature.
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final o in orders)
                _PickupOrderRow(order: o, last: o == orders.last, inset: false),
            ],
          ),
          16.szH,
          Container(
            height: AppSize.sH56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.inkFill,
              borderRadius: BorderRadius.circular(AppCircular.r15),
            ),
            // The label alone — the design frame's button carries no glyph.
            child: Text(
              LocaleKeys.pickupDispatchOk.tr(),
              style: const TextStyle().setWhite.s14.semiBold,
            ),
          ).onClick(onTap: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}

/// Confirm that the courier physically carried [batch] out of the branch.
/// Raised from the Orders tab's waiting-batch section (and the standalone
/// pickup page). Resolves to `true` on confirm.
Future<bool?> showCarryBatchSheet(
  BuildContext context, {
  required OrderBatch batch,
}) {
  return showAppSheet<bool>(context, child: _PickupCarrySheet(batch: batch));
}

class _PickupCarrySheet extends StatelessWidget {
  const _PickupCarrySheet({required this.batch});
  final OrderBatch batch;

  @override
  Widget build(BuildContext context) {
    return SheetShell(
      title: LocaleKeys.pickupCarryTitle.tr(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            LocaleKeys.pickupCarryBody.tr(
              namedArgs: {'id': batch.id, 'count': englishDigits(batch.count)},
            ),
            style: const TextStyle().setSecondaryColor.s14.regular.withHeight(
              1.5,
            ),
          ),
          20.szH,
          Container(
            height: AppSize.sH56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.inkFill,
              borderRadius: BorderRadius.circular(AppCircular.r15),
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
                Text(
                  LocaleKeys.pickupCarryConfirm.tr(),
                  style: const TextStyle().setWhite.s14.semiBold,
                ),
              ],
            ),
          ).onClick(onTap: () => Navigator.of(context).pop(true)),
          8.szH,
          Container(
            height: AppSize.sH52,
            alignment: Alignment.center,
            child: Text(
              LocaleKeys.pickupCarryCancel.tr(),
              style: const TextStyle().setSecondaryColor.s14.semiBold,
            ),
          ).onClick(onTap: () => Navigator.of(context).pop(false)),
        ],
      ),
    );
  }
}
