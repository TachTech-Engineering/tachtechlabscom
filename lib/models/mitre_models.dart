import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum CoverageLevel { loading, none, low, medium, high, blocked }

extension CoverageLevelExtension on CoverageLevel {
  String get name {
    switch (this) {
      case CoverageLevel.loading: return 'Loading';
      case CoverageLevel.none: return 'No Detection';
      case CoverageLevel.low: return 'Inactive';
      case CoverageLevel.medium: return 'Partial';
      case CoverageLevel.high: return 'Covered';
      case CoverageLevel.blocked: return 'N/A';
    }
  }

  Color get color {
    switch (this) {
      case CoverageLevel.loading: return AppTheme.coverageLoading;  // Grey
      case CoverageLevel.none: return AppTheme.coverageNone;        // Red
      case CoverageLevel.low: return AppTheme.coverageLow;          // Orange
      case CoverageLevel.medium: return AppTheme.coverageMedium;    // Yellow
      case CoverageLevel.high: return AppTheme.coverageHigh;        // Green
      case CoverageLevel.blocked: return AppTheme.coverageBlocked;  // Grey
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
