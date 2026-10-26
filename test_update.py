import hashlib
import io
import json
import os
from pathlib import Path
import runpy
import tempfile
import unittest
from unittest.mock import patch

from formula import render

SCRIPT = Path(__file__).with_name('update.py')


class UpdateTest(unittest.TestCase):
    def run_update(self, root, version):
        base = f'https://github.com/andrewmccall/sproozi/releases/download/v{version}/'
        name = f'sproozi_{version}_source.tar.gz'
        source = b'source bundle'
        digest = hashlib.sha256(source).hexdigest()
        release = {'tag_name': 'v' + version, 'draft': False, 'prerelease': False,
                   'assets': [{'name': n, 'browser_download_url': base + n} for n in [name, 'checksums.txt']]}

        def response(url, **kwargs):
            if not isinstance(url, str):
                return io.BytesIO(json.dumps(release).encode())
            if url.endswith('checksums.txt'):
                return io.BytesIO(f'{digest}  {name}\n'.encode())
            return io.BytesIO(source)

        previous = Path.cwd()
        try:
            os.chdir(root)
            with patch('urllib.request.urlopen', side_effect=response):
                try:
                    runpy.run_path(str(SCRIPT), run_name='__main__')
                except SystemExit as error:
                    self.assertEqual(error.code, 0)
        finally:
            os.chdir(previous)

    def test_poll_preserves_bottles_and_new_release_replaces_them(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            formula = root / 'Formula/sproozi.rb'
            formula.parent.mkdir()
            digest = hashlib.sha256(b'source bundle').hexdigest()
            current = render('0.2.0', 'https://github.com/andrewmccall/sproozi/releases/download/v0.2.0/sproozi_0.2.0_source.tar.gz', digest)
            current = current.replace('  depends_on', '  bottle do\n    root_url "https://example.test/bottles"\n  end\n\n  depends_on')
            formula.write_text(current)
            self.run_update(root, '0.2.0')
            self.assertEqual(formula.read_text(), current)
            self.run_update(root, '0.2.1')
            self.assertNotIn('bottle do', formula.read_text())
            self.assertIn('/v0.2.1/', formula.read_text())


if __name__ == '__main__':
    unittest.main()
