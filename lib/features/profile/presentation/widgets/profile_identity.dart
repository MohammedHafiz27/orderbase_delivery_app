part of '../imports/profile_imports.dart';

/// Who is signed in: photo, name, and the account they are signed in under.
///
/// The avatar is the courier's own photo once they upload one; initials until
/// then. Tapping it (or the camera badge on its corner) opens the system
/// photo picker via [ProfilePhoto]. An uploaded photo is not immediately
/// theirs to keep: it goes **under review** — the amber «قيد المراجعة» pill by
/// the name says so until the branch accepts or declines it (no backend yet,
/// so in the demo it stays pending).
class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity();

  Future<void> _changePhoto(BuildContext context) async {
    final uploaded = await ProfilePhoto.instance.pick();
    if (!uploaded || !context.mounted) return;
    AppHaptics.confirm();
    // Tell the courier what happens next — the photo is not live yet.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(LocaleKeys.profilePhotoUploaded.tr())),
      );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.borderHeader)),
      ),
      child:
          ListenableBuilder(
            listenable: ProfilePhoto.instance,
            builder: (context, _) {
              final photo = ProfilePhoto.instance;
              final pending = photo.status == ProfilePhotoStatus.pending;
              return Row(
                children: [
                  _AvatarButton(
                    bytes: photo.bytes,
                    onTap: () => _changePhoto(context),
                  ),
                  16.szW,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                Courier.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle()
                                    .setMainTextColor
                                    .s18
                                    .bold,
                              ),
                            ),
                            if (pending) ...[8.szW, const _ReviewPill()],
                          ],
                        ),
                        4.szH,
                        Text(
                          Courier.username,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle().setSecondaryColor.s12.regular,
                        ),
                        4.szH,
                        Text(
                          LocaleKeys.profileMerchantNo.tr(
                            namedArgs: {'num': Courier.merchant},
                          ),
                          style: const TextStyle().setHintColor.s12.regular,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ).paddingSymmetric(
            horizontal: AppPadding.pW20,
            vertical: AppPadding.pH20,
          ),
    );
  }
}

/// The avatar as a button: the photo (or initials) with a small ink pen
/// badge on its lower corner saying "this is editable" (the courier's pick —
/// Figma `edit-02`).
class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.bytes, required this.onTap});
  final Uint8List? bytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: LocaleKeys.profilePhotoChange.tr(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: AppSize.sW64,
            height: AppSize.sH64,
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceMuted,
            ),
            child: bytes == null
                ? Text(
                    Courier.initials,
                    style: const TextStyle().setMainTextColor.s18.bold,
                  )
                : Image.memory(
                    bytes!,
                    width: AppSize.sW64,
                    height: AppSize.sH64,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
          ),
          // The pen badge sits at the visual bottom-left of the avatar
          // (bottom-end in RTL), ringed in surface so it reads over a photo.
          PositionedDirectional(
            bottom: -2,
            end: -2,
            child: Container(
              width: AppSize.sW24,
              height: AppSize.sH24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.inkFill,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: IconWidget(
                icon: AppAssets.svg.pen,
                color: AppColors.surface,
                height: AppSize.sH12,
                width: AppSize.sW12,
              ),
            ),
          ),
        ],
      ).onClick(onTap: onTap),
    );
  }
}

/// «قيد المراجعة» — the uploaded photo awaits the branch's accept/decline.
class _ReviewPill extends StatelessWidget {
  const _ReviewPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.postponedBg,
        borderRadius: BorderRadius.circular(AppCircular.r7),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppPadding.pW8,
        vertical: AppPadding.pH2,
      ),
      child: Text(
        LocaleKeys.profilePhotoPending.tr(),
        style: const TextStyle()
            .setColor(AppColors.postponedText)
            .s12
            .semiBold,
      ),
    );
  }
}
