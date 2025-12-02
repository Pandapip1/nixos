{
  security.rtkit = {
    enable = true;
    args = [
      # https://github.com/heftig/rtkit/issues/13
      "--no-canary"
    ];
  };
}
