{ config, pkgs, lib, ... }:

let
  cfg = config.homelab.services.bentopdf;
in
{
  options.homelab.services.bentopdf = {
    enable = lib.mkEnableOption "Stirling PDF Service";

    # Optional configuration options
    disableAdditionalFeatures = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Disable additional Stirling PDF features";
    };

    langs = lib.mkOption {
      type = lib.types.str;
      default = "en_US";
      description = "OCR languages to use";
    };

    trainingDataPath = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Path to trainingData for OCR languages";
    };

    extraConfigsPath = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Path to extra configuration files";
    };

    customFilesPath = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Path to custom files";
    };

    logsPath = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Path to logs directory";
    };

    pipelinePath = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Path to pipeline directory";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.bentopdf = {
      enable = true;

      image = {
        repository = "ghcr.io/alam00000/bentopdf";
        tag = "latest";
      };

      volumes = lib.mkForce [
        "${cfg.trainingDataPath}:/usr/share/tessdata"
        "${cfg.extraConfigsPath}:/configs"
        "${cfg.customFilesPath}:/customFiles"
        "${cfg.logsPath}:/logs"
        "${cfg.pipelinePath}:/pipeline"
      ];

      environment = {
        DISABLE_ADDITIONAL_FEATURES = if cfg.disableAdditionalFeatures then "true" else "false";
        LANGS = cfg.langs;
      };
    };
  };
}