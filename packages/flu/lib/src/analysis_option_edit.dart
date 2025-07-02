import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

// TODO(albin): extract to a package

/// Add `custom_lint` to the `analyzer` section in the `analysis_options.yaml`
/// ```yaml
/// analyzer:
///   plugins:
///     - custom_lint
/// ```
String addCustomLint(String analysisOptionsSource) {
  final editor = YamlEditor(analysisOptionsSource);
  YamlMap yaml;
  try {
    yaml = loadYaml(analysisOptionsSource) as YamlMap;
    // ignore: avoid_catches_without_on_clauses
  } catch (e) {
    yaml = YamlMap();
  }

  if (yaml.isEmpty) {
    editor.update([], {
      'analyzer': {
        'plugins': ['custom_lint'],
      },
    });
  } else if (!yaml.containsKey('analyzer') || yaml['analyzer'] == null) {
    editor.update(
      ['analyzer'],
      {
        'plugins': ['custom_lint'],
      },
    );
  } else if (!(yaml['analyzer'] as YamlMap).containsKey('plugins')) {
    editor.update(['analyzer', 'plugins'], ['custom_lint']);
  } else {
    final list = (yaml['analyzer'] as YamlMap)['plugins'];
    if (list case YamlList()) {
      if (!list.contains('custom_lint')) {
        editor.appendToList(['analyzer', 'plugins'], 'custom_lint');
      }
    } else {
      editor.update(['analyzer', 'plugins'], ['custom_lint']);
    }
  }
  return editor.toString();
}
