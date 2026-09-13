part of '../imports/queue_imports.dart';

/// The Orders tab's browse list: the day as batch sections.
///
/// Frameless — the sections sit straight on the page (no cards, no sheets;
/// the flat-list rule), separated by hairlines. The order is the day itself:
/// the batches **with the courier** first (kept open — that is the work in
/// hand), then the ones waiting at the branch, then the completed ones at the
/// bottom, styled like the settlement's history rows.
class _QueueBatchList extends StatelessWidget {
  const _QueueBatchList({required this.groups, required this.vc});
  final List<QueueBatchGroup> groups;
  final QueueViewController vc;

  @override
  Widget build(BuildContext context) {
    // A filter is narrowing the list: the courier has already said what they
    // want to see, so the rows should not be a tap away.
    final filtering = vc.filter.value != QueueFilter.all;
    // Plain content, not a scrollable: the page is one CustomScrollView now,
    // and a day is three batches deep, so there is nothing here to lazily
    // build — only a nested scroll to avoid.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, group) in groups.indexed) ...[
          if (i > 0)
            // borderDefault, not surfaceSubtle: this rule separates batches
            // on the warm page ground, one step firmer than the row rules.
            const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.borderDefault,
            ),
          _QueueBatchSection(
            // The filter is part of the key: changing it rebuilds the section
            // so the expansion below is re-evaluated instead of keeping the
            // state the courier had before they filtered.
            key: ValueKey('${group.batch.id}-$filtering'),
            group: group,
            vc: vc,
            // The batch with the courier is always open — it is the work in
            // hand. The others arrive closed, unless a filter has already
            // said which orders the courier wants to see.
            initiallyExpanded: filtering || group.inHand,
          ),
        ],
      ],
    ).paddingOnlyDirectional(
      start: AppPadding.pW20,
      end: AppPadding.pW20,
      top: AppPadding.pH4,
      bottom: AppPadding.pH20,
    );
  }
}

/// One batch as a collapsible frameless section: its header row, then its
/// orders as flat rows divided by subtle hairlines. A batch still at the
/// branch closes with its own carry button, so carrying happens where the
/// batch is. A completed batch reads like a settlement-history row.
class _QueueBatchSection extends StatefulWidget {
  const _QueueBatchSection({
    super.key,
    required this.group,
    required this.vc,
    this.initiallyExpanded = true,
  });

  final QueueBatchGroup group;
  final QueueViewController vc;
  final bool initiallyExpanded;

  @override
  State<_QueueBatchSection> createState() => _QueueBatchSectionState();
}

class _QueueBatchSectionState extends State<_QueueBatchSection> {
  late bool _open = widget.initiallyExpanded;

  void _toggle() {
    AppHaptics.tick();
    setState(() => _open = !_open);
  }

  Future<void> _carry() async {
    final ok = await showCarryBatchSheet(context, batch: widget.group.batch);
    if (ok != true || !mounted) return;
    AppHaptics.confirm();
    widget.vc.carryBatch(widget.group.batch.id);
  }

  /// Ongoing orders lead; anything closed (delivered, failed, postponed)
  /// sinks below them — a done order above an open one read as a wrong
  /// arrangement. Stable by number within each half.
  static int _rowRank(OrderStatus s) => s == OrderStatus.transit ? 0 : 1;

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final rows = [...g.rows]..sort((a, b) {
      final r = _rowRank(a.status).compareTo(_rowRank(b.status));
      return r != 0 ? r : a.num.compareTo(b.num);
    });
    final reduced = AppMotion.reduced(context);
    // No card: the section sits straight on the page. A completed batch
    // wears the settlement history's quiet two-line header instead of the
    // live one.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (g.complete)
          _QueuePastBatchHeader(group: g, open: _open, onTap: _toggle)
        else
          _QueueBatchHeader(group: g, open: _open, onTap: _toggle),
        ClipRect(
          child: AnimatedAlign(
            alignment: AlignmentDirectional.topCenter,
            heightFactor: _open ? 1 : 0,
            duration: reduced ? Duration.zero : AppMotion.fill,
            curve: AppMotion.ease,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final order in rows)
                  _QueueBatchRow(
                    order: order,
                    pending: g.pending,
                    last: order == rows.last && !g.pending,
                    onTap: () => widget.vc.openOrder(context, order),
                  ),
                // The carry confirm appears only once the branch would
                // actually hand the batch over: the previous batch is done
                // AND the courier is standing in the branch — see
                // [ShiftController.canCarryPendingBatch] (the location half
                // is a stub until real geofencing lands).
                if (g.pending && ShiftController.instance.canCarryPendingBatch)
                  _CarryBatchButton(count: g.batch.count, onTap: _carry),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The batch's own row: ID + state pill on one line, the sizing line under it,
/// the disclosure chevron at the end.
class _QueueBatchHeader extends StatelessWidget {
  const _QueueBatchHeader({
    required this.group,
    required this.open,
    required this.onTap,
  });

  final QueueBatchGroup group;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = group.batch;
    final String meta;
    if (group.pending) {
      meta = LocaleKeys.queueBatchMetaPending.tr(
        namedArgs: {
          'count': englishDigits(b.count),
          'cash': formatThousands(b.codTotal),
        },
      );
    } else {
      meta = LocaleKeys.queueBatchMetaCarried.tr(
        namedArgs: {
          'count': englishDigits(b.count),
          'cash': formatThousands(b.codTotal),
        },
      );
    }
    return Semantics(
      button: true,
      expanded: open,
      label: b.id,
      // One line, justified — the ID and its state at the reading start, the
      // sizing meta at the far end beside the disclosure chevron (the design
      // frame's header). Frameless: the row owns no fill, only its padding
      // (the list supplies the page gutters).
      child:
          Row(
            children: [
              BatchIdLabel(id: b.id),
              8.szW,
              _BatchStatePill(group: group),
              8.szW,
              Expanded(
                child: Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle()
                      .setSecondaryColor
                      .s12
                      .regular
                      .tabular,
                ),
              ),
              8.szW,
              AnimatedRotation(
                // Points inward while closed, down while open.
                turns: open ? -0.25 : 0,
                duration: AppMotion.reduced(context)
                    ? Duration.zero
                    : AppMotion.fill,
                curve: AppMotion.ease,
                child: IconWidget(
                  icon: AppAssets.svg.chevronLeft,
                  color: AppColors.textSecondary,
                  height: AppSize.sH18,
                  width: AppSize.sW18,
                ),
              ),
            ],
          ).paddingSymmetric(vertical: AppPadding.pH16),
    ).onClick(onTap: onTap);
  }
}

/// A completed batch's header — the day's history, styled like the
/// settlement's past-days rows: the ID and a quiet meta line, the «مكتملة»
/// pill as the row's end, no chevron. Tapping still expands the section to
/// its closed rows.
class _QueuePastBatchHeader extends StatelessWidget {
  const _QueuePastBatchHeader({
    required this.group,
    required this.open,
    required this.onTap,
  });

  final QueueBatchGroup group;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = group.batch;
    return Semantics(
      button: true,
      expanded: open,
      label: b.id,
      child:
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The shared quiet-weight, red-underlined batch mark.
                    Row(children: [BatchIdLabel(id: b.id)]),
                    4.szH,
                    Text(
                      LocaleKeys.queueBatchMetaComplete.tr(
                        namedArgs: {'count': englishDigits(b.count)},
                      ),
                      style: const TextStyle()
                          .setSecondaryColor
                          .s12
                          .regular
                          .tabular,
                    ),
                  ],
                ),
              ),
              8.szW,
              _BatchStatePill(group: group),
            ],
          ).paddingSymmetric(vertical: AppPadding.pH12),
    ).onClick(onTap: onTap);
  }
}

/// «في الفرع» (amber — needs carrying) · «معك» · «مكتملة».
class _BatchStatePill extends StatelessWidget {
  const _BatchStatePill({required this.group});
  final QueueBatchGroup group;

  @override
  Widget build(BuildContext context) {
    final (String text, Color bg, Color fg) = group.pending
        ? (
            LocaleKeys.queueBatchAtBranch.tr(),
            AppColors.heroCodPillBg,
            AppColors.postponedText,
          )
        : group.complete
        ? (
            LocaleKeys.queueBatchComplete.tr(),
            AppColors.surfaceMuted,
            AppColors.textSecondary,
          )
        : (
            LocaleKeys.queueBatchInHand.tr(),
            AppColors.transitPillBg,
            AppColors.transitBg,
          );
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppCircular.r7),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppPadding.pW8,
        vertical: AppPadding.pH2,
      ),
      child: Text(text, style: const TextStyle().setColor(fg).s12.semiBold),
    );
  }
}

/// The ink confirm inside a waiting batch — «تأكيد استلام التشغيلة (3)».
class _CarryBatchButton extends StatelessWidget {
  const _CarryBatchButton({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child:
          Container(
            height: AppSize.sH48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.inkFill,
              borderRadius: BorderRadius.circular(AppCircular.r14),
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
                  LocaleKeys.queueCarryBatch.tr(
                    namedArgs: {'count': englishDigits(count)},
                  ),
                  style: const TextStyle().setWhite.s14.semiBold,
                ),
              ],
            ),
          ).paddingOnly(top: AppPadding.pH12, bottom: AppPadding.pH16),
    ).onClick(onTap: onTap);
  }
}
