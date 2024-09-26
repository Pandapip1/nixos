{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    (vscode-with-extensions.override {
      vscode = vscodium;
      vscodeExtensions = with vscode-extensions; [
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
        # Accessibility
        github.copilot
        github.copilot-chat
        # Languages
        ms-python.python
        james-yu.latex-workshop
        bbenoist.nix
        rust-lang.rust-analyzer
        reditorsupport.r
        # Language Packs
        vscjava.vscode-java-pack
      ];
    })
  ];
}