;;; idee-treemacs.el --- Treemacs integration

;; Author: Ioannis Canellos

;; Version: 0.0.1

;; Package-Requires: ((emacs "25.1"))

;;; Commentary:

;;; Code:

(defun idee-treemacs-collapse-dir-toggle ()
  "Toggle value of treemacs-collapse-dir between 3 0."
  (interactive)
  (if (= treemacs-collapse-dirs 0)
      (setq treemacs-collapse-dirs 3)
    (setq treemacs-collapse-dirs 0))
  (treemacs-refresh))

(defun idee-treemacs-create-and-switch-to-workspace ()
  "Create and switch to a new treemacs workspace."
  (interactive)
  (let* ((response (treemacs-do-create-workspace))
         (workspace (car (cdr response))))
    (setf (treemacs-current-workspace) workspace)
    ;; BEGIN: Copy and paste from treemacs-switch-workspace
    (let ((window-visible? nil)
          (buffer-exists? nil))
      (pcase (treemacs-current-visibility)
        ('visible
         (setq window-visible? t
               buffer-exists? t))
        ('exists
         (setq buffer-exists? t)))
      (when window-visible?
        (delete-window (treemacs-get-local-window)))
      (when buffer-exists?
        (kill-buffer (treemacs-get-local-buffer)))
      (when buffer-exists?
        (let ((treemacs-follow-after-init nil)
              (treemacs-follow-mode nil))
          (treemacs-select-window)))
      (when (not window-visible?)
        (bury-buffer)))
    (treemacs-pulse-on-success "Selected workspace %s."
      (propertize (treemacs-workspace->name workspace)))
    ;; END
    (idee-treemacs-open-project-workspace workspace)))

(defun idee-treemacs-switch-to-project-workspace ()
    "Select a different workspace for treemacs."
    (interactive)
    (pcase (treemacs-do-switch-workspace)
      ('only-one-workspace
       (treemacs-pulse-on-failure "There are no other workspaces to select."))
      (`(success ,workspace)
       (let ((window-visible? nil)
             (buffer-exists? nil))
         (pcase (treemacs-current-visibility)
           ('visible
            (setq window-visible? t
                  buffer-exists? t))
           ('exists
            (setq buffer-exists? t)))
         (when window-visible?
           (delete-window (treemacs-get-local-window)))
         (when buffer-exists?
           (kill-buffer (treemacs-get-local-buffer)))
         (when buffer-exists?
           (let ((treemacs-follow-after-init nil)
                 (treemacs-follow-mode nil))
             (treemacs-select-window)))
         (when (not window-visible?)
           (bury-buffer)))
       (treemacs-pulse-on-success "Selected workspace %s."
         (propertize (treemacs-workspace->name workspace))
         (idee-treemacs-open-project-workspace workspace)))))

(defun idee-treemacs-open-project-workspace (workspace)
  "Open the first project of the WORKSPACE."
  (let* ((selected workspace)
         (name (treemacs-project->name selected))
         (project (treemacs-project->path selected))
         (path (treemacs-project->path (car project))))
    (projectile-switch-project-by-name path)
    (idee-refresh-view)
    (idee-jump-to-non-ide-window)))

(defhydra treemacs-hydra (:hint nil :exit t)
  ;; The '_' character is not displayed. This affects columns alignment.
  ;; Remove s many spaces as needed to make up for the '_' deficit.
  "
                ^Workspaces^             ^Toggles^                 ^Windows^                     ^Navigation^
                ^^^^^^-----------------------------------------------------------------------------------------
                _N_: new workspace       _t_: tree view toggle     _s_: select window            _b_: bookmark
                _S_: switch workspace    _d_: show hidden files    _d_: delete other windows     _f_: find file
                _R_: remove workspace    _c_: collapse dirs                                      _T_: find tag
                _E_: edit workspace      _g_: magit             
                _F_: finish edit         
               "
                                        ; Toggles
  ("N" idee-treemacs-create-and-switch-to-workspace)
  ("R" treemacs-remove-workspace)
  ("S" idee-treemacs-switch-to-project-workspace)
  ("E" treemacs-edit-workspaces)
  ("F" treemacs-finish-edit)
  ("t" idee-toggle-tree)
  ("d" treemacs-toggle-show-dotfiles)
  ("c" idee-treemacs-collapse-dir-toggle)
  ("g" magit-status)
                                        ; Windows
  ("s" treemacs-select-window)
  ("d" treemacs-delete-other-windows)
                                        ; Navifation
  ("b" treemacs-bookmark)
  ("f" treemacs-find-file)
  ("T" treemacs-find-tag)
  ("q" nil "quit"))

(evil-leader/set-key "t" 'treemacs-hydra/body)

(provide 'idee-treemacs)
;;; idee-treemacs.el ends here.
