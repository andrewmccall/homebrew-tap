import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from bottles import prepare


class BottlesTest(unittest.TestCase):
    def test_publish_filename_and_checksum(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            local = root / 'sproozi--0.2.0.arm64_sequoia.bottle.tar.gz'
            local.write_bytes(b'bottle bytes')
            entry = {'local_filename': local.name,
                     'filename': local.name.replace('--', '-'),
                     'sha256': hashlib.sha256(local.read_bytes()).hexdigest()}
            metadata = root / 'sproozi.bottle.json'
            metadata.write_text(json.dumps({'sproozi': {'bottle': {'tags': {'arm64_sequoia': entry}}}}))
            prepare(root)
            self.assertFalse(local.exists())
            self.assertEqual((root / entry['filename']).read_bytes(), b'bottle bytes')

    def test_corrupt_bottle_is_not_published(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / 'local.tar.gz').write_bytes(b'corrupt')
            entry = {'local_filename': 'local.tar.gz', 'filename': 'public.tar.gz', 'sha256': '0' * 64}
            (root / 'sproozi.bottle.json').write_text(json.dumps({'sproozi': {'bottle': {'tags': {'x86_64_linux': entry}}}}))
            with self.assertRaisesRegex(ValueError, 'checksum mismatch'):
                prepare(root)
            self.assertFalse((root / 'public.tar.gz').exists())


if __name__ == '__main__':
    unittest.main()
