import 'dart:async';
import 'dart:ui' show FramePhase;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:liquid_tab_bar/liquid_tab_bar.dart';

import '../config/res/config_imports.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/nav_bar_controller.dart';

/// «مختبر شريط التبويب» — the tab bar over content that shows what glass
/// does: dark cards, amber pills, colour bands, text rows. With [autoplay] the
/// page scrolls itself and switches tabs on a timer, so the fold, the lens
/// and the material can be watched (and screenshotted) without a finger on
/// the screen; the bar stays fully live for a real finger too.
class NavBarLab extends StatefulWidget {
  const NavBarLab({super.key, this.autoplay = true, this.cycleMaterials = true});

  final bool autoplay;

  /// With [autoplay], step the material tier (auto → blur → opaque) once per
  /// loop, so the three renderings can be compared in one sitting.
  final bool cycleMaterials;

  @override
  State<NavBarLab> createState() => _NavBarLabState();
}

class _NavBarLabState extends State<NavBarLab> {
  NavTab _tab = NavTab.home;
  final ScrollController _scroll = ScrollController();
  Timer? _timer;
  int _step = 0;

  /// The tier the app was on when the lab opened, put back on the way out.
  /// Captured rather than named: the lab used to restore `glass` by name, so
  /// once `main.dart` pinned a different tier a visit here silently changed
  /// the whole app's bar on the way out.
  late final NavMaterial _entryMaterial;

  /// The frame-stats readout at the top of the page — the way to measure the
  /// bar on a phone with no cable attached (a mid-range Android, say):
  /// sideload, open the lab, read the numbers while autoplay drives the bar.
  /// Fed by the engine's own [SchedulerBinding.addTimingsCallback], flushed
  /// about once a second; idle frames are never reported, so a resting page
  /// shows the last window and stops updating — that stillness is itself the
  /// "no looping animation" check.
  final ValueNotifier<String> _perf = ValueNotifier('');
  final List<FrameTiming> _acc = [];
  int? _lastFlushUs;
  late final TimingsCallback _onTimings;

  @override
  void initState() {
    super.initState();
    _entryMaterial = NavBarController.instance.material;
    _onTimings = _flushTimings;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    if (widget.autoplay) {
      _timer = Timer.periodic(const Duration(milliseconds: 1500), (_) => _play());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _perf.dispose();
    // Leave the app on whatever tier it shipped with — the lab is the only
    // place the others are still reachable, and looking is not choosing.
    NavBarController.instance.material = _entryMaterial;
    super.dispose();
  }

  void _flushTimings(List<FrameTiming> timings) {
    if (!mounted) return;
    _acc.addAll(timings);
    final nowUs =
        timings.last.timestampInMicroseconds(FramePhase.rasterFinish);
    if (_lastFlushUs != null && nowUs - _lastFlushUs! < 1000000) return;
    _lastFlushUs = nowUs;
    final n = _acc.length;
    if (n == 0) return;
    final spanUs = nowUs -
        _acc.first.timestampInMicroseconds(FramePhase.buildStart);
    final fps = spanUs > 0 ? n * 1e6 / spanUs : 0;
    List<double> ms(Duration Function(FrameTiming) d) =>
        (_acc.map((t) => d(t).inMicroseconds / 1000).toList()..sort());
    final build = ms((t) => t.buildDuration);
    final raster = ms((t) => t.rasterDuration);
    double p90(List<double> v) =>
        v[((v.length * 0.9).ceil() - 1).clamp(0, v.length - 1)];
    final jank = _acc
        .where((t) => t.totalSpan.inMicroseconds > 33333)
        .length;
    final tier = NavBarController.instance.effectiveMaterial.name;
    final shader = LiquidGlass.supported ? 'shader ✓' : 'shader ✗ (blur)';
    _perf.value = '$tier · $shader\n'
        '${fps.toStringAsFixed(0)} fps · '
        'build p90 ${p90(build).toStringAsFixed(1)} · '
        'raster p90 ${p90(raster).toStringAsFixed(1)} '
        'max ${raster.last.toStringAsFixed(1)} · '
        'jank $jank/$n';
    _acc.clear();
  }

  /// One beat of the demo: scroll down (fold), scroll up (open), walk the
  /// tabs, back to the top. Loops.
  void _play() {
    if (!mounted) return;
    switch (_step % 8) {
      case 0:
        if (widget.cycleMaterials && _step > 0) {
          const tiers = [NavMaterial.glass, NavMaterial.blur, NavMaterial.opaque];
          NavBarController.instance.material =
              tiers[(_step ~/ 8) % tiers.length];
        }
        _to(360);
      case 1:
        break;
      case 2:
        _to(200);
      case 3:
        setState(() => _tab = NavTab.orders);
      case 4:
        setState(() => _tab = NavTab.profile);
      case 5:
        setState(() => _tab = NavTab.settlement);
      case 6:
        setState(() => _tab = NavTab.home);
      case 7:
        _to(0);
    }
    _step++;
  }

  void _to(double offset) {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      offset,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        extendBody: true,
        bottomNavigationBar: BottomNav(
          active: _tab,
          onTap: (t) {
            setState(() => _tab = t);
            NavBarController.instance.expand();
          },
        ),
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: NavBarController.instance.handleScroll,
                child: _list(context),
              ),
              // The frame-stats chip — LTR numbers on ink, above the list,
              // never over the bar. Updates only when frames render, so an
              // idle page freezes it (which is the point).
              PositionedDirectional(
                top: 4,
                end: 20,
                child: IgnorePointer(
                  child: ValueListenableBuilder<String>(
                    valueListenable: _perf,
                    builder: (_, s, _) => s.isEmpty
                        ? const SizedBox.shrink()
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.inkFill.withValues(alpha: 0.82),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              s,
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                height: 1.35,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(BuildContext context) => ListView(
              controller: _scroll,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: BottomNav.reservedHeight(context),
              ),
              children: [
                Text(
                  'مختبر شريط التبويب',
                  style: const TextStyle().setMainTextColor.s24.bold,
                ),
                8.szH,
                Text(
                  'المحتوى يمر تحت الشريط: انزل لتطويه، اطلع لتفتحه، اسحب عليه لتنتقل.',
                  style: const TextStyle().setSecondaryColor.s14.regular,
                ),
                16.szH,
                for (var i = 0; i < 3; i++) ...[
                  const _DarkCard(),
                  12.szH,
                  const _Band(),
                  12.szH,
                  for (var r = 0; r < 6; r++) _Row(index: i * 6 + r),
                  16.szH,
                ],
              ],
            );
}

class _DarkCard extends StatelessWidget {
  const _DarkCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.cashCardTop, AppColors.cashCardBottom],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'النقدية التي معك الآن',
            style: const TextStyle().setColor(AppColors.paymentLabel).s12.medium,
          ),
          8.szH,
          Text('1,250 جنيه', style: const TextStyle().setWhite.s28.bold),
        ],
      ),
    );
  }
}

/// A band of the app's own colours — the lens has something to bend.
class _Band extends StatelessWidget {
  const _Band();

  static const _colors = [
    AppColors.brand,
    AppColors.transitBg,
    AppColors.greenAccent,
    AppColors.postponedText,
    AppColors.heroBannerTop,
    AppColors.codExcessAmber,
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            for (final c in _colors)
              Expanded(child: ColoredBox(color: c)),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final cod = index.isEven;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderDefault)),
      ),
      child: Row(
        children: [
          Text(
            '#893${10 + index}',
            textDirection: TextDirection.ltr,
            style: const TextStyle().setMainTextColor.s14.bold,
          ),
          12.szW,
          Expanded(
            child: Text(
              'محمد حمدي · زهراء مدينة نصر · 4 قطعة',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle().setSecondaryColor.s12.regular,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cod ? AppColors.heroCodPillBg : AppColors.deliveredBg,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              cod ? '640 جنيه' : 'مدفوع',
              style: const TextStyle()
                  .setColor(cod ? AppColors.postponedText : AppColors.deliveredText)
                  .s12
                  .semiBold,
            ),
          ),
        ],
      ),
    );
  }
}
