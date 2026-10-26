"""Rename brew's local bottle files to the filenames in its download metadata."""
import hashlib
import json
from pathlib import Path
import sys


def prepare(directory):
    for metadata in directory.glob('*.bottle.json'):
        for formula in json.loads(metadata.read_text()).values():
            for entry in formula['bottle']['tags'].values():
                # brew writes sproozi--VERSION locally, but downloads
                # sproozi-VERSION. Use its metadata rather than guessing.
                local = directory / Path(entry['local_filename']).name
                target = directory / Path(entry['filename']).name
                if hashlib.sha256(local.read_bytes()).hexdigest() != entry['sha256']:
                    raise ValueError(f'Bottle checksum mismatch: {local.name}')
                if local != target:
                    local.rename(target)


if __name__ == '__main__':
    prepare(Path(sys.argv[1]))
