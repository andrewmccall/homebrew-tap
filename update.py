#!/usr/bin/env python3
"""Update the formula from the latest public Sproozi source release."""
import hashlib
import json
import os
from pathlib import Path
import re
from urllib.request import Request, urlopen

ROOT = 'https://api.github.com/repos/andrewmccall/sproozi'
headers = {'Accept': 'application/vnd.github+json', 'User-Agent': 'sproozi-homebrew-tap'}
if os.environ.get('GH_TOKEN'):
    headers['Authorization'] = 'Bearer ' + os.environ['GH_TOKEN']
with urlopen(Request(ROOT + '/releases/latest', headers=headers), timeout=60) as response:
    release = json.load(response)
tag = release['tag_name']
if release['draft'] or release['prerelease'] or not re.fullmatch(r'v[0-9]+\.[0-9]+\.[0-9]+', tag):
    raise ValueError('Expected a stable published version')
version = tag[1:]
name = f'sproozi_{version}_source.tar.gz'
base = f'https://github.com/andrewmccall/sproozi/releases/download/{tag}/'
assets = {asset['name']: asset for asset in release['assets']}
for filename in [name, 'checksums.txt']:
    if assets[filename]['browser_download_url'] != base + filename:
        raise ValueError('Unexpected asset URL')
with urlopen(base + 'checksums.txt', timeout=60) as response:
    lines = response.read(1 << 20).decode().splitlines()
sums = {}
for line in lines:
    digest, filename = line.split(None, 1)
    filename = filename.lstrip(' *')
    if filename in sums or not re.fullmatch(r'[a-f0-9]{64}', digest):
        raise ValueError('Invalid checksum list')
    sums[filename] = digest
with urlopen(base + name, timeout=60) as response:
    digest = hashlib.file_digest(response, 'sha256').hexdigest()
if digest != sums[name]:
    raise ValueError('Source checksum mismatch')
formula = '''class Sproozi < Formula
  desc "Run agents with limited permissions in Linux containers"
  homepage "https://github.com/andrewmccall/sproozi"
  url "URL"
  version "VERSION"
  sha256 "SHA256"
  license "Apache-2.0"

  depends_on "go" => :build

  def install
    metadata = JSON.parse((buildpath/"release.json").read)
    odie "Source version mismatch" unless metadata.fetch("version") == version.to_s
    ENV["CGO_ENABLED"] = "0"
    ENV["GOTOOLCHAIN"] = "local"
    ENV["GOPROXY"] = "off"
    ldflags = "-s -w -X main.version=#{version} -X main.commit=#{metadata.fetch('commit')} -X main.date=#{metadata.fetch('date')}"
    system "go", "build", "-mod=vendor", *std_go_args(ldflags: ldflags), "./cmd/sproozi"
  end

  test do
    assert_match "sproozi #{version} (commit ", shell_output("#{bin}/sproozi --version")
    assert_match "Usage: sproozi COMMAND", shell_output("#{bin}/sproozi --help")
  end
end
'''.replace('URL', base + name).replace('VERSION', version).replace('SHA256', digest)
path = Path('Formula/sproozi.rb')
path.parent.mkdir(exist_ok=True)
if path.exists():
    current = re.search(r'^  version "([0-9.]+)"$', path.read_text(), re.M)
    if current and tuple(map(int, current[1].split('.'))) > tuple(map(int, version.split('.'))):
        raise ValueError('Refusing a version downgrade')
path.write_text(formula)
print(tag)
