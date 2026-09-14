import 'package:flutter/widgets.dart';

import '../config/res/config_imports.dart';

/// One trip fact — a small glyph, then the figure. The glyph is what tells the
/// ETA from the distance at a glance.
///
/// Shared by the Orders batch row and the branch-handover sheet, which show the
/// same two facts about the same order and must not drift apart. The glyph is
/// the Row's **first** child, so under RTL it paints to the *right* of the
/// figure — that ordering is the layout, not an accident.
class TripFact extends StatelessWidget {
  const TripFact({super.key, required this.icon, required this.text});

  /// An `AppAssets.svg.*` path — `clock` for the ETA, `nav` for the distance.
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
