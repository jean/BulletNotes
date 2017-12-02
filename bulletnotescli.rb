class BulletNotesCLI < Formula
  desc "A command line tool to manage your notes"
  homepage "https://github.com/NickBusey/BulletNotes"
  url "https://github.com/NickBusey/BulletNotes/raw/master/archive/bulletnotescli-1.0.0.tar.gz"
  sha256 "185b95e5a441708df51a195b92526048ce1c3ae2a4be5ff6cc9c239dea2655b1"
  version "1.0.0"

  bottle :unneeded

  def install
    bin.install "bulletnotescli"
  end
end