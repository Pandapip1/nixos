{
  lib,
  pkgs,
  config,
  ...
}:

{
  programs.vscode = {
    enable = lib.mkDefault config.services.graphical-desktop.enable;
    package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions; [
      # Forge Integrations
      github.vscode-pull-request-github # github
      github.vscode-github-actions # github
      gitlab.gitlab-workflow # gitlab
      # Remote Development
      ms-azuretools.vscode-docker
      ms-vscode-remote.remote-ssh
      ms-vscode-remote.remote-ssh-edit
      github.codespaces
      # Nix-specific
      arrterian.nix-env-selector
      # Languages
      ms-python.python
      james-yu.latex-workshop
      jnoortheen.nix-ide
      reditorsupport.r
      reditorsupport.r-syntax
      chrischinchilla.vscode-pandoc # markdown
      llvm-vs-code-extensions.vscode-clangd # c, cpp
      myriad-dreamin.tinymist # typst
      (pkgs.vscode-utils.buildVscodeMarketplaceExtension {
        mktplcRef = {
          name = "vscode-ros";
          publisher = "ms-iot";
          version = "0.9.6";
          hash = "sha256-ZsGBzfLzRFzSWx4vttfXPb6gSrFBy+QUDz9hkAdKMCw=";
        };
      })
      # rust-lang.rust-analyzer
      # (pkgs.vscode-utils.buildVscodeMarketplaceExtension {
      #   mktplcRef = {
      #     name = "pddltools";
      #     publisher = "kristianskovjohansen";
      #     version = "1.6.0";
      #   };
      # })
      # "AI"
      continue.continue
    ];
  };
}
