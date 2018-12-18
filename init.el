;; init.el -- Patrick Thomson's emacs config. -*- lexical-binding: t; -*-

;;; Commentary:
;; This file is in the public domain.

;;; Code:

;; To start, we temporarily disable GC limits.

(defvar old-cons-threshold gc-cons-threshold)
(setq gc-cons-threshold 100000000)

(setq debug-on-error t          ;; If we encounter an error, don't just croak and die
      max-list-eval-depth 2000) ;; Bump up the recursion limit.

;; Package-initialization preamble, adding melpa and melpa-stable.

(require 'package)

(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/") t)
(add-to-list 'package-archives '("melpa-stable" . "http://stable.melpa.org/packages/") t)

(package-initialize)

;; Ensure use-package is present. From here on out, all packages are loaded
;; with use-package.

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-initialize)
  (package-install 'use-package))

(setq use-package-always-ensure t
      use-package-verbose t)

;; Fullscreen by default, as early as possible.

(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; Use Fira Code, my favorite monospaced/ligatured font, handling its absence gracefully.

(ignore-errors
  (set-frame-font "Fira Code Retina-14"))

;; Any Customize-based settings should live in custom.el, not here.

(setq custom-file "~/.emacs.d/custom.el")
(load custom-file 'noerror)

;; Always prefer newer files.

(setq
 load-prefer-newer t)

;; Disable otiose GUI settings: they just waste space.
;; fringe-mode is especially ruinous performance-wise.

(when (window-system)
  (tool-bar-mode -1)
  (scroll-bar-mode -1)
  (tooltip-mode -1)
  (fringe-mode -1))

;;
(use-package diminish
  :ensure t)

;; The Doom Emacs themes look really good.

(use-package doom-themes
  :config
  (load-theme 'doom-tomorrow-night)
  (doom-themes-visual-bell-config)
  (doom-themes-org-config)
  (setq org-hide-leading-stars nil)



  (custom-theme-set-faces
   'doom-tomorrow-night
   '(font-lock-doc-face ((t (:foreground "#D8D2C1"))))))

;; Number the windows.
(use-package winum
  :init (winum-mode)
  ;; I usually just use C-, for this
  :bind (("C-c w" . winum-select-window-by-number)))

(use-package spaceline
  :config
  (spaceline-spacemacs-theme))

;; Ace-window is a nice way to switch between frames quickly.

(use-package ace-window
  :disabled ; trying out winum-mode
  :bind (("C-," . ace-window)))

;; Ensure that items in the PATH are made available to Emacs. This should
;; probably just come with the main distribution.

(use-package exec-path-from-shell
  :config
  (exec-path-from-shell-initialize))

;; Dim inactive buffers.

(use-package dimmer
  :config
  (setq dimmer-fraction 0.15)
  (dimmer-mode))

;; Recentf comes with Emacs but it should always be enabled.

(recentf-mode t)
(add-to-list 'recentf-exclude "\\.emacs.d")
(add-to-list 'recentf-exclude ".+tmp......\\.org")

;; Ivy makes most minibuffer prompts sortable and filterable. I used
;; to use helm, but it was too slow. Unfortunately org-ref depends on
;; it, but I never load it, so we good.

(use-package ivy
  :ensure t
  :init
  (ivy-mode 1)
  (setq ivy-height 30
        ivy-use-virtual-buffers t
        ivy-use-selectable-prompt t)
  (defun swiper-at-point ()
    (interactive)
    (swiper (thing-at-point 'word)))
  :bind (("C-x b"   . ivy-switch-buffer)
         ("C-c C-r" . ivy-resume)
         ("C-c s"   . swiper-at-point)
         ("C-s"     . swiper))
  :diminish)

;; ivy-rich makes Ivy look a little bit more like Helm.

(use-package ivy-rich
  :after counsel
  :custom
  (ivy-virtual-abbreviate 'full
   ivy-rich-switch-buffer-align-virtual-buffer t
   ivy-rich-path-style 'abbrev)
  :init
  (ivy-rich-mode))

(use-package ivy-hydra
  :disabled
  :after ivy)

;; Counsel applies Ivy-like behavior to other builtin features of
;; emacs, e.g. search.

(use-package counsel
  :ensure t
  :after ivy
  :config
  (counsel-mode 1)
  (defun counsel-rg-at-point ()
    (interactive)
    (let ((selection (thing-at-point 'word)))
      (if (<= 4 (length selection))
          (counsel-rg selection)
        (counsel-rg))))
  :bind (("C-c ;" . counsel-M-x)
         ("C-c U" . counsel-unicode-char)
         ("C-c h" . counsel-rg)
         ("C-c H" . counsel-rg-at-point)
         ("C-c i" . counsel-imenu)
         ("C-x f" . counsel-find-file)
         ("C-c y" . counsel-yank-pop)
	 ("C-c r" . counsel-recentf)
         :map ivy-minibuffer-map
         ("C-r" . counsel-minibuffer-history))
  :diminish)

;; projectile comes with Emacs these days, but we want to enable
;; caching.

(use-package projectile
  :config
  (setq projectile-enable-caching t
        projectile-completion-system 'ivy)
  :diminish)

;; Counsel and projectile should work together.

(use-package counsel-projectile
  :bind (("C-c f" . counsel-projectile))
  :init
  ; This is a workaround until the below bugfix makes into melpa.
  ; https://github.com/ericdanan/counsel-projectile/pull/92
  (makunbound 'counsel-projectile-mode-map)
  (defvar counsel-projectile-mode-map
    (let ((map (make-sparse-keymap))
          (projectile-command-keymap (where-is-internal 'projectile-command-map nil t)))
      (when projectile-command-keymap
        (define-key map projectile-command-keymap 'counsel-projectile-command-map))
      (define-key map [remap projectile-find-file] 'counsel-projectile-find-file)
      (define-key map [remap projectile-find-dir] 'counsel-projectile-find-dir)
      (define-key map [remap projectile-switch-to-buffer] 'counsel-projectile-switch-to-buffer)
      (define-key map [remap projectile-grep] 'counsel-projectile-grep)
      (define-key map [remap projectile-ag] 'counsel-projectile-ag)
      (define-key map [remap projectile-switch-project] 'counsel-projectile-switch-project)
      map)
    "Keymap for Counsel-Projectile mode.")
  :config (counsel-projectile-mode))

;; If you don't use this, recent commands in ivy won't be shown first

(use-package smex)

;; Keychain stuff. Note to self: if you keep having to enter your
;; keychain password on OS X, make sure that you have the following in .ssh/config:
;; Host *
;;    UseKeychain yes

(use-package keychain-environment
  :config
  (keychain-refresh-environment))

;; Company is the best Emacs completion system, but I haven't sat down
;; and thought "okay, how am I going to implement this in my
;; workflow", which is a sign that I should leave this disabled.

(use-package company
  :bind (("C-." . company-complete))
  :diminish company-mode)

;; Textmate-style tap-to-expand-into-the-current-delimiter.

(use-package expand-region
  :bind (("C-c n" . er/expand-region)))

;; Magit is one of the best pieces of OSS I have ever used. It is truly esssential.

(use-package magit
  :bind (("C-c g" . magit-status))
  :diminish magit-auto-revert-mode
  :diminish auto-revert-mode
  :config
  (magit-auto-revert-mode t)
  (advice-add 'magit-refresh :before #'maybe-unset-buffer-modified)
  (setq magit-completing-read-function 'ivy-completing-read)
  (add-to-list 'magit-no-confirm 'stage-all-changes)
  (setq-default magit-last-seen-setup-instructions "1.4.0"))

;; Unclear whether this does anything at the moment.

(use-package libgit
  :after magit)

;; Since I grew up on Textmate, I'm more-or-less reliant on snippets.

(use-package yasnippet
  :config
  (yas-global-mode 1)
  (setq yas-prompt-functions '(yas-completing-prompt))
  :diminish yas-minor-mode)

;; I usually don't edit very large files, but saveplace is nice on the occasions I do.

(use-package saveplace
  :config (setq-default save-place t))

;; Haskell and Elisp are made a lot easier when delimiters are nicely color-coded.

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;; multiple-cursors is better than cua-selection-mode.
;; TODO: learn ace-mc

(use-package multiple-cursors
  :bind (("C-c M" . mc/edit-lines)))

;; Common Haskell snippets. These take a while to load, so no need to block on startup.

(use-package haskell-snippets
  :defer yasnippet)

;; The beauty of undo-tree is that it means that, once you've typed something into
;; a buffer, you'll always be able to get it back. That is crucial.

(use-package undo-tree
  :bind (("C-c _" . undo-tree-visualize))
  :config
  (global-undo-tree-mode +1)
  (unbind-key "M-_" undo-tree-map)
  :diminish)

;; (use-package ansi-color
;;   :config
;;   (add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on))

;; C stuff.

(use-package cc-mode)

;; I do all of my writing in either org-mode or markdown-mode.

(use-package markdown-mode
  :mode ("\\.md$" . gfm-mode)
  :config
  (when (executable-find "pandoc")
    (setq markdown-command "pandoc -f markdown -t html")))

;; Avy is better than ace-jump.
(use-package avy
  :defer ivy
  :bind (("C-l"   . avy-goto-line)
         ("C-c j" . avy-goto-word-1)
         ("C-'"   . ivy-avy)))

;; YAML is underappreciated.

(use-package yaml-mode)

;; Quickly duplicate whatever's under the cursor. I'm shocked this requires a
;; third-party package; it should be standard.

(use-package duplicate-thing
  :bind (("C-c u" . duplicate-thing)))

;; I can never remember the hierarchies of certain bindings, like C-x v for version control
;; stuff. Guide-key helps there. (TODO: figure out other places it'll help.)

(use-package guide-key
  :config
  (guide-key-mode t)
  (setq guide-key/guide-key-sequence '("C-x v"   ;; version control
                                       "C-c a")) ;; my mode-specific bindings
  :diminish guide-key-mode)

;; Since the in-emacs Dash browser doesn't work on OS X, we have to settle for dash-at-point.

(use-package dash-at-point
  :bind ("C-c d" . dash-at-point))

(use-package dumb-jump
  :bind (("C-c d" . dumb-jump-go)
	 ("C-c D" . dumb-jump-go-prompt))
  :config (setq dumb-jump-selector 'ivy))

;; OCaml is loaded not through melpa, but through OPAM itself.

(ignore-errors
  (autoload (expand-file-name "~/.opam/system/share/emacs/site-lisp/tuareg-site-file")))

(defun em-dash ()
  "Insert an em-dash."
  (interactive)
  (insert "—"))

(defun ellipsis ()
  "Insert an ellipsis."
  (interactive)
  (insert "…"))

(defun lambduh ()
  "Insert a lowercase lambda."
  (interactive)
  (insert "λ"))

;; I am very early on in my journey down the org-mode road.
;; But I like it a lot.

;; NOTE ORG-MODE STARTS HERE

(use-package org

  :diminish org-indent-mode

  :bind (:map org-mode-map
         ("M--"      . em-dash)
         ("M-;"      . ellipsis)
         ("C-c c"    . org-mode-insert-code)
         ("C-c a s"  . org-emphasize)
         ("C-c a r"  . org-ref)
         ("C-c a e"  . outline-show-all)
         ("C-c a l"  . lambduh)
         ("C-c a t"  . unindent-by-four))

  :hook (org-mode . visual-line-mode)

  :config

  (defun unindent-by-four ()
    (interactive)
    (indent-rigidly (region-beginning) (region-end) -4))
  
  (unbind-key "C-c ;" org-mode-map)
  (unbind-key "C-,"   org-mode-map)
  (unbind-key "M-<left>" org-mode-map)
  (unbind-key "M-<right>" org-mode-map)

  (let ((todo-path (expand-file-name "~/txt/todo.org")))
    (when (file-exists-p todo-path)
      (setq org-agenda-files (list todo-path)
            org-default-notes-file todo-path)))

  (setq org-footnote-section ""
        org-startup-with-inline-images t
        org-pretty-entities t
        org-ellipsis "…"
        org-startup-folded nil
        org-footnote-section nil
        )

  (setcar (nthcdr 4 org-emphasis-regexp-components) 4)

  (defun org-mode-insert-code ()
    (interactive)
    (org-emphasize ?~)))

(bind-key "C-c o c" 'org-capture)
(bind-key "C-c o n" 'open-semantic-notes)
(bind-key "C-c o s" 'org-store-link)
(bind-key "C-c o a" 'org-agenda)

(use-package org-ac
  :after org)

(use-package swift-mode
  :config
  (setq swift-mode:basic-offset 2))

(use-package org-ref
  :defer
  :config
  (ignore-errors (load-private-settings)))

(use-package ox-pandoc
  :after org
  :config
  (setq org-pandoc-format-extensions '(markdown+smart))

  ;; ;; Utterly brain-dead bullshit to enable org+smart as an input format.
  ;; (defun org-pandoc-run (input-file output-file format sentinel &optional options)
  ;;   (let* ((format (symbol-name format))
  ;;          (output-format
  ;;           (car (--filter (string-prefix-p format it)
  ;;                          org-pandoc-format-extensions-str)))
  ;;          (args
  ;;           `("-f" "org+smart"
  ;;             "-t" ,(or output-format format)
  ;;             ,@(and output-file
  ;;                    (list "-o" (expand-file-name output-file)))
  ;;             ,@(-mapcat (lambda (key)
  ;;                          (-when-let (vals (gethash key options))
  ;;                            (if (equal vals t) (setq vals (list t)))
  ;;                            (--map (concat "--" (symbol-name key)
  ;;                                           (when (not (equal it t)) (format "=%s" it)))
  ;;                                   vals)))
  ;;                        (ht-keys options))
  ;;             ,(expand-file-name input-file))))
  ;;     (message "Running pandoc with args: %s" args)
  ;;     (let ((process
  ;;            (apply 'start-process
  ;;                   `("pandoc" ,(generate-new-buffer "*Pandoc*")
  ;;                     ,org-pandoc-command ,@args))))
  ;;       (set-process-sentinel process sentinel)
  ;;       process)))

  )

(use-package wc-goal-mode
  :hook (org-mode . wc-goal-mode))

(use-package haskell-mode
  :config

  (defun haskell-right-arrow ()
    "Insert a right arrow."
    (interactive)
    (insert (if (eolp) " -> " "->")))

  (defun haskell-left-arrow ()
    "Insert a left arrow."
    (interactive)
    (insert (if (eolp) " <- " "<-")))

  (defun my-haskell-mode-hook ()
    "Make sure the compile command is right."
    (setq-local compile-command "stack build --fast"))

  (defun my-lithaskell-mode-hook ()
    "Turn off auto-indent for Literate Haskell snippets."
    (setq-local yas-indent-line nil))

  (setq haskell-font-lock-symbols-alist
        '(("\\" . "λ")
          ("not" . "¬")
          ("()" . "∅")
          ("!!" . "‼")
          ("&&" . "∧")
          ("||" . "∨")
          ("/=" . "≠")
          ("sqrt" . "√")
          ("undefined" . "⊥")
          ("pi" . "π")
          ("::" . "∷")
          ("." "∘" ;"○"
           ;; Need a predicate here to distinguish the . used by
           ;; forall <foo> . <bar>.
           haskell-font-lock-dot-is-not-composition)
          ("forall" . "∀")))

  (setq haskell-font-lock-symbols 't)

  :mode ("\\.hs$" . haskell-mode)

  :hook ((haskell-mode . my-haskell-mode-hook)
         (literate-haskell-mode-hook . my-lithaskell-mode-hook))

  :bind (:map haskell-mode-map
         ("C-c a c" . haskell-cabal-visit-file)
	 ("C-c a b" . haskell-mode-stylish-buffer)
         ("C-c a i" . haskell-navigate-imports)
         ("C-c a w" . stack-watch)
         ("C-c a ," . haskell-left-arrow)
         ("C-c a ." . haskell-right-arrow)))

(use-package intero
  :bind (:map haskell-mode-map
         ("C-c a r" . intero-repl)
         ("C-c a j" . intero-goto-definition)
         ("C-c a n" . intero-info)
         ("C-c a t" . intero-type-at)
         ("C-c a u" . intero-uses-at)
         ("C-c a s" . intero-apply-suggestions)))

;; My own mode for running stack build --file-watch
;; TODO: investigate why I have to use polling here.
;; Cobbled together from various sources, sic semper.

(define-minor-mode stack-watch-mode
  "A minor mode for stack build --file-watch."
  :lighter " stack watch"
  (compilation-minor-mode))

(defvar stack-watch-command
  "stack build semantic:lib --fast --file-watch-poll\n"
  "The command used to run stack-watch.")

(setq stack-watch-command "stack build semantic:lib --fast --file-watch-poll\n")

(defun get-or-create-stack-watch-buffer (buf-name)
  "Select the buffer with name BUF-NAME."
  (let ((stack-watch-buf (get-buffer-create buf-name)))
    (display-buffer
     stack-watch-buf
     '((display-buffer-pop-up-window
        display-buffer-reuse-window)
       (window-height . 25)))
    (select-window (get-buffer-window stack-watch-buf))))

(defun spawn-stack-watch (buf-name)
  "Spawn stack-watch inside the current buffer with BUF-NAME."
  (make-term (format "stack-watch: %s" (projectile-project-name)) "/bin/zsh")
  (term-mode)
  (term-line-mode)
  (setq-local compilation-down-aggressively t)
  (setq-local window-point-insertion-type t)
  (stack-watch-mode)
  (comint-send-string buf-name stack-watch-command))

(defun run-stack-watch (buf-name)
  "Run or display a stack-watch buffer with the given BUF-NAME."
  (let ((cur (selected-window))
        (buf-exists (get-buffer buf-name)))
    (progn
      (get-or-create-stack-watch-buffer buf-name)
      (if buf-exists (goto-char (point-max))
        (spawn-stack-watch buf-name))
      (select-window cur))))

(defun stack-watch-projectile-buf-name ()
  (format "*stack-watch: %s*" (projectile-project-name)))

(defun projectile-stack-watch-stop ()
  "Stop stack-watch for this project."
  (interactive)
  (let* ((buf-name (stack-watch-projectile-buf-name))
         (stack-watch-buf (get-buffer buf-name))
         (stack-watch-window (get-buffer-window stack-watch-buf))
         (stack-watch-proc (get-buffer-process stack-watch-buf)))
    (when stack-watch-buf
      (progn
        (when (processp stack-watch-proc)
          (progn
            (set-process-query-on-exit-flag stack-watch-proc nil)
            (kill-process stack-watch-proc)))))
        (select-window stack-watch-window)
        (kill-buffer-and-window)))

(defun projectile-stack-watch-switch-to-buffer ()
  "Switch to an active stack-watch buffer."
  (interactive)
  (projectile-with-default-dir (projectile-project-root)
    (let ((buf-name (stack-watch-projectile-buf-name)))
      (get-or-create-stack-watch-buffer buf-name))))

(defun stack-watch ()
  "Spawn stack-watch in the project root."
  (interactive)
  (projectile-with-default-dir (projectile-project-root)
    (let ((buf-name (stack-watch-projectile-buf-name)))
      (run-stack-watch buf-name))))

(use-package idris-mode
  :bind (("C-c C-v" . idris-case-split)))

(use-package typescript-mode)

(use-package protobuf-mode)

(defun my-elisp-mode-hook ()
  "My elisp customizations."
  (electric-pair-mode 1)
  (add-hook 'before-save-hook 'check-parens nil t)
  (auto-composition-mode nil))

(add-hook 'emacs-lisp-mode-hook 'my-elisp-mode-hook)

(defun open-init-file ()
  "Open this very file."
  (interactive)
  (find-file user-init-file))

(defun open-eshell-file ()
  (interactive)
  (find-file eshell-rc-script))

(defun open-semantic-notes ()
  "Open my notes file."
  (interactive)
  (find-file "~/txt/semantic.org"))

(defun kill-all-buffers ()
  "Close all buffers."
  (interactive)
  (maybe-unset-buffer-modified)
  (mapc 'kill-buffer (buffer-list)))

(defun split-right-and-enter ()
  "Split the window to the right and enter it."
  (interactive)
  (split-window-right)
  (other-window 1))

(defun switch-to-previous-buffer ()
  "Switch to previously open buffer.  Repeated invocations toggle between the two most recently open buffers."
  (interactive)
  (switch-to-buffer (other-buffer (current-buffer) 1)))

(defun display-startup-echo-area-message ()
  "Overrides the normally tedious error message."
  (message "Welcome back."))

(defun eol-then-newline ()
  "Go to end of line then return."
  (interactive)
  (move-end-of-line nil)
  (newline)
  (indent-for-tab-command))

;; There is an extant bug where magit-refresh prompts to save files that haven't
;; been modified. We work around this with some defadvice over maybe-unset-buffer-modified. SO:
;; https://emacs.stackexchange.com/questions/24011/make-emacs-diff-files-before-asking-to-save

(defun current-buffer-matches-file-p ()
  "Return t if the current buffer is identical to its associated file."
  (autoload 'diff-no-select "diff")
  (when buffer-file-name
    (diff-no-select buffer-file-name (current-buffer) nil 'noasync)
    (with-current-buffer "*Diff*"
      (and (search-forward-regexp "^Diff finished \(no differences\)\." (point-max) 'noerror) t))))

(defun maybe-unset-buffer-modified ()
  "Clear modified bit on all unmodified buffers."
  (interactive)
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when (and buffer-file-name (buffer-modified-p))
        (when (current-buffer-matches-file-p)
          (set-buffer-modified-p nil))))))

(defun kill-buffer-with-prejudice ()
  (interactive)
  (when (current-buffer-matches-file-p) (set-buffer-modified-p nil))
  (kill-buffer))

(defun my-goto-line ()
  "Go to a line and recenter the buffer."
  (interactive)
  (call-interactively 'goto-line)
  (recenter-top-bottom))

(bind-key "C-x k"      'kill-buffer-with-prejudice)
(bind-key "C-c e"      'open-init-file)
(bind-key "C-c k"      'kill-all-buffers)
(bind-key "s-<return>" 'eol-then-newline)
(bind-key "C-c 5"      'query-replace-regexp)
(bind-key "M-/"        'hippie-expand)
(bind-key "C-c '"      'switch-to-previous-buffer)
(bind-key "C-c \\"     'align-regexp)
(bind-key "C-c m"      'compile)
(bind-key "C-c 3"      'split-right-and-enter)
(bind-key "C-c /"      'comment-or-uncomment-region)
(bind-key "C-c t"      'shell)
(bind-key "C-c x"      'ESC-prefix)
(bind-key "C-,"        'other-window)
(bind-key "C-c l"      'my-goto-line)

(bind-key "C-c a p" 'profiler-start)
(bind-key "C-c a P" 'profiler-report)

;; macOS-style bindings, too (no cua-mode, it's nasty)
(bind-key "s-+"		'text-scale-increase)
(bind-key "s-_"		'text-scale-decrease)
(bind-key "s-s"         'save-buffer)
(bind-key "s-c"		'kill-ring-save)
(bind-key "s-v"		'yank)
(bind-key "s-z"		'undo)
(bind-key "s-a"		'mark-whole-buffer)
(bind-key "s-<"         'beginning-of-buffer)
(bind-key "s-x"         'kill-region)
(bind-key "<home>"      'beginning-of-buffer)
(bind-key "<end>"       'end-of-buffer)
(bind-key "s->"         'end-of-buffer)
(bind-key "M-_"         'em-dash)
(bind-key "M-;"         'ellipsis)
(bind-key "C-="         'next-error)

(unbind-key "C-z")
(unbind-key "C-<tab>")
(unbind-key "C-h n")

(defalias 'yes-or-no-p 'y-or-n-p)

(global-hl-line-mode t)              ; Always highlight the current line.
(show-paren-mode t)                  ; And point out matching parentheses.
(delete-selection-mode t)            ; Behave like any other sensible text editor would.
(column-number-mode t)               ; Show column information in the modeline.
(prettify-symbols-mode)              ; Use pretty Unicode symbols where possible.
(global-display-line-numbers-mode)   ; Emacs has this builtin now, it's fast
(mac-auto-operator-composition-mode) ; thanks, railwaycat

(setq
  compilation-always-kill t              ; Never prompt to kill a compilation session.
  compilation-scroll-output 'first-error ; Always scroll to the bottom.
  make-backup-files nil                  ; No backups, thanks.
  create-lockfiles nil                   ; Emacs sure loves to put lockfiles everywhere.
  default-directory "~/src"              ; My code lives here.
  inhibit-startup-screen t               ; No need to see GNU agitprop.
  kill-whole-line t                      ; Delete the whole line if C-k is hit at the beginning of a line.
  mac-command-modifier 'super            ; I'm not sure this is the right toggle, but whatever.
  require-final-newline t                ; Auto-insert trailing newlines.
  ring-bell-function 'ignore             ; Do not ding. Ever.
  use-dialog-box nil                     ; Dialogues always go in the modeline.
  frame-title-format "emacs – %b"        ; Put something useful in the status bar.
  initial-scratch-message nil            ; SHUT UP SHUT UP SHUT UP
  mac-option-modifier 'meta              ; why isn't this the default
  save-interprogram-paste-before-kill t  ; preserve paste to system ring
  enable-recursive-minibuffers t         ; don't fucking freak out if I use the minibuffer twice
  sentence-end-double-space nil          ; are you fucking kidding me with this shit
  scroll-conservatively 101              ; move minimum when cursor exits view, instead of recentering
  confirm-kill-processes nil             ; don't whine at me when I'm quitting.
  fast-but-imprecise-scrolling t         ; makes a difference
  mac-mouse-wheel-smooth-scroll nil      ; no smooth scrolling
  mac-drawing-use-gcd t                  ; and you can do it on other frames
  )

(setq-default
 cursor-type 'bar
 indent-tabs-mode nil
 cursor-in-non-selected-windows nil
 )

(add-to-list 'electric-pair-pairs '(?` . ?`)) ; electric-quote backticks

(set-fill-column 85)

;; Always trim trailing whitespace.

;; (add-hook 'before-save-hook 'delete-trailing-whitespace)

(defun open-notes-and-split ()
  "Open my notes and split the window."
  (when (eq system-type 'darwin)
    (split-window-horizontally)
    (other-window 1)
    (find-file "~/txt/todo.org")
    (other-window 1)))

(add-hook 'after-init-hook 'open-notes-and-split)

(setq debug-on-error nil)

(setq gc-cons-threshold 30000000)

(provide 'init)

;; goodbye, thanks for reading
