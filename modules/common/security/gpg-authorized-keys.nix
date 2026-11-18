{
  config,
  lib,
  pkgs,
  ...
}:

# SSH logins with keys from the OpenPGP web of trust.
#
# For each user with users.users.<name>.gpgAuthorizedKeys set, a root-owned
# keyring of that user's own (not their ~/.gnupg) holds their primary key,
# ultimately trusted and the only trust root, and any other keys listed. A
# refresh job (gpgAuthorizedKeys.updateScript, run by the nixos and darwin
# modules at activation and then periodically) fetches those keys through
# dirmngr (Tor and the .onion keyserver only), recomputes validity under the
# PGP trust model, and writes the authentication-capable subkeys of every
# valid key, with their expiry, to a root-owned file. sshd's
# AuthorizedKeysCommand (gpgAuthorizedKeys.commandScript) only reads that
# file: no network and no gpg at login, and it prints nothing if the file is
# missing or unreadable (fail closed). A subkey added to the key on the
# keyserver can be used after the next refresh, without a rebuild; a revoked
# one is dropped at the next refresh; an expired one stops working at login
# time. Static authorized keys (users.users.<name>.openssh.authorizedKeys)
# keep working alongside.

let
  cfg = config.gpgAuthorizedKeys;
  fingerprint = lib.types.strMatching "[0-9A-F]{40}";
  users = lib.filterAttrs (
    _: u: u.gpgAuthorizedKeys != null && (u.enable or true)
  ) config.users.users;
  validityRank = {
    marginal = 1;
    full = 2;
    ultimate = 3;
  };

  userOptions = {
    options.gpgAuthorizedKeys = lib.mkOption {
      default = null;
      description = ''
        Accept SSH logins as this user with the authentication subkeys of
        OpenPGP keys that are valid under the web of trust rooted at
        `primary`. See modules/common/security/gpg-authorized-keys.nix.
      '';
      type = lib.types.nullOr (
        lib.types.submodule {
          options = {
            primary = lib.mkOption {
              type = fingerprint;
              description = ''
                Fingerprint (40 upper-case hex digits) of the user's primary
                key: the only ultimately trusted key, so the root of the trust
                computation. Its own authentication subkeys are accepted.
              '';
            };
            keys = lib.mkOption {
              type = lib.types.listOf fingerprint;
              default = [ ];
              description = ''
                Other keys to fetch and consider. Each one's authentication
                subkeys are accepted only while the key itself is valid (at
                least `minValidity`) under the trust model rooted at
                `primary`, e.g. certified by it. Third-party certifications
                must reach this keyring for that: keys.openpgp.org (the
                default keyserver) strips them, so ship certified copies in
                `seedKeys`.
              '';
            };
            minValidity = lib.mkOption {
              type = lib.types.enum (lib.attrNames validityRank);
              default = "full";
              description = "The least validity a key needs for its subkeys to be accepted.";
            };
            seedKeys = lib.mkOption {
              type = lib.types.listOf lib.types.path;
              default = [ ];
              description = ''
                Public keys (files) imported on every refresh, before the
                keyserver is asked: they make logins work offline, from the
                first activation on.
              '';
            };
          };
        }
      );
    };
  };

  # One refresh of one user's keyring and authorized-keys file.
  updateUser =
    name: u:
    lib.escapeShellArgs (
      [
        "update_user"
        name
        u.gpgAuthorizedKeys.primary
        (toString validityRank.${u.gpgAuthorizedKeys.minValidity})
        (lib.concatStringsSep " " u.gpgAuthorizedKeys.keys)
      ]
      ++ map toString u.gpgAuthorizedKeys.seedKeys
    );

  updateScript = pkgs.writeShellApplication {
    name = "gpg-authorized-keys-update";
    runtimeInputs = with pkgs; [
      coreutils
      flock
      gawk
      gnupg
    ];
    text = ''
      # Usage: gpg-authorized-keys-update [--offline]
      # --offline: don't ask the keyserver (activation must not wait on it).
      online=1
      if [ "''${1:-}" = --offline ]; then
        online=0
      fi
      umask 022
      state=${lib.escapeShellArg cfg.stateDir}
      install -d -m 755 -o root "$state"
      # One refresh at a time: activation's offline run and the periodic job
      # share each user's keyring.
      # An offline run doesn't wait for a keyserver fetch in progress (which
      # writes a fresh list itself), so activation never hangs on Tor.
      exec 9> "$state/.lock"
      if [ "$online" = 0 ]; then
        if ! flock -n 9; then
          echo "gpg-authorized-keys: a refresh is already running" >&2
          exit 0
        fi
      else
        flock 9
      fi
      status=0

      update_user() {
        local user=$1 primary=$2 min=$3 keys=$4
        shift 4
        local dir="$state/$user" home="$state/$user/gnupg"
        local out="$dir/authorized_keys" tmp="$dir/authorized_keys.new"
        install -d -m 755 -o root "$dir"
        install -d -m 700 -o root "$home"
        local gpg=(gpg --homedir "$home" --batch --no-tty)

        cat > "$home/gpg.conf" <<'EOF'
      trust-model pgp
      # Only the keys this job asks for; never a URL named in a key.
      auto-key-locate local
      no-auto-key-retrieve
      keyserver-options no-honor-keyserver-url
      EOF
        # Keys come only from the .onion keyserver, through Tor's SocksPort
        # (127.0.0.1:9050). An onion keyserver needs no DNS (dirmngr skips SRV
        # and A lookups for .onion), and the nameserver points at loopback so
        # any other Tor-mode lookup fails instead of reaching a public
        # resolver (dirmngr's Tor-mode default is 8.8.8.8).
        cat > "$home/dirmngr.conf" <<'EOF'
      use-tor
      keyserver ${cfg.keyserver}
      nameserver 127.0.0.1
      EOF

        # Fail closed: if anything below fails, the user's list is removed and
        # no key is accepted until a refresh succeeds. Until then the previous
        # list stays in place (a slow keyserver fetch doesn't lock anyone
        # out), and the new one replaces it in one rename.
        # (Called in an || list, so errexit is off here: check every step.)
        deny() {
          echo "gpg-authorized-keys: $user: $1; accepting no keys" >&2
          gpgconf --homedir "$home" --kill all >/dev/null 2>&1 || true
          rm -f "$out" "$tmp"
          return 1
        }
        rm -f "$tmp"

        # Trust is recomputed from scratch: the primary is the only root.
        rm -f "$home/trustdb.gpg"
        if ! printf '%s:6:\n' "$primary" | "''${gpg[@]}" --import-ownertrust; then
          deny "setting the trust root failed"
          return 1
        fi

        for seed in "$@"; do
          "''${gpg[@]}" --import "$seed" || echo "gpg-authorized-keys: $user: importing $seed failed" >&2
        done
        if [ "$online" = 1 ]; then
          # shellcheck disable=SC2086 # $keys is a list of fingerprints
          if ! "''${gpg[@]}" --recv-keys "$primary" $keys; then
            echo "gpg-authorized-keys: $user: keyserver refresh failed; using the keys already here" >&2
          fi
        fi

        local listing selected fpr pexp sexp expiry line
        if ! "''${gpg[@]}" --check-trustdb ||
          ! listing=$("''${gpg[@]}" --with-colons --fixed-list-mode --list-keys); then
          deny "reading the keyring failed"
          return 1
        fi
        gpgconf --homedir "$home" --kill all || true
        selected=$(
          awk -F: -v min="$min" '
            function rank(v) { return v == "u" ? 3 : v == "f" ? 2 : v == "m" ? 1 : 0 }
            function emit() {
              if (want && fpr != "") print fpr, (pexp == "" ? "0" : pexp), (sexp == "" ? "0" : sexp)
              want = 0; fpr = ""
            }
            $1 == "pub" {
              emit()
              keyok = rank($2) >= min && $12 !~ /D/
              pexp = $7
              sexp = $7
              want = keyok && $12 ~ /a/
              next
            }
            $1 == "sub" {
              emit()
              sexp = $7
              want = keyok && $2 != "r" && $2 != "e" && $2 != "i" && $12 ~ /a/
              next
            }
            $1 == "fpr" && fpr == "" { fpr = $10; next }
            END { emit() }
          ' <<< "$listing"
        ) || { deny "selecting the keys failed"; return 1; }
        : > "$tmp" || { deny "writing $tmp failed"; return 1; }
        while read -r fpr pexp sexp; do
          [ -n "$fpr" ] || continue
          # The earlier of the key's and the subkey's expiry (0: never).
          expiry=$sexp
          if [ "$pexp" != 0 ] && { [ "$expiry" = 0 ] || [ "$pexp" -lt "$expiry" ]; }; then
            expiry=$pexp
          fi
          if line=$("''${gpg[@]}" --export-ssh-key "$fpr!"); then
            printf '%s %s\n' "$expiry" "$line" >> "$tmp"
          else
            # One fewer key (e.g. an algorithm SSH has no form for), not none.
            echo "gpg-authorized-keys: $user: no SSH form for subkey $fpr; skipped" >&2
          fi
        done <<< "$selected"
        gpgconf --homedir "$home" --kill all || true
        if ! chmod 644 "$tmp" || ! mv -f "$tmp" "$out"; then
          deny "installing the new list failed"
          return 1
        fi
        echo "gpg-authorized-keys: $user: $(wc -l < "$out") key(s)" >&2
      }

      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: u: "${updateUser name u} || status=1") users
      )}
      exit "$status"
    '';
  };

  # sshd's AuthorizedKeysCommand: prints the user's accepted keys that have
  # not expired. Reads only root-owned files; no network, no gpg.
  commandScript =
    {
      # nix-darwin's static keys, which it otherwise prints with its own
      # AuthorizedKeysCommand (sshd runs only one).
      staticKeysDir ? null,
    }:
    pkgs.writeShellScript "gpg-authorized-keys-command" ''
      PATH=${
        lib.makeBinPath [
          pkgs.coreutils
          pkgs.gawk
        ]
      }
      user=$1
      case "$user" in
        "" | .* | *[!A-Za-z0-9._-]*) exit 1 ;;
      esac
      ${lib.optionalString (staticKeysDir != null) ''
        if [ -f ${staticKeysDir}/"$user" ]; then
          cat ${staticKeysDir}/"$user"
        fi
      ''}
      file=${lib.escapeShellArg cfg.stateDir}/"$user"/authorized_keys
      [ -f "$file" ] || exit 0
      awk -v now="$(date +%s)" '
        $1 ~ /^[0-9]+$/ && ($1 == 0 || $1 > now) { sub(/^[0-9]+ /, ""); print }
      ' "$file"
    '';
in
{
  options.users.users = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule userOptions);
  };

  options.gpgAuthorizedKeys = {
    keyserver = lib.mkOption {
      type = lib.types.str;
      default = "hkp://zkaan2xfbuxia2wpf7ofnkbz6r5zdbbvxbunvp5g2iebopbfc4iqmbad.onion";
      description = "Keyserver for the refresh, reached through Tor only (dirmngr use-tor).";
    };
    stateDir = lib.mkOption {
      type = lib.types.str;
      description = "Root-owned directory for the keyrings and the generated key lists.";
    };
    enable = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      default = users != { };
      description = "Whether any user has gpgAuthorizedKeys set.";
    };
    updateScript = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
      default = updateScript;
    };
    commandScript = lib.mkOption {
      type = lib.types.raw;
      readOnly = true;
      internal = true;
      default = commandScript;
    };
  };
}
