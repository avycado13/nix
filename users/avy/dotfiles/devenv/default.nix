{
  pkgs,
  config,
  inputs,
  ...
}:
{
  programs = {
    bun = {
      enable = true;
      enableGitIntegration = true;
    };
    go.enable = true;
    try.enable = true;
    ruff = {
      enable = true;
      settings = {
        line-length = 100;
        per-file-ignores = {
          "__init__.py" = [ "F401" ];
        };
        lint = {
          select = [ ];
          ignore = [ ];
        };
      };
    };
    ty = {
      enable = true;
    };
    java.enable = true;
    mcp = {
      enable = true;
      servers = {
        context7 = {
          url = "https://mcp.context7.com/mcp";
          headers = {
            CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
          };
        };

        sequentialthinking = {
          command = "${pkgs.bun}/bin/bunx";
          args = [
            "-y"
            "@modelcontextprotocol/server-sequential-thinking"
          ];
        };
        chrome-devtools = {
          command = "${pkgs.bun}/bin/bunx";
          args = [
            "-y"
            "chrome-devtools-mcp@latest"
          ];
        };
        package-search = {
          url = "https://mcp.trychroma.com/package-search/v1";
          headers = {
            x-chroma-token = "{env:CHROMA_MCP_TOKEN}";
          };
          type = "http";
        };

      };
    };
    awscli = {
      enable = true;
    };
  };

  home.packages = [
    pkgs.biome
    pkgs.nodejs
    pkgs.nil
    pkgs.surge-cli
    pkgs.deno
    # pkgs.kicad
    # Rust
    (pkgs.fenix.complete.withComponents [
      "cargo"
      "clippy"
      "rust-src"
      "rustc"
      "rustfmt"
    ])
    inputs.gws-cli.packages.${pkgs.system}.gws
    # ruby
    pkgs.ruby
    # pkgs.bundler
    #

    pkgs.postgresql
    pkgs.ollama
    pkgs.secretspec
  ];
  programs.zsh.initContent = ''
    export CONTEXT7_API_KEY="$(cat ${config.age.secrets.context7_api_key.path})"
    export GH_MCP_TOKEN="$(cat ${config.age.secrets.gh_mcp_token.path})"
    export CHROMA_MCP_TOKEN="$(cat ${config.age.secrets.chroma_mcp_token.path})"
  '';
}
