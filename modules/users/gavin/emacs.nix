{
  pkgs,
  ...
}:

{
  home-manager.users.gavin.programs.emacs = {
    enable = true;
    package = pkgs.emacs-pgtk;
    extraPackages =
      epkgs: with epkgs; [
        use-package
        treemacs
        magit
        vterm
        which-key
        doom-themes
      ];
    extraConfig = ''
      (tab-bar-mode 1)
      (setq tab-bar-show 1)

      (use-package treemacs
        :bind (("C-c t t" . treemacs)
               ("C-c t d" . treemacs-select-directory)))

      (use-package magit
        :bind (("C-c g g" . magit-status)))

      (use-package vterm
        :bind (("C-c t v" . vterm)))

      (use-package which-key
        :config (which-key-mode))

      (use-package doom-themes
        :config (load-theme 'doom-one t))
    '';
  };
}
