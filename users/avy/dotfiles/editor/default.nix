{ pkgs, ... }:
{
  programs = {

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
          cursorline = true;
          color-modes = true;
          bufferline = "multiple";

          lsp = {
            display-messages = true;
            display-inlay-hints = true; # show type hints inline
          };

          indent-guides = {
            render = true;
            character = "▏";
          };

          statusline = {
            left = [
              "mode"
              "spinner"
              "file-name"
              "file-modification-indicator"
            ];
            center = [
              "diagnostics"
              "workspace-diagnostics"
            ];
            right = [
              "selections"
              "position"
              "file-encoding"
              "file-line-ending"
              "file-type"
              "version-control"
            ];
          };

          gutters = [
            "diagnostics"
            "spacer"
            "line-numbers"
            "spacer"
            "diff"
          ];

          soft-wrap.enable = true;

        };
        keys = {
          normal = {
            C-g = [
              ":w"
              ":write-all"
              ":insert-output lazygit >/dev/tty"
              ":redraw"
              ":reload-all"
              ":set mouse false"
              ":set mouse true"
            ];
            C-r = [
              ":w"
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
              ":w"
              ":write"
              ":insert-output glow -p %{buffer_name} >/dev/tty"
              ":redraw"
            ];
            space = {
              e = [
                ":w"
                ":sh rm -f /tmp/unique-file-h21a434"
                ":insert-output yazi \"%{buffer_name}\" --chooser-file=/tmp/unique-file-h21a434"
                ":sh printf \"\\x1b[?1049h\\x1b[?2004h\" > /dev/tty"
                ":open %sh{cat /tmp/unique-file-h21a434}"
                ":redraw"
                ":set mouse false"
                ":set mouse true"
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
          language-servers = [
            "graphql-language-server"
            "wakatime"
          ];
          scope = "source.graphql";
        }
        {
          auto-format = true;
          formatter = {
            args = [
              "format"
              "--stdin-file-path"
              "buffer.html"
            ];
            command = "${pkgs.biome}/bin/biome";
          };
          name = "html";
          language-servers = [
            "superhtml"
            "vscode-html-language-server"
            "biome"
            "wakatime"
          ];
          scope = "text.html.basic";
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
          language-servers = [
            "vscode-css-language-server"
            "biome"
            "wakatime"
          ];
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
          language-servers = [
            "typescript-language-server"
            "biome"
            "wakatime"
          ];
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
            "biome"
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
            "biome"
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
            "biome"
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
          language-servers = [
            "vscode-json-language-server"
            "biome"
            "wakatime"
          ];
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
          language-servers = [
            "vscode-json-language-server"
            "biome"
            "wakatime"
          ];
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
          language-servers = [
            "wakatime"
          ];
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
            "nixd"
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
            "ty"
            "ruff"
            "wakatime"
          ];
          scope = "source.python";
        }
        {
          auto-format = true;
          formatter = {
            command = "${pkgs.shfmt}/bin/shfmt";
          };
          name = "bash";
          language-servers = [
            "bash-language-server"
            "wakatime"
          ];
          scope = "source.bash";
        }
        {
          auto-format = true;
          formatter = {
            args = [
              "fmt"
              "--emit=stdout"
            ];
            command = "${pkgs.rustfmt}/bin/rustfmt";
          };
          name = "rust";
          language-servers = [
            "rust-analyzer"
            "wakatime"
          ];
          scope = "source.rust";
        }
        {
          auto-format = true;
          name = "markdown";
          language-servers = [
            # "marksman"
            "wakatime"
          ];
          scope = "source.md";
        }
      ];

      languages.language-server = {
        typescript-language-server = {
          command = "${pkgs.typescript-language-server}/bin/typescript-language-server";
          args = [ "--stdio" ];
        };
        nil = {
          command = "${pkgs.nil}/bin/nil";
        };
        nixd = {
          command = "${pkgs.nixd}/bin/nixd";
        };
        ty = {
          command = "${pkgs.ty}/bin/ty";
          args = [ "server" ];
        };
        ruff = {
          command = "${pkgs.ruff}/bin/ruff";
          args = [ "server" ];
        };
        biome = {
          command = "${pkgs.biome}/bin/biome";
          args = [ "lsp-proxy" ];
        };
        vscode-html-language-server = {
          command = "${pkgs.vscode-langservers-extracted}/bin/vscode-html-language-server";
          args = [ "--stdio" ];
        };
        superhtml = {
          command = "${pkgs.superhtml}/bin/superhtml";
          args = [ "lsp" ];
        };
        vscode-css-language-server = {
          command = "${pkgs.vscode-langservers-extracted}/bin/vscode-css-language-server";
          args = [ "--stdio" ];
        };
        vscode-json-language-server = {
          command = "${pkgs.vscode-langservers-extracted}/bin/vscode-json-language-server";
          args = [ "--stdio" ];
        };
        graphql-language-server = {
          command = "${pkgs.nodePackages.graphql-language-service-cli}/bin/graphql-lsp";
          args = [
            "server"
            "-m"
            "stream"
          ];
        };
        bash-language-server = {
          command = "${pkgs.bash-language-server}/bin/bash-language-server";
          args = [ "start" ];
        };
        # marksman = {
        #   command = "${pkgs.marksman}/bin/marksman";
        #   args = [ "server" ];
        # };
        rust-analyzer = {
          command = "${pkgs.rust-analyzer}/bin/rust-analyzer";
        };
        wakatime = {
          command = "wakatime-lsp";
        };
      };
    };

    vscode = {
      enable = true;
      profiles.default = {
        extensions = with pkgs.vscode-extensions; [
          esbenp.prettier-vscode
          # Note: You referenced these formnatters in settings,
          # you might want to add them here:
          charliermarsh.ruff
          # astral-sh.ty
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
          "json.schemaDownload.trustedDomains" = [
            "https://schemastore.azurewebsites.net/"
            "https://raw.githubusercontent.com/"
            "https://www.schemastore.org/"
            "https://json.schemastore.org/"
            "https://json-schema.org/"
            "https://biomejs.dev"
          ];
        };
        enableMcpIntegration = true;
      };
    };
  };
}
