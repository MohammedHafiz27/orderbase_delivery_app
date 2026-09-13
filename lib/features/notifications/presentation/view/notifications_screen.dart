part of '../imports/notifications_imports.dart';

/// Notifications / الاشعارات — the courier's activity feed (batch dispatched /
/// order assigned / cancelled / notes / wallet credit / cash limit / settled).
///
/// Two lifecycles:
///  * **In the shell** ([embedded] = true) — the app shell hosts it as a page
///    inside the tab frame: the unified header and the tab bar stay put and
///    this widget renders only the title row and the feed.
///  * **Standalone** (DevGallery) — it draws its own back header + indicator.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    this.onSelectTab,
    this.onOpenOrder,
    this.onOpenSearch,
    this.onClose,
    this.embedded = false,
  });

  /// Forwarded to the bottom nav so the app shell can switch tabs.
  final ValueChanged<NavTab>? onSelectTab;

  /// The header's search tile (embedded mode) — routed to the Orders tab.
  final VoidCallback? onOpenSearch;

  /// The header's bell, inverted here: it closes this page and returns to the
  /// tab the courier came from.
  final VoidCallback? onClose;

  /// Opens the order a notification refers to (by number, without '#'). The
  /// app shell resolves it against the shift and pushes the order flow.
  final ValueChanged<String>? onOpenOrder;

  /// Hosted inside the shell's frame — no header of its own, no indicator.
  final bool embedded;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scroll = ScrollController();

  // The header is transparent at the top and gains its surface background once
  // the feed scrolls beneath it (iOS large-title behaviour).
  final ValueNotifier<bool> _scrolled = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    final v = _scroll.offset > 2;
    if (v != _scrolled.value) _scrolled.value = v;
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _scrolled.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild as the feed grows — the simulator files batch / cash / settled
    // events while this page may be on screen.
    return AnimatedBuilder(
      animation: Listenable.merge([
        NotificationsStore.instance,
        ShiftController.instance,
      ]),
      builder: (context, _) {
        final items = NotificationsStore.instance.items;
        final unread = items.where((n) => n.unread).length;
        Widget tile(int i) => _NotificationTile(
          notification: items[i],
          last: i == items.length - 1,
          onTap: widget.onOpenOrder == null || items[i].orderNum.isEmpty
              ? null
              : () => widget.onOpenOrder!(items[i].orderNum),
        );

        if (widget.embedded) {
          // Inside the shell the page owns its own scroll view, so the title
          // collapses on the feed exactly like every tab's does.
          return CustomScrollView(
            slivers: [
              AppHeaderSliver(
                title: LocaleKeys.navNotifications.tr(),
                onSearch: widget.onOpenSearch,
                onOpenNotifications: widget.onClose,
                notificationsActive: true,
                // The cash chip switches to the Settlement tab.
                onCashTap: widget.onSelectTab == null
                    ? null
                    : () => widget.onSelectTab!(NavTab.settlement),
              ),
              // No banner atop the feed: the dispatch already announces
              // itself as a sheet, a notification and the Orders badge — a
              // standing hero here was a fourth copy of the same fact.
              SliverToBoxAdapter(
                child: _NotificationsListTitle(
                  onMarkAllRead: unread > 0
                      ? NotificationsStore.instance.markAllRead
                      : null,
                ),
              ),
              if (items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _NotificationsEmpty(),
                )
              else
                SliverPadding(
                  padding: EdgeInsetsDirectional.only(
                    start: AppPadding.pW20,
                    end: AppPadding.pW20,
                    top: AppPadding.pH4,
                    bottom: BottomNav.reservedHeight(context),
                  ),
                  sliver: SliverList.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) => tile(i),
                  ),
                ),
            ],
          );
        }

        final feed = items.isEmpty
            ? const _NotificationsEmpty()
            : ListView.builder(
                controller: _scroll,
                padding: EdgeInsetsDirectional.only(
                  start: AppPadding.pW20,
                  end: AppPadding.pW20,
                  top: AppPadding.pH4,
                  bottom: AppPadding.pH20,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) => tile(i),
              );

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: _scrolled,
                    builder: (_, scrolled, _) => _NotificationsHeader(
                      unread: unread,
                      scrolled: scrolled,
                    ),
                  ),
                  Expanded(child: feed),
                  const HomeIndicator(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The «التنبيهات السابقة» heading over the feed, with a «تحديد الكل كمقروء»
/// action (shown only while something is unread) at the far end.
class _NotificationsListTitle extends StatelessWidget {
  const _NotificationsListTitle({this.onMarkAllRead});
  final VoidCallback? onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          LocaleKeys.notifPrevious.tr(),
          style: const TextStyle().setMainTextColor.s12.bold,
        ),
        const Spacer(),
        if (onMarkAllRead != null)
          Text(
            LocaleKeys.notifMarkAllRead.tr(),
            style: const TextStyle().setSecondaryColor.s12.regular,
          ).onClick(onTap: onMarkAllRead),
      ],
    ).paddingOnly(
      left: AppPadding.pW20,
      top: AppPadding.pH8,
      right: AppPadding.pW20,
      bottom: AppPadding.pH12,
    );
  }
}
