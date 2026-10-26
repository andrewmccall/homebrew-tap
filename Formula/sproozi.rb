class Sproozi < Formula
  desc "Run agents with limited permissions in Linux containers"
  homepage "https://github.com/andrewmccall/sproozi"
  url "https://github.com/andrewmccall/sproozi/releases/download/v0.2.0/sproozi_0.2.0_source.tar.gz"
  sha256 "5aed1f2c61c153753a8dc3ea08cc7891b874a4d30db5c1f001bf8ca1c95d2545"
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
