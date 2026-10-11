{ pkgs, ... }:

{
  # Fonts
  fonts.packages = with pkgs; [
    jetbrains-mono
    nerd-fonts.jetbrains-mono
    nerd-fonts.caskaydia-mono
    nerd-fonts.symbols-only
    noto-fonts-color-emoji
    corefonts # MS core fonts (unfree): Arial, Times New Roman, Georgia, Verdana, …
  ];
}
