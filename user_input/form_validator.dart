import 'package:flutter/material.dart';

/// A utility class to validate form inputs in Flutter apps.
/// 
/// This helper provides common validation functions for various input types
/// like email, password, phone number, etc.
class FormValidator {
  /// Validate an email address
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    // Regular expression for email validation
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    
    return null;
  }
  
  /// Validate a password
  static String? validatePassword(
    String? value, {
    int minLength = 8,
    bool requireUppercase = true,
    bool requireLowercase = true,
    bool requireDigits = true,
    bool requireSpecialChars = true,
  }) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters long';
    }
    
    if (requireUppercase && !value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (requireLowercase && !value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (requireDigits && !value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    if (requireSpecialChars && !value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    
    return null;
  }
  
  /// Validate password confirmation
  static String? validatePasswordConfirmation(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }
  
  /// Validate a phone number
  static String? validatePhone(
    String? value, {
    bool allowEmpty = false,
    String? countryCode,
  }) {
    if (value == null || value.isEmpty) {
      return allowEmpty ? null : 'Phone number is required';
    }
    
    // Remove spaces, dashes, and parentheses
    final cleanedValue = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check if the phone number contains only digits
    if (!cleanedValue.contains(RegExp(r'^[0-9+]+$'))) {
      return 'Phone number can only contain digits, +, spaces, and dashes';
    }
    
    // Basic length check (this can be improved with country-specific validation)
    if (cleanedValue.length < 8 || cleanedValue.length > 15) {
      return 'Enter a valid phone number';
    }
    
    return null;
  }
  
  /// Validate a name
  static String? validateName(
    String? value, {
    bool allowEmpty = false,
    int minLength = 2,
    int maxLength = 50,
  }) {
    if (value == null || value.isEmpty) {
      return allowEmpty ? null : 'Name is required';
    }
    
    if (value.length < minLength) {
      return 'Name must be at least $minLength characters long';
    }
    
    if (value.length > maxLength) {
      return 'Name cannot be longer than $maxLength characters';
    }
    
    // Check if the name contains only letters, spaces, hyphens, and apostrophes
    if (!value.contains(RegExp(r"^[a-zA-Z\s\-']+$"))) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null;
  }
  
  /// Validate a username
  static String? validateUsername(
    String? value, {
    int minLength = 3,
    int maxLength = 20,
    bool allowSpecialChars = false,
  }) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    
    if (value.length < minLength) {
      return 'Username must be at least $minLength characters long';
    }
    
    if (value.length > maxLength) {
      return 'Username cannot be longer than $maxLength characters';
    }
    
    // Check if the username contains only allowed characters
    final pattern = allowSpecialChars
        ? r'^[a-zA-Z0-9_\-\.]+$'
        : r'^[a-zA-Z0-9_]+$';
    
    if (!value.contains(RegExp(pattern))) {
      return allowSpecialChars
          ? 'Username can only contain letters, numbers, underscores, hyphens, and periods'
          : 'Username can only contain letters, numbers, and underscores';
    }
    
    return null;
  }
  
  /// Validate a URL
  static String? validateUrl(
    String? value, {
    bool allowEmpty = false,
    bool requireHttps = false,
  }) {
    if (value == null || value.isEmpty) {
      return allowEmpty ? null : 'URL is required';
    }
    
    // Regular expression for URL validation
    final urlRegex = requireHttps
        ? RegExp(r'^https:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$')
        : RegExp(r'^(http|https):\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$');
    
    if (!urlRegex.hasMatch(value)) {
      return requireHttps
          ? 'Enter a valid HTTPS URL'
          : 'Enter a valid URL';
    }
    
    return null;
  }
  
  /// Validate a credit card number
  static String? validateCreditCard(String? value) {
    if (value == null || value.isEmpty) {
      return 'Credit card number is required';
    }
    
    // Remove spaces and dashes
    final cleanedValue = value.replaceAll(RegExp(r'[\s\-]'), '');
    
    // Check if the credit card number contains only digits
    if (!cleanedValue.contains(RegExp(r'^[0-9]+$'))) {
      return 'Credit card number can only contain digits';
    }
    
    // Check length (most credit cards are 13-19 digits)
    if (cleanedValue.length < 13 || cleanedValue.length > 19) {
      return 'Enter a valid credit card number';
    }
    
    // Luhn algorithm (checksum)
    int sum = 0;
    bool alternate = false;
    for (int i = cleanedValue.length - 1; i >= 0; i--) {
      int n = int.parse(cleanedValue.substring(i, i + 1));
      if (alternate) {
        n *= 2;
        if (n > 9) {
          n = (n % 10) + 1;
        }
      }
      sum += n;
      alternate = !alternate;
    }
    
    if (sum % 10 != 0) {
      return 'Enter a valid credit card number';
    }
    
    return null;
  }
  
  /// Validate a date
  static String? validateDate(
    String? value, {
    bool allowEmpty = false,
    DateTime? minDate,
    DateTime? maxDate,
    String format = 'yyyy-MM-dd',
  }) {
    if (value == null || value.isEmpty) {
      return allowEmpty ? null : 'Date is required';
    }
    
    // Try to parse the date
    DateTime? date;
    try {
      // This is a simple implementation. In a real app, you might want to use a
      // more sophisticated date parsing library that supports different formats.
      date = DateTime.parse(value);
    } catch (e) {
      return 'Enter a valid date in $format format';
    }
    
    if (minDate != null && date.isBefore(minDate)) {
      return 'Date cannot be before ${_formatDate(minDate, format)}';
    }
    
    if (maxDate != null && date.isAfter(maxDate)) {
      return 'Date cannot be after ${_formatDate(maxDate, format)}';
    }
    
    return null;
  }
  
  /// Format a date as a string
  static String _formatDate(DateTime date, String format) {
    // This is a simple implementation. In a real app, you might want to use a
    // more sophisticated date formatting library.
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  /// Validate a numeric value
  static String? validateNumeric(
    String? value, {
    bool allowEmpty = false,
    double? min,
    double? max,
    bool allowDecimal = true,
  }) {
    if (value == null || value.isEmpty) {
      return allowEmpty ? null : 'Value is required';
    }
    
    // Check if the value is numeric
    final numericRegex = allowDecimal
        ? RegExp(r'^-?\d*\.?\d+$')
        : RegExp(r'^-?\d+$');
    
    if (!numericRegex.hasMatch(value)) {
      return allowDecimal
          ? 'Enter a valid number'
          : 'Enter a valid integer';
    }
    
    // Parse the value
    final numericValue = double.parse(value);
    
    if (min != null && numericValue < min) {
      return 'Value cannot be less than $min';
    }
    
    if (max != null && numericValue > max) {
      return 'Value cannot be greater than $max';
    }
    
    return null;
  }
  
  /// Validate a postal code
  static String? validatePostalCode(
    String? value, {
    bool allowEmpty = false,
    String? countryCode,
  }) {
    if (value == null || value.isEmpty) {
      return allowEmpty ? null : 'Postal code is required';
    }
    
    // Different countries have different postal code formats
    // This is a simplified implementation for a few countries
    if (countryCode != null) {
      switch (countryCode.toUpperCase()) {
        case 'US':
          // US ZIP code: 5 digits or 5+4 digits
          final usRegex = RegExp(r'^\d{5}(-\d{4})?$');
          if (!usRegex.hasMatch(value)) {
            return 'Enter a valid US ZIP code';
          }
          break;
        case 'CA':
          // Canadian postal code: A1A 1A1
          final caRegex = RegExp(r'^[A-Za-z]\d[A-Za-z] \d[A-Za-z]\d$');
          if (!caRegex.hasMatch(value)) {
            return 'Enter a valid Canadian postal code';
          }
          break;
        case 'UK':
          // UK postal code: Various formats
          final ukRegex = RegExp(r'^[A-Za-z]{1,2}\d[A-Za-z\d]? \d[A-Za-z]{2}$');
          if (!ukRegex.hasMatch(value)) {
            return 'Enter a valid UK postal code';
          }
          break;
        default:
          // Generic validation: allow alphanumeric characters and spaces
          final genericRegex = RegExp(r'^[A-Za-z0-9 -]+$');
          if (!genericRegex.hasMatch(value)) {
            return 'Enter a valid postal code';
          }
      }
    } else {
      // Generic validation: allow alphanumeric characters and spaces
      final genericRegex = RegExp(r'^[A-Za-z0-9 -]+$');
      if (!genericRegex.hasMatch(value)) {
        return 'Enter a valid postal code';
      }
    }
    
    return null;
  }
  
  /// Validate required field
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null
          ? '$fieldName is required'
          : 'This field is required';
    }
    return null;
  }
  
  /// Validate minimum length
  static String? validateMinLength(String? value, int minLength, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return null; // Let validateRequired handle this
    }
    
    if (value.length < minLength) {
      return fieldName != null
          ? '$fieldName must be at least $minLength characters long'
          : 'Must be at least $minLength characters long';
    }
    
    return null;
  }
  
  /// Validate maximum length
  static String? validateMaxLength(String? value, int maxLength, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return null; // Let validateRequired handle this
    }
    
    if (value.length > maxLength) {
      return fieldName != null
          ? '$fieldName cannot be longer than $maxLength characters'
          : 'Cannot be longer than $maxLength characters';
    }
    
    return null;
  }
  
  /// Combine multiple validators
  static String? validateMultiple(String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) {
        return error;
      }
    }
    
    return null;
  }
}

/// A form field validator that combines multiple validators
class MultiValidator {
  final List<String? Function(String?)> validators;
  
  MultiValidator(this.validators);
  
  String? call(String? value) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) {
        return error;
      }
    }
    
    return null;
  }
}

/// Example usage:
///
/// ```dart
/// // Basic usage
/// TextFormField(
///   decoration: InputDecoration(labelText: 'Email'),
///   validator: FormValidator.validateEmail,
/// );
///
/// // Password with custom requirements
/// TextFormField(
///   decoration: InputDecoration(labelText: 'Password'),
///   obscureText: true,
///   validator: (value) => FormValidator.validatePassword(
///     value,
///     minLength: 10,
///     requireSpecialChars: false,
///   ),
/// );
///
/// // Combining validators
/// TextFormField(
///   decoration: InputDecoration(labelText: 'Username'),
///   validator: (value) => FormValidator.validateMultiple(
///     value,
///     [
///       FormValidator.validateRequired,
///       (value) => FormValidator.validateMinLength(value, 3),
///       (value) => FormValidator.validateMaxLength(value, 20),
///       (value) => FormValidator.validateUsername(value),
///     ],
///   ),
/// );
///
/// // Using MultiValidator
/// TextFormField(
///   decoration: InputDecoration(labelText: 'Username'),
///   validator: MultiValidator([
///     (value) => FormValidator.validateRequired(value, fieldName: 'Username'),
///     (value) => FormValidator.validateMinLength(value, 3),
///     (value) => FormValidator.validateMaxLength(value, 20),
///     FormValidator.validateUsername,
///   ]),
/// );
/// ```
