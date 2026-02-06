let
  mkService = import ../../lib/mkService.nix;
in
mkService {
  name = "bentopdf";
  description = "Stirling PDF Service";
  defaultPort = 8080;
  runtime = "container";
  defaultImage = "ghcr.io/alam00000/bentopdf:latest";

  extraOptions =
    { lib, ... }:
    {
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

  extraConfig = cfg: {
    homelab.services.bentopdf.container = {
      volumes =
        (if cfg.trainingDataPath != "" then [ "${cfg.trainingDataPath}:/usr/share/tessdata" ] else [ ])
        ++ (if cfg.extraConfigsPath != "" then [ "${cfg.extraConfigsPath}:/configs" ] else [ ])
        ++ (if cfg.customFilesPath != "" then [ "${cfg.customFilesPath}:/customFiles" ] else [ ])
        ++ (if cfg.logsPath != "" then [ "${cfg.logsPath}:/logs" ] else [ ])
        ++ (if cfg.pipelinePath != "" then [ "${cfg.pipelinePath}:/pipeline" ] else [ ]);
    };

    homelab.services.bentopdf.environment = {
      DISABLE_ADDITIONAL_FEATURES = if cfg.disableAdditionalFeatures then "true" else "false";
      LANGS = cfg.langs;
    };
  };
}
