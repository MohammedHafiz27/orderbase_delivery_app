import 'package:flutter/material.dart';

import '../config/res/config_imports.dart';

/// The batch's ID as every list prints it — «تشغيلة #7877».
///
/// Quieter than the order numbers around it (medium, not bold — the courier's
/// ask): what marks it as a batch is not weight but the thin brand-red rule
/// underneath. Shared by the Orders sections and the settlement so the two
/// pages cannot drift.
class BatchIdLabel extends StatelessWidget {
  const BatchIdLabel({super.key, required this.id, this.muted = false});

  /// The batch's identity as the branch prints it — «تشغيلة #7877».
  final String id;

  /// Secondary ink for pending/empty settlement rows.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: 2.h),
      decoration: const BoxDecoration(
        // brand, not dangerAccent: the rule is a mark, not text, so the
        // logo red is the right one (see the contrast notes in CLAUDE.md).
        border: Border(bottom: BorderSide(color: AppColors.brand)),
      ),
      child: Text(
        id,
        // «تشغيلة #7877» reads RTL; the #number embeds LTR on its own.
        textDirection: TextDirection.rtl,
        style:
            (muted
                    ? const TextStyle().setSecondaryColor
                    : const TextStyle().setMainTextColor)
                .s14
                .medium
                .tabular,
      ),
    );
  }
}
