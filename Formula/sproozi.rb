class Sproozi < Formula
  desc "Run agents with limited permissions in Linux containers"
  homepage "https://github.com/andrewmccall/sproozi"
  url "https://github.com/andrewmccall/sproozi/releases/download/v0.2.1/sproozi_0.2.1_source.tar.gz"
  sha256 "c8a10f957268c52edbffece8ca585b3ab37ad42719f6334efa94bcf03593dcf5"
  license "Apache-2.0"

  bottle do
    root_url "https://github.com/andrewmccall/homebrew-tap/releases/download/bottles-40396502052-1"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "ac38e3d4f407b5a4e9529d2307f2085d26acf060fbca1d6f560c70d87e56799c"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "d242160f3e72951ff8ea41fef5649db060563c64b4d560c156f3acbb7cdcf05b"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "76072ea510162f46a7dc797d0c601400c1148ba39ae974f86db248a82dd26171"
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
