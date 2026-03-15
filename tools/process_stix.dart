import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  print('Starting STIX pre-processing pipeline...');

  String contents;
  if (args.isNotEmpty) {
    print('Reading from local file: ${args[0]}');
    final file = File(args[0]);
    contents = await file.readAsString();
  } else {
    print('Downloading enterprise-attack.json from MITRE GitHub...');
    final url = Uri.parse('https://raw.githubusercontent.com/mitre/cti/master/enterprise-attack/enterprise-attack.json');
    final request = await HttpClient().getUrl(url);
    final response = await request.close();
    contents = await response.transform(utf8.decoder).join();
  }

  final Map<String, dynamic> data = jsonDecode(contents);
  final List<dynamic> objects = data['objects'];

  print('Parsing STIX objects...');

  final tactics = <String, Map<String, dynamic>>{};
  final techniques = <String, Map<String, dynamic>>{};
  final subTechniques = <String, Map<String, dynamic>>{};
  final relSubToParent = <String, String>{}; // child_stix_id -> parent_stix_id
  
  // Extract x-mitre-matrix tactic_refs for column ordering
  final List<String> tacticOrder = [];

  for (final obj in objects) {
    final type = obj['type'];
    if (type == 'x-mitre-tactic') {
      final extRefs = obj['external_references'] as List?;
      final attackRef = extRefs?.firstWhere((ref) => ref['source_name'] == 'mitre-attack', orElse: () => null);
      if (attackRef != null) {
        tactics[obj['x_mitre_shortname']] = {
          'id': attackRef['external_id'],
          'name': obj['name'],
          'stix_id': obj['id'],
        };
      }
    } else if (type == 'x-mitre-matrix') {
      final refs = obj['tactic_refs'] as List?;
      if (refs != null) {
        tacticOrder.addAll(refs.cast<String>());
      }
    } else if (type == 'attack-pattern') {
      // Filter out revoked and deprecated objects
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
    } else if (type == 'relationship') {
      // subtechnique-of relationships
      if (obj['relationship_type'] == 'subtechnique-of') {
        relSubToParent[obj['source_ref']] = obj['target_ref'];
      }
    }
  }

  print('Building tactic -> technique -> sub-technique tree...');

  final resultTactics = <Map<String, dynamic>>[];
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
    
    final tacticTechniques = <Map<String, dynamic>>[];
    for (final techEntry in techniques.entries) {
      final tech = techEntry.value;
      final phases = tech['kill_chain_phases'] as List?;
      if (phases != null && phases.any((p) => p['phase_name'] == shortname)) {
        
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
        
        techSubTechniques.sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));

        tacticTechniques.add({
          'id': tech['id'],
          'name': tech['name'],
          'subTechniques': techSubTechniques,
        });
      }
    }

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

  final outDir = Directory('assets/data');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }
  
  final outPath = 'assets/data/attack_matrix.json';
  print('Writing output to $outPath...');
  final outFile = File(outPath);
  await outFile.writeAsString(jsonEncode(outputData));
  
  int techniqueCount = 0;
  for (var tactic in resultTactics) {
    techniqueCount += (tactic['techniques'] as List).length;
  }
  
  print('Done!');
  print('Result: ${resultTactics.length} tactics, $techniqueCount parent techniques extracted.');
}
