{
  config,
  lib,
  pkgs,
  ...
}:

let
  keychainService = "org.pandapip1.keepass-sync";

  storeKeepassPassword = pkgs.writeShellApplication {
    name = "keepass-sync-store-password";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      if (( $# == 0 )); then
        echo "Usage: keepass-sync-store-password DATABASE.kdbx [...]" >&2
        exit 2
      fi

      for database in "$@"; do
        database=$(basename "$database")
        read -r -s -p "Password for $database: " password
        printf '\n'
        /usr/bin/security add-generic-password -U \
          -a "$database" \
          -s "${keychainService}" \
          -w "$password"
        unset password
      done
    '';
  };

  keepassMerge = pkgs.writeShellApplication {
    name = "keepass-merge";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnupg
      pkgs.keepassxc
    ];
    text = ''
      # Git passes the ancestor for completeness, but KeePassXC performs its
      # own UUID/history-aware merge of the two database snapshots.
      _ancestor=$1
      current=$2
      other=$3
      database_path=$4

      ${
        if pkgs.stdenv.hostPlatform.isDarwin then
          ''
            if ! password=$(/usr/bin/security find-generic-password \
              -a "$database_path" -s "${keychainService}" -w); then
              echo "No macOS Keychain password is stored for $database_path." >&2
              echo "Run: keepass-sync-store-password '$database_path'" >&2
              exit 1
            fi
          ''
        else
          ''
            password_file="''${database_path%.kdbx}.pass.gpg"
            if [[ ! -f "$password_file" ]]; then
              echo "Cannot merge $database_path: $password_file does not exist" >&2
              exit 1
            fi
            password=$(gpg --quiet --batch --decrypt "$password_file")
          ''
      }
      printf '%s\n' "$password" \
        | keepassxc-cli merge --quiet --same-credentials "$current" "$other"
    '';
  };

  keepassSync = pkgs.writeShellApplication {
    name = "keepass-sync";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.git
    ];
    text = ''
      repo="$HOME/KeePass"
      if [[ ! -d "$repo/.git" ]]; then
        echo "$repo is not a Git checkout; skipping KeePass sync" >&2
        exit 0
      fi

      cd "$repo"
      lock_dir=.git/keepass-sync.lock
      if ! mkdir "$lock_dir" 2>/dev/null; then
        echo "Another KeePass sync is already running; skipping"
        exit 0
      fi

      cleanup() {
        status=$?
        if [[ $status -ne 0 ]] && [[ -f .git/MERGE_HEAD ]]; then
          git merge --abort || true
        fi
        rmdir "$lock_dir"
        exit "$status"
      }
      trap cleanup EXIT INT TERM

      branch=$(git symbolic-ref --quiet --short HEAD) || {
        echo "KeePass checkout has a detached HEAD" >&2
        exit 1
      }

      # Make changes made by KeePassXC durable before incorporating work from
      # other devices. Service commits deliberately do not require a GUI
      # pinentry, even when interactive commits are normally signed.
      git add --all
      if ! git diff --cached --quiet; then
        git -c commit.gpgsign=false commit -m "Automatic KeePass backup from $branch"
      fi

      git fetch --prune origin
      git config --local merge.keepass.name "KeePassXC database merge"
      git config --local merge.keepass.driver \
        "${lib.getExe keepassMerge} %O %A %B %P"

      mapfile -t remote_branches < <(
        git for-each-ref --format='%(refname:strip=3)' refs/remotes/origin \
          | while IFS= read -r remote_branch; do
              [[ "$remote_branch" == "HEAD" ]] || printf '%s\n' "$remote_branch"
            done
      )
      if [[ ! " ''${remote_branches[*]} " =~ " $branch " ]]; then
        remote_branches+=("$branch")
      fi

      for remote_branch in "''${remote_branches[@]}"; do
        remote_ref="refs/remotes/origin/$remote_branch"
        # The active device branch may not have been published yet.
        git show-ref --verify --quiet "$remote_ref" || continue
        if ! git merge-base --is-ancestor "$remote_ref" HEAD; then
          git -c commit.gpgsign=false merge --no-edit "$remote_ref"
        fi
      done

      # HEAD now descends from every fetched branch. Updating all branch refs
      # to that one commit keeps their histories and database bytes in sync.
      push_args=()
      for remote_branch in "''${remote_branches[@]}"; do
        push_args+=("HEAD:refs/heads/$remote_branch")
      done
      if (( ''${#push_args[@]} )); then
        git push --atomic origin "''${push_args[@]}"
      fi
    '';
  };
in
{
  home-manager.users.gavin = {
    home.packages = lib.optional pkgs.stdenv.hostPlatform.isDarwin storeKeepassPassword;

    systemd.user = lib.mkIf (config.moduleClass == "nixos") {
      services.keepass-sync = {
        Unit.Description = "Synchronize KeePass databases across device branches";
        Service = {
          Type = "oneshot";
          ExecStart = lib.getExe keepassSync;
        };
      };
      timers.keepass-sync = {
        Unit.Description = "KeePass database synchronization schedule";
        Timer = {
          OnBootSec = "30s";
          OnUnitActiveSec = "15m";
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };

    launchd.agents.keepass-sync = lib.mkIf (config.moduleClass == "darwin") {
      enable = true;
      config = {
        ProgramArguments = [ (lib.getExe keepassSync) ];
        RunAtLoad = true;
        StartInterval = 900;
        ProcessType = "Background";
        StandardOutPath = "/tmp/keepass-sync.log";
        StandardErrorPath = "/tmp/keepass-sync.error.log";
      };
    };
  };
}
