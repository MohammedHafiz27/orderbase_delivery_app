part of '../imports/queue_imports.dart';

/// One order inside a batch section — the batch row, one step richer than the
/// pickup version: number and cash pill (or the outcome badge once closed),
/// name · area · pieces, and — while the order is still out — the expected
/// arrival and the leg distance, each behind its own glyph. Frameless: no
/// fill, no container, a subtle hairline between rows. Tapping opens the
/// order.
class _QueueBatchRow extends StatelessWidget {
  const _QueueBatchRow({
    required this.order,
    required this.onTap,
    this.pending = false,
    this.last = false,
  });

  final Order order;
  final VoidCallback onTap;

  /// The order is still at the branch (its batch has not been carried).
  final bool pending;

  /// Last row of its batch — drops the trailing hairline.
  final bool last;

  @override
  Widget build(BuildContext context) {
    final isTransit = order.status == OrderStatus.transit;
    final meta = [
      order.name,
      order.area,
      if (order.pieces > 0)
        LocaleKeys.queuePieces.tr(
          namedArgs: {'count': englishDigits(order.pieces)},
        ),
    ].join(' · ');

    final Widget row = Container(
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.surfaceSubtle)),
      ),
      padding: EdgeInsetsDirectional.only(
        top: AppPadding.pH12,
        bottom: AppPadding.pH12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                order.num,
                textDirection: TextDirection.ltr,
                style: const TextStyle().setMainTextColor.s14.bold.tabular,
              ),
              const Spacer(),
              // Payment while the order is out; its outcome once it is closed,
              // so a dimmed row says *why* it is dimmed. At the far end of the
              // line, opposite the number (the design frame's row).
              if (isTransit)
                _PayPillSmall(prepaid: order.prepaid, amount: order.cod)
              else
                _StatusBadge(status: order.status, returns: order.returns),
            ],
          ),
          4.szH,
          Text(
            meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle().setSecondaryColor.s12.regular,
          ),
          if (isTransit && !pending && (order.due != null || order.dist != null)) ...[
            6.szH,
            // The two trip facts, each behind its own glyph: when the order
            // is expected at the door («الوصول المتوقع» — ETA, in Arabic),
            // and how far its leg runs.
            Row(
              children: [
                if (order.due != null) ...[
                  _RowTripFact(
                    icon: AppAssets.svg.clock,
                    text: LocaleKeys.queueEta.tr(
                      namedArgs: {'time': order.due!},
                    ),
                  ),
                  if (order.dist != null) 16.szW,
                ],
                if (order.dist != null)
                  _RowTripFact(icon: AppAssets.svg.nav, text: order.dist!),
              ],
            ),
          ],
        ],
      ),
    );
    final tappable = row.onClick(onTap: onTap);
    // Closed orders are de-emphasised — the badge says why.
    return isTransit ? tappable : Opacity(opacity: 0.6, child: tappable);
  }
}

/// One trip fact on a batch row — a small glyph, then the figure. The glyph
/// is what tells the ETA from the distance at a glance.
class _RowTripFact extends StatelessWidget {
  const _RowTripFact({required this.icon, required this.text});
  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconWidget(
          icon: icon,
          color: AppColors.textTertiary,
          height: AppSize.sH14,
          width: AppSize.sW14,
        ),
        4.szW,
        Text(
          text,
          style: const TextStyle().setTertiaryColor.s12.regular.tabular,
        ),
      ],
    );
  }
}

/// The filled cash / prepaid pill on a batch row — the figure alone on a COD
/// order (an amount can only mean cash on delivery), «مدفوع» on a prepaid one.
class _PayPillSmall extends StatelessWidget {
  const _PayPillSmall({required this.prepaid, this.amount});
  final bool prepaid;
  final int? amount;

  @override
  Widget build(BuildContext context) {
    final cod = !prepaid;
    final label = cod && amount != null
        ? LocaleKeys.amountEgp.tr(
            namedArgs: {'amount': formatThousands(amount!)},
          )
        : cod
        ? LocaleKeys.payCod.tr()
        : LocaleKeys.pickupPayPaid.tr();
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
        label,
        style: const TextStyle()
            .setColor(cod ? AppColors.postponedText : AppColors.deliveredText)
            .s12
            .semiBold
            .tabular,
      ),
    );
  }
}
