{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    uv
    nodejs
    pnpm
    bun
    lua
  ];
}
