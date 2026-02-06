# Example: Bun-based service with SQLite backup
# File: homelab/services/myapp/default.nix
{ lib, ... }:
let
  mkService = import ../../lib/mkService.nix;
in
mkService {
  name = "myapp";
  description = "My Bun application";
  defaultPort = 3001;
  runtime = "bun";
  entryPoint = "src/index.ts";

  extraOptions = {
    # Add service-specific options here
    apiKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "API key for external service";
    };
  };

  extraConfig = cfg: {
    # Add service-specific config here
    systemd.services.myapp.environment.API_KEY = lib.mkIf (cfg.apiKey != null) cfg.apiKey;
  };
}

# ---
# Example: Node.js API with PostgreSQL
# File: homelab/services/nodeapi/default.nix

# let
#   mkService = import ../../lib/mkService.nix;
# in
# mkService {
#   name = "nodeapi";
#   description = "Node.js API service";
#   defaultPort = 3002;
#   runtime = "node";
#   entryPoint = "dist/server.js";
# }

# ---
# Example: OCI Container service
# File: homelab/services/nginx-proxy/default.nix

# let
#   mkService = import ../../lib/mkService.nix;
# in
# mkService {
#   name = "nginx-proxy";
#   description = "Nginx reverse proxy";
#   defaultPort = 8080;
#   runtime = "container";
#   defaultImage = "nginx:alpine";
# }

# ---
# Example: Custom systemd service
# File: homelab/services/worker/default.nix

# let
#   mkService = import ../../lib/mkService.nix;
# in
# mkService {
#   name = "worker";
#   description = "Background worker";
#   runtime = "systemd";
#   startCommand = "${pkgs.python3}/bin/python /opt/worker/main.py";
# }

# ---
# Usage in your NixOS configuration:
#
# homelab.services.myapp = {
#   enable = true;
#   domain = "myapp.example.com";
#   port = 3001;
#
#   deploy = {
#     repository = "https://github.com/user/myapp.git";
#     branch = "main";
#     autoUpdate = true;
#   };
#
#   caddy = {
#     enable = true;
#     rateLimit = {
#       enable = true;
#       events = 100;
#       window = "1m";
#     };
#   };
#
#   backup = {
#     enable = true;
#     sqlite = {
#       enable = true;
#       databases = [ "data.db" ];
#     };
#     schedule = "daily";
#     retentionDays = 14;
#   };
#
#   environment = {
#     LOG_LEVEL = "info";
#   };
# };
#
# homelab.services.nodeapi = {
#   enable = true;
#   domain = "api.example.com";
#
#   backup = {
#     enable = true;
#     postgres = {
#       enable = true;
#       databases = [ "nodeapi" ];
#     };
#   };
#
#   after = [ "postgresql.service" ];
#   requires = [ "postgresql.service" ];
# };
#
# homelab.services.nginx-proxy = {
#   enable = true;
#   domain = "proxy.example.com";
#
#   container = {
#     image = "nginx:alpine";
#     volumes = [ "/etc/nginx/nginx.conf:/etc/nginx/nginx.conf:ro" ];
#   };
# };
