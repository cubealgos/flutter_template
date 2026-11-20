import 'package:test/test.dart';
import 'package:tooling/src/package_rename_config_yaml.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('renders every platform key package_rename expects', () {
    const fields = PackageRenameFields(
      displayName: 'Acme Notes',
      applicationId: 'de.example.acme_notes',
      exeName: 'acme_notes',
      organization: 'de.example',
      oldApplicationId: 'com.example.app',
      androidLang: 'kotlin',
      macCopyright: 'Copyright © 2026 de.example. All rights reserved.',
      windowsCopyright: 'Copyright (C) 2026 de.example. All rights reserved.',
    );

    final yaml = buildPackageRenameConfigYaml(fields);
    final doc = loadYaml(yaml) as YamlMap;
    final config = doc['package_rename_config'] as YamlMap;

    final android = config['android'] as YamlMap;
    expect(android['app_name'], 'Acme Notes');
    expect(android['package_name'], 'de.example.acme_notes');
    expect(android['override_old_package'], 'com.example.app');
    expect(android['lang'], 'kotlin');

    final ios = config['ios'] as YamlMap;
    expect(ios['app_name'], 'Acme Notes');
    expect(ios['package_name'], 'de.example.acme_notes');

    final macos = config['macos'] as YamlMap;
    expect(macos['package_name'], 'de.example.acme_notes');
    expect(
      macos['copyright_notice'],
      'Copyright © 2026 de.example. All rights reserved.',
    );

    final linux = config['linux'] as YamlMap;
    expect(linux['package_name'], 'de.example.acme_notes');
    expect(linux['exe_name'], 'acme_notes');

    final windows = config['windows'] as YamlMap;
    expect(windows['organization'], 'de.example');
    expect(windows['exe_name'], 'acme_notes');
    expect(
      windows['copyright_notice'],
      'Copyright (C) 2026 de.example. All rights reserved.',
    );

    final web = config['web'] as YamlMap;
    expect(web['app_name'], 'Acme Notes');
    expect(web['short_app_name'], 'Acme Notes');
  });

  test('single quotes a display name containing a single quote', () {
    const fields = PackageRenameFields(
      displayName: "Kev's App",
      applicationId: 'de.example.app',
      exeName: 'app',
      organization: 'de.example',
      oldApplicationId: 'com.example.app',
      androidLang: 'kotlin',
      macCopyright: '',
      windowsCopyright: '',
    );

    final yaml = buildPackageRenameConfigYaml(fields);
    final doc = loadYaml(yaml) as YamlMap;
    final config = doc['package_rename_config'] as YamlMap;

    expect((config['android'] as YamlMap)['app_name'], "Kev's App");
  });
}
