{
  pkgs,
  ...
}:

{
  programs.vscode = {
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
      rust-lang.rust-analyzer
      reditorsupport.r
      chrischinchilla.vscode-pandoc
      # Language Packs
      vscjava.vscode-java-pack
      # "AI"
      continue.continue
    ];
  };
}
