{
  environment.shellInit = ''
    # Disable storing root's executed commands
    if [ "$(id -u)" -eq 0 ]; then
      HISTSIZE=0
      HISTFILESIZE=0
      export HISTSIZE
      export HISTFILESIZE
    fi
  '';
}
