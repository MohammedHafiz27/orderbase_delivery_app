part of '../imports/queue_imports.dart';

/// Outcome mark for a closed order — a small glyph and a coloured word, no
/// pill behind them (the courier asked the statuses to take less room). The
/// colour still says the outcome at a glance: delivered (green), failed
/// (red), postponed (amber). Shown in place of the pay label once an order is
/// done, so a dimmed row says *why* it's dimmed.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, this.returns});
  final OrderStatus status;
  final String? returns;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      OrderStatus.transit => _mark(
        fg: AppColors.transitBg,
        text: LocaleKeys.statusTransit.tr(),
      ),
      OrderStatus.postponed => _mark(
        fg: AppColors.postponedText,
        leading: AppAssets.svg.clock,
        text: LocaleKeys.statusPostponedReturns.tr(
          namedArgs: {'time': returns ?? ''},
        ),
      ),
      OrderStatus.delivered => _mark(
        fg: AppColors.deliveredText,
        leading: AppAssets.svg.check,
        text: LocaleKeys.statusDelivered.tr(),
      ),
      OrderStatus.failed => _mark(
        fg: AppColors.failedText,
        leading: AppAssets.svg.fail,
        text: LocaleKeys.statusFailed.tr(),
      ),
    };
  }

  Widget _mark({required Color fg, String? leading, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[
          IconWidget(
            icon: leading,
            color: fg,
            height: AppSize.sH12,
            width: AppSize.sW12,
          ),
          4.szW,
        ],
        Text(text, style: const TextStyle().setColor(fg).s12.semiBold),
      ],
    );
  }
}

/// Pay label — COD (amber, the COD semaphore) vs prepaid (green). Amber keeps
/// red reserved as a locator (The One Red Rule) and matches the home hero pill.
class _PayLabel extends StatelessWidget {
  const _PayLabel({required this.prepaid});
  final bool prepaid;

  @override
  Widget build(BuildContext context) {
    return Text(
      (prepaid ? LocaleKeys.payPrepaid : LocaleKeys.payCod).tr(),
      style: const TextStyle()
          .setColor(prepaid ? AppColors.deliveredText : AppColors.postponedText)
          .s12
          .semiBold,
    );
  }
}
