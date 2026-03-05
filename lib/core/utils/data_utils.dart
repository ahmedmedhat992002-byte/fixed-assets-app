import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralized utility for safe data extraction from Firestore/dynamic maps.
/// Prevents [TypeError] by checking types before casting.
class DataUtils {
  const DataUtils._();

  static String asString(dynamic value, [String defaultValue = '']) {
    if (value is String) return value;
    if (value == null) return defaultValue;
    return value.toString();
  }

  static double asDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static int asInt(dynamic value, [int defaultValue = 0]) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  static String? asStringNullable(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static double? asDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? asIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool asBool(dynamic value, [bool defaultValue = false]) {
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    return defaultValue;
  }

  static Timestamp? asTimestamp(dynamic value) {
    if (value is Timestamp) return value;
    if (value is int) return Timestamp.fromMillisecondsSinceEpoch(value);
    // Legacy support for ISO strings if needed
    if (value is String) {
      final dt = DateTime.tryParse(value);
      if (dt != null) return Timestamp.fromDate(dt);
    }
    return null;
  }

  static DateTime asDateTime(dynamic value, [DateTime? defaultValue]) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      return DateTime.tryParse(value) ?? defaultValue ?? DateTime.now();
    }
    return defaultValue ?? DateTime.now();
  }

  static String formatCurrency(double value) {
    if (value == 0) return '0';
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)} m';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)} k';
    }
    return value.toStringAsFixed(0);
  }
}
