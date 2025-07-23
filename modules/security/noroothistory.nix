{
  environment.etc."profile.d".no-root-history = {
    text = ''
      if [ "$(id -u)" -eq 0 ]; then
        unset HISTFILE
        export HISTSIZE=0
        export HISTFILESIZE=0
      fi
    '';
    mode = "0555";
  };
}
