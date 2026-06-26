class Devdash < Formula
  desc "Web dashboard to launch and monitor a process-compose/nix dev environment"
  homepage "https://github.com/nicolasclaisse/devdash"
  url "https://github.com/nicolasclaisse/devdash/archive/refs/tags/v0.7.0.tar.gz"
  sha256 "373b210c73b78738297deb938099e93f56144b0ccbac04472233165be946b9db"
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
