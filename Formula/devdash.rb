class Devdash < Formula
  desc "Web dashboard to launch and monitor a process-compose/nix dev environment"
  homepage "https://github.com/nicolasclaisse/devdash"
  url "https://github.com/nicolasclaisse/devdash/archive/refs/tags/v0.5.1.tar.gz"
  sha256 "024b745630c54f8778343a337d9a5b6c0dc796ec05eb78514bdb31717004cac8"
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
