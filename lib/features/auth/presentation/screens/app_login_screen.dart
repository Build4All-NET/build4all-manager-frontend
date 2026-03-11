import 'dart:async';
import 'dart:ui';

import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/core/notifications/firebase_push_service.dart';
import 'package:build4all_manager/features/auth/data/datasources/jwt_local_datasource.dart';
import 'package:build4all_manager/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:build4all_manager/features/auth/data/services/auth_api.dart';
import 'package:build4all_manager/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:build4all_manager/features/auth/domain/usecases/get_role_usecase.dart';
import 'package:build4all_manager/features/auth/domain/usecases/login_usecase.dart';
import 'package:build4all_manager/features/auth/domain/usecases/logout_usecase.dart';
import 'package:build4all_manager/features/auth/presentation/bloc/login/auth_bloc.dart';
import 'package:build4all_manager/features/auth/presentation/bloc/login/auth_event.dart';
import 'package:build4all_manager/features/auth/presentation/bloc/login/auth_state.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_toast.dart';

Future<void> _initPushSafely() async {
  try {
    await FirebasePushService().initForAdmin();
  } catch (_) {
    // ignore push init errors here so login navigation is never blocked
  }
}

void _goAfterFrame(BuildContext context, String route) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) {
      context.go(route);
    }
  });
}

enum _LoginErrorType {
  incorrectPassword,
  incorrectEmailOrUsername,
  incorrectCredentials,
  raw,
}

_LoginErrorType? _resolveLoginErrorType(String? rawError) {
  final raw = (rawError ?? '').trim();
  if (raw.isEmpty) return null;

  final msg = raw.toLowerCase();

  bool hasAny(List<String> values) {
    for (final value in values) {
      if (msg.contains(value.toLowerCase())) return true;
    }
    return false;
  }

  // password wrong
  if (hasAny([
    'incorrect password',
    'wrong password',
    'invalid password',
    'password incorrect',
    'password is incorrect',
    'bad password',
  ])) {
    return _LoginErrorType.incorrectPassword;
  }

  // email / username / owner identifier wrong
  if (hasAny([
    'incorrect email',
    'wrong email',
    'invalid email',
    'email not found',
    'incorrect username',
    'wrong username',
    'invalid username',
    'username not found',
    'owner not found',
    'account not found',
    'identifier not found',
    'invalid identifier',
  ])) {
    return _LoginErrorType.incorrectEmailOrUsername;
  }

  // generic backend auth errors
  if (hasAny([
    'bad credentials',
    'invalid credentials',
    'wrong credentials',
    'invalid login',
    'login failed',
    'invalid username or password',
    'incorrect username or password',
    'incorrect email or password',
    'invalid email or password',
  ])) {
    return _LoginErrorType.incorrectCredentials;
  }

  // fallback heuristics
  if (msg.contains('password') &&
      (msg.contains('wrong') ||
          msg.contains('incorrect') ||
          msg.contains('invalid'))) {
    return _LoginErrorType.incorrectPassword;
  }

  if ((msg.contains('email') ||
          msg.contains('username') ||
          msg.contains('owner') ||
          msg.contains('identifier') ||
          msg.contains('account')) &&
      (msg.contains('wrong') ||
          msg.contains('incorrect') ||
          msg.contains('invalid') ||
          msg.contains('not found') ||
          msg.contains('does not exist'))) {
    return _LoginErrorType.incorrectEmailOrUsername;
  }

  return _LoginErrorType.raw;
}

String? _mapLoginError(BuildContext context, String? rawError) {
  final raw = (rawError ?? '').trim();
  if (raw.isEmpty) return null;

  final l10n = AppLocalizations.of(context)!;
  final type = _resolveLoginErrorType(raw);

  switch (type) {
    case _LoginErrorType.incorrectPassword:
      return l10n.loginIncorrectPassword;
    case _LoginErrorType.incorrectEmailOrUsername:
      return l10n.loginIncorrectEmailOrUsername;
    case _LoginErrorType.incorrectCredentials:
      return l10n.loginIncorrectCredentials;
    case _LoginErrorType.raw:
      return raw;
    case null:
      return null;
  }
}

class AppLoginScreen extends StatelessWidget {
  const AppLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final IAuthRepository repo = AuthRepositoryImpl(
      api: AuthApi(DioClient.ensure()),
      jwtStore: JwtLocalDataSource(),
    );

    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (_) => AuthBloc(
        loginUseCase: LoginUseCase(repo),
        logoutUseCase: LogoutUseCase(repo),
        getRoleUseCase: GetStoredRoleUseCase(repo),
      ),
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (p, c) => p.role != c.role || p.error != c.error,
        listener: (context, state) {
          final role = (state.role ?? '').toUpperCase();
          final friendlyError = _mapLoginError(context, state.error);

          if (friendlyError != null && friendlyError.isNotEmpty) {
            AppToast.error(context, friendlyError);
            return;
          }

          if (role == 'SUPER_ADMIN') {
            AppToast.success(context, l10n.msgWelcomeBack);

            _goAfterFrame(context, '/manager');
            unawaited(_initPushSafely());
            return;
          }

          if (role.isNotEmpty) {
            AppToast.success(context, l10n.msgWelcomeBack);

            _goAfterFrame(context, '/owner');
            unawaited(_initPushSafely());
          }
        },
        child: Scaffold(
          backgroundColor: cs.surface,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, cts) {
                final isWide = cts.maxWidth >= 900;
                final cardMaxWidth = isWide ? 560.0 : 480.0;

                return Stack(
                  children: [
                    _Header(title: l10n.appTitle),
                    Align(
                      alignment: Alignment.topCenter,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          top: isWide ? 120 : 140,
                          left: 16,
                          right: 16,
                          bottom: 24,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: cardMaxWidth),
                          child: _FrostedCard(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Hero(
                                        tag: 'brand',
                                        child: CircleAvatar(
                                          radius: 30,
                                          backgroundColor: cs.primary.withOpacity(.12),
                                          child: Text(
                                            'B4',
                                            style: TextStyle(
                                              color: cs.primary,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    l10n.signInGeneralTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    l10n.signInGeneralSubtitle,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: cs.outline),
                                  ),
                                  const SizedBox(height: 20),
                                  const Divider(height: 1),
                                  const SizedBox(height: 20),
                                  const _LoginForm(),
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: () => context.go('/owner/register'),
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: l10n.noAccount,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(color: cs.outline),
                                          ),
                                          TextSpan(
                                            text: ' ${l10n.signUp}',
                                            style: TextStyle(
                                              color: cs.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.termsNotice,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: cs.outline),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  final _idNode = FocusNode();
  final _pwNode = FocusNode();

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    _idNode
      ..unfocus()
      ..dispose();
    _pwNode
      ..unfocus()
      ..dispose();
    super.dispose();
  }

  String? _idValidator(String? v, AppLocalizations l10n) {
    if (v == null || v.trim().isEmpty) return l10n.errIdentifierRequired;
    return null;
  }

  String? _pwValidator(String? v, AppLocalizations l10n) {
    if (v == null || v.isEmpty) return l10n.errPasswordRequired;
    if (v.length < 6) return l10n.errPasswordMin;
    return null;
  }

  void _submit(BuildContext context, AppLocalizations l10n) {
    final form = _formKey.currentState;
    if (form == null) return;

    if (!form.validate()) {
      AppToast.warn(context, l10n.errFixForm);
      return;
    }

    FocusScope.of(context).unfocus();

    context.read<AuthBloc>().add(
          LoginSubmitted(_identifier.text.trim(), _password.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final friendlyError = _mapLoginError(context, state.error);

        return Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextField(
                controller: _identifier,
                focusNode: _idNode,
                label: l10n.lblIdentifier,
                hint: l10n.hintIdentifier,
                prefix: const Icon(Icons.alternate_email),
                textInputAction: TextInputAction.next,
                validator: (v) => _idValidator(v, l10n),
                onSubmitted: (_) => _pwNode.requestFocus(),
              ),
              const SizedBox(height: 14),
              AppPasswordField(
                controller: _password,
                focusNode: _pwNode,
                label: l10n.lblPassword,
                hint: l10n.hintPassword,
                prefix: const Icon(Icons.lock_outline),
                textInputAction: TextInputAction.done,
                validator: (v) => _pwValidator(v, l10n),
                onSubmitted: (_) => _submit(context, l10n),
              ),
              const SizedBox(height: 14),
              AppButton(
                label: l10n.btnSignIn,
                expand: true,
                isBusy: state.loading,
                trailing: const Icon(Icons.login_rounded),
                onPressed: state.loading ? null : () => _submit(context, l10n),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: (friendlyError?.isNotEmpty == true)
                    ? Text(
                        friendlyError!,
                        key: ValueKey(friendlyError),
                        style: TextStyle(
                          color: cs.error,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
          ),
          Positioned(
            top: 24,
            left: -30,
            child: _Blob(color: Colors.white.withOpacity(.08), size: 120),
          ),
          Positioned(
            top: 0,
            right: -18,
            child: _Blob(color: Colors.white.withOpacity(.10), size: 90),
          ),
          Positioned.fill(
            top: 18,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .2,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(.4),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
      );
}

class _FrostedCard extends StatelessWidget {
  final Widget child;
  const _FrostedCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(.92),
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
            border: Border.all(color: cs.outlineVariant.withOpacity(.5)),
          ),
          child: child,
        ),
      ),
    );
  }
}