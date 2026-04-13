{
  config,
  pkgs,
  ...
}:

{
  security.pam.services.login.rules.auth.ropc = {
    control = "sufficient";
    modulePath = "${pkgs.pam_ropc}/lib/security/pam_ropc.so";
    order = config.security.pam.services.login.rules.auth.unix.order + 10; # Place it just after the built-in unix rule
    settings = {
      client_id = "pam_ropc";
      token_url = "https://keycloak.berry.pandapip1.com/realms/pandaport/protocol/openid-connect/token";
      timeout_ms = 1000;
    };
  };
}
