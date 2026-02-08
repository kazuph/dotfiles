{
  description = "kazuph's dotfiles with Claude Code plugin management";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Claude Code plugins to install (user scope)
        claudePlugins = {
          user = [
            "dotenvx-direnv-worktree"
            "moonbit-luna-ui"
            "moonbit-practice"
            "qwen-tts-on-macos"
          ];
          # Project-scoped plugins (MCP servers) - installed but disabled by default
          project = [
            "mcp-browser-tabs"
            "mcp-chrome-devtools"
            "mcp-fetch"
            "mcp-github-pera1"
            "mcp-gmail-gas"
            "mcp-google-image-search"
            "mcp-limitless"
            "mcp-linear"
            "mcp-obsidian"
            "mcp-pera1-remote"
            "mcp-playwright"
            "mcp-raindrop"
            "mcp-screenshot"
            "mcp-slack"
            "mcp-taskmanager"
            "mcp-tmux"
            "mcp-youtube"
          ];
        };

        # Script to install and enable Claude Code plugins
        install-claude-plugins = pkgs.writeShellScriptBin "install-claude-plugins" ''
          set -e

          DOTFILES_DIR="${toString ./.}"
          MARKETPLACE_NAME="kazuph-dotfiles"

          echo "🔌 Claude Code Plugin Manager"
          echo "=============================="
          echo ""

          # Check if claude command exists
          if ! command -v claude &> /dev/null; then
            echo "❌ Error: 'claude' command not found"
            echo "   Please install Claude Code first: npm install -g @anthropic-ai/claude-code"
            exit 1
          fi

          # Add marketplace if not already added
          echo "📦 Adding marketplace: $DOTFILES_DIR"
          claude marketplace add "$DOTFILES_DIR" 2>/dev/null || true

          echo ""
          echo "📥 Installing user-scope plugins..."
          for plugin in ${builtins.concatStringsSep " " claudePlugins.user}; do
            echo "  → $plugin@$MARKETPLACE_NAME"
            claude plugin install "$plugin@$MARKETPLACE_NAME" --scope user 2>/dev/null || true
            claude plugin enable "$plugin@$MARKETPLACE_NAME" 2>/dev/null || true
          done

          echo ""
          echo "📥 Installing project-scope plugins (MCP servers)..."
          for plugin in ${builtins.concatStringsSep " " claudePlugins.project}; do
            echo "  → $plugin@$MARKETPLACE_NAME"
            claude plugin install "$plugin@$MARKETPLACE_NAME" --scope project 2>/dev/null || true
          done

          echo ""
          echo "✅ Done! Restart your Claude Code session to use new skills."
          echo ""
          echo "📋 Installed skills:"
          ${builtins.concatStringsSep "\n" (map (p: "echo \"  - ${p}\"") claudePlugins.user)}
        '';

        # Script to sync plugins (update existing)
        sync-claude-plugins = pkgs.writeShellScriptBin "sync-claude-plugins" ''
          set -e

          echo "🔄 Syncing Claude Code plugins..."

          if ! command -v claude &> /dev/null; then
            echo "❌ Error: 'claude' command not found"
            exit 1
          fi

          # Update all plugins from marketplace
          claude marketplace update kazuph-dotfiles 2>/dev/null || true

          echo "✅ Sync complete! Restart your Claude Code session to apply updates."
        '';

        # Script to list current plugin status
        list-claude-plugins = pkgs.writeShellScriptBin "list-claude-plugins" ''
          if ! command -v claude &> /dev/null; then
            echo "❌ Error: 'claude' command not found"
            exit 1
          fi

          claude plugin list | grep -E "(kazuph-dotfiles|Status)"
        '';

      in {
        packages = {
          inherit install-claude-plugins sync-claude-plugins list-claude-plugins;
          default = install-claude-plugins;
        };

        apps = {
          install = {
            type = "app";
            program = "${install-claude-plugins}/bin/install-claude-plugins";
          };
          sync = {
            type = "app";
            program = "${sync-claude-plugins}/bin/sync-claude-plugins";
          };
          list = {
            type = "app";
            program = "${list-claude-plugins}/bin/list-claude-plugins";
          };
          default = {
            type = "app";
            program = "${install-claude-plugins}/bin/install-claude-plugins";
          };
        };

        # Development shell with plugin management tools
        devShells.default = pkgs.mkShell {
          buildInputs = [
            install-claude-plugins
            sync-claude-plugins
            list-claude-plugins
          ];

          shellHook = ''
            echo "🎯 Claude Code Plugin Management Shell"
            echo ""
            echo "Available commands:"
            echo "  install-claude-plugins  - Install all plugins from dotfiles"
            echo "  sync-claude-plugins     - Update existing plugins"
            echo "  list-claude-plugins     - List installed plugins"
            echo ""
          '';
        };
      }
    );
}
