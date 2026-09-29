"""Check shipped language coverage and optionally update iOS permission resources."""
import argparse
import hashlib
import json
import plistlib
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LANGUAGES = ['ar', 'en', 'fr', 'de', 'he', 'id', 'it', 'ja', 'ko', 'pl', 'pt', 'ro', 'ru', 'zh_Hans', 'es', 'th', 'tr', 'vi', 'zh_Hant']
NATIVE_KEYS = {
    'CFBundleDisplayName': 'appName',
    'NSPhotoLibraryUsageDescription': 'nativePhotoRead',
    'NSPhotoLibraryAddUsageDescription': 'nativePhotoAdd',
    'NSContactsUsageDescription': 'nativeContacts',
    'NSUserTrackingUsageDescription': 'nativeTracking',
}

# Numbers, units, brand names and genuine shared words are intentional matches.
# A new untranslated English sentence must not silently enter a shipped locale.
SHARED_KEYS = {
    'onboardingStep', 'homeProBadge', 'homeUsedPercent', 'swipeProgressCount',
    'assetDimensions', 'assetPreviewDetails', 'videoSizeGb', 'videoSizeMb',
    'assetSizeGigabytes', 'assetSizeMegabytes', 'assetSizeKilobytes',
    'paywallTitle', 'homeAppName', 'settingsProPlan', 'appName',
    'v2ScanningCount',
}
SHARED_WORDS = {
    'de': {'videoPauseOriginal', 'paywallBuild', 'videoOriginalSize',
           'homeScreenshots', 'settingsVersion', 'scanCategoryScreenshots',
           'scanCategoryVideos', 'v2VideoCount'},
    'es': {'videoOriginalSize', 'settingsStorageTotal', 'settingsGeneral',
           'homeStorageTotal'},
    'fr': {'settingsStorageTotal', 'settingsVersion', 'homeStorageTotal',
           'homePhotoCount', 'scanCategoryPhotos'},
    'id': {'settingsStorageTotal', 'homeStorageTotal'},
    'pt': {'videoOriginalSize', 'settingsStorageTotal', 'homeStorageTotal'},
    'ro': {'videoOriginalSize', 'settingsStorageTotal', 'settingsGeneral',
           'homeStorageTotal'},
}


def unique_object(pairs):
    value = {}
    for key, item in pairs:
        if key in value:
            raise ValueError(f'Duplicate JSON key: {key}')
        value[key] = item
    return value


def read_catalog(path):
    return json.loads(path.read_text(encoding='utf-8-sig'),
                      object_pairs_hook=unique_object)


def icu_arguments(message):
    """Read nested ICU arguments and require a valid fallback for every choice.

    This complements gen-l10n's compiler: checking argument sets with a regex
    alone previously accepted broken nested choices or a missing `other`.
    """
    args, index = {}, 0

    def whitespace():
        nonlocal index
        while index < len(message) and message[index].isspace():
            index += 1

    def body(nested=False):
        nonlocal index
        while index < len(message):
            if message[index] == '}':
                if not nested:
                    raise ValueError('Unexpected closing ICU brace')
                index += 1
                return
            if message[index] != '{':
                index += 1
                continue
            index += 1
            whitespace()
            match = re.match(r'[A-Za-z][A-Za-z0-9_]*', message[index:])
            if match is None:
                raise ValueError('Invalid ICU argument name')
            name = match.group()
            index += len(name)
            args.setdefault(name, set())
            whitespace()
            if index < len(message) and message[index] == '}':
                args[name].add('value')
                index += 1
                continue
            if index >= len(message) or message[index] != ',':
                raise ValueError(f'{name}: incomplete ICU argument')
            index += 1
            whitespace()
            match = re.match(r'plural|selectordinal|select', message[index:])
            if match is None:
                raise ValueError(f'{name}: unsupported ICU choice')
            kind = match.group()
            args[name].add(kind)
            index += len(kind)
            whitespace()
            if index >= len(message) or message[index] != ',':
                raise ValueError(f'{name}: missing choice separator')
            index += 1
            whitespace()
            offset = re.match(r'offset:\s*\d+', message[index:])
            if offset:
                index += len(offset.group())
                whitespace()
            options = set()
            while index < len(message) and message[index] != '}':
                match = re.match(r'=\d+|[A-Za-z][A-Za-z0-9_]*', message[index:])
                if match is None:
                    raise ValueError(f'{name}: invalid choice selector')
                option = match.group()
                if option in options:
                    raise ValueError(f'{name}: duplicate choice {option}')
                if kind != 'select' and not (
                    option.startswith('=') or option in
                    {'zero', 'one', 'two', 'few', 'many', 'other'}
                ):
                    raise ValueError(f'{name}: invalid plural category {option}')
                options.add(option)
                index += len(option)
                whitespace()
                if index >= len(message) or message[index] != '{':
                    raise ValueError(f'{name}: missing choice body')
                index += 1
                body(nested=True)
                whitespace()
            if 'other' not in options:
                raise ValueError(f'{name}: choice missing other fallback')
            if index >= len(message):
                raise ValueError(f'{name}: unclosed ICU choice')
            index += 1
        if nested:
            raise ValueError('Unclosed ICU body')

    body()
    return args


def validate_translation(language, key, source, translation):
    if not isinstance(translation, str) or not translation.strip():
        raise ValueError(f'{language}:{key}: empty or invalid translation')
    expected, actual = icu_arguments(source), icu_arguments(translation)
    if set(expected) != set(actual):
        raise ValueError(f'{language}:{key}: changed placeholders '
                         f'{set(expected)} -> {set(actual)}')
    if '${' in translation or '\ufffd' in translation:
        raise ValueError(f'{language}:{key}: interpolation or invalid Unicode')
    plain_translation = re.sub(r'[\u2066-\u2069]', '', translation)
    plain_source = re.sub(r'[\u2066-\u2069]', '', source)
    if (language != 'en' and plain_translation == plain_source and
        key not in SHARED_KEYS and key not in SHARED_WORDS.get(language, set())):
        raise ValueError(f'{language}:{key}: untranslated English fallback')
    if language not in {'zh_Hans', 'zh_Hant', 'ja'} and re.search(
        r'[\u4e00-\u9fff]', translation
    ):
        raise ValueError(f'{language}:{key}: unexpected Chinese text')
    if re.search(r'[\u202a-\u202e]', translation):
        raise ValueError(f'{language}:{key}: directional override is unsafe')
    depth = 0
    for character in translation:
        if character in '\u2066\u2067\u2068':
            depth += 1
        elif character == '\u2069':
            depth -= 1
            if depth < 0:
                raise ValueError(f'{language}:{key}: unmatched bidi terminator')
    if depth:
        raise ValueError(f'{language}:{key}: unclosed bidi isolate')

def load_catalogs():
    base = read_catalog(ROOT / 'lib/l10n/app_en.arb')
    keys = {key for key in base if not key.startswith('@')}
    for key in keys:
        params = icu_arguments(base[key])
        metadata = base.get('@' + key, {}).get('placeholders', {})
        if set(params) != set(metadata):
            raise ValueError(f'en:{key}: missing or stale placeholder metadata')
        for name, kinds in params.items():
            field_type = metadata[name].get('type')
            if field_type not in {'int', 'String'}:
                raise ValueError(f'en:{key}:{name}: invalid placeholder type')
            if kinds.intersection({'plural', 'selectordinal'}) and field_type != 'int':
                raise ValueError(f'en:{key}:{name}: plural requires an int')
    catalogs = {}
    for language in LANGUAGES:
        path = ROOT / f'lib/l10n/app_{language}.arb'
        value = read_catalog(path)
        if value.get('@@locale') != language:
            raise ValueError(f'{path}: incorrect locale')
        actual = {key for key in value if not key.startswith('@')}
        if keys != actual:
            raise ValueError(f'{path}: missing {keys - actual}, extra {actual - keys}')
        for key in keys:
            validate_translation(language, key, base[key], value[key])
            kinds = icu_arguments(value[key])
            metadata = base.get('@' + key, {}).get('placeholders', {})
            for name, variants in kinds.items():
                if variants.intersection({'plural', 'selectordinal'}) and metadata[name]['type'] != 'int':
                    raise ValueError(f'{path}:{key}:{name}: non-numeric plural')
        catalogs[language] = value
    chinese = read_catalog(ROOT / 'lib/l10n/app_zh.arb')
    hans = catalogs['zh_Hans']
    if chinese.get('@@locale') != 'zh' or {
        key: value for key, value in chinese.items() if not key.startswith('@')
    } != {key: value for key, value in hans.items() if not key.startswith('@')}:
        raise ValueError('Chinese base catalog does not match Simplified Chinese')
    return catalogs, len(keys)

def identifier(name):
    return hashlib.sha256(('cleanup-localization-' + name).encode()).hexdigest()[:24].upper()

def write_ios(catalogs):
    tags = [language.replace('_', '-') for language in LANGUAGES]
    for language, tag in zip(LANGUAGES, tags):
        directory = ROOT / f'ios/Runner/{tag}.lproj'
        directory.mkdir(exist_ok=True)
        lines = ['/* Generated from lib/l10n/app_*.arb by scripts/check_localizations.py. */']
        lines += [f'{json.dumps(key)} = {json.dumps(catalogs[language][message], ensure_ascii=False)};' for key, message in NATIVE_KEYS.items()]
        (directory / 'InfoPlist.strings').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    plist_path = ROOT / 'ios/Runner/Info.plist'
    plist = plist_path.read_text(encoding='utf-8')
    block = '\t<key>CFBundleLocalizations</key>\n\t<array>\n' + ''.join(f'\t\t<string>{tag}</string>\n' for tag in tags) + '\t</array>\n'
    plist = re.sub(r'\t<key>CFBundleLocalizations</key>\s*<array>.*?</array>\n?', '', plist, flags=re.S)
    marker = '\t<key>CFBundleDevelopmentRegion</key>'
    if marker not in plist:
        raise ValueError('Missing development-region marker')
    plist_path.write_text(plist.replace(marker, block + marker), encoding='utf-8')
    project_path = ROOT / 'ios/Runner.xcodeproj/project.pbxproj'
    project = project_path.read_text(encoding='utf-8')
    group_id, build_id = identifier('variant'), identifier('build')
    if f'{group_id} /* InfoPlist.strings */ = ' not in project:
        build = f'\t\t{build_id} /* InfoPlist.strings in Resources */ = {{isa = PBXBuildFile; fileRef = {group_id} /* InfoPlist.strings */; }};\n'
        project = project.replace('/* End PBXBuildFile section */', build + '/* End PBXBuildFile section */')
        files = ''.join(f'\t\t{identifier(tag)} /* {tag} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = "{tag}"; path = "{tag}.lproj/InfoPlist.strings"; sourceTree = "<group>"; }};\n' for tag in tags)
        project = project.replace('/* End PBXFileReference section */', files + '/* End PBXFileReference section */')
        children = ''.join(f'\t\t\t\t{identifier(tag)} /* {tag} */,\n' for tag in tags)
        variant = f'/* Begin PBXVariantGroup section */\n\t\t{group_id} /* InfoPlist.strings */ = {{\n\t\t\tisa = PBXVariantGroup;\n\t\t\tchildren = (\n{children}\t\t\t);\n\t\t\tname = InfoPlist.strings;\n\t\t\tsourceTree = "<group>";\n\t\t}};\n/* End PBXVariantGroup section */\n\n'
        project = project.replace('/* Begin XCBuildConfiguration section */', variant + '/* Begin XCBuildConfiguration section */')
        project = project.replace('97C147021CF9000F007C117D /* Info.plist */,', f'97C147021CF9000F007C117D /* Info.plist */,\n\t\t\t\t{group_id} /* InfoPlist.strings */,')
        project = project.replace('97C146FE1CF9000F007C117D /* Assets.xcassets in Resources */,', f'97C146FE1CF9000F007C117D /* Assets.xcassets in Resources */,\n\t\t\t\t{build_id} /* InfoPlist.strings in Resources */,')
    regions = ''.join(f'\t\t\t\t"{tag}",\n' for tag in tags) + '\t\t\t\tBase,\n'
    project = re.sub(r'knownRegions = \(.*?\);', f'knownRegions = (\n{regions}\t\t\t);', project, count=1, flags=re.S)
    project_path.write_text(project, encoding='utf-8')

def check_ios(catalogs):
    tags = {language.replace('_', '-') for language in LANGUAGES}
    info = plistlib.loads((ROOT / 'ios/Runner/Info.plist').read_bytes())
    if set(info.get('CFBundleLocalizations', [])) != tags:
        raise ValueError('iOS localization declarations do not match supported languages')
    project = (ROOT / 'ios/Runner.xcodeproj/project.pbxproj').read_text(encoding='utf-8')
    if f'{identifier("build")} /* InfoPlist.strings in Resources */,' not in project:
        raise ValueError('iOS localized permission resources are not in the app build phase')
    for language, catalog in catalogs.items():
        tag = language.replace('_', '-')
        resource = (ROOT / f'ios/Runner/{tag}.lproj/InfoPlist.strings').read_text(encoding='utf-8')
        expected = {key: catalog[message] for key, message in NATIVE_KEYS.items()}
        matches = re.findall(r'("(?:\\.|[^"\\])*")\s*=\s*("(?:\\.|[^"\\])*")\s*;', resource)
        actual = {json.loads(key): json.loads(value) for key, value in matches}
        if expected != actual or f'path = "{tag}.lproj/InfoPlist.strings";' not in project:
            raise ValueError(f'iOS {tag}: missing or stale permission translations')


def escape_dart_isolates(paths=None):
    """Keep intentional RTL isolates visible to reviewers in generated Dart.

    gen-l10n emits these characters literally. Dart flags invisible direction
    controls even when they are intentional and balanced. Unicode escapes have
    identical runtime text without hiding source characters or ignoring warnings.
    Run after gen-l10n; ARB and native permission resources are not altered.
    """
    paths = paths if paths is not None else (
        ROOT / 'lib/l10n'
    ).glob('app_localizations*.dart')
    changed = 0
    for path in paths:
        source = path.read_text(encoding='utf-8')
        escaped = source
        for code in [0x2066, 0x2067, 0x2068, 0x2069]:
            escaped = escaped.replace(chr(code), f'\\u{code:04x}')
        if source != escaped:
            path.write_text(escaped, encoding='utf-8')
            changed += 1
    return changed

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write-ios', action='store_true')
    parser.add_argument('--escape-dart-isolates', action='store_true',
                        help='Make generated RTL isolates explicit after gen-l10n')
    args = parser.parse_args()
    catalogs, count = load_catalogs()
    if args.write_ios:
        write_ios(catalogs)
    if args.escape_dart_isolates:
        escaped = escape_dart_isolates()
        print(f'Escaped RTL isolates in {escaped} generated Dart files')
    check_ios(catalogs)
    print(f'PASS: {len(catalogs)} languages, {count} messages each, placeholders, and iOS permission resources')
