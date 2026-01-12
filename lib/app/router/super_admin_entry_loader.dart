import 'package:build4all_manager/core/auth/jwt_claims.dart';
import 'package:build4all_manager/features/auth/data/datasources/jwt_local_datasource.dart';
import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/features/superadmin/nav/super_admin_entry.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:build4all_manager/l10n/app_localizations.dart';


Future<(int?, String?)> _loadSuperAdminFromJwt() async {
  try {
    final store = JwtLocalDataSource();
    final (token, roleRaw) = await store.read();

    if (token.isEmpty) return (null, null);

    final role = roleRaw.toUpperCase().trim();
    if (role != 'SUPER_ADMIN') return (null, null);

    final claims = JwtClaims.decode(token);

    final id = JwtClaims.extractInt(claims, ['id', 'adminId', 'sub']);

    final rawName =
        (claims?['name'] ?? claims?['fullName'] ?? claims?['username'])
            ?.toString()
            .trim();

    final name = (rawName == null || rawName.isEmpty) ? null : rawName;

    return (id, name);
  } catch (_) {
    return (null, null);
  }
}

class SuperAdminEntryLoader extends StatelessWidget {
  final int initialIndex;
  const SuperAdminEntryLoader({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<(int?, String?)>(
      future: _loadSuperAdminFromJwt(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final (adminId, adminName) = snap.data ?? (null, null);

        if (adminId == null) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => context.go('/login'));
          return Scaffold(body: Center(child: Text(l10n.err_unauthorized)));
        }

        final Dio dio = DioClient.ensure();

        return SuperAdminEntry(
          adminId: adminId,
          adminName: adminName,
          dio: dio,
          backendMenuType: 'bottom', // later you can fetch this from backend
          initialIndex: initialIndex,
        );
      },
    );
  }
}
