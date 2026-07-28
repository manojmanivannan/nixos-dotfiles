{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Host-specific system packages go here
  ];
}