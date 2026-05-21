class Devdash < Formula
  desc "Web dashboard to launch and monitor a process-compose/nix dev environment"
  homepage "https://github.com/nicolasclaisse/devdash"
  url "https://github.com/nicolasclaisse/devdash/archive/refs/tags/v0.6.8.tar.gz"
  sha256 "13918979c9bdf4f3acf2b557a51f11c51bf1e07f5aabb227f129a3d1d3c68319"
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
