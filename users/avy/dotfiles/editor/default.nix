{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
let
  flakeDir = "${config.home.homeDirectory}/nix";
  flakeExpr = "(builtins.getFlake \"${flakeDir}\")";
in
{
  options.dots.editor.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable the editor dotfiles module.";
  };

  config = lib.mkIf config.dots.editor.enable {
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
              C-1 = [
                ":w"
                ":write-all"
                ":insert-output ${lib.getExe pkgs.lazygit} >/dev/tty"
                ":redraw"
                ":reload-all"
                ":set mouse false"
                ":set mouse true"
              ];
              C-r = [
                ":w"
                ":write-all"
                ":insert-output ${lib.getExe pkgs.scooter} --no-stdin >/dev/tty"
                ":redraw"
                ":reload-all"
                ":set mouse false"
                ":set mouse true"
              ];
              "C-f" = [
                ":write-all"
                ":insert-output ${lib.getExe pkgs.ripgrep} --column --line-number --no-heading --color=always \"%{selection}\" | less -R"
                ":redraw"
              ];
              "C-p" = [
                ":w"
                ":write"
                ":insert-output ${lib.getExe pkgs.glow} -p %{buffer_name} >/dev/tty"
                ":redraw"
              ];
              space = {
                e = [
                  ":w"
                  ":sh rm -f /tmp/unique-file-h21a434"
                  ":insert-output ${lib.getExe pkgs.yazi} \"%{buffer_name}\" --chooser-file=/tmp/unique-file-h21a434"
                  ":sh printf \"\\x1b[?1049h\\x1b[?2004h\" > /dev/tty"
                  ":open %sh{cat /tmp/unique-file-h21a434}"
                  ":redraw"
                  ":set mouse false"
                  ":set mouse true"
                ];
              };

              g.a = "code_action";
              # Maps `ga` to show possible code actions

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
              command = "${lib.getExe pkgs.gawk}";
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
              command = "${lib.getExe pkgs.biome}";
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
              command = "${lib.getExe pkgs.biome}";
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
              command = "${lib.getExe pkgs.biome}";
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
              command = "${lib.getExe pkgs.biome}";
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
              command = "${lib.getExe pkgs.biome}";
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
              command = "${lib.getExe pkgs.biome}";
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
              command = "${lib.getExe pkgs.biome}";
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
              command = "${lib.getExe pkgs.biome}";
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
              command = "${lib.getExe pkgs.biome}";
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
              command = "${lib.getExe pkgs.just}";
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
              command = "${lib.getExe pkgs.nixfmt}";
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
              command = "${lib.getExe pkgs.ruff}";
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
              command = "${lib.getExe pkgs.shfmt}";
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
              command = "${lib.getExe pkgs.rustfmt}";
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
          {
            auto-format = true;
            name = "go";
            language-servers = [
              "gopls"
              "golangci-lint-lsp"
              "wakatime"
            ];
          }
          {
            name = "templ";
            scope = "source.templ";
            file-types = [ "templ" ];
            roots = [
              "go.work"
              "go.mod"
            ];
            comment-token = "//";
            indent = {
              tab-width = 2;
              unit = "  ";
            };
            language-servers = [
              "templ"
              "wakatime"
            ];
          }
        ];

        languages.language-server = {
          typescript-language-server = {
            command = "${lib.getExe pkgs.typescript-language-server}";
            args = [ "--stdio" ];
          };
          nil = {
            command = "${lib.getExe pkgs.nil}";
          };
          nixd = {
            command = "${lib.getExe pkgs.nixd}";
            config.nixd = {
              options = {
                nix-darwin.expr = "${flakeExpr}.darwinConfigurations.\"Avys-Mac\".options";
                home-manager.expr = "${flakeExpr}.darwinConfigurations.\"Avys-Mac\".options.home-manager.users.type.getSubOptions []";
              };
            };
          };
          ty = {
            command = "${lib.getExe pkgs.ty}";
            args = [ "server" ];
          };
          ruff = {
            command = "${lib.getExe pkgs.ruff}";
            args = [ "server" ];
          };
          biome = {
            command = "${lib.getExe pkgs.biome}";
            args = [ "lsp-proxy" ];
          };
          vscode-html-language-server = {
            command = "${lib.getExe pkgs.vscode-langservers-extracted}";
            args = [ "--stdio" ];
          };
          superhtml = {
            command = "${lib.getExe pkgs.superhtml}";
            args = [ "lsp" ];
            except-features = [ "format" ];
          };
          vscode-css-language-server = {
            command = "${lib.getExe pkgs.vscode-langservers-extracted}";
            args = [ "--stdio" ];
          };
          vscode-json-language-server = {
            command = "${lib.getExe pkgs.vscode-langservers-extracted}";
            args = [ "--stdio" ];
          };
          graphql-language-server = {
            command = "${lib.getExe pkgs.graphql-language-service-cli}";
            args = [
              "server"
              "-m"
              "stream"
            ];
          };
          bash-language-server = {
            command = "${lib.getExe pkgs.bash-language-server}";
            args = [ "start" ];
          };
          # marksman = {
          #   command = "${lib.getExe pkgs.marksman}";
          #   args = [ "server" ];
          # };
          rust-analyzer = {
            command = "${lib.getExe pkgs.rust-analyzer}";
          };
          wakatime = {
            command = "${lib.getExe inputs.wakatime-ls.packages.${pkgs.stdenv.hostPlatform.system}.default}";
          };
          gopls = {
            command = "${lib.getExe pkgs.gopls}";
            args = [ "serve" ];
          };
          golang-ci-langserver = {
            command = "${lib.getExe pkgs.golangci-lint-langserver}";
            args = [
              "run"
              "--output.json.path"
              "stdout"
              "--show-stats=false"
              "--issues-exit-code=1"
            ];

          };
          templ = {
            command = "${lib.getExe pkgs.templ}";
            args = [ "lsp" ];
          };

        };
      };

      vscode = {
        enable = false;
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

    home.activation.mkHelixGrammars = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${lib.getExe pkgs.helix} -g fetch && ${lib.getExe pkgs.helix} -g build
    '';
  };
}
