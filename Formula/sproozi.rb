class Sproozi < Formula
  desc "Run agents with limited permissions in Linux containers"
  homepage "https://github.com/andrewmccall/sproozi"
  url "https://github.com/andrewmccall/sproozi/releases/download/v0.2.3/sproozi_0.2.3_source.tar.gz"
  sha256 "4b611e3b2ff9bbbd17533cb3fa06ff95aca5655c34250c051a8b77176a1afc58"
  license "Apache-2.0"

  bottle do
    root_url "https://github.com/andrewmccall/homebrew-tap/releases/download/bottles-41993552164-1"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "e9778f72a075618afff179bfbe5aafae0b76476f6c97ebab4a60a71925c5535e"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "cd80120579ed75887efe8fb23fc15d6848188fde653723d947a38c5338e710a7"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "04587d35d3a0445ea040225674fec26579db2b60bdf422127bbd94982b126edb"
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
