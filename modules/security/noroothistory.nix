{
  pkgs,
  ...
}:

{
  environment.profiles = [
    (pkgs.writeScriptBin "no-root-history" ''
      if [ "$(id -u)" -eq 0 ]; then
        unset HISTFILE
        export HISTSIZE=0
        export HISTFILESIZE=0
      fi
    '')
  ];
}
