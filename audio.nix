{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    pulseaudio
    easyeffects
    pavucontrol
  ];
}
