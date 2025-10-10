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
      # GitHub Integration
      github.vscode-pull-request-github
      github.vscode-github-actions
      # GitLab Integration
      gitlab.gitlab-workflow
      # Remote Development
      ms-azuretools.vscode-docker
      ms-vscode-remote.remote-ssh
      ms-vscode-remote.remote-ssh-edit
      github.codespaces
      # Languages
      ms-python.python
      james-yu.latex-workshop
      bbenoist.nix
      # rust-lang.rust-analyzer
      reditorsupport.r
      chrischinchilla.vscode-pandoc
      llvm-vs-code-extensions.vscode-clangd
      ms-vscode.cmake-tools
      myriad-dreamin.tinymist
      (pkgs.vscode-utils.buildVscodeMarketplaceExtension {
        mktplcRef = {
          name = "vscode-ros";
          publisher = "ms-iot";
          version = "0.9.6";
          hash = "sha256-ZsGBzfLzRFzSWx4vttfXPb6gSrFBy+QUDz9hkAdKMCw=";
        };
      })
      # (pkgs.vscode-utils.buildVscodeMarketplaceExtension {
      #   mktplcRef = {
      #     name = "pddltools";
      #     publisher = "kristianskovjohansen";
      #     version = "1.6.0";
      #   };
      # })
      # "AI"
      # continue.continue
    ];
  };
}
