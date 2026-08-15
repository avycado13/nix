{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.dots.media;
in
{
  options.dots.media = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable the media utilities module.";
    };
    music.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable music player packages (cmus, ncmpcpp, mpc, mpv, mpdscribble).";
    };
  };

  config = lib.mkIf config.dots.media.enable {
    programs.yt-dlp = {
      enable = true;
      extraConfig = ''
        --ffmpeg-location ${lib.getExe pkgs.ffmpeg}
      '';
    };
    programs.zsh.shellAliases = lib.mkIf cfg.enable {
      ya = "${lib.getExe pkgs.yt-dlp} --continue --no-check-certificate --format=bestaudio -x --audio-format wav";
      yam = "${lib.getExe pkgs.yt-dlp} --embed-metadata --embed-thumbnail -x --audio-format m4a -o '%(title)s.%(ext)s'";
      yd = "${lib.getExe pkgs.yt-dlp} --continue --no-check-certificate --format=bestvideo+bestaudio --exec='ffmpeg -i {} -c:v prores_ks -profile:v 1 -vf fps=25/1 -pix_fmt yuv422p -c:a pcm_s16le {}.mov && rm {}'";
      yh = "${lib.getExe pkgs.yt-dlp} --continue --no-check-certificate --format=bestvideo+bestaudio --exec='ffmpeg -i {} -c:a copy -c:v copy {}.mkv && rm {}'";
    };

    programs.bash.shellAliases = lib.mkIf cfg.enable {
      ya = "${lib.getExe pkgs.yt-dlp} --continue --no-check-certificate --format=bestaudio -x --audio-format wav";
      yam = "${lib.getExe pkgs.yt-dlp} --embed-metadata --embed-thumbnail -x --audio-format m4a -o '%(title)s.%(ext)s'";
      yd = "${lib.getExe pkgs.yt-dlp} --continue --no-check-certificate --format=bestvideo+bestaudio --exec='ffmpeg -i {} -c:v prores_ks -profile:v 1 -vf fps=25/1 -pix_fmt yuv422p -c:a pcm_s16le {}.mov && rm {}'";
      yh = "${lib.getExe pkgs.yt-dlp} --continue --no-check-certificate --format=bestvideo+bestaudio --exec='ffmpeg -i {} -c:a copy -c:v copy {}.mkv && rm {}'";
    };

    programs.fish.shellAliases = lib.mkIf cfg.enable {
      ya = "${lib.getExe pkgs.yt-dlp} --continue --no-check-certificate --format=bestaudio -x --audio-format wav";
      yam = "${lib.getExe pkgs.yt-dlp} --embed-metadata --embed-thumbnail -x --audio-format m4a -o '%(title)s.%(ext)s'";
      yd = "${lib.getExe pkgs.yt-dlp} --continue --no-check-certificate --format=bestvideo+bestaudio --exec='ffmpeg -i {} -c:v prores_ks -profile:v 1 -vf fps=25/1 -pix_fmt yuv422p -c:a pcm_s16le {}.mov && rm {}'";
      yh = "${lib.getExe pkgs.yt-dlp} --continue --no-check-certificate --format=bestvideo+bestaudio --exec='ffmpeg -i {} -c:a copy -c:v copy {}.mkv && rm {}'";
    };
    home.packages = [
      pkgs.ffmpeg
      pkgs.imagemagick
      (pkgs.writeShellScriptBin "transcode-video-1080p" ''
        ${pkgs.ffmpeg}/bin/ffmpeg -i "$1" -vf scale=1920:1080 -c:v libx264 -preset fast -crf 23 -c:a copy "''${1%.*}-1080p.mp4"
      '')
      (pkgs.writeShellScriptBin "transcode-video-4K" ''
        ${pkgs.ffmpeg}/bin/ffmpeg -i "$1" -c:v libx265 -preset slow -crf 24 -c:a aac -b:a 192k "''${1%.*}-optimized.mp4"
      '')
      (pkgs.writeShellScriptBin "img2jpg" ''
        img="$1"
        shift
        ${pkgs.imagemagick}/bin/magick "$img" "$@" -quality 95 -strip "''${img%.*}-converted.jpg"
      '')
      (pkgs.writeShellScriptBin "img2jpg-small" ''
        img="$1"
        shift
        ${pkgs.imagemagick}/bin/magick "$img" "$@" -resize 1080x\> -quality 95 -strip "''${img%.*}-small.jpg"
      '')
      (pkgs.writeShellScriptBin "img2jpg-medium" ''
        img="$1"
        shift
        ${pkgs.imagemagick}/bin/magick "$img" "$@" -resize 1800x\> -quality 95 -strip "''${img%.*}-medium.jpg"
      '')
      (pkgs.writeShellScriptBin "img2png" ''
        img="$1"
        shift
        ${pkgs.imagemagick}/bin/magick "$img" "$@" -strip \
          -define png:compression-filter=5 \
          -define png:compression-level=9 \
          -define png:compression-strategy=1 \
          -define png:exclude-chunk=all \
          "''${img%.*}-optimized.png"
      '')
    ]
    ++ lib.optionals cfg.music.enable [
      pkgs.cmus
      pkgs.ncmpcpp
      pkgs.mpc
      pkgs.mpv
      pkgs.mpdscribble
    ];
  };
}
