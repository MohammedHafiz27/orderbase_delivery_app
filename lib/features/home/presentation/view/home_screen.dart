part of '../imports/home_imports.dart';

/// Force one of Home's states for a preview (DevGallery). Null reads the live
/// shift, which is what the app shell does.
enum HomePreview { idle, returning, settled }

/// Home / الرئيسية — the branch line (branch · merchant) leading the page,
/// the collect-the-new-batch row when one is waiting, then the next order as
/// a hero card. The day's numbers left the page: the cash rides the app
/// header's chip and the counts live on the Orders tab. Reads the live
/// [ShiftController] so the hero advances as stops close, and swaps the hero
/// for a status card when there is nothing to deliver: before the first
/// batch, once everything in hand is closed (expected back at the branch),
/// and after the branch has settled the day.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onSelectTab,
    this.onOpenOrder,
    this.onDeliverOrder,
    this.onCallCustomer,
    this.onCallBranch,
    this.onOpenSettlement,
    this.onOpenPendingBatch,
    this.onOpenNotifications,
    this.onOpenSearch,
    this.onStartNewDay,
    this.preview,
    this.hostsTabBar = true,
  });

  /// Forwarded to the bottom nav so the app shell can switch tabs.
  final ValueChanged<NavTab>? onSelectTab;

  /// Opens the notifications page (the header bell).
  final VoidCallback? onOpenNotifications;

  /// Opens search (the header search icon) — routed to the Orders tab.
  final VoidCallback? onOpenSearch;

  /// Opens the current next-stop order's detail — the hero card taps through
  /// to it.
  final VoidCallback? onOpenOrder;

  /// Hands the current order over («تم تسليم الطلب» — the hero's black
  /// button): handoff sheet → COD collection when there is cash → result.
  final VoidCallback? onDeliverOrder;

  /// The hero's call tile — dials the current customer.
  final VoidCallback? onCallCustomer;

  /// «اتصال بالفرع» on the expected-at-branch card.
  final VoidCallback? onCallBranch;

  /// The header's cash chip → settlement.
  final VoidCallback? onOpenSettlement;

  /// The status card's «تشغيلة جديدة في انتظارك» row → the Orders tab.
  final VoidCallback? onOpenPendingBatch;

  /// Dev-only: reset the simulated day from the settled card.
  final VoidCallback? onStartNewDay;

  /// Force a state for previews; null follows the live shift.
  final HomePreview? preview;

  /// Standalone (DevGallery, a route) the page carries its own tab bar; inside
  /// the app shell the shell owns the one bar, so this is false there.
  final bool hostsTabBar;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CourierStatus _status(ShiftController shift) => switch (widget.preview) {
    HomePreview.idle => CourierStatus.idle,
    HomePreview.returning => CourierStatus.returning,
    HomePreview.settled => CourierStatus.settled,
    null => shift.status,
  };

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        // The page runs under the floating tab bar — that is what gives the
        // glass something to blur.
        extendBody: true,
        bottomNavigationBar: widget.hostsTabBar
            ? BottomNav(
                active: NavTab.home,
                notificationsBadge: true,
                onTap: widget.onSelectTab,
              )
            : null,
        body: SafeArea(
          // The header sliver carries the top inset (see AppHeaderSliver), so the
          // page passes under the status bar and the scroll-edge blur runs to the
          // top of the screen.
          top: false,
          bottom: false,
          child: CustomScrollView(
            slivers: [
              AppHeaderSliver(
                title: LocaleKeys.navHome.tr(),
                onSearch: widget.onOpenSearch,
                onOpenNotifications: widget.onOpenNotifications,
                onCashTap: widget.onOpenSettlement,
              ),
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    ShiftController.instance,
                    RoadMode.instance,
                  ]),
                  builder: (_, _) {
                    final shift = ShiftController.instance;
                    final status = _status(shift);
                    // There is an order to deliver: the hero, not a status
                    // card, occupies the top of the page.
                    final hasStop =
                        status == CourierStatus.onRoute &&
                        shift.nextStop != null;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Which branch the courier is on today, and the
                        // merchant it belongs to — it left the header when
                        // the header became a page title. (The stat strip
                        // that used to follow is gone: the cash now rides
                        // the header itself, and the counts live on the
                        // Orders tab.)
                        _HomeBranchLine(
                          branch: shift.branchName,
                          merchant: Courier.merchantName,
                        ),
                        // A batch dispatched mid-route is a reason to turn
                        // around now — those orders are not in the bag. The
                        // row sits with the branch it points back to, above
                        // the hero (the courier's Figma), whatever state the
                        // hero slot is in.
                        if (shift.hasPendingBatch) ...[
                          12.szH,
                          _PendingBatchRow(
                            onTap: widget.onOpenPendingBatch,
                            returning: status == CourierStatus.returning,
                          ),
                        ],
                        20.szH,
                        if (hasStop)
                          // The hero is self-contained: the lead-in sits
                          // inside it above the destination, and the
                          // deliver/call actions live inside the card too.
                          _HomeNextStopCard(
                            onViewOrder: widget.onOpenOrder,
                            onDeliver: widget.onDeliverOrder,
                            onCall: widget.onCallCustomer,
                          )
                        else
                          _HomeStateCard(
                            status: status,
                            onCallBranch: widget.onCallBranch,
                            onStartNewDay: widget.onStartNewDay,
                          ),
                      ],
                    ).paddingOnly(
                      left: AppPadding.pW16,
                      top: AppPadding.pH12,
                      right: AppPadding.pW16,
                      // Clears the floating tab bar the page runs under.
                      bottom: BottomNav.reservedHeight(context),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
