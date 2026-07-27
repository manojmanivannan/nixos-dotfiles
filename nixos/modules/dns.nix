{ ... }:

{
  # Enable Encrypted DNS
  networking = {
    nameservers = [ "192.168.1.1" "8.8.8.8" ];
    # If using dhcpcd:
    dhcpcd.enable = false; # disable, because enabled by default
    dhcpcd.extraConfig = "nohook resolv.conf";

    # If using NetworkManager:
    networkmanager.dns = "none";

    # If using resolvconf:
    resolvconf = {
      enable = true; # FIXME remember to delete /etc/resolv.conf if you disable `resolvconf`
      useLocalResolver = false;
    };

    # If using iwd:
    wireless.iwd.settings.Network.NameResolvingService = "none";
  };

#  services.dnscrypt-proxy = {
#    enable = false;
#    settings = {
#      listen_addresses = [ "127.0.0.1:53" "[::1]:53" ];
#
#      ipv6_servers = true;
#      require_dnssec = true;
#
#      sources.public-resolvers = {
##        urls = [
#          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
#          "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
#        ];
#        cache_file = "/var/lib/dnscrypt-proxy2/public-resolvers.md";
#        minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
#      };
#
#      # You can choose a specific set of servers from https://github.com/DNSCrypt/dnscrypt-resolvers/blob/master/v3/public-resolvers.md
#      server_names = [ "cloudflare" "cloudflare-ipv6" "cloudflare-security" "cloudflare-security-ipv6" "adguard-dns-doh" "mullvad-adblock-doh" "mullvad-doh" "nextdns" "nextdns-ipv6" "quad9-dnscrypt-ipv4-filter-pri" "google" "google-ipv6" "ibksturm" ];
#    };
#  };

#  systemd.services.dnscrypt-proxy2.serviceConfig = {
#    StateDirectory = "dnscrypt-proxy";
#  };
}
