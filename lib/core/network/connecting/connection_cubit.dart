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

  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;

  //  new: delay before showing "serverDown"
  static const Duration serverDownDelay = Duration(seconds: 5);
  DateTime? _downSince;
  Timer? _downTimer;
  String? _downMessage;

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
    final results = await _connectivity.checkConnectivity();
    _updateFromResults(results);

    _subscription = _connectivity.onConnectivityChanged.listen((_) async {
      final r = await _connectivity.checkConnectivity();
      _updateFromResults(r);
    });
  }

  void _updateFromResults(List<ConnectivityResult> results) {
    final hasNetwork =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);

    if (!hasNetwork) {
      _clearServerDownDelay();
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

  void _armServerDownDelay([String? message]) {
    if (state.status == ConnectionStatus.offline) return;
    if (state.status == ConnectionStatus.serverDown) return;

    _downMessage = message ?? 'Connecting… (server unreachable)';
    _downSince ??= DateTime.now();

    // already armed
    if (_downTimer != null) return;

    final elapsed = DateTime.now().difference(_downSince!);
    final remaining = serverDownDelay - elapsed;

    if (remaining <= Duration.zero) {
      emit(ConnectionStateModel(
        status: ConnectionStatus.serverDown,
        message: _downMessage,
      ));
      _downTimer?.cancel();
      _downTimer = null;
      return;
    }

    _downTimer = Timer(remaining, () {
      // still down? only then emit
      if (_downSince != null && state.status != ConnectionStatus.offline) {
        emit(ConnectionStateModel(
          status: ConnectionStatus.serverDown,
          message: _downMessage,
        ));
      }
      _downTimer = null;
    });
  }

  void _clearServerDownDelay() {
    _downSince = null;
    _downMessage = null;
    _downTimer?.cancel();
    _downTimer = null;
  }

  ///  “Server reachable” logic:
  /// - Any HTTP response (200/401/403/404/500) => reachable => online
  /// - Timeout/socket => unreachable => serverDown (after 5s debounce)
  Future<void> _pingServer() async {
    if (state.status == ConnectionStatus.offline) return;

    try {
      final uri = Uri.parse('$baseUrl/');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));

      if (res.statusCode > 0) {
        //  recovered -> cancel pending "down" + set online
        _clearServerDownDelay();
        if (state.status != ConnectionStatus.online) {
          emit(const ConnectionStateModel(status: ConnectionStatus.online));
        }
      }
    } catch (_) {
      //  don’t scream immediately — arm 5s delay first
      _armServerDownDelay('Connecting… (server unreachable)');
    }
  }

  // Optional: let Dio errors force the state (also debounced)
  void setServerDown([String? message]) {
    if (state.status == ConnectionStatus.offline) return;
    _armServerDownDelay(message);
  }

  void setOnline() {
    _clearServerDownDelay();
    emit(const ConnectionStateModel(status: ConnectionStatus.online));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _stopHeartbeat();
    _clearServerDownDelay();
    return super.close();
  }
}