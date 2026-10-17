cask "flclash" do
  version "VERSION"

  on_macos do
    arch arm: "arm64", intel: "amd64"

    sha256 arm:   "ARM_SHA256",
           intel: "AMD_SHA256"

    url "https://github.com/chen08209/FlClash/releases/download/v#{version}/FlClash-#{version}-macos-#{arch}.dmg"
  end

  name "FlClash"
  desc "Multi-platform proxy client based on ClashMeta"
  homepage "https://github.com/chen08209/FlClash"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on :macos

  app "FlClash.app"

  postflight do
    system_command "xattr",
                   args: ["-rd", "com.apple.quarantine", "#{appdir}/FlClash.app"]
  end

  uninstall quit: "com.quanclash.app"

  zap trash: [
    "~/Library/Application Support/com.quanclash.app",
    "~/Library/Caches/com.quanclash.app",
    "~/Library/Preferences/com.quanclash.app.plist",
    "~/Library/Saved Application State/com.quanclash.app.savedState",
  ]
end
