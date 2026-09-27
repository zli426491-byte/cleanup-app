"""Regression checks for the shipping catalog validator (standard library only)."""
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory

import check_localizations as checker


class CatalogContracts(unittest.TestCase):
    def test_all_shipping_catalogs_and_ios_permissions(self):
        catalogs, count = checker.load_catalogs()
        self.assertEqual(len(catalogs), 19)
        self.assertGreaterEqual(count, 361)
        checker.check_ios(catalogs)

    def test_nested_plural_preserves_both_arguments(self):
        args = checker.icu_arguments(
            '{count, plural, one{{count} item: {size}} '
            'other{{count} items: {size}}}'
        )
        self.assertEqual(set(args), {'count', 'size'})
        self.assertIn('plural', args['count'])

    def test_missing_plural_fallback_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'other'):
            checker.icu_arguments('{count, plural, one{one item}}')

    def test_unclosed_nested_body_is_rejected(self):
        with self.assertRaises(ValueError):
            checker.icu_arguments('{count, plural, other{{count} items}')

    def test_duplicate_choices_are_rejected(self):
        with self.assertRaisesRegex(ValueError, 'duplicate'):
            checker.icu_arguments('{n, plural, one{A} one{B} other{C}}')

    def test_invalid_plural_category_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'category'):
            checker.icu_arguments('{n, plural, manyy{A} other{B}}')

    def test_renaming_an_argument_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'placeholders'):
            checker.validate_translation('fr', 'example', '{count} items',
                                         '{total} éléments')

    def test_accidental_english_fallback_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'English fallback'):
            checker.validate_translation('fr', 'homePermissionTitle',
                                         'Photo access needed', 'Photo access needed')

    def test_isolates_do_not_hide_an_english_fallback(self):
        with self.assertRaisesRegex(ValueError, 'English fallback'):
            checker.validate_translation('ar', 'example', 'Subscribe {price}',
                                         'Subscribe \u2068{price}\u2069')

    def test_brand_and_local_shared_word_are_allowed(self):
        checker.validate_translation('ja', 'paywallTitle',
                                     'Cleanup Pro', 'Cleanup Pro')
        checker.validate_translation('fr', 'scanCategoryPhotos', 'Photos', 'Photos')

    def test_foreign_chinese_leak_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'Chinese'):
            checker.validate_translation('ar', 'example', 'Photo', '照片')

    def test_price_isolates_preserve_interpolation(self):
        checker.validate_translation('ar', 'example', 'Subscribe {price}',
                                     'اشتراك \u2068{price}\u2069')
        with self.assertRaisesRegex(ValueError, 'unclosed'):
            checker.validate_translation('ar', 'example', 'Subscribe {price}',
                                         'اشتراك \u2068{price}')

    def test_directional_override_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'override'):
            checker.validate_translation('he', 'example', 'Price {price}',
                                         'מחיר \u202e{price}')

    def test_duplicate_catalog_keys_are_not_silently_overwritten(self):
        with self.assertRaisesRegex(ValueError, 'Duplicate JSON'):
            checker.unique_object([('key', 'first'), ('key', 'second')])

    def test_generated_isolates_are_explicit_and_escaping_is_idempotent(self):
        with TemporaryDirectory() as directory:
            path = Path(directory) / 'app_localizations_ar.dart'
            path.write_text("String price = '\u2068USD 4.99\u2069';\n",
                            encoding='utf-8')
            self.assertEqual(checker.escape_dart_isolates([path]), 1)
            self.assertEqual(path.read_text(encoding='utf-8'),
                             "String price = '\\u2068USD 4.99\\u2069';\n")
            self.assertEqual(checker.escape_dart_isolates([path]), 0)


if __name__ == '__main__':
    unittest.main()
