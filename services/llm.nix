{
  pkgs,
  lib,
  system-config,
  ...
}:
let
  cfg = system-config.options.llm;
in
{
  config = lib.mkIf (cfg != null) {
    services.ollama = {
      enable = true;
      package = pkgs.ollama;
      host = "0.0.0.0";
    };
    systemd.services.ollama = {
      wantedBy = lib.mkForce [ ];
      stopIfChanged = lib.mkForce true;
      serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = "alan";
      };
    };

    services.llama-cpp = {
      enable = true;
      package = pkgs.llama-cpp-vulkan;
      settings = {
        model = cfg.llama-cpp.model;
        host = "0.0.0.0";
        port = 11435;
        ctx-checkpoints = 0;
        device = "Vulkan0";
      };
    };
    systemd.services.llama-cpp = {
      wantedBy = lib.mkForce [ ];
      stopIfChanged = lib.mkForce true;
      serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = "alan";
      };
    };

    services.open-webui = {
      enable = true;
      package = pkgs.open-webui;
      port = 5000;
      environment = {
        HOME = "/var/lib/open-webui";
      };
    };
    systemd.services.open-webui = {
      wantedBy = lib.mkForce [ ];
      stopIfChanged = lib.mkForce true;
    };

  };
}
