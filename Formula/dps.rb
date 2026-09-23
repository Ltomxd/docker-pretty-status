class Dps < Formula
  desc "Docker Pretty Status — a colorful, interactive replacement for docker ps"
  homepage "https://github.com/Ltomxd/docker-pretty-status"
  url "https://github.com/Ltomxd/docker-pretty-status/archive/refs/tags/v1.2.0.tar.gz"
  sha256 "REPLACE_WITH_SHA256_AFTER_TAGGING_RELEASE"
  license "MIT"

  depends_on "bash"

  def install
    bin.install "dps.sh" => "dps"
  end

  test do
    assert_match "dps v", shell_output("#{bin}/dps --version")
  end
end
