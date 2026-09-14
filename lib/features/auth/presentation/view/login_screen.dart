part of '../imports/auth_imports.dart';

/// Auth 1a — Login. Merchant number + username (prefilled) + password with the
/// active 2px-ink border and eye toggle, a danger-red "forgot password" link,
/// and the ink primary "دخول". The Screen owns the [LoginController] lifecycle.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onSubmit});

  /// Called on a successful sign-in — the route wires this to enter the app.
  final VoidCallback? onSubmit;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginController _vc = LoginController();

  @override
  void dispose() {
    _vc.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.onSubmit != null) {
      widget.onSubmit!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _openForgot() => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const ForgotPasswordScreen()));

  @override
  Widget build(BuildContext context) {
    // Logo sits on the paper ground; the form (title → button) lives inside a
    // single white card, mirroring the reference layout.
    return _AuthScaffold(
      centered: true,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [const _AuthBrandLockup(), 24.szH, _card()],
      ),
    );
  }

  /// The card's rhythm comes straight from the courier's Figma frame
  /// (`639:2`, 14 Sep 2026): **16 padding**, and **four blocks 12 apart** —
  /// the heading, the fields, the forgot link, the button. The blocks are real
  /// groups, not a flat run of spacers, because the spacing inside each one is
  /// tighter than the spacing between them: the heading holds its two lines
  /// **2** apart, the field group holds its three inputs **8** apart. (2 is off
  /// the 4px gap scale on purpose — see the 4-pixel rule note in CLAUDE.md.)
  Widget _card() => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppCircular.r22),
      border: Border.all(color: AppColors.borderCardFaint),
      boxShadow: AppShadows.card,
    ),
    padding: EdgeInsets.all(AppPadding.pW16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(),
        12.szH,
        _fields(),
        12.szH,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: _AuthLink(
            label: LocaleKeys.authForgotLink.tr(),
            onTap: _openForgot,
            compact: true,
          ),
        ),
        12.szH,
        AnimatedBuilder(
          animation: _vc.formListenable,
          builder: (context, _) => _AuthPrimaryButton(
            label: LocaleKeys.authLoginSubmit.tr(),
            enabled: _vc.canSubmit,
            onTap: _submit,
          ),
        ),
      ],
    ),
  );

  /// Title over subtitle, 2 apart — one thought on two lines, so they sit
  /// closer to each other than to anything else on the card.
  Widget _heading() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        LocaleKeys.authLoginTitle.tr(),
        textAlign: TextAlign.center,
        style: const TextStyle().setMainTextColor.s18.bold.withHeight(1.4),
      ),
      2.szH,
      Text(
        LocaleKeys.authLoginSubtitle.tr(),
        textAlign: TextAlign.center,
        style: const TextStyle().setSecondaryColor.s14.regular.withHeight(1.4),
      ),
    ],
  );

  /// The three inputs as one block, 8 apart.
  Widget _fields() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _AuthField(
        label: LocaleKeys.authMerchant.tr(),
        controller: _vc.merchant,
        icon: _kStoreIcon,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ltr: true,
        tabular: true,
        compact: true,
      ),
      8.szH,
      _AuthField(
        label: LocaleKeys.authUsername.tr(),
        controller: _vc.username,
        icon: AppAssets.svg.user,
        ltr: true,
        compact: true,
      ),
      8.szH,
      _AuthField(
        label: LocaleKeys.authPassword.tr(),
        controller: _vc.password,
        icon: _kLockIcon,
        obscure: true,
        showToggle: true,
        compact: true,
      ),
    ],
  );
}
