{ pkgs, ... }:
{
  programs = {
    neovim = {
      enable = true;
      defaultEditor = false;
    };

    helix = {
      enable = true;
      defaultEditor = true;
      settings = {
        editor = {
          mouse = true;
          auto-format = true;
          cursor-shape = {
            normal = "block";
            insert = "bar";
            select = "underline";
          };

        };
        keys = {
          normal = {
            C-g = [
              ":write-all"
              ":insert-output lazygit >/dev/tty"
              ":redraw"
              ":reload-all"
              ":set mouse false"
              ":set mouse true"
            ];
            C-r = [
              ":write-all"
              ":insert-output scooter --no-stdin >/dev/tty"
              ":redraw"
              ":reload-all"
              ":set mouse false"
              ":set mouse true"
            ];
            "C-f" = [
  ":write-all"
  ":insert-output rg --column --line-number --no-heading --color=always \"%{selection}\" | less -R"
  ":redraw"
];
"C-p" = [
  ":write"
  ":insert-output glow -p %{buffer_name} >/dev/tty"
  ":redraw"
];
            space = {
              e = [
                ":sh rm -f /tmp/unique-file-h21a434"
                ":insert-output yazi \"%{buffer_name}\" --chooser-file=/tmp/unique-file-h21a434"
                ":sh printf \"\\x1b[?1049h\\x1b[?2004h\" > /dev/tty"
                ":open %sh{cat /tmp/unique-file-h21a434}"
                ":redraw"
                ":set mouse false"
                ":set mouse true"
              ];
              m = [
  ":write-all"
  ":insert-output glow >/dev/tty"
  ":redraw"
];
            };
            g = {
              a = "code_action";
            }; # Maps `ga` to show possible code actions

          };
        };

      };
      languages.language = [
        {
          auto-format = true;
          formatter = {
            args = [
              "--file=/dev/stdin"
              "--pretty-print=/dev/stdout"
            ];
            command = "${pkgs.gawk}/bin/awk";
            timeout = 5;
          };
          name = "awk";
          scope = "source.awk";
        }
        {
          auto-format = true;
          formatter = {
            args = [
              "format"
              "--stdin-file-path buffer.graphql"
            ];
            command = "${pkgs.biome}/bin/biome";
          };
          name = "graphql";
          scope = "source.graphql";
        }
        {
          auto-format = true;
          formatter = {
            args = [
              "format"
              "--stdin-file-path"
              "buffer.css"
            ];
            command = "${pkgs.biome}/bin/biome";
          };
          name = "css";
          language-servers = [ "wakatime" ];
          scope = "source.css";
        }
        {
          auto-format = true;
          formatter = {
            args = [
              "format"
              "--stdin-file-path"
              "buffer.js"
            ];
            command = "${pkgs.biome}/bin/biome";
          };
          name = "javascript";
          language-servers = [ "wakatime" ];
          scope = "source.js";
        }
        {
          auto-format = true;
          formatter = {
            args = [
              "format"
              "--stdin-file-path"
              "buffer.ts"
            ];
            command = "${pkgs.biome}/bin/biome";
          };
          name = "typescript";
          language-servers = [
            "typescript-language-server"
            "wakatime"
          ];
          scope = "source.ts";
        }
        {
          auto-format = true;
          formatter = {
            args = [
              "format"
              "--stdin-file-path"
              "buffer.jsx"
            ];
            command = "${pkgs.biome}/bin/biome";
          };
          name = "jsx";
          language-servers = [
            "typescript-language-server"
            "wakatime"
          ];
          scope = "source.jsx";
        }
        {
          auto-format = true;
          formatter = {
            args = [
              "format"
              "--stdin-file-path"
              "buffer.tsx"
            ];
            command = "${pkgs.biome}/bin/biome";
          };
          name = "tsx";
          language-servers = [
            "typescript-language-server"
            "wakatime"
          ];
          scope = "source.tsx";
        }
        {
          auto-format = true;
          formatter = {
            args = [
              "format"
              "--stdin-file-path"
              "buffer.json"
            ];
            command = "${pkgs.biome}/bin/biome";
          };
          name = "json";
          language-servers = [ "wakatime" ];
          scope = "source.json";
        }
        {
          auto-format = true;
          formatter = {
            args = [
              "format"
              "--stdin-file-path"
              "buffer.jsonc"
            ];
            command = "${pkgs.biome}/bin/biome";
          };
          name = "jsonc";
          language-servers = [ "wakatime" ];
          scope = "source.json";
        }
        {
          auto-format = true;
          formatter = {
            args = [
              "--justfile"
              "/dev/stdin"
              "--dump"
            ];
            command = "${pkgs.just}/bin/just";
          };
          name = "just";
          language-servers = [ "wakatime" ];
          scope = "source.just";
        }
        {
          auto-format = true;
          formatter = {
            command = "${pkgs.nixfmt}/bin/nixfmt";
          };
          name = "nix";
          language-servers = [
            "nil"
            "wakatime"
          ];
          scope = "source.nix";
        }
        {
          auto-format = true;
          formatter = {
            args = [
              "format"
              "--line-length"
              "88"
              "-"
            ];
            command = "${pkgs.ruff}/bin/ruff";
          };
          name = "python";
          language-servers = [
            "pylsp"
            "ruff"
            "wakatime"
          ];
          scope = "source.python";
        }
      ];

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
        enableMcpIntegration = true;
      };
    };
  };
}
