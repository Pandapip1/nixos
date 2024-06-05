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
        github.codespaces
        # Accessibility
        github.copilot
        github.copilot-chat
        # Languages
        ms-python.python
        vscode-extensions.james-yu.latex-workshop
        bbenoist.nix
        rust-lang.rust-analyzer
        reditorsupport.r
      ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "remote-ssh-edit";
          publisher = "ms-vscode-remote";
          version = "0.47.2";
          sha256 = "1hp6gjh4xp2m1xlm1jsdzxw9d8frkiidhph6nvl24d0h8z34w49g";
        }
      ];
    })
  ];
}