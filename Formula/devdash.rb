class Devdash < Formula
  desc "Web dashboard to launch and monitor a process-compose/nix dev environment"
  homepage "https://github.com/nicolasclaisse/devdash"
  url "https://github.com/nicolasclaisse/devdash/archive/refs/tags/v0.6.3.tar.gz"
  sha256 "22fc82981d5962932725fd474d0746ee8c6281281faaa848914ee616c92e1091"
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
