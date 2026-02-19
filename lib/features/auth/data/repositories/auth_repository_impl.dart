import 'package:dio/dio.dart';
import 'package:build4all_manager/core/network/dio_client.dart';
import 'package:build4all_manager/shared/utils/ApiErrorHandler.dart';

import 'package:build4all_manager/core/exceptions/auth_failure.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/auth_token.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/jwt_local_datasource.dart';
import '../models/login_request_dto.dart';
import '../models/login_response_dto.dart';
import '../services/auth_api.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AuthApi api;
  final JwtLocalDataSource jwtStore;

  AuthRepositoryImpl({required this.api, required this.jwtStore});

  @override
  Future<(AuthToken, AppUser)> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final res = await api.login(
        LoginRequestDto(usernameOrEmail: identifier, password: password),
      );

      final dto = LoginResponseDto.fromJson(res.data as Map<String, dynamic>);

      final role = (dto.role).toString().toUpperCase();

      final userOrAdmin = dto.userOrAdmin;
      final user = AppUser(
        id: (userOrAdmin['id'] as num?)?.toInt() ?? 0,
        username: (userOrAdmin['username'] ?? '').toString(),
        firstName: (userOrAdmin['firstName'] ?? '').toString(),
        lastName: (userOrAdmin['lastName'] ?? '').toString(),
        email: (userOrAdmin['email'] ?? '').toString(),
        role: role,
      );

      await jwtStore.save(token: dto.token, role: role);
      DioClient.setToken(dto.token);

      return (AuthToken(dto.token), user);
    }

    // ✅ IMPORTANT: parse {code, error} coming from backend
    on DioException catch (e) {
      final data = e.response?.data;

      if (data is Map) {
        final code = (data['code'] ?? 'AUTH_ERROR').toString();
        final msg = (data['error'] ?? ApiErrorHandler.message(e)).toString();
        throw AuthFailure(code: code, message: msg);
      }

      // no body => network / timeout / etc.
      throw AuthFailure(code: 'NETWORK_ERROR', message: ApiErrorHandler.message(e));
    }

    // ✅ fallback
    catch (e) {
      throw AuthFailure(code: 'AUTH_ERROR', message: ApiErrorHandler.message(e));
    }
  }

  @override
  Future<void> logout() => jwtStore.clear();

  @override
  Future<bool> isLoggedIn() async {
    final (t, _) = await jwtStore.read();
    return t.isNotEmpty;
  }

  @override
  Future<String> getStoredRole() async {
    final (_, r) = await jwtStore.read();
    return r.trim();
  }

  @override
  Future<bool> isSuperAdmin() async {
    final role = (await getStoredRole()).toUpperCase();
    return role == 'SUPER_ADMIN';
  }

  // -------- OWNER REGISTER OTP FLOW --------

  @override
  Future<void> ownerSendOtp({
    required String email,
    required String password,
  }) async {
    try {
      await api.ownerSendOtp(email: email, password: password);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) {
        final code = (data['code'] ?? 'OTP_ERROR').toString();
        final msg = (data['error'] ?? ApiErrorHandler.message(e)).toString();
        throw AuthFailure(code: code, message: msg);
      }
      throw AuthFailure(code: 'NETWORK_ERROR', message: ApiErrorHandler.message(e));
    } catch (e) {
      throw AuthFailure(code: 'OTP_ERROR', message: ApiErrorHandler.message(e));
    }
  }

  @override
  Future<String> ownerVerifyOtp({
    required String email,
    required String password,
    required String code,
  }) async {
    try {
      final res = await api.ownerVerifyOtp(
        email: email,
        password: password,
        code: code,
      );

      return (res.data['registrationToken'] ?? '').toString();
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) {
        final c = (data['code'] ?? 'OTP_ERROR').toString();
        final msg = (data['error'] ?? ApiErrorHandler.message(e)).toString();
        throw AuthFailure(code: c, message: msg);
      }
      throw AuthFailure(code: 'NETWORK_ERROR', message: ApiErrorHandler.message(e));
    } catch (e) {
      throw AuthFailure(code: 'OTP_ERROR', message: ApiErrorHandler.message(e));
    }
  }

  @override
  Future<(AuthToken, AppUser)> ownerCompleteProfile({
    required String registrationToken,
    required String username,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    try {
      final res = await api.ownerCompleteProfile(
        registrationToken: registrationToken,
        username: username,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );

      final token = (res.data['token'] ?? '').toString();
      final admin = (res.data['owner'] ?? res.data['admin'] ?? {}) as Map;

      final user = AppUser(
        id: (admin['id'] as num?)?.toInt() ?? 0,
        username: (admin['username'] ?? '').toString(),
        firstName: (admin['firstName'] ?? '').toString(),
        lastName: (admin['lastName'] ?? '').toString(),
        email: (admin['email'] ?? '').toString(),
        role: 'OWNER',
      );

      await jwtStore.save(token: token, role: 'OWNER');
      DioClient.setToken(token);

      return (AuthToken(token), user);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) {
        final c = (data['code'] ?? 'PROFILE_ERROR').toString();
        final msg = (data['error'] ?? ApiErrorHandler.message(e)).toString();
        throw AuthFailure(code: c, message: msg);
      }
      throw AuthFailure(code: 'NETWORK_ERROR', message: ApiErrorHandler.message(e));
    } catch (e) {
      throw AuthFailure(code: 'PROFILE_ERROR', message: ApiErrorHandler.message(e));
    }
  }
}
