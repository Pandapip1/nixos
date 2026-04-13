{
  config,
  pkgs,
  ...
}:

{
  security.pam.services = {
    cosmic-greeter.rules.auth.ropc_pandaport = {
      control = "sufficient";
      modulePath = "${pkgs.pam_ropc}/lib/security/pam_ropc.so";
      order = config.security.pam.services.cosmic-greeter.rules.auth.unix.order + 10; # Place it just after the built-in unix rule
      settings = {
        client_id = "pam_ropc";
        token_url = "https://keycloak.berry.pandapip1.com/realms/pandaport/protocol/openid-connect/token";
        timeout_ms = 1000;
      };
    };
    cups.rules.auth.ropc_pandaport = {
      control = "sufficient";
      modulePath = "${pkgs.pam_ropc}/lib/security/pam_ropc.so";
      order = config.security.pam.services.cups.rules.auth.unix.order + 10; # Place it just after the built-in unix rule
      settings = {
        client_id = "pam_ropc";
        token_url = "https://keycloak.berry.pandapip1.com/realms/pandaport/protocol/openid-connect/token";
        timeout_ms = 1000;
      };
    };
    greetd.rules.auth.ropc_pandaport = {
      control = "sufficient";
      modulePath = "${pkgs.pam_ropc}/lib/security/pam_ropc.so";
      order = config.security.pam.services.greetd.rules.auth.unix.order + 10; # Place it just after the built-in unix rule
      settings = {
        client_id = "pam_ropc";
        token_url = "https://keycloak.berry.pandapip1.com/realms/pandaport/protocol/openid-connect/token";
        timeout_ms = 1000;
      };
    };
    login.rules.auth.ropc_pandaport = {
      control = "sufficient";
      modulePath = "${pkgs.pam_ropc}/lib/security/pam_ropc.so";
      order = config.security.pam.services.login.rules.auth.unix.order + 10; # Place it just after the built-in unix rule
      settings = {
        client_id = "pam_ropc";
        token_url = "https://keycloak.berry.pandapip1.com/realms/pandaport/protocol/openid-connect/token";
        timeout_ms = 1000;
      };
    };
    polkit-1.rules.auth.ropc_pandaport = {
      control = "sufficient";
      modulePath = "${pkgs.pam_ropc}/lib/security/pam_ropc.so";
      order = config.security.pam.services.polkit-1.rules.auth.unix.order + 10; # Place it just after the built-in unix rule
      settings = {
        client_id = "pam_ropc";
        token_url = "https://keycloak.berry.pandapip1.com/realms/pandaport/protocol/openid-connect/token";
        timeout_ms = 1000;
      };
    };
    runuser.rules.auth.ropc_pandaport = {
      control = "sufficient";
      modulePath = "${pkgs.pam_ropc}/lib/security/pam_ropc.so";
      order = config.security.pam.services.runuser.rules.auth.unix.order + 10; # Place it just after the built-in unix rule
      settings = {
        client_id = "pam_ropc";
        token_url = "https://keycloak.berry.pandapip1.com/realms/pandaport/protocol/openid-connect/token";
        timeout_ms = 1000;
      };
    };
    runuser-l.rules.auth.ropc_pandaport = {
      control = "sufficient";
      modulePath = "${pkgs.pam_ropc}/lib/security/pam_ropc.so";
      order = config.security.pam.services.runuser-l.rules.auth.unix.order + 10; # Place it just after the built-in unix rule
      settings = {
        client_id = "pam_ropc";
        token_url = "https://keycloak.berry.pandapip1.com/realms/pandaport/protocol/openid-connect/token";
        timeout_ms = 1000;
      };
    };
    su.rules.auth.ropc_pandaport = {
      control = "sufficient";
      modulePath = "${pkgs.pam_ropc}/lib/security/pam_ropc.so";
      order = config.security.pam.services.su.rules.auth.unix.order + 10; # Place it just after the built-in unix rule
      settings = {
        client_id = "pam_ropc";
        token_url = "https://keycloak.berry.pandapip1.com/realms/pandaport/protocol/openid-connect/token";
        timeout_ms = 1000;
      };
    };
    sudo.rules.auth.ropc_pandaport = {
      control = "sufficient";
      modulePath = "${pkgs.pam_ropc}/lib/security/pam_ropc.so";
      order = config.security.pam.services.sudo.rules.auth.unix.order + 10; # Place it just after the built-in unix rule
      settings = {
        client_id = "pam_ropc";
        token_url = "https://keycloak.berry.pandapip1.com/realms/pandaport/protocol/openid-connect/token";
        timeout_ms = 1000;
      };
    };
    systemd-run0.rules.auth.ropc_pandaport = {
      control = "sufficient";
      modulePath = "${pkgs.pam_ropc}/lib/security/pam_ropc.so";
      order = config.security.pam.services.systemd-run0.rules.auth.unix.order + 10; # Place it just after the built-in unix rule
      settings = {
        client_id = "pam_ropc";
        token_url = "https://keycloak.berry.pandapip1.com/realms/pandaport/protocol/openid-connect/token";
        timeout_ms = 1000;
      };
    };
    systemd-user.rules.auth.ropc_pandaport = {
      control = "sufficient";
      modulePath = "${pkgs.pam_ropc}/lib/security/pam_ropc.so";
      order = config.security.pam.services.systemd-user.rules.auth.unix.order + 10; # Place it just after the built-in unix rule
      settings = {
        client_id = "pam_ropc";
        token_url = "https://keycloak.berry.pandapip1.com/realms/pandaport/protocol/openid-connect/token";
        timeout_ms = 1000;
      };
    };
  };
}
