import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/mitre_models.dart';

class MatrixService {
  /// Loads the pre-processed ATT&CK JSON from assets and parses it into models
  Future<List<Tactic>> loadMatrix() async {
    final String response = await rootBundle.loadString('assets/data/attack_matrix.json');
    final data = await json.decode(response);
    final List<dynamic> tacticsJson = data['tactics'];

    return tacticsJson.map((tJson) {
      return Tactic(
        id: tJson['id'],
        name: tJson['name'],
        techniques: (tJson['techniques'] as List).map((techJson) {
          return Technique(
            id: techJson['id'],
            name: techJson['name'],
            coverage: CoverageLevel.none, 
            subTechniques: (techJson['subTechniques'] as List).map((subJson) {
              return SubTechnique(
                id: subJson['id'],
                name: subJson['name'],
                coverage: CoverageLevel.none,
              );
            }).toList(),
          );
        }).toList(),
      );
    }).toList();
  }
}
