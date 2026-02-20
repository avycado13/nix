{
  pkgs,
  ...
}:
{
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
        amend = "commit -a --amend";
        bmerged = "!f() { DEFAULT=$(git default); git branch --merged \${1-DEFAULT} | grep -v \"\${1-DEFAULT}$\" | xargs -r git branch -d; }; f";
        brebased = "!f() { DEFAULT=$(git default); for b in $(git branch --format=\"%(refname:short)\" | grep -vE \"(\${1-DEFAULT}|$DEFAULT)\"); do if [ -z \"$(git cherry \${1-\$DEFAULT} $b | grep \"^+\")\" ]; then git branch -D $b; fi; done; }; f";
        bdone = "!f() { DEFAULT=$(git default); git switch \${1-$DEFAULT} && git up && git brebased \${1-$DEFAULT}; }; f";
        co = "checkout";
        clog = "log --pretty=%C(yellow)%s%n%Creset%n%b%n---";
        ddfind = "log --decorate --stat --date=iso --format=fuller --patch --grep";
        ddlog = "log --decorate --stat --date=iso --format=fuller -p";
        default = " !git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'";
        dfind = "log --decorate --stat --date=iso --format=fuller --name-status --grep";
        files = "diff --name-only";
        di = "diff --color-words";
        dic = "diff --color-words=.";
        dlog = "log --decorate --stat --date=iso --format=fuller";
        ec = " config --global -e";
        find = "log --pretty=\"format:%Cgreen%H %Cblue%s\" --name-status --grep";
        flog = "log --pretty=fixes";
        format-patch-repo = "!git format-patch --subject-prefix=\'PATCH $(basename $(git rev-parse --show-toplevel))\'";
        glog = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%aN>%Creset'";
        hist = "log --follow -p";
        pf = "push --force-with-lease";
        plog = "log -1 --pretty=%B";
        rba = "!f() { DEFAULT=$(git default); git rebase -i --autosquash \${1-\$DEFAULT}; }; f";
        save = "!git add -A && git commit -m 'SAVEPOINT'";
        sba = "!f() { git subtree add --prefix $1 $2 master --squash; }; f";
        sbp = "!f() { git subtree push --prefix $1 $2 $3; }; f";
        sbu = "!f() { git subtree pull --prefix $1 $2 master --squash; }; f";
        sc = "switch -c";
        send-email-repo = "!git send-email --subject-prefix=\'PATCH $(basename $(git rev-parse --show-toplevel))\'";
        slog = "shortlog -e --no-merges";
        tlog = "tag --sort=-v:refname -l --format='%(color:red)%(refname:strip=2)%(color:reset) - %(color:yellow)%(contents:subject)%(color:reset) by %(taggername) on %(taggerdate:human)\n\n%(contents:body)'";
        undo = "reset HEAD~1 --mixed";
        up = "!f() { git pull --rebase --prune $@ && git submodule update --init --recursive; }; f";
        wip = "!git add -u && git commit -m 'WIP'";
        wipe = " !git add -A && git commit -qm 'WIPE SAVEPOINT' && git reset HEAD~1 --hard";
        wt = "worktree";
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
      transfer.fsckobjects = false;
      fetch.fsckobjects = false;
      receive.fsckObjects = false;

      fsck.zeroPaddedFilemode = "ignore";
      fetch.fsck.zeroPaddedFilemode = "ignore";
      transfer.fsck.zeroPaddedFilemode = "ignore";
      receive.fsck.zeroPaddedFilemode = "ignore";
      commit.gpgsign = true;
      tag.gpgsign = true;
    };
    signing.format = "openpgp";
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
  programs.gh-dash.enable = true;
  programs.lazygit = {
    enable = true;
    package = pkgs.lazygit;
    enableZshIntegration = true;
  };
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
  home.packages = with pkgs; [
    git-extras
    mob
  ];
}
