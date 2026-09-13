part of '../imports/settlement_imports.dart';

/// The returns on the settlement page — the parcels are listed inside their
/// batches above, and that is all now: the «تسليم المرتجعات للفرع» CTA was
/// **removed on the courier's ask** (13 Sep 2026) — handing the parcels over
/// is confirmed at the branch, not by a button here (the standalone
/// `/returns` page keeps the flow for anyone who needs it). Once the returns
/// are handed over, the green note still says so; otherwise the section is
/// silent.
class _ReturnsSection extends StatelessWidget {
  const _ReturnsSection();

  @override
  Widget build(BuildContext context) {
    final shift = ShiftController.instance;
    if (shift.pendingReturns.isEmpty && shift.returnsHandedOver) {
      return const _ReturnsHandedNote().paddingOnly(top: AppPadding.pH12);
    }
    return const SizedBox.shrink();
  }
}

/// Shown once the returns are back at the branch — the settlement page should
/// still say so, otherwise the button simply disappears and the courier is
/// left wondering whether it was ever there.
class _ReturnsHandedNote extends StatelessWidget {
  const _ReturnsHandedNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.deliveredBg,
        borderRadius: BorderRadius.circular(AppCircular.r16),
      ),
      child: Row(
        children: [
          IconWidget(
            icon: AppAssets.svg.check,
            color: AppColors.greenAccent,
            height: AppSize.sH18,
            width: AppSize.sW18,
          ),
          12.szW,
          Expanded(
            child: Text(
              LocaleKeys.failureReturnsDoneTitle.tr(),
              style: const TextStyle()
                  .setColor(AppColors.deliveredText)
                  .s12
                  .semiBold
                  .withHeight(1.5),
            ),
          ),
        ],
      ).paddingAll(AppPadding.pH16),
    );
  }
}

/// «N قطعة» / «N قطع» with Eastern-Arabic digits.
String _piecesLabel(int pieces) {
  final unit = pieces == 1
      ? LocaleKeys.failurePiecesUnitSingular.tr()
      : LocaleKeys.failurePiecesUnitPlural.tr();
  return '${englishDigits(pieces)} $unit';
}
