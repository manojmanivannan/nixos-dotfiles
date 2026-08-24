{ config, lib, pkgs, ... }:

lib.mkIf (config.manoj.profile == "full") {
  environment.systemPackages = with pkgs; [
    ruff
    jsonnet-language-server
    yaml-language-server
    taplo #toml formatter & lsp
    tombi
    bash-language-server
    dockerfile-language-server
    docker-compose-language-service
    marksman
    markdown-oxide
    nil
    nixd
  ];
}
