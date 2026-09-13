part of '../imports/auth_imports.dart';

/// Auth 1e — Change password (opened from the profile).
///
/// Redesigned to speak the **profile page's language** (the courier's ask —
/// the old carded auth look read as a different app): white edge-to-edge
/// sections ruled by hairlines on the warm ground, a back tile + title bar
/// like every pushed page, and the **shared [ProfileIdentityCard]** on top —
/// so the photo (and its pen badge / «قيد المراجعة» review flow) is changeable
/// from here exactly as it is on the Account tab. The password form sits in
/// its own white group beneath: current (with «نسيتها؟»), a rule, then the
/// new + confirm pair and the note. The sticky «تحديث كلمة المرور» footer
/// stays (disabled until valid).
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final ChangePasswordController _vc = ChangePasswordController();

  @override
  void dispose() {
    _vc.dispose();
    super.dispose();
  }

  void _update() => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const AuthSuccessScreen()));

  void _openForgot() => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const ForgotPasswordScreen()));

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Back tile + title — the pushed-page header, not a floating
              // inline link.
              Row(
                children: [
                  const HeaderBackButton(),
                  12.szW,
                  Expanded(
                    child: Text(
                      LocaleKeys.authChangeTitle.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle().setMainTextColor.s18.bold,
                    ),
                  ),
                ],
              ).paddingOnlyDirectional(
                start: AppPadding.pW20,
                end: AppPadding.pW20,
                top: AppPadding.pH8,
                bottom: AppPadding.pH12,
              ),
              Expanded(
                child: SingleChildScrollView(
                  // No side padding: the sections run edge to edge like the
                  // profile page's groups.
                  padding: EdgeInsetsDirectional.only(
                    top: AppPadding.pH8,
                    bottom: AppPadding.pH24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // The same identity block the Account tab shows — one
                      // widget, so the two screens can never disagree, and
                      // the photo is changeable from here too.
                      const ProfileIdentityCard(topHairline: true),
                      16.szH,
                      // The form as one white group, ruled like the rows.
                      DecoratedBox(
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          border: Border(
                            top: BorderSide(color: AppColors.borderHeader),
                            bottom: BorderSide(color: AppColors.borderHeader),
                          ),
                        ),
                        child:
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _AuthField(
                                  label: LocaleKeys.authCurrentPassword.tr(),
                                  controller: _vc.current,
                                  icon: _kLockIcon,
                                  obscure: true,
                                  showToggle: true,
                                  labelTrailing: _AuthLink(
                                    label: LocaleKeys.authForgotItLink.tr(),
                                    onTap: _openForgot,
                                  ),
                                ),
                                16.szH,
                                Container(
                                  height: 1,
                                  color: AppColors.itemDivider,
                                ),
                                16.szH,
                                _AuthField(
                                  label: LocaleKeys.authNewPassword.tr(),
                                  controller: _vc.password,
                                  icon: _kLockIcon,
                                  obscure: true,
                                  showToggle: true,
                                  hint: LocaleKeys.authRuleLength.tr(),
                                ),
                                16.szH,
                                _AuthField(
                                  label: LocaleKeys.authConfirmPassword.tr(),
                                  controller: _vc.confirm,
                                  icon: _kLockIcon,
                                  obscure: true,
                                  showToggle: true,
                                  hint: LocaleKeys.authConfirmHint.tr(),
                                ),
                                16.szH,
                                Text(
                                  LocaleKeys.authChangeNote.tr(),
                                  style: const TextStyle()
                                      .setSecondaryColor
                                      .s12
                                      .regular
                                      .withHeight(1.5),
                                ),
                                // No sign-out here: signing out lives in ONE
                                // place, the profile tab.
                              ],
                            ).paddingSymmetric(
                              horizontal: AppPadding.pW20,
                              vertical: AppPadding.pH20,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              // Sticky footer + home indicator, the auth-flow treatment.
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.borderHeader),
                  ),
                ),
                child:
                    AnimatedBuilder(
                      animation: _vc.formListenable,
                      builder: (context, _) => _AuthPrimaryButton(
                        label: LocaleKeys.authUpdatePassword.tr(),
                        enabled: _vc.canUpdate,
                        onTap: _update,
                      ),
                    ).paddingOnlyDirectional(
                      start: AppPadding.pW20,
                      end: AppPadding.pW20,
                      top: AppPadding.pH16,
                      bottom: AppPadding.pH12,
                    ),
              ),
              const HomeIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
