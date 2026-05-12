class ClaudeCodeVscodeNotifier < Formula
  desc "macOS notifications for Claude Code (VS Code) showing the actual last message"
  homepage "https://github.com/nicolasclaisse/claude-code-vscode-notifier"
  url "https://github.com/nicolasclaisse/claude-code-vscode-notifier/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "7b05cdcd13ae2991d3af787e5129ad41759e3094225c1445c32bf324cda25aa5"
  license "MIT"

  depends_on :macos

  def install
    system "swiftc", "ClaudeNotifier/main.swift", "-o", "ClaudeNotifier"
    bin.install "ClaudeNotifier"

    # Créer notify.sh avec le bon chemin vers le binaire
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
      Pour activer les notifications, exécute :

        mkdir -p ~/.claude/hooks
        cp #{bin}/claude-notifier-hook ~/.claude/hooks/notify.sh

      Puis ajoute dans ~/.claude/settings.json :

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
