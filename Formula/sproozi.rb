class Sproozi < Formula
  desc "Run agents with limited permissions in Linux containers"
  homepage "https://github.com/andrewmccall/sproozi"
  url "https://github.com/andrewmccall/sproozi/releases/download/v0.2.4/sproozi_0.2.4_source.tar.gz"
  sha256 "e407de4a0e76d93f7272dcc03a7066df5cbc0c1e113e1223a48a1f8f22172165"
  license "Apache-2.0"

  bottle do
    root_url "https://github.com/andrewmccall/homebrew-tap/releases/download/bottles-42021122240-1"
    sha256 cellar: :any_skip_relocation, arm64_sequoia: "9290e5f19b924ded64ae2a4a52fd3da161573ca1f9af9cc4c215388d75cdae6d"
    sha256 cellar: :any_skip_relocation, arm64_linux:   "c691ed936da16661a8751c485adaf843a6f4a070a3417ce84bb862dd19664daf"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "aa43e012e77ad3a86b58e5be10c36c653d54443c987810b4e6dd96fdf9f22c6c"
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
