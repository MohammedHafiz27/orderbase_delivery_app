part of '../imports/notifications_imports.dart';

/// A single notification row — a kind-tinted icon tile (leading, RTL right),
/// the message with the relative time beneath it, and the unread dot at the
/// far end. The message sits at **medium** weight; only the figures inside it
/// — order numbers, batch IDs, amounts — step up to semibold, so a feed of
/// rows reads as prose with the facts standing out, not as a wall of bold.
/// Tapping opens the referenced order.
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    this.onTap,
    this.last = false,
  });
  final AppNotification notification;
  final VoidCallback? onTap;

  /// Last row of the feed — drops the trailing hairline.
  final bool last;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return Container(
      decoration: last
          ? null
          : const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderDefault),
              ),
            ),
      padding: EdgeInsets.symmetric(vertical: AppPadding.pH12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Kind-tinted circle at the reading-start (right in RTL).
          Container(
            width: AppSize.sW44,
            height: AppSize.sH44,
            decoration: BoxDecoration(
              color: n.kind.tileBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: IconWidget(
                icon: n.kind.icon,
                color: n.kind.iconColor,
                height: AppSize.sH20,
                width: AppSize.sW20,
              ),
            ),
          ),
          12.szW,
          // The message, with the relative time directly beneath it.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _EmphasizedTitle(text: n.title),
                4.szH,
                Text(
                  n.time,
                  style: const TextStyle().setHintColor.s12.regular,
                ),
              ],
            ),
          ),
          // Unread marker at the far reading-end, vertically centered.
          if (n.unread) ...[
            12.szW,
            Container(
              width: AppSize.sW8,
              height: AppSize.sH8,
              decoration: const BoxDecoration(
                color: AppColors.brand,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    ).onClick(onTap: onTap);
  }
}

/// The notification message at medium weight, with only its figures —
/// order numbers, batch IDs («T #7877»), amounts — stepped up to semibold.
class _EmphasizedTitle extends StatelessWidget {
  const _EmphasizedTitle({required this.text});
  final String text;

  /// A run that reads as a figure: an optional «T #» / «#» prefix, then
  /// digits with their thousands separators or clock colons.
  static final RegExp _figure = RegExp(r'(?:T\s?#\s?|#)?\d[\d,.:]*');

  @override
  Widget build(BuildContext context) {
    final base = const TextStyle().setMainTextColor.s14.medium.withHeight(
      1.35,
    );
    final strong = const TextStyle().setMainTextColor.s14.semiBold.tabular
        .withHeight(1.35);
    final spans = <TextSpan>[];
    var i = 0;
    for (final m in _figure.allMatches(text)) {
      if (m.start > i) spans.add(TextSpan(text: text.substring(i, m.start)));
      spans.add(TextSpan(text: m.group(0), style: strong));
      i = m.end;
    }
    if (i < text.length) spans.add(TextSpan(text: text.substring(i)));
    return Text.rich(
      TextSpan(style: base, children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
