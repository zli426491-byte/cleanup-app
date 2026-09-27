"""Synthetic packaged-artifact regressions; no signing or Flutter tool required."""
import json
import plistlib
import tempfile
import unittest
import zipfile
from pathlib import Path

import check_ios_ipa as checker


class ArtifactGateTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        catalog = self.root / 'lib/l10n'
        catalog.mkdir(parents=True)
        self.files = {}
        self.prefix = 'Payload/Runner.app/'
        self.info = {
            'CFBundleIdentifier': 'com.cleanupapp.cleaner', 'CFBundlePackageType': 'APPL',
            'CFBundleVersion': '44', 'CFBundleShortVersionString': '1.1.3',
            'MinimumOSVersion': '13.0', 'UIDeviceFamily': [1, 2],
            'CFBundleSupportedPlatforms': ['iPhoneOS'],
            'CFBundleLocalizations': [lang.replace('_', '-') for lang in checker.LANGUAGES],
        }
        for lang in checker.LANGUAGES:
            source = {message: f'{lang} {message}' for message in checker.NATIVE_KEYS.values()}
            (catalog / f'app_{lang}.arb').write_text(json.dumps(source), encoding='utf-8')
            native = {key: source[message] for key, message in checker.NATIVE_KEYS.items()}
            self.files[f'{lang.replace("_", "-")}.lproj/InfoPlist.strings'] = plistlib.dumps(native, fmt=plistlib.FMT_BINARY)
        for name in ['App', 'Flutter', 'photo_manager']:
            self.files[f'Frameworks/{name}.framework/Info.plist'] = plistlib.dumps({
                'MinimumOSVersion': '13.0', 'CFBundleExecutable': name})
            self.files[f'Frameworks/{name}.framework/{name}'] = b'synthetic-binary'
        # Metadata-only nested resource bundles are deliberately outside executable framework checks.
        self.files['Frameworks/photo_manager.framework/privacy.bundle/Info.plist'] = plistlib.dumps({})
        self.files['Frameworks/MetadataOnly.framework/Info.plist'] = plistlib.dumps({})

    def inspect(self, app_directory=False, expected_build='44'):
        self.files['Info.plist'] = plistlib.dumps(self.info)
        if app_directory:
            artifact = self.root / 'Runner.app'
            artifact.mkdir()
            for name, contents in self.files.items():
                target = artifact / name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(contents)
        else:
            artifact = self.root / 'test.ipa'
            with zipfile.ZipFile(artifact, 'w') as archive:
                for name, contents in self.files.items():
                    archive.writestr(self.prefix + name, contents)
        return checker.inspect_artifact(artifact, source_root=self.root, expected_build=expected_build)

    def test_complete_ipa_checks_real_payload_and_ignores_resource_bundle_minimum(self):
        report = self.inspect()
        self.assertTrue(report['passed'])
        self.assertEqual(19, report['language_count'])
        self.assertEqual(3, len(report['frameworks']))
        self.assertEqual(64, len(report['ipa_sha256']))

    def test_compiled_app_directory_is_also_checked(self):
        self.assertEqual(19, self.inspect(app_directory=True)['language_count'])

    def test_missing_native_locale_fails_even_when_declared(self):
        del self.files['ar.lproj/InfoPlist.strings']
        with self.assertRaisesRegex(ValueError, 'Missing or extra native'):
            self.inspect()

    def test_stale_native_message_fails_source_comparison(self):
        self.files['he.lproj/InfoPlist.strings'] = plistlib.dumps({'CFBundleDisplayName': 'stale'})
        with self.assertRaisesRegex(ValueError, 'do not match ARB: he'):
            self.inspect()

    def test_iphone_only_bundle_fails(self):
        self.info['UIDeviceFamily'] = [1]
        with self.assertRaisesRegex(ValueError, 'iPhone and iPad'):
            self.inspect()

    def test_app_minimum_ios_increase_fails(self):
        self.info['MinimumOSVersion'] = '14.0'
        with self.assertRaisesRegex(ValueError, 'minimum iOS differs'):
            self.inspect()

    def test_framework_minimum_increase_or_missing_fails(self):
        for minimum in ['14.0', None]:
            with self.subTest(minimum=minimum):
                metadata = {'CFBundleExecutable': 'App'}
                if minimum is not None:
                    metadata['MinimumOSVersion'] = minimum
                self.files['Frameworks/App.framework/Info.plist'] = plistlib.dumps(metadata)
                with self.assertRaises(ValueError):
                    self.inspect()

    def test_wrong_build_and_simulator_bundle_fail(self):
        with self.assertRaisesRegex(ValueError, 'build number'):
            self.inspect(expected_build='45')
        self.info['CFBundleSupportedPlatforms'] = ['iPhoneSimulator']
        with self.assertRaisesRegex(ValueError, 'not Simulator'):
            self.inspect()

    def test_text_utf16_native_resources_parse(self):
        source = json.loads((self.root / 'lib/l10n/app_ja.arb').read_text(encoding='utf-8'))
        content = '\n'.join(f'{json.dumps(key)} = {json.dumps(source[message])};'
                            for key, message in checker.NATIVE_KEYS.items())
        self.files['ja.lproj/InfoPlist.strings'] = content.encode('utf-16')
        self.assertTrue(self.inspect()['passed'])


if __name__ == '__main__':
    unittest.main()
