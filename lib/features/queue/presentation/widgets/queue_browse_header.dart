part of '../imports/queue_imports.dart';

/// Browse sub-head (1b/1d) — now only the breathing room under the unified
/// [AppHeader] (search lives in that header). Sits on the page ground.
///
/// The filter chips that used to sit here are long gone, and the exceptions
/// row followed them (the courier's ask): the batch sections one row below
/// already carry every outcome, so the row restated what the list shows.
/// The filter machinery itself stays dormant behind [_FilterResultsBar].
class _QueueBrowseHeader extends StatelessWidget {
  const _QueueBrowseHeader({required this.vc});
  final QueueViewController vc;

  @override
  Widget build(BuildContext context) => 8.szH;
}

/// Reused square icon button (search / back) — white tile + hairline border,
/// matching the home header icons and the shared back tile (one icon-button look).
class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.icon,
    required this.onTap,
    required this.size,
    this.label,
  });
  final String icon;
  final VoidCallback onTap;
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    // Guarantee a >=44pt tap area even when the visual tile is smaller.
    return Semantics(
      button: true,
      label: label,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 44.w, minHeight: 44.h),
        child: Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppCircular.r12),
              border: Border.all(color: AppColors.iconButtonBorder),
            ),
            child: Center(
              child: IconWidget(
                icon: icon,
                color: AppColors.textPrimary,
                height: AppSize.sH20,
                width: AppSize.sW20,
              ),
            ),
          ),
        ),
      ).onClick(onTap: onTap),
    );
  }
}
