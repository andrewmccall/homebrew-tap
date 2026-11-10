class Sproozi < Formula
  desc "Run agents with limited permissions in Linux containers"
  homepage "https://github.com/andrewmccall/sproozi"
  url "https://github.com/andrewmccall/sproozi/releases/download/v0.2.5/sproozi_0.2.5_source.tar.gz"
  sha256 "f88148870f2c04a09bac852310f67529d8fee10a630f743379fe0a468431deae"
  license "Apache-2.0"

  bottle do
    root_url "https://github.com/andrewmccall/homebrew-tap/releases/download/bottles-42884291033-1"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "20bac9ae61f76b46588803ee33be9d21e7ae1fd924f81e57113963c45854c0b3"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "5578b82fc4a9884070894415041168aa27a61c5be3576210a1eebebb7e4896c9"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "1b6dcc6ffb5d0cddfe0d5208a3eaf5180349e81ca90a585a2e27429d7390a3c0"
  end

  depends_on "go" => :build

  def install
    metadata = JSON.parse((buildpath/"release.json").read)
    odie "Source version mismatch" if metadata.fetch("version") != version.to_s
    ENV["CGO_ENABLED"] = "0"
    ENV["GOTOOLCHAIN"] = "local"
    ENV["GOPROXY"] = "off"
    ldflags = "-s -w -X main.version=#{version} -X main.commit=#{metadata.fetch("commit")} -X main.date=#{metadata.fetch("date")}"
    system "go", "build", "-mod=vendor", *std_go_args(ldflags: ldflags), "./cmd/sproozi"
    # `sproozi images build` uses this release source; image builds fetch modules themselves.
    pkgshare.install (Dir.glob("*", File::FNM_DOTMATCH) - [".", "..", "vendor"])
  end

  test do
    assert_match "sproozi #{version} (commit ", shell_output("#{bin}/sproozi --version")
    assert_match "Usage: sproozi COMMAND", shell_output("#{bin}/sproozi --help")
    assert_equal version.to_s, JSON.parse((pkgshare/"release.json").read).fetch("version")
    assert_path_exists pkgshare/"hack/release/docker-bake.hcl"
  end
end
