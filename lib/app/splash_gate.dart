import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


import 'package:build4all_manager/features/auth/data/datasources/jwt_local_datasource.dart';

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final store = JwtLocalDataSource();
    final (token, roleRaw) = await store.read();

    if (!mounted) return;

    final role = roleRaw.toUpperCase().trim();

    if (token.isEmpty || role.isEmpty) {
      context.go('/login');
      return;
    }

    // Optional (not required, interceptor will attach token anyway)
    DioClient.setToken(token);

    context.go(role == 'SUPER_ADMIN' ? '/manager' : '/owner');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.6),
        ),
      ),
    );
  }
}
