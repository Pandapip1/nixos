# VM test for modules/{common,nixos}/security/gpg-authorized-keys.nix:
# SSH logins with the authentication subkeys of keys valid under the web of
# trust rooted at a user's primary key.
#
#   nix build .#checks.<system>.gpg-authorized-keys
#
# pkgs runs the test driver and the VMs (on macOS too: the guests are then
# pkgs.pkgsLinux, run by qemu with hvf).
{ pkgs }:

let

  # Test keys: alice's primary key with two authentication subkeys, a friend
  # certified by alice, and a stranger nobody certified. "Later" is the same
  # keys after alice revoked her second subkey and added a third, as the
  # keyserver would hand them out.
  keys = pkgs.runCommand "gpg-authorized-keys-test-keys" {
    nativeBuildInputs = [
      pkgs.gnupg
      pkgs.openssh
    ];
  } ''
    export GNUPGHOME=$PWD/gnupg
    mkdir -m 700 "$GNUPGHOME"
    g() { gpg --batch --pinentry-mode loopback --passphrase "" "$@"; }
    fpr() { gpg --with-colons --list-keys "$1" | awk -F: '$1 == "fpr" { print $10; exit }'; }
    # Keygrip of subkey number $2 of key $1.
    grip() {
      gpg --with-colons --with-keygrip --list-keys "$1" |
        awk -F: -v n="$2" '$1 == "sub" { i++ } $1 == "grp" && i == n { print $10; exit }'
    }

    g --quick-gen-key "Alice <alice@test>" ed25519 cert never
    alice=$(fpr alice@test)
    g --quick-add-key "$alice" ed25519 auth never
    g --quick-add-key "$alice" ed25519 auth never
    g --quick-gen-key "Friend <friend@test>" ed25519 cert never
    friend=$(fpr friend@test)
    g --quick-add-key "$friend" ed25519 auth never
    g --quick-gen-key "Stranger <stranger@test>" ed25519 cert never
    stranger=$(fpr stranger@test)
    g --quick-add-key "$stranger" ed25519 auth never
    g --local-user "$alice" --quick-sign-key "$friend" "Friend <friend@test>"

    mkdir $out
    g --armor --export "$alice" "$friend" "$stranger" > $out/seed.asc

    printf 'key 2\nrevkey\ny\n0\n\ny\nsave\n' |
      g --command-fd 0 --edit-key "$alice"
    g --quick-add-key "$alice" ed25519 auth never
    g --armor --export "$alice" "$friend" "$stranger" > $out/later.asc
    g --armor --export-secret-keys > $out/secret.asc

    echo -n "$alice" > $out/alice
    echo -n "$friend" > $out/friend
    echo -n "$stranger" > $out/stranger
    grip "$alice" 1 > $out/grip-alice-1
    grip "$alice" 2 > $out/grip-alice-2
    grip "$alice" 3 > $out/grip-alice-3
    grip "$friend" 1 > $out/grip-friend
    grip "$stranger" 1 > $out/grip-stranger
    # A plain SSH key in users.users.alice.openssh.authorizedKeys.
    ssh-keygen -q -t ed25519 -N "" -C static -f $out/static
  '';
  read = name: builtins.readFile "${keys}/${name}";
in
pkgs.testers.runNixOSTest {
  name = "gpg-authorized-keys";

  nodes = {
    server = {
      imports = [
        ../modules/common/security/gpg-authorized-keys.nix
        ../modules/nixos/security/gpg-authorized-keys.nix
      ];
      services.openssh.enable = true;
      users.users.alice = {
        isNormalUser = true;
        gpgAuthorizedKeys = {
          primary = read "alice";
          keys = [
            (read "friend")
            (read "stranger")
          ];
          seedKeys = [ "${keys}/seed.asc" ];
        };
        openssh.authorizedKeys.keys = [ (read "static.pub") ];
      };
    };
    client =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.gnupg ];
      };
  };

  testScript = ''
    start_all()
    server.wait_for_unit("sshd.service")
    client.succeed("mkdir -m 700 -p /root/.gnupg")
    client.succeed("echo enable-ssh-support > /root/.gnupg/gpg-agent.conf")
    client.succeed("gpg --batch --import ${keys}/secret.asc")


    def login(grip_file, expect):
        # Offer only this subkey: gpg-agent's SSH side serves sshcontrol's keys.
        client.succeed(f"cp ${keys}/{grip_file} /root/.gnupg/sshcontrol")
        client.succeed("gpgconf --kill gpg-agent")
        client.succeed("gpg-connect-agent /bye")
        command = (
            "SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket) "
            "ssh -o BatchMode=yes -o StrictHostKeyChecking=no alice@server true"
        )
        if expect:
            client.succeed(command)
        else:
            client.fail(command)


    with subtest("keys from activation (offline, seed keys only)"):
        server.succeed("test -s /var/lib/gpg-authorized-keys/alice/authorized_keys")
        login("grip-alice-1", True)
        login("grip-alice-2", True)
        login("grip-friend", True)
        login("grip-stranger", False)

    with subtest("the keyserver hands out a revocation and a new subkey"):
        # What the refresh would fetch (the VM has no Tor or keyserver).
        server.succeed(
            "gpg --homedir /var/lib/gpg-authorized-keys/alice/gnupg --batch --import ${keys}/later.asc"
        )
        server.succeed("systemctl start gpg-authorized-keys.service")
        login("grip-alice-1", True)
        login("grip-alice-2", False)
        login("grip-alice-3", True)

    with subtest("fail closed: no list, no keys"):
        server.succeed("rm /var/lib/gpg-authorized-keys/alice/authorized_keys")
        login("grip-alice-1", False)

    with subtest("static authorized keys still work"):
        client.succeed("install -m 600 ${keys}/static /root/static")
        client.succeed(
            "ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o IdentityAgent=none "
            "-o IdentitiesOnly=yes -i /root/static alice@server true"
        )
  '';
}
