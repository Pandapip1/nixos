{
  pkgs,
  ...
}:

{
  home-manager.users.gavin.programs.emacs = {
    enable = true;
    package = pkgs.emacs-nox;
    extraPackages =
      epkgs: with epkgs; [
        use-package
        treemacs
        magit
        vterm
        which-key
        hydra
        kkp
      ];
    extraConfig = ''
      ;; === BASIC SETTINGS ===
      (xterm-mouse-mode 1)
      (tab-bar-mode 1)
      (setq tab-bar-show 1)
      (use-package kkp
        :ensure t
        :hook (tty-setup . global-kkp-mode)
        :config
        ;; (setq kkp-alt-modifier 'alt) ;; use this if you want to map the Alt keyboard modifier to Alt in Emacs (and not to Meta)
        )

      ;; === SIDE WINDOW RULES ===
      (add-to-list 'display-buffer-alist
        '((lambda (buf _)
            (with-current-buffer buf
              (derived-mode-p 'magit-mode)))
          (display-buffer-in-side-window)
          (side . left)
          (slot . 0)
          (window-width . 35)))

      (add-to-list 'display-buffer-alist
        '("\\*vterm\\*"
          (display-buffer-in-side-window)
          (side . bottom)
          (slot . 0)
          (window-height . 0.3)))

      ;; === FILE TREE ===
      (use-package treemacs
        :bind (("C-c t" . my-open-treemacs))
        :config
        (setq treemacs-width 35)
        (setq treemacs-follow-mode t))

      ;; === GIT ===
      (use-package magit
        :bind (("C-c g" . my-open-magit)))

      ;; === TERMINAL ===
      (use-package vterm
        :config
        (defun my-vterm-bottom ()
          "Toggle vterm pinned to bottom of frame."
          (interactive)
          (if-let ((win (get-buffer-window "*vterm*")))
            (delete-window win)
            (let ((buf (get-buffer-create "*vterm*")))
              (unless (get-buffer-process buf)
                (with-current-buffer buf (vterm-mode)))
              (display-buffer buf))))
        (global-set-key (kbd "C-`") #'my-vterm-bottom)
        (global-set-key (kbd "C-c v") #'my-vterm-bottom))

      ;; === MUTUAL EXCLUSION TOGGLES ===
      (defun my-open-treemacs ()
        "Close all magit buffers and open treemacs."
        (interactive)
        (dolist (buf (buffer-list))
          (when (with-current-buffer buf (derived-mode-p 'magit-mode))
            (kill-buffer buf)))
        (treemacs))

      (defun my-open-magit ()
        "Close treemacs and open magit."
        (interactive)
        (when (treemacs-get-local-window)
          (treemacs))
        (magit-status))

      ;; === HEADER LINE ===
      (defun my-header-button (label action)
        (propertize label
                    'mouse-face 'highlight
                    'help-echo (symbol-name action)
                    'local-map (let ((map (make-sparse-keymap)))
                                 (define-key map [header-line mouse-1] action)
                                 map)))

      (defun my-set-header-line ()
        (if (derived-mode-p 'treemacs-mode
                            'magit-mode
                            'magit-status-mode)
          (progn
            (face-remap-add-relative 'header-line 'header-line)
            (face-remap-add-relative 'magit-header-line
              '(:inherit header-line :weight normal :foreground unspecified))
            (setq header-line-format
              (list
                (my-header-button " [tree] " #'my-open-treemacs)
                (my-header-button " [git] "  #'my-open-magit))))
          (setq header-line-format nil)))

      (add-hook 'after-change-major-mode-hook #'my-set-header-line)
      (add-hook 'find-file-hook #'my-set-header-line)

      ;; === MODELINE ===
      ;; Set [term] globally as default so all buffers get it
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

      ;; Override locally for side buffers to strip [term]
      (defun my-set-mode-line ()
        (when (derived-mode-p 'treemacs-mode
                              'magit-mode
                              'magit-status-mode
                              'vterm-mode)
          (setq-local mode-line-format
            (list
              mode-line-modified
              "  "
              mode-line-buffer-identification
              "  "
              mode-line-modes))))

      (add-hook 'after-change-major-mode-hook #'my-set-mode-line)
      (add-hook 'find-file-hook #'my-set-mode-line)

      ;; === HYDRA MENU ===
      (use-package hydra
        :bind (("C-c m" . my-menu/body))
        :config
        (defhydra my-menu (:color blue :hint nil)
          "
      _t_: File Tree    _g_: Git    _v_: Terminal    _q_: Quit
          "
          ("t" my-open-treemacs)
          ("g" my-open-magit)
          ("v" my-vterm-bottom)
          ("q" nil :color blue)))

      ;; === WHICH-KEY ===
      (use-package which-key
        :config (which-key-mode))

      ;; === STARTUP LAYOUT ===
      (add-hook 'after-init-hook
        (lambda ()
          (treemacs)
          (other-window 1))
        t)
    '';
  };
}
