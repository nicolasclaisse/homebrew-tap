class Devdash < Formula
  desc "Web dashboard to launch and monitor a process-compose/nix dev environment"
  homepage "https://github.com/nicolasclaisse/devdash"
  url "https://github.com/nicolasclaisse/devdash/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "5a8d526120d39c25c0f6a8b4ad374b714616ffa634ece889ff5ce4581e6b0139"
  license "MIT"

  depends_on "node"

  def install
    system "npm", "install"
    system "npm", "run", "build"
    system "npm", "prune", "--omit=dev"

    libexec.install Dir["*"]
    bin.install_symlink libexec/"bin/devdash.js" => "devdash"
  end

  test do
    assert_predicate libexec/"dist/server.js", :exist?
    assert_predicate libexec/"bin/devdash.js", :exist?
  end
end
