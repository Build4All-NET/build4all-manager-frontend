import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'connection_cubit.dart';
import 'connection_status.dart';

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return BlocBuilder<ConnectionCubit, ConnectionStateModel>(
      buildWhen: (p, n) => p.status != n.status || p.message != n.message,
      builder: (context, state) {
        if (state.status == ConnectionStatus.online) {
          return const SizedBox.shrink();
        }

        final bg = state.status == ConnectionStatus.offline
            ? Colors.redAccent
            : Colors.orange;

        final text = state.status == ConnectionStatus.offline
            ? 'No internet connection'
            : (state.message ?? 'Connecting… (server unreachable)');

        return Material(
          color: bg,
          child: SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      text,
                      style: t.bodyMedium?.copyWith(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
