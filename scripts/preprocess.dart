// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

void main() async {
  print('Loading STIX data...');
  final file = File('scripts/enterprise-attack.json');
  final String contents = await file.readAsString();
  final Map<String, dynamic> data = jsonDecode(contents);
  final List<dynamic> objects = data['objects'];

  print('Parsing STIX objects...');

  final tactics = <String, Map<String, dynamic>>{};
  final techniques = <String, Map<String, dynamic>>{};
  final subTechniques = <String, Map<String, dynamic>>{};
  final relSubToParent = <String, String>{}; // child_stix_id -> parent_stix_id
  
  // Also collect tactics in order from x-mitre-matrix if present
  final List<String> tacticOrder = [];

  for (final obj in objects) {
    if (obj['type'] == 'x-mitre-tactic') {
      final extRefs = obj['external_references'] as List?;
      final attackRef = extRefs?.firstWhere((ref) => ref['source_name'] == 'mitre-attack', orElse: () => null);
      if (attackRef != null) {
        tactics[obj['x_mitre_shortname']] = {
          'id': attackRef['external_id'],
          'name': obj['name'],
          'stix_id': obj['id'],
        };
      }
    } else if (obj['type'] == 'x-mitre-matrix') {
      final refs = obj['tactic_refs'] as List?;
      if (refs != null) {
        tacticOrder.addAll(refs.cast<String>());
      }
    } else if (obj['type'] == 'attack-pattern') {
      final isDeprecated = obj['x_mitre_deprecated'] == true;
      final isRevoked = obj['revoked'] == true;
      if (isDeprecated || isRevoked) continue;

      final isSub = obj['x_mitre_is_subtechnique'] == true;
      final extRefs = obj['external_references'] as List?;
      final attackRef = extRefs?.firstWhere((ref) => ref['source_name'] == 'mitre-attack', orElse: () => null);
      if (attackRef != null) {
        final parsedObj = {
          'id': attackRef['external_id'],
          'name': obj['name'],
          'stix_id': obj['id'],
          'kill_chain_phases': obj['kill_chain_phases'],
        };
        if (isSub) {
          subTechniques[obj['id']] = parsedObj;
        } else {
          techniques[obj['id']] = parsedObj;
        }
      }
    } else if (obj['type'] == 'relationship') {
      if (obj['relationship_type'] == 'subtechnique-of') {
        relSubToParent[obj['source_ref']] = obj['target_ref'];
      }
    }
  }

  // Build the tree
  print('Building tactic -> technique -> sub-technique tree...');

  final resultTactics = <Map<String, dynamic>>[];

  // Reorder tactics based on tacticOrder
  // tacticOrder contains STIX IDs of tactics.
  final sortedTactics = <Map<String, dynamic>>[];
  for (final stixId in tacticOrder) {
    final t = tactics.values.firstWhere((element) => element['stix_id'] == stixId, orElse: () => <String, dynamic>{});
    if (t.isNotEmpty) {
      sortedTactics.add(t);
    }
  }

  // Fallback to all tactics if x-mitre-matrix wasn't found or incomplete
  for (final t in tactics.values) {
    if (!sortedTactics.any((element) => element['stix_id'] == t['stix_id'])) {
      sortedTactics.add(t);
    }
  }

  for (final t in sortedTactics) {
    final shortname = tactics.keys.firstWhere((k) => tactics[k]!['stix_id'] == t['stix_id']);
    
    // Find techniques for this tactic
    final tacticTechniques = <Map<String, dynamic>>[];
    for (final tech in techniques.values) {
      final phases = tech['kill_chain_phases'] as List?;
      if (phases != null && phases.any((p) => p['phase_name'] == shortname)) {
        // Find sub-techniques
        final techSubTechniques = <Map<String, dynamic>>[];
        for (final subEntry in subTechniques.entries) {
          final parentId = relSubToParent[subEntry.key];
          if (parentId == tech['stix_id']) {
            techSubTechniques.add({
              'id': subEntry.value['id'],
              'name': subEntry.value['name'],
            });
          }
        }
        
        // Sort sub-techniques by ID
        techSubTechniques.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));

        tacticTechniques.add({
          'id': tech['id'],
          'name': tech['name'],
          'subTechniques': techSubTechniques,
        });
      }
    }

    // Sort techniques by ID
    tacticTechniques.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));

    resultTactics.add({
      'id': t['id'],
      'name': t['name'],
      'techniques': tacticTechniques,
    });
  }

  final outputData = {
    'tactics': resultTactics,
  };

  print('Writing output to lib/data/attck_data.json...');
  final outDir = Directory('lib/data');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }
  final outFile = File('lib/data/attck_data.json');
  await outFile.writeAsString(jsonEncode(outputData));
  print('Done!');
}
