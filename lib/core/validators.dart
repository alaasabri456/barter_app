class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    const String emailPattern =
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

    if (!RegExp(emailPattern).hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }

    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters long';
    }

    if (value.length > 50) {
      return 'Name must be less than 50 characters';
    }

    return null;
  }

  // Product title validation
  static String? validateProductTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Product title is required';
    }

    if (value.length < 3) {
      return 'Title must be at least 3 characters long';
    }

    if (value.length > 100) {
      return 'Title must be less than 100 characters';
    }

    return null;
  }

  // Product description validation
  static String? validateProductDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Product description is required';
    }

    if (value.length < 10) {
      return 'Description must be at least 10 characters long';
    }

    if (value.length > 500) {
      return 'Description must be less than 500 characters';
    }

    return null;
  }

  // Product category validation
  static String? validateProductCategory(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a category';
    }

    return null;
  }

  // Product condition validation
  static String? validateProductCondition(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select product condition';
    }

    return null;
  }

  // Phone number validation (required, E.164 format)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    const String phonePattern = r'^\+[1-9]\d{6,14}$';

    if (!RegExp(phonePattern).hasMatch(value.trim())) {
      return 'Enter a valid phone number with country code (e.g. +201012345678)';
    }

    return null;
  }

  // General text validation with custom length
  static String? validateText(String? value, {
    required String fieldName,
    int minLength = 1,
    int maxLength = 255,
    bool required = true,
  }) {
    if (value == null || value.isEmpty) {
      if (required) {
        return '$fieldName is required';
      }
      return null;
    }

    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters long';
    }

    if (value.length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }

    return null;
  }

  // URL validation (for product images)
  static String? validateUrl(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      if (required) {
        return 'URL is required';
      }
      return null;
    }

    try {
      Uri.parse(value);
      return null;
    } catch (e) {
      return 'Please enter a valid URL';
    }
  }
}