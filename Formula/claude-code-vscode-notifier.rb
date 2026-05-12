class ClaudeCodeVscodeNotifier < Formula
  desc "macOS notifications for Claude Code (VS Code) showing the actual last message"
  homepage "https://github.com/nicolasclaisse/claude-code-vscode-notifier"
  url "https://github.com/nicolasclaisse/claude-code-vscode-notifier/releases/download/v1.0.2/ClaudeNotifier-v1.0.2-arm64.zip"
  sha256 "d46c621d3876f29b0ef87eed3aed0f579133647f8e3d90b83e98a290583bdcb0"
  version "1.0.2"
  license "MIT"

  depends_on :macos
  depends_on arch: :arm64

  def install
    # Construire le .app bundle
    app_bundle = prefix/"ClaudeNotifier.app/Contents"
    (app_bundle/"MacOS").mkpath
    (app_bundle/"Resources").mkpath

    (app_bundle/"MacOS").install "ClaudeNotifier"
    (app_bundle/"Resources").install "AppIcon.icns"

    (app_bundle/"Info.plist").write <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>CFBundleIdentifier</key>
        <string>com.nicolasclaisse.claude-notifier</string>
        <key>CFBundleName</key>
        <string>Claude Code</string>
        <key>CFBundleExecutable</key>
        <string>ClaudeNotifier</string>
        <key>CFBundleIconFile</key>
        <string>AppIcon</string>
        <key>CFBundleVersion</key>
        <string>1</string>
        <key>CFBundleShortVersionString</key>
        <string>1.0.1</string>
        <key>LSUIElement</key>
        <true/>
        <key>NSUserNotificationAlertStyle</key>
        <string>alert</string>
      </dict>
      </plist>
    XML

    notifier_path = "#{prefix}/ClaudeNotifier.app/Contents/MacOS/ClaudeNotifier"

    hook_script = <<~BASH
      #!/bin/bash

      NOTIFIER="#{prefix}/ClaudeNotifier.app/Contents/MacOS/ClaudeNotifier"
      MSG="Claude a terminé"

      INPUT=$(cat)

      TRANSCRIPT=$(echo "$INPUT" | sed -n 's/.*"transcript_path"[[:space:]]*:[[:space:]]*"\\([^"]*\\)".*/\\1/p')

      if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
        LINES_BEFORE=$(wc -l < "$TRANSCRIPT")
        for i in $(seq 1 6); do
          sleep 0.5
          LINES_NOW=$(wc -l < "$TRANSCRIPT")
          [ "$LINES_NOW" -gt "$LINES_BEFORE" ] && break
        done

        LAST_TEXT=$(grep '"role"[[:space:]]*:[[:space:]]*"assistant"' "$TRANSCRIPT" \\
          | grep -o '"type"[[:space:]]*:[[:space:]]*"text"[[:space:]]*,[[:space:]]*"text"[[:space:]]*:[[:space:]]*"[^"]*"' \\
          | sed 's/.*"text"[[:space:]]*:[[:space:]]*"//;s/"$//' \\
          | tail -1)

        if [ -n "$LAST_TEXT" ]; then
          if [[ "$LAST_TEXT" =~ \\?[[:space:]]*$ ]]; then
            MSG="Attends ton input - ${LAST_TEXT:0:80}"
          else
            MSG="${LAST_TEXT:0:100}"
          fi
        fi
      fi

      "$NOTIFIER" "Claude Code" "$MSG" 2>/dev/null \\
        || osascript -e "display notification \\"$MSG\\" with title \\"Claude Code\\" sound name \\"Submarine\\""
    BASH

    (bin/"claude-notifier-hook").write(hook_script)
    chmod 0755, bin/"claude-notifier-hook"

    # Signer le bundle pour que macOS affiche l'icône dans les notifications
    system "codesign", "--sign", "-", "--force", "--deep", "#{prefix}/ClaudeNotifier.app"

    # Symlink dans ~/Applications pour que Launch Services enregistre le bundle
    apps_dir = Pathname.new(Dir.home)/"Applications"
    apps_dir.mkpath
    ln_sf "#{prefix}/ClaudeNotifier.app", apps_dir/"ClaudeNotifier.app"
  end

  def caveats
    <<~EOS
      Pour activer les notifications, ajoute dans ~/.claude/settings.json :

        {
          "hooks": {
            "Stop": [
              {
                "matcher": "",
                "hooks": [{ "type": "command", "command": "#{bin}/claude-notifier-hook" }]
              }
            ]
          }
        }
    EOS
  end

  test do
    assert_predicate prefix/"ClaudeNotifier.app/Contents/MacOS/ClaudeNotifier", :exist?
    assert_predicate bin/"claude-notifier-hook", :exist?
  end
end
