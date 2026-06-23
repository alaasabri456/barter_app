import 'package:firebase_auth/firebase_auth.dart';

/// Centralized Error Handler to map Firebase, Firestore, and generic exceptions
/// to user-friendly messages.
class ErrorHandler {
  /// Converts any exception/error object into a user-friendly error message.
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return _handleAuthError(error);
    } else if (error is FirebaseException) {
      return _handleFirestoreError(error);
    } else if (error is Exception) {
      // Strips "Exception: " prefix for cleaner presentation
      final msg = error.toString();
      if (msg.startsWith('Exception: ')) {
        return msg.substring(11);
      }
      return msg;
    } else if (error is String) {
      return error;
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Maps Firebase Auth error codes to descriptive English messages.
  static String _handleAuthError(FirebaseAuthException error) {
    switch (error.code) {
      // Login/Authentication errors
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      
      // Registration errors
      case 'weak-password':
        return 'The password is too weak. Please use a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'operation-not-allowed':
        return 'Sign-in method not allowed.';

      // Phone verification errors
      case 'invalid-phone-number':
        return 'The phone number entered is invalid. Please check the format.';
      case 'quota-exceeded':
        return 'SMS quota has been exceeded for this project. Please try again tomorrow.';
      case 'invalid-verification-code':
        return 'The SMS verification code you entered is incorrect. Please try again.';
      case 'session-expired':
        return 'The verification code has expired. Please request a new code.';
      case 'credential-already-in-use':
      case 'provider-already-linked':
        return 'This credential/phone number is already linked with another account.';
      
      default:
        return error.message ?? 'Authentication failed: ${error.code}';
    }
  }

  /// Maps Cloud Firestore error codes to user-friendly messages.
  static String _handleFirestoreError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to execute this operation.';
      case 'unavailable':
        return 'The database service is temporarily unavailable. Please try again later.';
      case 'not-found':
        return 'The requested database document was not found.';
      case 'already-exists':
        return 'The document you are trying to create already exists.';
      case 'deadline-exceeded':
        return 'The database operation timed out. Please check your connection.';
      case 'cancelled':
        return 'The operation was cancelled.';
      default:
        return error.message ?? 'Database operation failed: ${error.code}';
    }
  }
}
