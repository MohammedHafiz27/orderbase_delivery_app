part of '../imports/home_imports.dart';

/// «فرع مدينة نصر · Sale Sucre» — the branch the courier is assigned to
/// today, and the merchant it belongs to a step quieter beside it.
///
/// It used to lead the app header. The header is a page title now, so the one
/// fact it carried that no page repeats came down here, at the top of the
/// page: the branch is where the day's orders came from and where the cash
/// goes back.
class _HomeBranchLine extends StatelessWidget {
  const _HomeBranchLine({required this.branch, this.merchant});

  final String branch;

  /// The merchant name, rendered a size down and unbolded — one identity
  /// line, two weights (the courier's Figma).
  final String? merchant;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconWidget(
          icon: AppAssets.svg.store,
          color: AppColors.textSecondary,
          height: AppSize.sH18,
          width: AppSize.sW18,
        ),
        8.szW,
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: branch,
                  style: const TextStyle().setMainTextColor.s16.semiBold,
                ),
                if (merchant != null && merchant!.isNotEmpty)
                  TextSpan(
                    text: ' · $merchant',
                    style: const TextStyle().setSecondaryColor.s14.regular,
                  ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
