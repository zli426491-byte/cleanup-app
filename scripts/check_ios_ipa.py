"""Read-only iOS artifact gate. Never reads profiles, certificates or key files."""
import argparse
import hashlib
import json
import plistlib
import re
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LANGUAGES = ['ar', 'en', 'fr', 'de', 'he', 'id', 'it', 'ja', 'ko', 'pl', 'pt',
             'ro', 'ru', 'zh_Hans', 'es', 'th', 'tr', 'vi', 'zh_Hant']
NATIVE_KEYS = {
    'CFBundleDisplayName': 'appName',
    'NSPhotoLibraryUsageDescription': 'nativePhotoRead',
    'NSPhotoLibraryAddUsageDescription': 'nativePhotoAdd',
    'NSContactsUsageDescription': 'nativeContacts',
    'NSUserTrackingUsageDescription': 'nativeTracking',
}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def version(value):
    require(isinstance(value, str) and re.fullmatch(r'\d+(?:\.\d+){0,2}', value),
            'Missing or invalid MinimumOSVersion')
    return tuple((list(map(int, value.split('.'))) + [0, 0])[:3])


def parse_strings(raw):
    try:
        value = plistlib.loads(raw)
        require(isinstance(value, dict), 'Invalid InfoPlist.strings dictionary')
        return value
    except plistlib.InvalidFileException:
        encoding = 'utf-16' if raw.startswith((b'\xff\xfe', b'\xfe\xff')) else 'utf-8-sig'
        content = raw.decode(encoding)
        scanner = re.compile(r'\s+|/\*.*?\*/|//[^\r\n]*|"(?:\\.|[^"\\])*"|[=;]', re.DOTALL)
        tokens, offset = [], 0
        while offset < len(content):
            match = scanner.match(content, offset)
            require(match is not None, 'Invalid InfoPlist.strings text')
            token = match.group()
            if not token.isspace() and not token.startswith(('/*', '//')):
                tokens.append(token)
            offset = match.end()
        require(len(tokens) % 4 == 0, 'Incomplete InfoPlist.strings entry')
        result = {}
        for offset in range(0, len(tokens), 4):
            key, equals, value, semicolon = tokens[offset:offset + 4]
            require(key.startswith('"') and value.startswith('"') and
                    equals == '=' and semicolon == ';', 'Invalid InfoPlist.strings entry')
            key, value = json.loads(key), json.loads(value)
            require(key not in result, 'Duplicate InfoPlist.strings key')
            result[key] = value
        return result


def inspect_artifact(path, *, source_root=ROOT, expected_build=None, minimum_ios='13.0'):
    path = Path(path)
    archive = None
    try:
        if path.is_dir():
            require(path.suffix == '.app', 'Directory input must be an .app bundle')
            names = [p.relative_to(path).as_posix() for p in path.rglob('*') if p.is_file()]
            read = lambda name: (path / name).read_bytes()
            prefix = ''
        else:
            archive = zipfile.ZipFile(path)
            names = archive.namelist()
            require(len(names) == len(set(names)), 'Duplicate ZIP entries')
            main = [name for name in names if re.fullmatch(r'Payload/[^/]+\.app/Info\.plist', name)]
            require(len(main) == 1, 'Expected exactly one top-level app in IPA')
            prefix = main[0][:-len('Info.plist')]
            read = archive.read
        info = plistlib.loads(read(prefix + 'Info.plist'))
        require(info.get('CFBundleIdentifier') == 'com.cleanupapp.cleaner', 'Unexpected app bundle identifier')
        require(info.get('CFBundlePackageType') == 'APPL', 'Input is not an application bundle')
        require(set(info.get('UIDeviceFamily', [])) == {1, 2}, 'Both iPhone and iPad must be supported')
        require(version(info.get('MinimumOSVersion')) == version(minimum_ios), 'App minimum iOS differs from expected support')
        require('iPhoneOS' in info.get('CFBundleSupportedPlatforms', []), 'Expected device build, not Simulator')
        if expected_build is not None:
            require(str(info.get('CFBundleVersion')) == str(expected_build), 'Unexpected build number')
        tags = {language.replace('_', '-') for language in LANGUAGES}
        declared = info.get('CFBundleLocalizations', [])
        require(set(declared) == tags and len(declared) == len(tags), 'Expected exactly 19 declared locales')
        actual_tags = {match.group(1) for name in names
                       if (match := re.fullmatch(re.escape(prefix) + r'([^/]+)\.lproj/InfoPlist\.strings', name))}
        require(actual_tags == tags, 'Missing or extra native InfoPlist.strings locale')
        languages = []
        for language in LANGUAGES:
            tag = language.replace('_', '-')
            native = parse_strings(read(prefix + tag + '.lproj/InfoPlist.strings'))
            source = json.loads((Path(source_root) / 'lib/l10n' / f'app_{language}.arb').read_text(encoding='utf-8-sig'))
            expected = {key: source[message] for key, message in NATIVE_KEYS.items()}
            require(all(isinstance(value, str) and value.strip() for value in expected.values()),
                    f'Empty native source message: {tag}')
            require(native == expected, f'Native localized messages do not match ARB: {tag}')
            languages.append({'locale': tag, 'native_messages': len(native), 'matches_source': True})
        frameworks = []
        for name in names:
            match = re.fullmatch(re.escape(prefix) + r'Frameworks/([^/]+)\.framework/Info\.plist', name)
            if not match:
                continue
            framework = plistlib.loads(read(name))
            if not framework.get('CFBundleExecutable'):
                continue  # Resource-only metadata has no executable deployment requirement.
            require(version(framework.get('MinimumOSVersion')) <= version(minimum_ios),
                    f'Framework requires newer iOS: {match.group(1)}')
            executable = name[:-len('Info.plist')] + framework['CFBundleExecutable']
            require(executable in names, f'Missing framework binary: {match.group(1)}')
            frameworks.append({'name': match.group(1), 'minimum_ios': framework['MinimumOSVersion']})
        require({'App', 'Flutter'}.issubset({f['name'] for f in frameworks}), 'Missing Flutter or App framework')
        result = {'passed': True, 'bundle_id': info['CFBundleIdentifier'],
                  'version': info.get('CFBundleShortVersionString'), 'build': info.get('CFBundleVersion'),
                  'minimum_ios': info['MinimumOSVersion'], 'device_families': sorted(info['UIDeviceFamily']),
                  'language_count': len(languages), 'languages': languages, 'frameworks': frameworks,
                  'scope': 'Packaged native language resources and declared iOS support; does not execute Flutter locales or verify cryptographic signatures.'}
        if path.is_file():
            digest = hashlib.sha256()
            with path.open('rb') as stream:
                for chunk in iter(lambda: stream.read(1024 * 1024), b''):
                    digest.update(chunk)
            result['ipa_sha256'] = digest.hexdigest()
        return result
    finally:
        if archive is not None:
            archive.close()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('artifact', type=Path, help='One .ipa file or compiled .app directory')
    parser.add_argument('--expected-build')
    parser.add_argument('--minimum-ios', default='13.0')
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    try:
        report = inspect_artifact(args.artifact, expected_build=args.expected_build, minimum_ios=args.minimum_ios)
    except (ValueError, OSError, KeyError, TypeError, zipfile.BadZipFile, plistlib.InvalidFileException):
        # Do not echo arbitrary bundle contents, key material or malformed source values.
        print('iOS artifact verification failed. Check language resources, build identity and minimum OS.', file=sys.stderr)
        return 1
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'passed': True, 'build': report['build'], 'language_count': report['language_count'],
                      'minimum_ios': report['minimum_ios']}, ensure_ascii=True))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
