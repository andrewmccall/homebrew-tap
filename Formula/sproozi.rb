class Sproozi < Formula
  desc "Run agents with limited permissions in Linux containers"
  homepage "https://github.com/andrewmccall/sproozi"
  url "https://github.com/andrewmccall/sproozi/releases/download/v0.2.6/sproozi_0.2.6_source.tar.gz"
  sha256 "67e8a80250dd1555efd5dd59743acc29f86e6987d08209caaf52110b70d28456"
  license "Apache-2.0"

  bottle do
    root_url "https://github.com/andrewmccall/homebrew-tap/releases/download/bottles-42913589507-1"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "5d6f1a3d4c9a380776ecfefa08b3fe3289206710cbe853ce06e6d1d6ff5fd35e"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "6985050813f6e58d7e6a82c439f36c7422e2c0a3e991e37c88608211ba536235"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "24f09a60091fad435253700fc8819a6460bde1eb6b6933136e2ea8056ec6025b"
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
