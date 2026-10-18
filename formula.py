"""The source formula shared by release smoke tests and the stable updater."""
import re


def render(version, url, digest):
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+(?:[-+.][0-9A-Za-z.-]+)?", version):
        raise ValueError("Invalid formula version")
    if not re.fullmatch(r"[a-f0-9]{64}", digest) or any(c in url for c in ['"', "\\", "\n", "\r"]):
        raise ValueError("Invalid formula URL or checksum")
    return '''class Sproozi < Formula
  desc "Run agents with limited permissions in Linux containers"
  homepage "https://github.com/andrewmccall/sproozi"
  url "URL"
VERSION_LINE  sha256 "SHA256"
  license "Apache-2.0"

  depends_on "go" => :build

  def install
    metadata = JSON.parse((buildpath/"release.json").read)
    odie "Source version mismatch" if metadata.fetch("version") != version.to_s
    ENV["CGO_ENABLED"] = "0"
    ENV["GOTOOLCHAIN"] = "local"
    ENV["GOPROXY"] = "off"
    ldflags = "-s -w -X main.version=#{version} -X main.commit=#{metadata.fetch("commit")} -X main.date=#{metadata.fetch("date")}"
    system "go", "build", "-mod=vendor", *std_go_args(ldflags: ldflags), "./cmd/sproozi"
  end

  test do
    assert_match "sproozi #{version} (commit ", shell_output("#{bin}/sproozi --version")
    assert_match "Usage: sproozi COMMAND", shell_output("#{bin}/sproozi --help")
  end
end
'''.replace('VERSION_LINE', f'  version "{version}"\n' if '-' in version else '').replace('URL', url).replace('SHA256', digest)
