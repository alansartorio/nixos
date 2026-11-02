{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.services.llm;
in
{
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.llamaCppModel != null;
        message = "my.services.llm.enable requires my.services.llm.llamaCppModel to be set.";
      }
    ];

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
        model = cfg.llamaCppModel;
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
