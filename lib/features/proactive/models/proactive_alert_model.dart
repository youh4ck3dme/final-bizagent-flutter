import 'package:flutter/material.dart';

/// Type of proactive alert from "Proaktívny AI účtovník".
enum ProactiveAlertType {
  /// Prediktívne upozornenie (faktúra, zostatok, rezerva).
  predictive,

  /// Daňový stratég (chýbajúce výdavky, optimalizácia).
  taxStrategist,

  /// Anomália (nočný strážca – podozrivá platba, duplicita).
  anomaly,

  /// Benchmarking (porovnanie s podobnými firmami).
  benchmarking,
}

class ProactiveAlert {
  final String id;
  final ProactiveAlertType type;
  final String title;
  final String body;
  final String? actionLabel;
  final String? actionRoute;
  final DateTime? dueDate;
  final double? amount;
  final double? secondaryAmount;
  final IconData icon;
  final Color color;
  final DateTime createdAt;

  const ProactiveAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.actionLabel,
    this.actionRoute,
    this.dueDate,
    this.amount,
    this.secondaryAmount,
    required this.icon,
    required this.color,
    required this.createdAt,
  });

  String get typeLabel {
    switch (type) {
      case ProactiveAlertType.predictive:
        return 'Prediktívny alert';
      case ProactiveAlertType.taxStrategist:
        return 'Daňový stratég';
      case ProactiveAlertType.anomaly:
        return 'Nočný strážca';
      case ProactiveAlertType.benchmarking:
        return 'Benchmarking';
    }
  }
}
