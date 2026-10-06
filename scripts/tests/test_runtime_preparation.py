import importlib.util
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('runtime', ROOT / 'scripts/prepare-codex-runtime.py')
runtime = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runtime)

class RuntimePreparationTests(unittest.TestCase):
    def test_untrusted_archive_is_rejected_without_overwriting_existing_runtime(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            archive = root / 'tampered.tgz'
            archive.write_bytes(b'not the pinned official runtime')
            destination = root / 'installed'
            destination.mkdir()
            marker = destination / 'existing'
            marker.write_text('keep')
            with self.assertRaisesRegex(ValueError, 'integrity mismatch'):
                runtime.prepare('arm64', destination, archive)
            self.assertEqual(marker.read_text(), 'keep')
            self.assertEqual(list(destination.iterdir()), [marker])

    def test_manifest_pins_both_supported_architectures(self):
        import base64
        for architecture in ('arm64', 'x86_64'):
            item = runtime.MANIFEST['architectures'][architecture]
            self.assertEqual(len(base64.b64decode(item['integrity'].removeprefix('sha512-'))), 64)
            self.assertTrue(item['url'].startswith('https://registry.npmjs.org/@openai/codex/'))
            self.assertIn('0.160.0', item['url'])
