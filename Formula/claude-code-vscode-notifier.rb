class ClaudeCodeVscodeNotifier < Formula
  desc "macOS notifications for Claude Code (VS Code) showing the actual last message"
  homepage "https://github.com/nicolasclaisse/claude-code-vscode-notifier"
  url "https://github.com/nicolasclaisse/claude-code-vscode-notifier/releases/download/v1.0.0/ClaudeNotifier-v1.0.0-arm64.zip"
  sha256 "5f5411e46f0983ed3d6a71039008c741cf1b12c50f700e2bf30d72a0d55dd89c"
  version "1.0.0"
  license "MIT"

  depends_on :macos
  depends_on arch: :arm64

  def install
    bin.install "ClaudeNotifier"

    hook_script = <<~BASH
      #!/bin/bash

      NOTIFIER="#{bin}/ClaudeNotifier"
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
    assert_predicate bin/"ClaudeNotifier", :exist?
    assert_predicate bin/"claude-notifier-hook", :exist?
  end
end
