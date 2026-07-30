{ ... }:

{
  services.avahi = {
    enable = true;
    # This specific flag is required to resolve .local domains
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };
}