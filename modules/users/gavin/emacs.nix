{
  pkgs,
  ...
}:

{
  home-manager.users.gavin.programs.emacs = {
    enable = true;
    package = pkgs.emacs30-nox;
    extraPackages =
      epkgs: with epkgs; [
        use-package
        treemacs
        magit
        vterm
        which-key
        hydra
      ];
    extraConfig = ''
      (xterm-mouse-mode 1)
      (tab-bar-mode 1)
      (setq tab-bar-show 1)

      ;; === FILE TREE ===
      (use-package treemacs
        :bind (("C-c t" . treemacs))
        :config
        (setq treemacs-width 30)
        (setq treemacs-follow-mode t))

      ;; === GIT ===
      (use-package magit
        :bind (("C-c g" . magit-status))
        :config
        ;; Force magit to open in a proper window
        (setq magit-display-buffer-function
              #'magit-display-buffer-fullframe-status-v1))

      ;; === TERMINAL (always bottom of frame) ===
      (use-package vterm
        :config
        (add-to-list 'display-buffer-alist
          '("\\*vterm\\*"
            (display-buffer-in-side-window)
            (side . bottom)
            (slot . 0)
            (window-height . 0.3)))

        (defun my-vterm-bottom ()
          "Open vterm pinned to bottom of frame."
          (interactive)
          (let ((buf (get-buffer-create "*vterm*")))
            (unless (get-buffer-process buf)
              (with-current-buffer buf (vterm-mode)))
            (display-buffer buf)))

        (global-set-key (kbd "C-`") #'my-vterm-bottom)
        (global-set-key (kbd "C-c v") #'my-vterm-bottom))

      ;; === HYDRA MENU ===
      (use-package hydra
        :bind (("C-c m" . my-menu/body))
        :config
        (defhydra my-menu (:color blue :hint nil)
          "
      _t_: File Tree    _g_: Git    _v_: Terminal    _q_: Quit
          "
          ("t" treemacs)
          ("g" magit-status)
          ("v" my-vterm-bottom)
          ("q" nil :color blue)))

      ;; === HEADER LINE (tree + git only) ===
      (defun my-header-button (label action)
        (propertize label
                    'mouse-face 'highlight
                    'help-echo (symbol-name action)
                    'local-map (let ((map (make-sparse-keymap)))
                                (define-key map [header-line mouse-1] action)
                                map)))

      (defun my-set-header-line ()
        (setq header-line-format
          (list
            (my-header-button " [tree] " #'treemacs)
            (my-header-button " [git] "  #'magit-status))))

      (add-hook 'after-change-major-mode-hook #'my-set-header-line)

      ;; === MODELINE (term only) ===
      (defun my-modeline-button (label action)
        (propertize label
                    'mouse-face 'mode-line-highlight
                    'help-echo (symbol-name action)
                    'local-map (make-mode-line-mouse-map 'mouse-1 action)))

      (setq-default mode-line-format
        (list
          '(:eval (my-modeline-button " [term] " #'my-vterm-bottom))
          "  "
          mode-line-modified
          "  "
          mode-line-buffer-identification
          "  "
          mode-line-modes
          "  "
          mode-line-end-spaces))

      ;; === STARTUP LAYOUT ===
      (add-hook 'after-init-hook
        (lambda ()
          (treemacs)
          (other-window 1))
        t)
    '';
  };
}
