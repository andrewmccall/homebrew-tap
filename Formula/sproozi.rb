class Sproozi < Formula
  desc "Run agents with limited permissions in Linux containers"
  homepage "https://github.com/andrewmccall/sproozi"
  url "https://github.com/andrewmccall/sproozi/releases/download/v0.2.2/sproozi_0.2.2_source.tar.gz"
  sha256 "07d73f122479374213db0ab7bc70e1ef2735e8e0b97126b8be3a9779203c55e8"
  license "Apache-2.0"

  bottle do
    root_url "https://github.com/andrewmccall/homebrew-tap/releases/download/bottles-40865642250-1"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "678d10595b21917ddfe50e3c95962485a6f8838f10ff67199b39e9a66db0e3fe"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "61fe933eb150a75a5b9d2e009de6c950d4e13962c5d64c83aab61d1bce929d91"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "f721fd23c2dc59988851d72c790339a41a001526866c60e0499476231b971473"
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
