{
  pkgs,
  ...
}:

{
  /*
  home-manager.users.gavin = {
    systemd.user = {
      timers = {
        keepass-backup = {
          Unit.Description = "KeePassXC backup schedule";
          Timer = {
            OnBootSec = "30sec";
            OnUnitActiveSec = "15min";
          };
          Install.WantedBy = [ "timers.target" ];
        };
      };
      services = {
        keepass-backup = {
          Unit.Description = "Back up KeePassXC";
          Install = {
            WantedBy = [ "default.target" ];
          };
          Service.ExecStart = toString (pkgs.writeShellScript "keepassxc-backup" ''
            #!${lib.getExe pkgs.bash}
            pushd $HOME/KeePass
            if [[ -n $(git status --porcelain) ]]; then
              echo "Local changes detected. Committing and pushing..."
              git add -A
              git commit -m "Automatic KeePassXC backup"
              git push
            else
              echo "No local changes. Pulling latest from remote..."
              git pull
          '');
        };
      };
    };
  };
  */
}
