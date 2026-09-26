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

def load_catalogs():
    base = json.loads((ROOT / 'lib/l10n/app_en.arb').read_text(encoding='utf-8-sig'))
    keys = {key for key in base if not key.startswith('@')}
    catalogs = {}
    for language in LANGUAGES:
        path = ROOT / f'lib/l10n/app_{language}.arb'
        value = json.loads(path.read_text(encoding='utf-8-sig'))
        if value.get('@@locale') != language:
            raise ValueError(f'{path}: incorrect locale')
        actual = {key for key in value if not key.startswith('@')}
        if keys != actual:
            raise ValueError(f'{path}: missing {keys - actual}, extra {actual - keys}')
        for key in keys:
            if not isinstance(value[key], str) or not value[key].strip():
                raise ValueError(f'{path}:{key}: empty or invalid translation')
            params = set(re.findall(r'\{([A-Za-z][A-Za-z0-9_]*)\s*[,}]', base[key]))
            translated = set(re.findall(r'\{([A-Za-z][A-Za-z0-9_]*)\s*[,}]', value[key]))
            if params != translated:
                raise ValueError(f'{path}:{key}: changed placeholders {params} -> {translated}')
            if '${' in value[key]:
                raise ValueError(f'{path}:{key}: Dart interpolation in translation')
        catalogs[language] = value
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

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--write-ios', action='store_true')
    args = parser.parse_args()
    catalogs, count = load_catalogs()
    if args.write_ios:
        write_ios(catalogs)
    check_ios(catalogs)
    print(f'PASS: {len(catalogs)} languages, {count} messages each, placeholders, and iOS permission resources')
