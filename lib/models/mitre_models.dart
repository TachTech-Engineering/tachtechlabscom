import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum CoverageLevel { none, low, medium, high, blocked }

extension CoverageLevelExtension on CoverageLevel {
  String get name {
    switch (this) {
      case CoverageLevel.none: return 'None';
      case CoverageLevel.low: return 'Low';
      case CoverageLevel.medium: return 'Medium';
      case CoverageLevel.high: return 'High';
      case CoverageLevel.blocked: return 'Blocked';
    }
  }

  Color get color {
    switch (this) {
      case CoverageLevel.none: return AppTheme.coverageNone;
      case CoverageLevel.low: return AppTheme.coverageLow;
      case CoverageLevel.medium: return AppTheme.coverageMedium;
      case CoverageLevel.high: return AppTheme.coverageHigh;
      case CoverageLevel.blocked: return AppTheme.coverageBlocked;
    }
  }
}

class SubTechnique {
  final String id;
  final String name;
  final CoverageLevel coverage;

  SubTechnique({
    required this.id,
    required this.name,
    this.coverage = CoverageLevel.none,
  });
}

class Technique {
  final String id;
  final String name;
  final CoverageLevel coverage;
  final List<SubTechnique> subTechniques;

  Technique({
    required this.id,
    required this.name,
    this.coverage = CoverageLevel.none,
    this.subTechniques = const [],
  });
}

class Tactic {
  final String id;
  final String name;
  final List<Technique> techniques;

  Tactic({
    required this.id,
    required this.name,
    required this.techniques,
  });
}
