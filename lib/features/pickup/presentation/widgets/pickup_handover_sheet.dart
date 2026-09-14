part of '../imports/pickup_imports.dart';

/// **The handover.** Raised the moment the branch is actually ready to give the
/// courier their next batch — he is standing in the branch and everything he
/// was carrying is closed ([ShiftController.pendingHandoverBatch]).
///
/// This is the sheet where custody changes hands, so it carries what he needs
/// to check the parcels against: the batch's size and cash, then one row per
/// order with its number, customer, area, and the two trip facts — when it is
/// expected at the door and how far its leg runs. Confirming makes the batch
/// his and puts its orders «في الطريق».
///
/// It is **not** the mid-flight announcement ([showPickupDispatchSheet]), which
/// only tells him a batch exists while he is still out on the road, and it is
/// not the Orders tab's short confirm ([showCarryBatchSheet]), which guards
/// that button against a mis-tap. Three sheets, three jobs.
///
/// «مش دلوقتي» resolves `false` and the shell records it, so this never raises
/// again for that batch; the Orders tab's «تأكيد استلام التشغيلة» button stays
/// as the way in.
Future<bool?> showBatchHandoverSheet(
  BuildContext context, {
  required OrderBatch batch,
}) {
  return showAppSheet<bool>(context, child: _BatchHandoverSheet(batch: batch));
}

class _BatchHandoverSheet extends StatelessWidget {
  const _BatchHandoverSheet({required this.batch});
  final OrderBatch batch;

  @override
  Widget build(BuildContext context) {
    final orders = batch.orders;
    return SheetShell(
      title: LocaleKeys.pickupHandoverTitle.tr(namedArgs: {'id': batch.id}),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HandoverSummary(count: orders.length, cash: batch.codTotal),
          12.szH,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final o in orders)
                _HandoverRow(order: o, last: o == orders.last),
            ],
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
                  LocaleKeys.pickupHandoverConfirm.tr(),
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
              LocaleKeys.pickupHandoverLater.tr(),
              style: const TextStyle().setSecondaryColor.s14.semiBold,
            ),
          ).onClick(onTap: () => Navigator.of(context).pop(false)),
        ],
      ),
    );
  }
}

/// How big the batch is, on one quiet strip: the count at the reading start,
/// the cash he becomes responsible for at the far end.
class _HandoverSummary extends StatelessWidget {
  const _HandoverSummary({required this.count, required this.cash});
  final int count;
  final int cash;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppCircular.r13),
      ),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppPadding.pW12,
        vertical: AppPadding.pH10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            LocaleKeys.pickupDispatchCount.tr(
              namedArgs: {'count': englishDigits(count)},
            ),
            style: const TextStyle().setMainTextColor.s12.bold,
          ),
          Text(
            LocaleKeys.pickupHandoverCash.tr(
              namedArgs: {'cash': formatThousands(cash)},
            ),
            style: const TextStyle().setMainTextColor.s12.bold,
          ),
        ],
      ),
    );
  }
}

/// One parcel on the manifest: the payment tag at the far end, then the order
/// number, the customer and area, and the two trip facts.
class _HandoverRow extends StatelessWidget {
  const _HandoverRow({required this.order, required this.last});
  final Order order;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: last
          ? null
          : const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.surfaceSubtle),
              ),
            ),
      padding: EdgeInsetsDirectional.symmetric(vertical: AppPadding.pH12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  order.num,
                  style: const TextStyle().setMainTextColor.s14.semiBold,
                ),
                2.szH,
                Text(
                  '${order.name} · ${order.area}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle().setSecondaryColor.s12.regular,
                ),
                if (order.due != null || order.dist != null) ...[
                  2.szH,
                  Row(
                    children: [
                      if (order.due != null) ...[
                        TripFact(
                          icon: AppAssets.svg.clock,
                          text: LocaleKeys.queueEta.tr(
                            namedArgs: {'time': order.due!},
                          ),
                        ),
                        if (order.dist != null) 16.szW,
                      ],
                      if (order.dist != null)
                        TripFact(
                          icon: AppAssets.svg.nav,
                          text: order.dist!,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          12.szW,
          _HandoverPayTag(prepaid: order.prepaid, amount: order.cod),
        ],
      ),
    );
  }
}

/// The cash figure alone on a COD parcel — an amount can only mean cash on
/// delivery — and «مدفوع» on a prepaid one, which has no figure to show.
class _HandoverPayTag extends StatelessWidget {
  const _HandoverPayTag({required this.prepaid, this.amount});
  final bool prepaid;
  final int? amount;

  @override
  Widget build(BuildContext context) {
    final cod = !prepaid && amount != null;
    return Container(
      decoration: BoxDecoration(
        color: cod ? AppColors.heroCodPillBg : AppColors.deliveredBg,
        borderRadius: BorderRadius.circular(AppCircular.r7),
      ),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppPadding.pW8,
        vertical: AppPadding.pH4,
      ),
      child: Text(
        cod
            ? LocaleKeys.amountEgp.tr(
                namedArgs: {'amount': formatThousands(amount!)},
              )
            : LocaleKeys.pickupPayPaid.tr(),
        style: const TextStyle()
            .setColor(cod ? AppColors.postponedText : AppColors.deliveredText)
            .s14
            .bold,
      ),
    );
  }
}
