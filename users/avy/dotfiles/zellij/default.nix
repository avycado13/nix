{ ... }:
{
  programs.zellij = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      show_startup_tips = false;
      keybinds = {
        _children = [
          {
            shared_except = {
              _args = [ "locked" ];

              bind = {
                _args = [ "Ctrl y" ];

                LaunchOrFocusPlugin = {
                  _args = [ "file:~/.config/zellij/plugins/room.wasm" ];

                  floating = true;
                  ignore_case = true;
                  quick_jump = true;
                };
              };
            };
          }
        ];
      };
    };
  };
}
