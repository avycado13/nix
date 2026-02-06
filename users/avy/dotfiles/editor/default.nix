{ pkgs, ... }:
{
  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
    };

    helix = {
      enable = true;
      settings = {
        editor.cursor-shape = {
          normal = "block";
          insert = "bar";
          select = "underline";
        };
      };
      languages.language = [
        {
          name = "nix";
          auto-format = true;
          formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
        }
      ];
      themes = {
        autumn_night_transparent = {
          "inherits" = "autumn_night";
          "ui.background" = { };
        };
      };
    };

    vscode = {
      enable = true;
      profiles.default = {
        extensions = with pkgs.vscode-extensions; [
          esbenp.prettier-vscode
          rust-lang.rust-analyzer
          # Note: You referenced these formnatters in settings,
          # you might want to add them here:
          charliermarsh.ruff
          biomejs.biome
          mkhl.direnv
          wakatime.vscode-wakatime
          svelte.svelte-vscode
          ms-vscode-remote.vscode-remote-extensionpack
          sourcegraph.amp
        ];

        userSettings = {
          "files.autoSave" = "afterDelay";
          "git.enableSmartCommit" = true;
          "git.confirmSync" = false;
          "files.associations" = {
            "*.tsx" = "typescriptreact";
            "*.jinja" = "jinja";
          };
          "remoteHub.commitDirectlyWarning" = "off";
          "security.promptForLocalFileProtocolHandling" = false;
          "git.autofetch" = true;
          "makefile.configureOnOpen" = true;
          "[typescript]" = {
            "editor.defaultFormatter" = "biomejs.biome";
          };
          "explorer.fileNesting.patterns" = {
            "*.ts" = "\${capture}.js";
            "*.js" = "\${capture}.js.map ; \${capture}.min.js ; \${capture}.d.ts";
            "*.jsx" = "\${capture}.js";
            "*.tsx" = "\${capture}.ts";
            "tsconfig.json" = "tsconfig.*.json";
            "package.json" = "package-lock.json ; yarn.lock ; pnpm-lock.yaml ; pnpm-lock.yaml ; bun.lockb";
            "*.sqlite" = "\${capture}.\${extname}-*";
            "*.db" = "\${capture}.\${extname}-*";
            "*.sqlite3" = "\${capture}.\${extname}-*";
            "*.db3" = "\${capture}.\${extname}-*";
            "*.sdb" = "\${capture}.\${extname}-*";
            "*.s3db" = "\${capture}.\${extname}-*";
          };
          "git.ignoreRebaseWarning" = true;
          "typescript.updateImportsOnFileMove.enabled" = "always";
          "[python]" = {
            "editor.codeActionsOnSave" = {
              "source.fixAll" = "explicit";
              "source.organizeImports" = "explicit";
            };
            "editor.defaultFormatter" = "charliermarsh.ruff";
          };
          "[jsonc]" = {
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
          };
          "[javascript]" = {
            "editor.defaultFormatter" = "biomejs.biome";
          };
          "[html]" = {
            "editor.defaultFormatter" = "biomejs.biome";
          };
          "[svelte]" = {
            "editor.defaultFormatter" = "svelte.svelte-vscode";
          };
          "workbench.colorTheme" = "Catppuccin Mocha";
          "amp.experimental.modes" = [
            "deep"
            "large"
          ];
        };
      };
    };
  };
}
