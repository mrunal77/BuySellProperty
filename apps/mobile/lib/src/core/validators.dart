import 'package:dio/dio.dart';

/// Shared form validators (mirror backend rules).
String? emailValidator(String? v) {
  if (v == null || v.trim().isEmpty) return 'Enter your email address.';
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(v.trim())) {
    return 'Enter a valid email address.';
  }
  return null;
}

String? phoneValidator(String? v) {
  if (v == null || v.trim().isEmpty) return null; // optional
  if (!RegExp(r'^[+0-9][0-9\s\-]{5,17}$').hasMatch(v.trim())) {
    return 'Enter a valid phone number.';
  }
  return null;
}

/// Strict mobile check mirroring backend PhoneNumber.Normalize.
String normalizeMobile(String v) => v.trim().replaceAll(RegExp(r'[\s\-()]'), '');

bool isValidMobile(String v) => RegExp(r'^\+?[1-9]\d{7,14}$').hasMatch(normalizeMobile(v));

String? mobileValidator(String? v) {
  if (v == null || v.trim().isEmpty) return 'Enter your mobile number.';
  if (!isValidMobile(v)) return 'Enter a valid 8–15 digit mobile number.';
  return null;
}

String? requiredValidator(String? v, [String what = 'This field']) {
  if (v == null || v.trim().isEmpty) return '$what is required.';
  return null;
}

int passwordScore(String pw) {
  var s = 0;
  if (pw.length >= 8) s++;
  if (RegExp(r'[a-z]').hasMatch(pw) && RegExp(r'[A-Z]').hasMatch(pw)) s++;
  if (RegExp(r'\d').hasMatch(pw)) s++;
  if (RegExp(r'[^a-zA-Z0-9]').hasMatch(pw)) s++;
  return s;
}

String passwordLabel(int score) => ['Too weak', 'Weak', 'Okay', 'Good', 'Strong'][score];

String? passwordValidator(String? v) {
  if (v == null || v.isEmpty) return 'Enter a password.';
  if (passwordScore(v) < 2) {
    return 'Use 8+ characters with upper/lower case, a number and a symbol.';
  }
  return null;
}

/// Friendly message for API failures. Reads the backend error envelope
/// ({ error: { code, message } }) off the Dio response — e.toString() alone
/// never contains the body, so string-matching it hides the real error.
String apiErrorMessage(Object e, String fallback) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final err = data['error'];
      if (err is Map<String, dynamic>) {
        final code = err['code'] as String?;
        final msg = (err['message'] as String?)?.trim();
        switch (code) {
          case 'auth.email_taken':
            return 'This email is already registered. Try logging in.';
          case 'auth.phone_taken':
            return 'This mobile number is already registered. Try OTP login.';
          case 'auth.invalid_credentials':
            return 'Incorrect email or password.';
          case 'auth.invalid_otp':
            return msg?.isNotEmpty == true ? msg! : 'Invalid or expired code.';
          case 'auth.invalid_phone':
            return 'Enter a valid mobile number.';
        }
        if (msg?.isNotEmpty == true) return msg!;
      }
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return 'The server is taking too long to respond. Check your connection and try again.';
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return 'Cannot reach the server. Check your connection and try again.';
      case DioExceptionType.badCertificate:
        return 'Connection is not secure. Try again on a trusted network.';
      case DioExceptionType.cancel:
        return fallback;
      case DioExceptionType.badResponse:
        break; // envelope handled above; fall through to generic below
    }
  }
  final s = e.toString();
  if (s.contains('SocketException') || s.contains('Connection refused') || s.contains('Network is unreachable')) {
    return 'Cannot reach the server. Check your connection and try again.';
  }
  return fallback;
}

String formatINR(num n) {
  if (n >= 1e7) return '₹${(n / 1e7).toStringAsFixed(n % 1e7 == 0 ? 0 : 2)} Cr';
  if (n >= 1e5) return '₹${(n / 1e5).toStringAsFixed(n % 1e5 == 0 ? 0 : 2)} L';
  return '₹$n';
}
