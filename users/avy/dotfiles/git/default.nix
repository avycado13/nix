{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    settings = {
      user = {
        name = "avycado13";
        email = "108358183+avycado13@users.noreply.github.com";
        signingkey = "680098B290681E1D28F555A90F7A57CF72410272";
      };

      alias = {
        st = "status";
      };

      color.ui = "auto";
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = false;
      url."git@github.com:".insteadOf = "https://github.com/";
      diff."sqlite3" = {
        binary = true;
        textconv = "echo .dump | sqlite3";
      };
      commit.gpgsign = true;
      tag.gpgsign = true;
    };
  };
  programs.gh = {
    enable = true;
    package = pkgs.gh;
    settings = {
      git_protocol = "ssh";

      prompt = "enabled";
      editor = "nvim";

      aliases = {
        co = "pr checkout";
        pv = "pr view";
      };
    };
  };
  programs.lazygit = {
    enable = true;
    package = pkgs.lazygit;
    enableZshIntegration = true;
  };
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
}
