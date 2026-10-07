import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'logger.dart';
import 'network.dart';

const listerTypes = ['Owner', 'Agent', 'Builder'];

/// OTP challenge / verification payloads (99acres-style mobile-first auth).
class OtpChallenge {
  final String phone;
  final String maskedPhone;
  final int expiresInSeconds;
  final String? devCode;
  OtpChallenge.fromJson(Map<String, dynamic> j)
      : phone = j['phone'] as String,
        maskedPhone = j['maskedPhone'] as String,
        expiresInSeconds = (j['expiresInSeconds'] as num).toInt(),
        devCode = j['devCode'] as String?;
}

class OtpVerification {
  final String otpToken;
  final bool isNewUser;
  final String maskedPhone;
  OtpVerification.fromJson(Map<String, dynamic> j)
      : otpToken = j['otpToken'] as String,
        isNewUser = j['isNewUser'] as bool,
        maskedPhone = j['maskedPhone'] as String;
}

class AuthState {
  final String? accessToken;
  final String? refreshToken;
  final String? email;
  final String? userType;
  final String? userId;
  final List<String> roles;
  const AuthState({this.accessToken, this.refreshToken, this.email, this.userType, this.userId, this.roles = const []});
  bool get isLoggedIn => accessToken != null;
  bool get isLister =>
      listerTypes.contains(userType) || roles.any(listerTypes.contains);
  bool get isAgent => userType == 'Agent' || roles.contains('Agent');
  bool get isAdmin => userType == 'Admin' || roles.contains('Admin');
  /// Where to land right after login / registration.
  String get homeRoute => isAgent ? '/agent' : (isLister ? '/owner' : '/home');
}

/// One-line diagnosis for logs: type + status + server code/message.
String _describe(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    String detail = '';
    if (data is Map<String, dynamic> && data['error'] is Map<String, dynamic>) {
      final err = data['error'] as Map<String, dynamic>;
      detail = ' code=${err['code']} msg=${err['message']}';
    }
    return 'Dio[${e.type.name}] status=${e.response?.statusCode}$detail msg=${e.message}';
  }
  return e.toString();
}

class AuthStore extends StateNotifier<AuthState> {
  AuthStore(this._dio) : super(const AuthState()) {
    _load();
  }
  final Dio _dio;
  static const _storage = FlutterSecureStorage();

  Future<void> _load() async {
    final access = await _storage.read(key: 'access');
    if (access == null) return;
    final refresh = await _storage.read(key: 'refresh');
    final email = await _storage.read(key: 'email');
    final userType = await _storage.read(key: 'userType');
    final userId = await _storage.read(key: 'userId');
    final rolesRaw = await _storage.read(key: 'roles');
    List<String> roles = const [];
    if (rolesRaw != null && rolesRaw.isNotEmpty) {
      roles = rolesRaw.split(',').where((r) => r.isNotEmpty).toList();
    }
    state = AuthState(accessToken: access, refreshToken: refresh, email: email, userType: userType, userId: userId, roles: roles);
  }

  Future<String?> get accessToken async => state.accessToken ?? await _storage.read(key: 'access');

  Future<void> login(String email, String password) async {
    AppLog.info('login attempt for ${email.trim()}');
    try {
      final res = await _dio.post('/api/v1/auth/login', data: {'email': email.trim(), 'password': password});
      await _save(res.data as Map<String, dynamic>);
      AppLog.info('login ok');
    } catch (e) {
      AppLog.error('login failed: ${_describe(e)}');
      rethrow;
    }
  }

  Future<void> register(String email, String password, String userType, [String? phone]) async {
    final res = await _dio.post('/api/v1/auth/register', data: {
      'email': email.trim(), 'password': password, 'userType': userType,
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
    });
    await _save(res.data as Map<String, dynamic>);
  }

  /// In-memory verified-number handoff from OTP login to registration.
  ({String phone, String otpToken})? pendingOtp;

  Future<OtpChallenge> requestOtp(String phone) async {
    AppLog.info('otp request for ${phone.trim()}');
    try {
      final res = await _dio.post('/api/v1/auth/otp/request', data: {'phone': phone.trim()});
      return OtpChallenge.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      AppLog.error('otp request failed: ${_describe(e)}');
      rethrow;
    }
  }

  Future<OtpVerification> verifyOtp(String phone, String code) async {
    AppLog.info('otp verify for ${phone.trim()}');
    try {
      final res = await _dio.post('/api/v1/auth/otp/verify',
          data: {'phone': phone.trim(), 'code': code.trim()});
      final v = OtpVerification.fromJson(res.data as Map<String, dynamic>);
      pendingOtp = v.isNewUser ? (phone: phone.trim(), otpToken: v.otpToken) : null;
      return v;
    } catch (e) {
      AppLog.error('otp verify failed: ${_describe(e)}');
      rethrow;
    }
  }

  Future<void> loginWithOtp(String otpToken) async {
    pendingOtp = null;
    final res = await _dio.post('/api/v1/auth/otp/login', data: {'otpToken': otpToken});
    await _save(res.data as Map<String, dynamic>);
  }

  Future<void> registerWithOtp(String phone, String email, String password, String userType) async {
    final token = pendingOtp?.otpToken;
    if (token == null || pendingOtp?.phone != phone.trim()) {
      throw DioException(requestOptions: RequestOptions(path: '/api/v1/auth/otp/register'), message: 'Verification expired. Please verify again.');
    }
    final res = await _dio.post('/api/v1/auth/otp/register', data: {
      'otpToken': token, 'phone': phone.trim(), 'email': email.trim(),
      'password': password, 'userType': userType,
    });
    pendingOtp = null;
    await _save(res.data as Map<String, dynamic>);
  }

  Future<void> _save(Map<String, dynamic> json) async {
    final roles = List<String>.from(json['roles'] ?? []);
    final userId = json['userId']?.toString();
    await _storage.write(key: 'access', value: json['accessToken'] as String);
    await _storage.write(key: 'refresh', value: json['refreshToken'] as String);
    await _storage.write(key: 'email', value: json['email'] as String);
    await _storage.write(key: 'userType', value: json['userType'] as String);
    if (userId != null) await _storage.write(key: 'userId', value: userId);
    await _storage.write(key: 'roles', value: roles.join(','));
    state = AuthState(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      email: json['email'] as String,
      userType: json['userType'] as String,
      userId: userId,
      roles: roles,
    );
  }

  Future<bool> refresh() async {
    final rt = state.refreshToken ?? await _storage.read(key: 'refresh');
    if (rt == null) return false;
    try {
      final res = await _dio.post('/api/v1/auth/refresh', data: {'refreshToken': rt});
      await _save(res.data as Map<String, dynamic>);
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  Future<void> setRole(String newUserType) async {
    await _storage.write(key: 'userType', value: newUserType);
    state = AuthState(
      accessToken: state.accessToken,
      refreshToken: state.refreshToken,
      email: state.email,
      userType: newUserType,
      roles: state.roles,
    );
  }

  Future<void> logout() async {
    final rt = state.refreshToken ?? await _storage.read(key: 'refresh');
    if (rt != null) {
      try {
        await _dio.post('/api/v1/auth/logout', data: {'refreshToken': rt});
      } catch (_) { /* best-effort */ }
    }
    await _storage.deleteAll();
    state = const AuthState();
  }
}

final authStoreProvider = StateNotifierProvider<AuthStore, AuthState>((ref) {
  return AuthStore(ref.watch(dioProvider));
});
