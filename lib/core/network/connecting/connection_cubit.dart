import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import 'connection_status.dart';

class ConnectionStateModel {
  final ConnectionStatus status;
  final String? message;

  const ConnectionStateModel({required this.status, this.message});

  ConnectionStateModel copyWith({ConnectionStatus? status, String? message}) {
    return ConnectionStateModel(
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}

class ConnectionCubit extends Cubit<ConnectionStateModel> {
  final Connectivity _connectivity;

  // v6: often List<ConnectivityResult>
  StreamSubscription? _subscription;

  Timer? _heartbeatTimer;

  // ✅ pass a real url that exists (example: http://192.168.1.4:8080)
  final String baseUrl;

  ConnectionCubit({
    required this.baseUrl,
    Connectivity? connectivity,
  })  : _connectivity = connectivity ?? Connectivity(),
        super(const ConnectionStateModel(status: ConnectionStatus.online)) {
    _init();
  }

  Future<void> _init() async {
    // initial check
    final results = await _connectivity.checkConnectivity();
    _updateFromResults(results);

    // listen changes (ignore type differences safely)
    _subscription = _connectivity.onConnectivityChanged.listen((_) async {
      final r = await _connectivity.checkConnectivity();
      _updateFromResults(r);
    });
  }

  void _updateFromResults(List<ConnectivityResult> results) {
    final hasNetwork =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);

    if (!hasNetwork) {
      emit(const ConnectionStateModel(
        status: ConnectionStatus.offline,
        message: 'No internet connection',
      ));
      _stopHeartbeat();
      return;
    }

    // Internet available → start heartbeat and re-check server
    if (state.status == ConnectionStatus.offline) {
      emit(const ConnectionStateModel(status: ConnectionStatus.online));
    }
    _startHeartbeat();
    _pingServer(); // immediate ping
  }

  void _startHeartbeat() {
    _heartbeatTimer ??= Timer.periodic(
      const Duration(seconds: 8),
      (_) => _pingServer(),
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// ✅ “Server reachable” logic:
  /// - Any HTTP response (200/401/403/404/500) => reachable => online
  /// - Timeout/socket => unreachable => serverDown
  Future<void> _pingServer() async {
    if (state.status == ConnectionStatus.offline) return;

    try {
      // ✅ Ping root or a known endpoint
      // If you have ping endpoint: "$baseUrl/api/public/ping"
      final uri = Uri.parse('$baseUrl/');

      final res = await http.get(uri).timeout(const Duration(seconds: 4));

      // Any response means server reachable
      if (res.statusCode > 0) {
        if (state.status != ConnectionStatus.online) {
          emit(const ConnectionStateModel(status: ConnectionStatus.online));
        }
      }
    } catch (_) {
      if (state.status != ConnectionStatus.offline) {
        emit(const ConnectionStateModel(
          status: ConnectionStatus.serverDown,
          message: 'Connecting… (server unreachable)',
        ));
      }
    }
  }

  // Optional: let Dio errors force the state
  void setServerDown([String? message]) {
    if (state.status == ConnectionStatus.offline) return;
    emit(ConnectionStateModel(
      status: ConnectionStatus.serverDown,
      message: message ?? 'Connecting… (server unreachable)',
    ));
  }

  void setOnline() {
    emit(const ConnectionStateModel(status: ConnectionStatus.online));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _stopHeartbeat();
    return super.close();
  }
}
