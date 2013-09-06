;;; ergoemacs-mode.el --- Emacs mode based on common modern software interface and ergonomics.

;; Copyright © 2007, 2008, 2009 by Xah Lee
;; Copyright © 2009, 2010 by David Capello
;; Copyright © 2012, 2013 by Matthew Fidler

;; Author: Xah Lee <xah@xahlee.org>
;;         David Capello <davidcapello@gmail.com>
;;         Matthew L. Fidler <matthew.fidler@gmail.com>
;; Maintainer: Matthew L. Fidler <matthew.fidler@gmail.com>
;; Created: August 01 2007
;; Keywords: convenience
;; Package-Requires: ((org-cua-dwim "0.5"))

;; ErgoEmacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.

;; ErgoEmacs is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with ErgoEmacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This keybinding set puts the most frequently used Emacs keyboard
;; shortcuts into the most easy-to-type spots.
;;
;; For complete detail, see:
;; http://ergoemacs.github.io/ergoemacs-mode/

;; Todo:

;; 

;;; Acknowledgment:
;; Thanks to Shahin Azad for persian layout (fa) ishahinism at g
;; mail.com
;; Thanks to Thomas Rikl workhorse.t at googlemail.com for german layout
;; Thanks to Baptiste Fouques  bateast at bat.fr.eu.org for bepo layout
;; Thanks to Andrey Kotlarski (aka m00naticus) for a patch on 2012-12-08
;; Thanks to Nikolaj Schumacher for his implementation of extend-selection.
;; Thanks to Andreas Politz and Nikolaj Schumacher for correcting/improving implementation of toggle-letter-case.
;; Thanks to Lennart Borgman for several suggestions on code to prevent shortcuts involving shift key to start select text when CUA-mode is on.
;; Thanks to marciomazza for spotting several default bindings that
;; should have been unbound.
;; Thanks to lwarxx for bug report on diff-mode
;; Thanks to maddin for ergoemacs-global/local-set-key functions and ergoemacs-hook-modes improvements.
;; Thanks to many users who send in comments and appreciations on this.
;; Layout contributors:
;; Danish layout “da”.  Contributors: Michael Budde
;; UK QWERTY layout “gb”.  Contributor: Jorge Dias (aka theturingmachine)
;; UK Dvorak layout “gb-dv”.  Contributor: Phillip Wood
;; French AZERTY layout “fr”.  Contributor: Alexander Doe
;; Italian QWERTY layout “it”.  Contributor: David Capello, Francesco Biccari


;;; Code:

; (eval-when-compile (require 'cl))
; FIXME: Use cl-lib when available.
(require 'cl)
(require 'easymenu)
(require 'cua-base)
(require 'cua-rect)

(defvar ergoemacs-debug ""
  "Debugging for `ergoemacs-mode'.")

(defun ergoemacs-debug (&rest arg)
  "Ergoemacs debugging facility."
  (interactive)
  (if (interactive-p)
      (progn
        (ergoemacs-debug-flush)
        (switch-to-buffer-other-window (get-buffer-create " *ergoemacs-debug*")))
    (setq ergoemacs-debug
          (format "%s\n%s"
                  ergoemacs-debug
                  (apply 'format arg)))))

(defun ergoemacs-debug-flush ()
  "Flushes ergoemacs debug to *ergoemacs-debug*"
  (with-current-buffer (get-buffer-create " *ergoemacs-debug*") ;; Should be hidden.
    (insert ergoemacs-debug "\n"))
  (setq ergoemacs-debug ""))

;; Include extra files
(defvar ergoemacs-dir
  (file-name-directory
   (or
    load-file-name
    (buffer-file-name)))
  "Ergoemacs directory.")
(add-to-list 'load-path ergoemacs-dir)


(require 'ergoemacs-layouts)

(require 'org-cua-dwim nil "NOERROR")


(when (featurep 'org-cua-dwim)
  (org-cua-dwim-activate))

;; Ergoemacs-keybindings version
(defconst ergoemacs-mode-version "5.8.0"
  "Ergoemacs-keybindings minor mode version number.")

(defconst ergoemacs-mode-changes "Delete window Alt+0 changed to Alt+2.
Added beginning-of-buffer Alt+n (QWERTY notation) and end-of-buffer Alt+Shift+n")

(defgroup ergoemacs-mode nil
  "Emacs mode based on common modern software interface and ergonomics."
  :group 'editing-basics
  :group 'convenience
  :group 'emulations)

(defcustom ergoemacs-mode-used nil
  "Ergoemacs-keybindings minor mode version number used."
  :type 'string
  :group 'ergoemacs-mode)

(defvar ergoemacs-movement-functions
  '(scroll-down
    move-beginning-of-line move-end-of-line scroll-up
    scroll-down forward-block backward-block
    forward-word backward-word next-line previous-line
    forward-char backward-char ergoemacs-backward-block
    ergoemacs-forward-block ergoemacs-backward-open-bracket
    ergoemacs-forward-close-bracket move-end-of-line
    move-beginning-of-line backward-word forward-word
    subword-backward subword-forward
    beginning-of-buffer end-of-buffer)
  "Movement functions.")

(defvar ergoemacs-deletion-functions
  '(delete-backward-char
    delete-char backward-kill-word kill-word kill-line
    ergoemacs-shrink-whitespaces ergoemacs-kill-line-backward)
  "Deletion functions.")

(defvar ergoemacs-undo-redo-functions
  '(undo
    redo
    undo-tree-undo
    undo-tree-redo)
  "Undo and redo functions that ErgoEmacs is aware of...")

(defvar ergoemacs-window-tab-switching
  '(ergoemacs-switch-to-previous-frame
    ergoemacs-switch-to-next-frame
    ergoemacs-previous-user-buffer
    split-window-horizontally
    delete-window
    delete-other-windows
    split-window-vertically
    ergoemacs-next-user-buffer)
  "Window/Tab switching functions.")

(defun ergoemacs-set-default (symbol new-value)
  "Ergoemacs equivalent to set-default.
Will reload `ergoemacs-mode' after setting the values."
  (set-default symbol new-value)
  (when (and (or (not (boundp 'ergoemacs-fixed-layout-tmp))
                 (save-match-data (string-match "ergoemacs-redundant-keys-" (symbol-name symbol))))
             (boundp 'ergoemacs-mode) ergoemacs-mode)
    (ergoemacs-mode -1)
    (ergoemacs-mode 1)))

(defcustom ergoemacs-keyboard-layout (or (getenv "ERGOEMACS_KEYBOARD_LAYOUT") "us")
  (concat "Specifies which keyboard layout to use.
This is a mirror of the environment variable ERGOEMACS_KEYBOARD_LAYOUT.

Valid values are:

" (ergoemacs-get-layouts-doc))
  :type (ergoemacs-get-layouts-type)
  :set 'ergoemacs-set-default
  :group 'ergoemacs-mode)

;; FIXME: maybe a better name is `ergoemacs-change-smex-meta-x', since
;; Customization displays it as "Ergoemacs Change Smex M X".
(defcustom ergoemacs-change-smex-M-x t
  "Changes the `smex-prompt-string' to match the `execute-extended-command'"
  :type 'boolean
  :set 'ergoemacs-set-default
  :group 'ergoemacs-mode)

(defvar ergoemacs-cua-rect-modifier-orig cua--rectangle-modifier-key)

(defcustom ergoemacs-cua-rect-modifier 'super
  "Change the CUA rectangle modifier to this key."
  :type '(choice
          (const :tag "Do not modify the cua-rectangle modifier" nil)
          (const :tag "Meta Modifier" 'meta)
          (const :tag "Super Modifier" 'super)
          (const :tag "Hyper Modifier" 'hyper)
          (const :tag "Alt Modifier" 'alt))
  :set 'ergoemacs-set-default
  :group 'ergoemacs-mode)

(defcustom ergoemacs-repeat-movement-commands nil
  "Allow movement commands to be repeated without pressing the ALT key."
  :group 'ergoemacs-mode
  :type '(choice
          (const :tag "Do not allow fast repeat commands." nil)
          (const :tag "Allow fast repeat command of the current movement command" 'single)
          (const :tag "Allow fast repeat of all movement commands" 'all)))

(defcustom ergoemacs-repeat-undo-commands 'apps
  "Allow undo commands to be repeated without pressing the entire key.  For example if <apps> z is undo, then <apps> z z sould be undo twice if enabled."
  :group 'ergoemacs-mode
  :type '(choce
          (const :tag "Do not allow fast repeat commands." nil)
          (const :tag "Allow fast repeat for <apps> menu." 'apps)))


(when (not (fboundp 'set-temporary-overlay-map))
  ;; Backport this function from newer emacs versions
  (defun set-temporary-overlay-map (map &optional keep-pred)
    "Set a new keymap that will only exist for a short period of time.
The new keymap to use must be given in the MAP variable. When to
remove the keymap depends on user input and KEEP-PRED:

- if KEEP-PRED is nil (the default), the keymap disappears as
  soon as any key is pressed, whether or not the key is in MAP;

- if KEEP-PRED is t, the keymap disappears as soon as a key *not*
  in MAP is pressed;

- otherwise, KEEP-PRED must be a 0-arguments predicate that will
  decide if the keymap should be removed (if predicate returns
  nil) or kept (otherwise). The predicate will be called after
  each key sequence."
    
    (let* ((clearfunsym (make-symbol "clear-temporary-overlay-map"))
           (overlaysym (make-symbol "t"))
           (alist (list (cons overlaysym map)))
           (clearfun
            `(lambda ()
               (unless ,(cond ((null keep-pred) nil)
                              ((eq t keep-pred)
                               `(eq this-command
                                    (lookup-key ',map
                                                (this-command-keys-vector))))
                              (t `(funcall ',keep-pred)))
                 (remove-hook 'pre-command-hook ',clearfunsym)
                 (setq emulation-mode-map-alists
                       (delq ',alist emulation-mode-map-alists))))))
      (set overlaysym overlaysym)
      (fset clearfunsym clearfun)
      (add-hook 'pre-command-hook clearfunsym)
      
      (push alist emulation-mode-map-alists))))

(defvar ergoemacs-undo-apps-keymap nil
  "Keymap for repeating undo/redo commands in apps menu.")

(defun ergoemacs-undo-apps-text nil
  "Text for repeat undo/redo commands in apps menu.")

(defun ergoemacs-create-undo-apps-keymap ()
  "Create `ergoemacs-undo-apps-keymap', based on current ergoemacs keybindings."
  (let ((ergoemacs-undo-key
         (replace-regexp-in-string "<\\(apps\\|menu\\)> " "" (key-description (ergoemacs-key-fn-lookup 'undo t))))
        (ergoemacs-redo-key
         (replace-regexp-in-string "<\\(apps\\|menu\\)> " "" (key-description (ergoemacs-key-fn-lookup 'redo t)))))
    (setq ergoemacs-undo-apps-text (format "Undo repeat key `%s'; Redo repeat key `%s'"
                                           ergoemacs-undo-key ergoemacs-redo-key))
    (setq ergoemacs-undo-apps-keymap (make-keymap))
    (define-key ergoemacs-undo-apps-keymap (read-kbd-macro ergoemacs-undo-key) 'undo)
    (define-key ergoemacs-undo-apps-keymap (read-kbd-macro ergoemacs-redo-key) 'redo)))

(defmacro ergoemacs-create-undo-advices (command)
  "Creates repeat advices for undo/redo commands defined in `ergoemacs-undo-redo-functions'. The repeat behavior is defined by `ergoemacs-repeat-undo-commands'.ergoemacs-repeat-undo-commands"
  `(defadvice ,(intern (symbol-name command)) (around ergoemacs-undo-redo-advice activate)
     ,(format "ErgoEmacs fast keymap for `%s'" (symbol-name command))
     ad-do-it
     (when (and ergoemacs-mode (eq ergoemacs-repeat-undo-commands 'apps))
       (message "%s" ergoemacs-undo-apps-text)
       (set-temporary-overlay-map ergoemacs-undo-apps-keymap t))))

(mapc
 (lambda(x)
   (eval `(ergoemacs-create-undo-advices ,x)))
 ergoemacs-undo-redo-functions)


(defmacro ergoemacs-create-movement-commands (command)
  "Creates a shifted and repeat advices and isearch commands."
  `(progn
     ,(if (eq 'backward-char command)
          `(defun ,(intern (concat "ergoemacs-isearch-" (symbol-name command))) (&optional arg)
             ,(format "Ergoemacs isearch movement command for `%s'.  Behviour controlled with `ergoemacs-isearch-backward-char-to-edit'.  A prefix command will temporarily toggle if the keyboard will edit the item." (symbol-name command))
             (interactive "^P")
             (if (or (and arg (not ergoemacs-isearch-backward-char-to-edit))
                     (and (not arg) ergoemacs-isearch-backward-char-to-edit))
                 (isearch-edit-string)
               (isearch-exit)
               (call-interactively ',command t)
               (setq this-command ',command)))
        `(defun ,(intern (concat "ergoemacs-isearch-" (symbol-name command))) (&optional arg)
           ,(format "Ergoemacs isearch movement command for `%s'." (symbol-name command))
           (interactive "^P")
           (isearch-exit)
           (call-interactively ',command t)
           (setq this-command ',command)))
     (defvar ,(intern (concat "ergoemacs-fast-" (symbol-name command) "-keymap")) (make-sparse-keymap)
       ,(format "Ergoemacs fast keymap for `%s'." (symbol-name command)))
     ;; Change to advices
     (defadvice ,(intern (symbol-name command)) (around ergoemacs-movement-advice activate)
       ,(format "Ergoemacs advice for command for `%s'.
May install a fast repeat key based on `ergoemacs-repeat-movement-commands',  `ergoemacs-full-fast-keys-keymap' and `ergoemacs-fast-%s-keymap'.
" (symbol-name command) (symbol-name command))
       ad-do-it
       (when (and ergoemacs-mode ergoemacs-repeat-movement-commands
                  (called-interactively-p 'interactive) (not cua--rectangle-overlays)) ;; Don't add overlays to rectangles
         (set-temporary-overlay-map (cond
                                     ((eq ergoemacs-repeat-movement-commands 'single)
                                      ,(intern (concat "ergoemacs-fast-" (symbol-name command) "-keymap")))
                                     ((eq ergoemacs-repeat-movement-commands 'all)
                                      ergoemacs-full-fast-keys-keymap)
                                     (t ,(intern (concat "ergoemacs-fast-" (symbol-name command) "-keymap")))) t)))))
(mapc
 (lambda(x)
   (eval `(ergoemacs-create-movement-commands ,x)))
 ergoemacs-movement-functions)


(defvar ergoemacs-M-O-trans
  '(
    ("2A" [S-up])        ; xterm.el
    ("2B" [S-down])      ; xterm.el
    ("2C" [S-right])     ; xterm.el
    ("2D" [S-left])      ; xterm.el
    ("2F" [S-end])       ; xterm.el
    ("2H" [S-home])      ; xterm.el
    ("2P" [S-f1])        ; xterm.el
    ("2Q" [S-f2])        ; xterm.el
    ("2R" [S-f3])        ; xterm.el
    ("2S" [S-f4])        ; xterm.el
    ("3P" [M-f1])        ; xterm.el
    ("3Q" [M-f2])        ; xterm.el
    ("3R" [M-f3])        ; xterm.el
    ("3S" [M-f4])        ; xterm.el
    ("4P" [M-S-f1])      ; xterm.el
    ("4Q" [M-S-f2])      ; xterm.el
    ("4R" [M-S-f3])      ; xterm.el
    ("4S" [M-S-f4])      ; xterm.el
    ("5A" [C-up])        ; xterm.el
    ("5B" [C-down])      ; xterm.el
    ("5C" [C-right])     ; xterm.el
    ("5D" [C-left])      ; xterm.el
    ("5F" [C-end])       ; xterm.el
    ("5H" [C-home])      ; xterm.el
    ("5P" [C-f1])        ; xterm.el
    ("5Q" [C-f2])        ; xterm.el
    ("5R" [C-f3])        ; xterm.el
    ("5S" [C-f4])        ; xterm.el
    ("6P" [C-S-f1])      ; xterm.el
    ("6Q" [C-S-f2])      ; xterm.el
    ("6R" [C-S-f3])      ; xterm.el
    ("6S" [C-S-f4])      ; xterm.el
    ("A" up)             ; xterm.el
    ("B" down)           ; xterm.el
    ("C" right)          ; xterm.el
    ("D" left)           ; xterm.el
    ("E" begin)          ; xterm.el
    ("F" end)            ; xterm.el
    ("H" home)           ; xterm.el
    ("I" [kp-tab])       ; lk201.el
    ("M" kp-enter)       ; xterm.el
    ("P" f1)             ; xterm.el
    ("Q" f2)             ; xterm.el
    ("R" f3)             ; xterm.el
    ("S" f4)             ; xterm.el
    ("a" [C-up])         ; rxvt.el
    ("b" [C-down])       ; rxvt.el
    ("c" [C-right])      ; rxvt.el
    ("d" [C-left])       ; rxvt.el
    ("j" [kp-multiply])  ; xterm.el
    ("k" [kp-add])       ; xterm.el
    ("l" [kp-separator]) ; xterm.el
    ("m" [kp-subtract])  ; xterm.el
    ("n" [kp-decimal])   ; lk201.el
    ("o" [kp-divide])    ; xterm.el
    ("p" [kp-0])         ; xterm.el
    ("q" [kp-1])         ; xterm.el
    ("r" [kp-2])         ; xterm.el
    ("s" [kp-3])         ; xterm.el
    ("t" [kp-4])         ; xterm.el
    ("u" [kp-5])         ; xterm.el
    ("v" [kp-6])         ; xterm.el
    ("w" [kp-7])         ; xterm.el
    ("x" [kp-8])         ; xterm.el
    ("y" [kp-9])         ; xterm.el
    )
  "Terminal Translations.")

(defvar ergoemacs-M-b-translations
  '(
    ("27;6;41~"  [?\C-)])
    ("000q" [begin]) ; iris-ansi
    ("001q" [f1]) ; iris-ansi
    ("002q" [f2]) ; iris-ansi
    ("003q" [f3]) ; iris-ansi
    ("004q" [f4]) ; iris-ansi
    ("005q" [f5]) ; iris-ansi
    ("006q" [f6]) ; iris-ansi
    ("007q" [f7]) ; iris-ansi
    ("008q" [f8]) ; iris-ansi
    ("009q" [f9]) ; iris-ansi
    ("010q" [f10]) ; iris-ansi
    ("011q" [f11]) ; iris-ansi
    ("012q" [f12]) ; iris-ansi
    ("013q" [S-f1]) ; iris-ansi
    ("014q" [S-f2]) ; iris-ansi
    ("015q" [S-f3]) ; iris-ansi
    ("016q" [S-f4]) ; iris-ansi
    ("017q" [S-f5]) ; iris-ansi
    ("018q" [S-f6]) ; iris-ansi
    ("019q" [S-f7]) ; iris-ansi
    ("020q" [S-f8]) ; iris-ansi
    ("021q" [S-f9]) ; iris-ansi
    ("022q" [S-f10]) ; iris-ansi
    ("023q" [S-f11]) ; iris-ansi
    ("024q" [S-f12]) ; iris-ansi
    ("025q" [C-f1]) ; iris-ansi
    ("026q" [C-f2]) ; iris-ansi
    ("027q" [C-f3]) ; iris-ansi
    ("028q" [C-f4]) ; iris-ansi
    ("029q" [C-f5]) ; iris-ansi
    ("030q" [C-f6]) ; iris-ansi
    ("031q" [C-f7]) ; iris-ansi
    ("032q" [C-f8]) ; iris-ansi
    ("033q" [C-f9]) ; iris-ansi
    ("034q" [C-f10]) ; iris-ansi
    ("035q" [C-f11]) ; iris-ansi
    ("036q" [C-f12]) ; iris-ansi
    ("038q" [M-f2]) ; iris-ansi
    ("047q" [M-f11]) ; iris-ansi
    ("048q" [M-f12]) ; iris-ansi
    ("049q" [?\C-1]) ; iris-ansi
    ("050q" [?\C-3]) ; iris-ansi
    ("051q" [?\C-4]) ; iris-ansi
    ("052q" [?\C-5]) ; iris-ansi
    ("053q" [?\C-7]) ; iris-ansi
    ("054q" [?\C-8]) ; iris-ansi
    ("055q" [?\C-9]) ; iris-ansi
    ("056q" [?\C-0]) ; iris-ansi
    ("057q" [?\C-`]) ; iris-ansi
    ("058q" [?\M-1]) ; iris-ansi
    ("059q" [?\M-2]) ; iris-ansi
    ("060q" [?\M-3]) ; iris-ansi
    ("061q" [?\M-4]) ; iris-ansi
    ("062q" [?\M-5]) ; iris-ansi
    ("063q" [?\M-6]) ; iris-ansi
    ("064q" [?\M-7]) ; iris-ansi
    ("065q" [?\M-8]) ; iris-ansi
    ("066q" [?\M-9]) ; iris-ansi
    ("067q" [?\M-0]) ; iris-ansi
    ("068q" [?\M--]) ; iris-ansi
    ("069q" [?\C-=]) ; iris-ansi
    ("070q" [?\M-=]) ; iris-ansi
    ("072q" [?\C-\t]) ; iris-ansi
    ("073q" [?\M-\t]) ; iris-ansi
    ("074q" [?\M-q]) ; iris-ansi
    ("075q" [?\M-w]) ; iris-ansi
    ("076q" [?\M-e]) ; iris-ansi
    ("077q" [?\M-r]) ; iris-ansi
    ("078q" [?\M-t]) ; iris-ansi
    ("079q" [?\M-y]) ; iris-ansi
    ("080q" [?\M-u]) ; iris-ansi
    ("081q" [?\M-i]) ; iris-ansi
    ("082q" [?\M-o]) ; iris-ansi
    ("083q" [?\M-p]) ; iris-ansi
    ("084q" [?\M-\[]) ; iris-ansi
    ("085q" [?\M-\]]) ; iris-ansi
    ("086q" [?\M-\\]) ; iris-ansi
    ("087q" [?\M-a]) ; iris-ansi
    ("088q" [?\M-s]) ; iris-ansi
    ("089q" [?\M-d]) ; iris-ansi
    ("090q" [?\M-f]) ; iris-ansi
    ("091q" [?\M-g]) ; iris-ansi
    ("092q" [?\M-h]) ; iris-ansi
    ("093q" [?\M-j]) ; iris-ansi
    ("094q" [?\M-k]) ; iris-ansi
    ("095q" [?\M-l]) ; iris-ansi
    ("096q" [?\C-\;]) ; iris-ansi
    ("097q" [?\M-:]) ; iris-ansi
    ("098q" [?\C-']) ; iris-ansi
    ("099q" [?\M-']) ; iris-ansi
    ("100q" [?\M-\n]) ; iris-ansi
    ("100q" [M-enter]) ; iris-ansi
    ("101q" [?\M-z]) ; iris-ansi
    ("102q" [?\M-x]) ; iris-ansi
    ("103q" [?\M-c]) ; iris-ansi
    ("104q" [?\M-v]) ; iris-ansi
    ("105q" [?\M-b]) ; iris-ansi
    ("106q" [M-n]) ; iris-ansi
    ("107q" [M-m]) ; iris-ansi
    ("108q" [?\C-,]) ; iris-ansi
    ("109q" [?\M-,]) ; iris-ansi
    ("110q" [?\C-.]) ; iris-ansi
    ("111q" [?\M-.]) ; iris-ansi
    ("112q" [?\C-/]) ; iris-ansi
    ("113q" [?\M-/]) ; iris-ansi
    ("115q" [?\M-`]) ; iris-ansi
    ("11^" [C-f1]) ; rxvt
    ("11~" [f1])
    ("120q" [S-escape]) ; iris-ansi
    ("121q" [C-escape]) ; iris-ansi
    ("12^" [C-f2]) ; rxvt
    ("12~" [f2])
    ("139q" [insert]) ; iris-ansi ;; Not sure 
    ("13^" [C-f3]) ; rxvt
    ("13~" [f3])
    ("140q" [C-insert]) ; iris-ansi
    ("141q" [M-insert]) ; iris-ansi
    ("142q" [C-delete]) ; iris-ansi
    ("143q" [S-home]) ; iris-ansi
    ("144q" [C-home]) ; iris-ansi
    ("146q" [end]) ; iris-ansi
    ("147q" [S-end]) ; Those don't seem to generate anything. ; iris-ansi
    ("148q" [C-end]) ; iris-ansi
    ("14^" [C-f4]) ; rxvt
    ("14~" [f4])
    ("14~" [f4]) ; lk201
    ("14~" [f4]) ; rxvt
    ("150q" [prior]) ; iris-ansi
    ("151q" [S-prior]) ;Those don't seem to generate anything. ; iris-ansi
    ("152q" [C-prior]) ; iris-ansi
    ("154q" [next]) ; iris-ansi
    ("155q" [S-next]) ; iris-ansi
    ("156q" [C-next]) ; iris-ansi
    ("158q" [S-left]) ; iris-ansi
    ("159q" [C-left]) ; iris-ansi
    ("15;2~" [S-f5])
    ("15;3~" [M-f5])
    ("15;4~" [M-S-f5])
    ("15;6~" [C-S-f5])
    ("15^" [C-f5]) ; rxvt
    ("15~" [f5])
    ("160q" [M-left]) ; iris-ansi
    ("161q" [S-up]) ; iris-ansi
    ("162q" [C-up]) ; iris-ansi
    ("163q" [M-up]) ; iris-ansi
    ("164q" [S-down]) ; iris-ansi
    ("165q" [C-down]) ; iris-ansi
    ("166q" [M-down]) ; iris-ansi
    ("167q" [S-right]) ; iris-ansi
    ("168q" [C-right]) ; iris-ansi
    ("169q" [M-right]) ; iris-ansi
    ("172q" [C-home]) ; iris-ansi
    ("174q" [C-left]) ; iris-ansi
    ("176q" [C-end]) ; iris-ansi
    ("178q" [C-inset]) ; iris-ansi
    ("179q" [?\C-/]) ; iris-ansi
    ("17;2~" [S-f6])
    ("17;3~" [M-f6])
    ("17;4~" [M-S-f6])
    ("17;6~" [C-S-f6])
    ("17^" [C-f6]) ; rxvt
    ("17~" [f6])
    ("17~" [f6]) ; lk201
    ("17~" [f6]) ; rxvt
    ("180q" [?\M-/]) ; iris-ansi
    ("182q" [C-up]) ; iris-ansi
    ("184q" [C-begin]) ; iris-ansi
    ("186q" [C-down]) ; iris-ansi
    ("187q" [?\C-*]) ; iris-ansi
    ("188q" [?\M-*]) ; iris-ansi
    ("18;3~" [M-f7])
    ("18;4~" [M-S-f7])
    ("18;6~" [C-S-f7])
    ("18^" [C-f7]) ; rxvt
    ("18~" [f7])
    ("18~" [f7]) ; lk201
    ("18~" [f7]) ; rxvt
    ("190q" [C-prior]) ; iris-ansi
    ("192q" [C-right]) ; iris-ansi
    ("194q" [C-next]) ; iris-ansi
    ("196q" [C-delete]) ; iris-ansi
    ("197q" [M-delete]) ; iris-ansi    
    ("198q" [?\C--]) ; iris-ansi
    ("199q" [?\M--]) ; iris-ansi
    ("19;3~" [M-f8])
    ("19;4~" [M-S-f8])
    ("19;6~" [C-S-f8])
    ("19^" [C-f8]) ; rxvt
    ("19h" [S-erasepage]) ;; Not an X keysym ; tvi
    ("19l" [key_seol])   ;; Not an X keysym ; tvi
    ("19~" [f8])
    ("1;2A" [S-up])
    ("1;2B" [S-down])
    ("1;2C" [S-right])
    ("1;2D" [S-left])
    ("1;2F" [S-end])
    ("1;2H" [S-home])
    ("1;2P" [S-f1])
    ("1;2Q" [S-f2])
    ("1;2R" [S-f3])
    ("1;2S" [S-f4])
    ("1;3A" [M-up])
    ("1;3B" [M-down])
    ("1;3C" [M-right])
    ("1;3D" [M-left])
    ("1;3F" [M-end])
    ("1;3H" [M-home])
    ("1;4A" [M-S-up])
    ("1;4B" [M-S-down])
    ("1;4C" [M-S-right])
    ("1;4D" [M-S-left])
    ("1;4F" [M-S-end])
    ("1;4H" [M-S-home])
    ("1;5A" [C-up])
    ("1;5B" [C-down])
    ("1;5C" [C-right])
    ("1;5D" [C-left])
    ("1;5F" [C-end])
    ("1;5H" [C-home])
    ("1;6A" [C-S-up])
    ("1;6B" [C-S-down])
    ("1;6C" [C-S-right])
    ("1;6D" [C-S-left])
    ("1;6F" [C-S-end])
    ("1;6H" [C-S-home])
    ("1;7A" [C-M-up])
    ("1;7B" [C-M-down])
    ("1;7C" [C-M-right])
    ("1;7D" [C-M-left])
    ("1;7F" [C-M-end])
    ("1;7H" [C-M-home])
    ("1;8A" [C-M-S-up])
    ("1;8B" [C-M-S-down])
    ("1;8C" [C-M-S-right])
    ("1;8D" [C-M-S-left])
    ("1;8F" [C-M-S-end])
    ("1;8H" [C-M-S-home])
    ("1~" [home])
    ("200q" [?\C-+]) ; iris-ansi
    ("201q" [?\M-+]) ; iris-ansi
    ("20;3~" [M-f9])
    ("20;4~" [M-S-f9])
    ("20;6~" [C-S-f9])
    ("20^" [C-f9]) ; rxvt
    ("20~" [f9])
    ("21;3~" [M-f10])
    ("21;4~" [M-S-f10])
    ("21;6~" [C-S-f10])
    ("21^" [C-f10]) ; rxvt
    ("21~" [f10])
    ("23;3~" [M-f11])
    ("23;4~" [M-S-f11])
    ("23;6~" [C-S-f11])
    ("23^" [C-S-f1]) ; rxvt
    ;;("23~" [S-f1]) ; rxvt
    ;;("23~" [f11]) ;Probably redundant.
    ("24;3~" [M-f12])
    ("24;4~" [M-S-f12])
    ("24;5~" [C-f12])
    ("24;6~" [C-S-f12])
    ("24^" [C-S-f2]) ; rxvt
    ;;("24~" [S-f2]) ; rxvt
    ;;("24~" [f12])
    ("25^" [C-S-f3]) ; rxvt
    ("25~" [S-f3]) ; rxvt
    ;;("25~" [f13]) ; lk201
    ("26^" [C-S-f4]) ; rxvt
    ("26~" [S-f4]) ; rxvt
    ;;("26~" [f14]) ; lk201
    ("27;13;13~" [C-M-return])
    ("27;13;39~" [?\C-\M-\'])
    ("27;13;44~" [?\C-\M-,])
    ("27;13;45~" [?\C-\M--])
    ("27;13;46~" [?\C-\M-.])
    ("27;13;47~" [?\C-\M-/])
    ("27;13;48~" [?\C-\M-0])
    ("27;13;49~" [?\C-\M-1])
    ("27;13;50~" [?\C-\M-2])
    ("27;13;51~" [?\C-\M-3])
    ("27;13;52~" [?\C-\M-4])
    ("27;13;53~" [?\C-\M-5])
    ("27;13;54~" [?\C-\M-6])
    ("27;13;55~" [?\C-\M-7])
    ("27;13;56~" [?\C-\M-8])
    ("27;13;57~" [?\C-\M-9])
    ("27;13;59~" [?\C-\M-\;])
    ("27;13;61~" [?\C-\M-=])
    ("27;13;92~" [?\C-\M-\\])
    ("27;13;9~"  [C-M-tab])
    ("27;14;33~"  [?\C-\M-!])
    ("27;14;34~"  [?\C-\M-\"])
    ("27;14;35~"  [?\C-\M-#])
    ("27;14;36~"  [?\C-\M-$])
    ("27;14;37~"  [?\C-\M-%])
    ("27;14;38~"  [?\C-\M-&])
    ("27;14;40~"  [?\C-\M-\(])
    ("27;14;41~"  [?\C-\M-\)])
    ("27;14;42~"  [?\C-\M-*])
    ("27;14;43~"  [?\C-\M-+])
    ("27;14;58~"  [?\C-\M-:])
    ("27;14;60~"  [?\C-\M-<])
    ("27;14;62~"  [?\C-\M->])
    ("27;14;63~"  [(control meta ??)])
    ("27;2;13~"  [S-return])
    ("27;2;9~"   [S-tab])
    ("27;5;13~"  [C-return])
    ("27;5;39~"  [?\C-\'])
    ("27;5;44~"  [?\C-,])
    ("27;5;45~"  [?\C--])
    ("27;5;46~"  [?\C-.])
    ("27;5;47~"  [?\C-/])
    ("27;5;48~"  [?\C-0])
    ("27;5;49~"  [?\C-1])
    ("27;5;57~"  [?\C-9])
    ("27;5;59~"  [?\C-\;])
    ("27;5;61~"  [?\C-=])
    ("27;5;92~"  [?\C-\\])
    ("27;5;9~"   [C-tab])
    ("27;6;13~"  [C-S-return])
    ("27;6;33~"  [?\C-!])
    ("27;6;34~"  [?\C-\"])
    ("27;6;35~"  [?\C-#])
    ("27;6;36~"  [?\C-$])
    ("27;6;37~"  [?\C-%])
    ("27;6;38~"  [?\C-&])
    ("27;6;40~"  [?\C-(])
    ("27;6;42~"  [?\C-*])
    ("27;6;43~"  [?\C-+])
    ("27;6;58~"  [?\C-:])
    ("27;6;60~"  [?\C-<])
    ("27;6;62~"  [?\C->])
    ("27;6;63~"  [(control ??)])
    ("27;6;9~"   [C-S-tab])
    ("27;7;13~" [C-M-return])
    ("27;7;32~" [?\C-\M-\s])
    ("27;7;39~" [?\C-\M-\'])
    ("27;7;44~" [?\C-\M-,])
    ("27;7;45~" [?\C-\M--])
    ("27;7;46~" [?\C-\M-.])
    ("27;7;47~" [?\C-\M-/])
    ("27;7;48~" [?\C-\M-0])
    ("27;7;49~" [?\C-\M-1])
    ("27;7;50~" [?\C-\M-2])
    ("27;7;51~" [?\C-\M-3])
    ("27;7;52~" [?\C-\M-4])
    ("27;7;53~" [?\C-\M-5])
    ("27;7;54~" [?\C-\M-6])
    ("27;7;55~" [?\C-\M-7])
    ("27;7;56~" [?\C-\M-8])
    ("27;7;57~" [?\C-\M-9])
    ("27;7;59~" [?\C-\M-\;])
    ("27;7;61~" [?\C-\M-=])
    ("27;7;92~" [?\C-\M-\\])
    ("27;7;9~"  [C-M-tab])
    ("27;8;33~"  [?\C-\M-!])
    ("27;8;34~"  [?\C-\M-\"])
    ("27;8;35~"  [?\C-\M-#])
    ("27;8;36~"  [?\C-\M-$])
    ("27;8;37~"  [?\C-\M-%])
    ("27;8;38~"  [?\C-\M-&])
    ("27;8;40~"  [?\C-\M-\(])
    ("27;8;41~"  [?\C-\M-\)])
    ("27;8;42~"  [?\C-\M-*])
    ("27;8;43~"  [?\C-\M-+])
    ("27;8;58~"  [?\C-\M-:])
    ("27;8;60~"  [?\C-\M-<])
    ("27;8;62~"  [?\C-\M->])
    ("27;8;63~"  [(control meta ??)])
    ("28^" [C-S-f5]) ; rxvt
    ("28~" [S-f5]) ; rxvt
    ;;("28~" [help]) ; lk201
    ("29^" [C-S-f6]) ; rxvt
    ("29~" [S-f6]) ; rxvt
    ;;("29~" [menu]) ; lk201
    ;;("29~" [print])
    ;;("29~" [print]) ; rxvt
    ("2;2~" [S-insert]) ; rxvt
    ("2;2~" [S-insert])
    ("2;3~" [M-insert])
    ("2;4~" [M-S-insert])
    ("2;5~" [C-insert])
    ("2;6~" [C-S-insert])
    ("2;7~" [C-M-insert])
    ("2;8~" [C-M-S-insert])
    ("2J" [key_clear])    ;; Not an X keysym ; tvi
    ("2K" [S-clearentry]) ;; Not an X keysym ; tvi
    ("2N" [clearentry])   ;; Not an X keysym ; tvi
    ("2^" [C-insert]) ; rxvt
    ("2~" [insert])
    ;;("2~" [insert]) ; lk201
    ;;("2~" [insert]) ; rxvt
    ("3$" [S-delete]) ; rxvt
    ("31^" [C-S-f7]) ; rxvt
    ("31~" [S-f7]) ; rxvt
    ;;("31~" [f17]) ; lk201
    ("32^" [C-S-f8]) ; rxvt
    ("32~" [S-f8]) ; rxvt
    ;;("32~" [f18]) ; lk201
    ("33^" [C-S-f9]) ; rxvt
    ("33~" [S-f9]) ; rxvt
    ;;("33~" [f19]) ; lk201
    ("34^" [C-S-f10]) ; rxvt
    ("34~" [S-f10]) ; rxvt
    ;;("34~" [f20]) ; lk201
    ("3;2~" [S-delete])
    ("3;3~" [M-delete])
    ("3;4~" [M-S-delete])
    ("3;5~" [C-delete])
    ("3;6~" [C-S-delete])
    ("3;7~" [C-M-delete])
    ("3;8~" [C-M-S-delete])
    ("3^" [C-delete]) ; rxvt
    ("3~" [delete])
    ;;("3~" [delete]) ; lk201
    ;;("3~" [delete]) ; rxvt
    ("4h" [key_sic])            ;; Not an X
    ("4l" [S-delete])           ;; Not an X
    ("4~" [select])
    ;;("4~" [select]) ; lk201
    ;;("4~" [select]) ; rxvt
    ("5$" [S-prior]) ; rxvt
    ("5;2~" [S-prior])
    ("5;3~" [M-prior])
    ("5;4~" [M-S-prior])
    ("5;5~" [C-prior])
    ("5;6~" [C-S-prior])
    ("5;7~" [C-M-prior])
    ("5;8~" [C-M-S-prior])
    ("5^" [C-prior]) ; rxvt
    ("5~" [prior])
    ;;("5~" [prior]) ; lk201
    ;;("5~" [prior]) ; rxvt
    ("6$" [S-next]) ; rxvt
    ("6;2~" [S-next])
    ("6;3~" [M-next])
    ("6;4~" [M-S-next])
    ("6;5~" [C-next])
    ("6;6~" [C-S-next])
    ("6;7~" [C-M-next])
    ("6;8~" [C-M-S-next])
    ("6^" [C-next]) ; rxvt
    ("6~" [next])
    ;;("6~" [next]) ; lk201
    ;;("6~" [next]) ; rxvt
    ("7$" [S-home]) ; rxvt
    ("7^" [C-home]) ; rxvt
    ("7~" [home]) ; rxvt
    ("8$" [S-end]) ; rxvt
    ("8^" [C-end]) ; rxvt
    ("8~" [end]) ; rxvt
    ("?1i" [key_sprint]) ;; Not an X keysym ; tvi
    ("@" [insert]) ; tvi
    ("A" [up])
    ("A" [up]) ; rxvt
    ("B" [down])
    ("B" [down]) ; rxvt
    ("C" [right])
    ("C" [right]) ; rxvt
    ("D" [left])
    ("D" [left]) ; rxvt
    ("E" [?\C-j])        ;; Not an X keysym ; tvi
    ("H" [home]) ; iris-ansi
    ("H" [home]) ; tvi
    ("J" [key_eos])      ;; Not an X keysym ; tvi
    ("K" [key_eol])      ;; Not an X keysym ; tvi
    ("L" [insertline]) ; tvi
    ("M" [M-delete]) ; iris-ansi
    ;;("M" [deleteline]) ; tvi
    ;;("P" [S-delete]) ; iris-ansi
    ;;("P" [delete]) ; iris-ansi
    ("P" [key_dc])       ;; Not an X keysym ; tvi
    ("Q" [S-insertline])       ;; Not an X keysym ; tvi
    ("U" [next]) ;; actually the `page' key ; tvi
    ("V" [S-page])              ;; Not an X keysym ; tvi8
    ("Z" [?\S-\t]) ; iris-ansi
    ;;("Z" [backtab]) ; tvi
    ("a" [S-up]) ; rxvt
    ("b" [S-down]) ; rxvt
    ("c" [S-right]) ; rxvt
    ("d" [S-left]) ; rxvt
    ("e15;5~" [C-f5])
    ("e17;5~" [C-f6])
    ("e18;2~" [S-f7])
    ("e18;5~" [C-f7])
    ("e19;2~" [S-f8])
    ("e19;5~" [C-f8])
    ("e20;2~" [S-f9])
    ("e20;5~" [C-f9])
    ("e21;2~" [S-f10])
    ("e21;5~" [C-f10])
    ("e23;2~" [S-f11])
    ("e23;5~" [C-f11])
    ("e24;2~" [S-f12])
    ;;("g" [S-backtab])    ;; Not an X keysym ; tvi
    ("g" [S-tab])        ;; Not an X keysym ; tvi
    ("i" [print]) ; tvi
    )
  "Ergoemacs terminal ESC [ translations.")

(defvar ergoemacs-M-O-keymap (make-keymap)
  "M-O translation map.")

(defvar ergoemacs-M-o-keymap (make-keymap)
  "M-o translation map.")

(defun ergoemacs-cancel-M-O ()
  "Cancels M-O [timeout] key."
  (setq ergoemacs-push-M-O-timeout nil)
  (when (timerp ergoemacs-M-O-timer)
    (cancel-timer ergoemacs-M-O-timer)))

(defvar ergoemacs-push-M-O-timeout nil
  "Should the M-O [timeout] key be canceled?")

(defvar ergoemacs-curr-prefix-arg nil)

(mapc
 (lambda(x)
   (define-key ergoemacs-M-o-keymap
     (read-kbd-macro (nth 0 x))
     `(lambda(&optional arg) (interactive "P")
        (setq ergoemacs-push-M-O-timeout nil)
        (when (timerp ergoemacs-M-O-timer)
          (cancel-timer ergoemacs-M-O-timer))
        (setq prefix-arg ergoemacs-curr-prefix-arg)
        (setq unread-command-events (cons ',(nth 1 x) unread-command-events))))
   (define-key ergoemacs-M-O-keymap
     (read-kbd-macro (nth 0 x))
     `(lambda(&optional arg) (interactive "P")
        (setq ergoemacs-push-M-O-timeout nil)
        (when (timerp ergoemacs-M-O-timer)
          (cancel-timer ergoemacs-M-O-timer))
        (setq prefix-arg ergoemacs-curr-prefix-arg)
        (setq unread-command-events (cons ',(nth 1 x) unread-command-events)))))
 ergoemacs-M-O-trans)


(defvar ergoemacs-fix-M-O t
  "Fixes the ergoemacs M-O console translation.")

(defvar ergoemacs-M-O-delay 0.01
  "Number of seconds before sending the M-O event instead of sending the terminal's arrow key equivalent.")

(defvar ergoemacs-M-O-timer nil
  "Timer for the M-O")

(defun ergoemacs-exit-M-O-keymap ()
  "Exit M-O keymap and cancel the `ergoemacs-M-O-timer'"
  (setq ergoemacs-push-M-O-timeout nil)
  (when (timerp ergoemacs-M-O-timer)
    (cancel-timer ergoemacs-M-O-timer))
  nil)

(defun ergoemacs-M-O-timeout ()
  "Push timeout on unread command events."
  (when (timerp ergoemacs-M-O-timer)
    (cancel-timer ergoemacs-M-O-timer))
  (when ergoemacs-push-M-O-timeout
    (setq prefix-arg ergoemacs-curr-prefix-arg)
    (setq unread-command-events (cons 'timeout unread-command-events))))

(defun ergoemacs-M-o (&optional arg use-map)
  "Ergoemacs M-o function.
Allows arrow keys and the to work in the terminal. Call the true
function immediately when `window-system' is true."
  (interactive "P")
  (setq ergoemacs-curr-prefix-arg current-prefix-arg)
  (let ((map (or use-map ergoemacs-M-o-keymap)))
    (if window-system
        (let ((fn (lookup-key map [timeout] t)))
          (call-interactively fn t))
      (when (timerp ergoemacs-M-O-timer)
        (cancel-timer ergoemacs-M-O-timer)
        ;; Issue correct command.
        (let ((window-system t))
          (ergoemacs-M-o arg use-map)))
      (setq ergoemacs-push-M-O-timeout t)
      (set-temporary-overlay-map map 'ergoemacs-exit-M-O-keymap)
      (run-with-timer ergoemacs-M-O-delay nil #'ergoemacs-M-O-timeout))))

(defun ergoemacs-M-O (&optional arg)
  "Ergoemacs M-O function to allow arrow keys and the like to work in the terminal."
  (interactive "P")
  (ergoemacs-M-o arg ergoemacs-M-O-keymap))

(require 'ergoemacs-themes)
(require 'ergoemacs-unbind)


(defvar ergoemacs-needs-translation nil
  "Tells if ergoemacs keybindings need a translation")

(defvar ergoemacs-translation-from nil
  "Translation from keyboard layout")

(defvar ergoemacs-translation-to nil
  "Translation to keyboard layout")

(defvar ergoemacs-translation-assoc nil
  "Translation alist")

(defvar ergoemacs-translation-regexp nil
  "Translation regular expression")

;;; ergoemacs-keymap


(defvar ergoemacs-keymap (make-sparse-keymap)
  "ErgoEmacs minor mode keymap.")

(defvar ergoemacs-full-fast-keys-keymap (make-sparse-keymap)
  "Ergoemacs full fast keys keymap")

(defvar ergoemacs-full-alt-keymap (make-keymap)
  "Ergoemacs full Alt+ keymap.  Alt is removed from all these keys so that no key chord is necessary.")

(defvar ergoemacs-full-alt-shift-keymap (make-keymap)
  "Ergoemacs full Alt+Shift+ keymap.
Alt+shift is removed from all these keys so that no key chord is
necessary.  Unshifted keys are changed to shifted keys.")

(defun ergoemacs-exit-dummy ()
  "Dummy function for exiting keymaps."
  (interactive))

(defun ergoemacs-setup-fast-keys ()
  "Setup an array listing the fast keys."
  (interactive)
  (ergoemacs-create-undo-apps-keymap)
  (setq ergoemacs-full-fast-keys-keymap (make-sparse-keymap))
  (setq ergoemacs-full-alt-keymap (make-keymap))
  (setq ergoemacs-full-alt-shift-keymap (make-keymap))
  (define-key ergoemacs-full-alt-keymap (kbd "<menu>") 'ergoemacs-exit-dummy)
  (define-key ergoemacs-full-alt-shift-keymap (kbd "<menu>") 'ergoemacs-exit-dummy)
  (mapc
   (lambda(var)
     (let* ((key (ergoemacs-kbd (nth 0 var) t))
            (cmd (nth 1 var))
            (stripped-key (replace-regexp-in-string "\\<[CM]-" "" key))
            (new-cmd (nth 1 var)))
       (when (string-match "^[A-Za-z]$" stripped-key)
         ;;(message "Stripped key: %s" stripped-key)
         (if (string= (downcase stripped-key) stripped-key)
             (progn
               (define-key ergoemacs-full-alt-keymap (edmacro-parse-keys stripped-key) new-cmd)
               (define-key ergoemacs-full-alt-shift-keymap (edmacro-parse-keys (upcase stripped-key)) new-cmd))
           (define-key ergoemacs-full-alt-shift-keymap (edmacro-parse-keys (downcase stripped-key)) new-cmd)
           (define-key ergoemacs-full-alt-keymap (edmacro-parse-keys stripped-key) new-cmd)))
       (when (member cmd ergoemacs-movement-functions)
         (set (intern (concat "ergoemacs-fast-" (symbol-name cmd) "-keymap"))
              (make-sparse-keymap))
         (eval `(define-key ,(intern (concat "ergoemacs-fast-" (symbol-name cmd) "-keymap"))
                  ,(edmacro-parse-keys stripped-key) new-cmd))
         (define-key ergoemacs-full-fast-keys-keymap
           (edmacro-parse-keys stripped-key)
           new-cmd))))
   (symbol-value (ergoemacs-get-variable-layout))))

(defvar ergoemacs-exit-temp-map-var nil)

(defun ergoemacs-minibuffer-exit-maps ()
  "Exit temporary overlay maps."
  (setq ergoemacs-exit-temp-map-var t))

(add-hook 'minibuffer-setup-hook #'ergoemacs-minibuffer-exit-maps)

(defun ergoemacs-exit-alt-keys ()
  "Exit alt keys predicate."
  (let (ret cmd)
    (condition-case err
        (progn
          (setq cmd (lookup-key ergoemacs-full-alt-keymap
                                (this-command-keys-vector)))
          (when cmd
            (setq ret t))
          (when (eq cmd 'ergoemacs-exit-dummy)
            (setq ret nil))
          (when ergoemacs-exit-temp-map-var
            (setq ret nil)
            (setq ergoemacs-exit-temp-map-var nil)))
      (error (message "Err %s" err)))
    (symbol-value 'ret)))

(defun ergoemacs-alt-keys ()
  "Install the alt keymap temporarily"
  (interactive)
  (setq ergoemacs-exit-temp-map-var nil)
  (set-temporary-overlay-map  ergoemacs-full-alt-keymap
                              'ergoemacs-exit-alt-keys))

(defun ergoemacs-exit-alt-shift-keys ()
  "Exit alt-shift keys predicate"
  (let (ret cmd)
    (condition-case err
        (progn
          (setq cmd (lookup-key ergoemacs-full-alt-shift-keymap
                                (this-command-keys-vector)))
          (when cmd
            (setq ret t))
          (when (eq cmd 'ergoemacs-exit-dummy)
            (setq ret nil))
          (when ergoemacs-exit-temp-map-var
            (setq ret nil)
            (setq ergoemacs-exit-temp-map-var nil)))
      (error (message "Err %s" err)))
    (symbol-value 'ret)))

(defun ergoemacs-alt-shift-keys ()
  "Install the alt-shift keymap temporarily"
  (interactive)
  (setq ergoemacs-exit-temp-map-var nil)
  (set-temporary-overlay-map ergoemacs-full-alt-shift-keymap
                             'ergoemacs-exit-alt-shift-keys))

(require 'ergoemacs-functions)

(defun ergoemacs-setup-translation (layout &optional base-layout)
  "Setup translation from BASE-LAYOUT to LAYOUT."
  (let ((base (or base-layout "us"))
        lay
        len i)
    (unless (and (string= layout ergoemacs-translation-to)
                 (string= base ergoemacs-translation-from))
      (if (equal layout base)
          (progn
            (setq ergoemacs-translation-from base)
            (setq ergoemacs-translation-to layout)
            (setq ergoemacs-needs-translation nil)
            (setq ergoemacs-translation-assoc nil)
            (setq ergoemacs-translation-regexp nil))
        (setq ergoemacs-translation-from base)
        (setq ergoemacs-translation-to layout)
        (setq lay (symbol-value (intern (concat "ergoemacs-layout-" layout))))
        (setq base (symbol-value (intern (concat "ergoemacs-layout-" base))))
        (setq ergoemacs-needs-translation t)
        (setq ergoemacs-translation-assoc nil)
        (setq len (length base))
        (setq i 0)
        (while (< i len)
          (unless (or (string= "" (nth i base))
                      (string= "" (nth i lay)))
            (add-to-list 'ergoemacs-translation-assoc
                         `(,(nth i base) . ,(nth i lay))))
          (setq i (+ i 1)))
        (setq ergoemacs-translation-regexp
              (format "\\(-\\| \\|^\\)\\(%s\\)\\($\\| \\)"
                      (regexp-opt (mapcar (lambda(x) (nth 0 x))
                                          ergoemacs-translation-assoc) nil)))))))

(defvar ergoemacs-kbd-hash nil)

(setq ergoemacs-kbd-hash (make-hash-table :test 'equal))
;; This is called so frequently make a hash-table of the results.

(defun ergoemacs-kbd (key &optional just-translate only-first)
  "Translates kbd code KEY for layout `ergoemacs-translation-from' to kbd code for `ergoemacs-translation-to'.
If JUST-TRANSLATE is non-nil, just return the KBD code, not the actual emacs key sequence.
"
  (save-match-data
    (if (not key)
        nil
      (let ((new-key (gethash `(,key ,just-translate ,only-first ,ergoemacs-translation-from ,ergoemacs-translation-to)
                              ergoemacs-kbd-hash)))
        (if new-key
            (symbol-value 'new-key)
          (setq new-key key)
          (cond
           ((eq system-type 'windows-nt)
            (setq new-key (replace-regexp-in-string "<menu>" "<apps>" new-key)))
           (t
            (setq new-key (replace-regexp-in-string "<apps>" "<menu>" new-key))))
          ;; Translate Alt+ Ctl+ or Ctrl+ to M- and C-
          (setq new-key (replace-regexp-in-string "[Aa][Ll][Tt][+]" "M-" new-key))
          (setq new-key (replace-regexp-in-string "[Cc][Tt][Rr]?[Ll][+]" "C-" new-key))
        (when ergoemacs-needs-translation
          (setq new-key
                (with-temp-buffer
                  (insert new-key)
                  (goto-char (point-min))
                  (when (re-search-forward ergoemacs-translation-regexp nil t)
                    (replace-match (concat (match-string 1) (cdr (assoc (match-string 2) ergoemacs-translation-assoc)) (match-string 3)) t t)
                    (skip-chars-backward " "))
                  (when (not only-first)
                    (while (re-search-forward ergoemacs-translation-regexp nil t)
                      (replace-match (concat (match-string 1) (cdr (assoc (match-string 2) ergoemacs-translation-assoc)) (match-string 3)) t t)
                      (skip-chars-backward " ")))
                  (buffer-string))))
        (if (not just-translate)
             (condition-case err
                (read-kbd-macro new-key)
              (error
               (read-kbd-macro (encode-coding-string new-key locale-coding-system))))
          (puthash `(,key ,just-translate ,only-first ,ergoemacs-translation-from ,ergoemacs-translation-to) new-key
                   ergoemacs-kbd-hash)
          new-key))))))

(defvar ergoemacs-backward-compatability-variables
  '((ergoemacs-backward-paragraph-key            backward-block)
    (ergoemacs-forward-paragraph-key             forward-block)
    (ergoemacs-recenter-key                      recenter-top-bottom)
    (ergoemacs-kill-region-key                   cut-line-or-region)
    (ergoemacs-kill-ring-save-key                copy-line-or-region))
  "Backward compatible variables that do not follow the convention ergoemacs-FUNCTION-key")

(defun ergoemacs-setup-backward-compatability ()
  "Set up backward-compatible variables"
  (mapc
   (lambda(var)
     (condition-case err
         (eval `(setq ,(intern (concat "ergoemacs-" (symbol-name (nth 1 var)) "-key")) (ergoemacs-kbd (nth 0 var))))
       (error (ergoemacs-debug "Ignored backward compatability for %s" (nth 1 var)))))
   (symbol-value (ergoemacs-get-variable-layout)))
  (mapc
   (lambda(var)
     (let ((saved-var (intern-soft (concat "ergoemacs-" (symbol-name (nth 1 var)) "-key"))))
       (when saved-var
         (set (nth 0 var) (symbol-value saved-var)))))
   ergoemacs-backward-compatability-variables))

(defcustom ergoemacs-swap-alt-and-control nil
  "Swaps Alt and Ctrl keys"
  :type 'boolean
  :set 'ergoemacs-set-default
  :group 'ergoemacs-mode)

(defun ergoemacs-get-kbd-translation (pre-kbd-code &optional dont-swap)
  "This allows a translation from the listed kbd-code and the true kbd code."
  (let ((ret (replace-regexp-in-string
              "[Cc]\\(?:on\\)?tro?l[+-]" "C-"
              (replace-regexp-in-string
               "[Aa]lt[+-]" "M-" pre-kbd-code))))
    (when (and ergoemacs-swap-alt-and-control (not dont-swap))
      (setq ret
            (replace-regexp-in-string
             "\\^-" "M-"
             (replace-regexp-in-string
              "M-" "C-"
              (replace-regexp-in-string
               "C-" "^-" ret)))))
    (symbol-value 'ret)))

(defun ergoemacs-setup-keys-for-keymap---internal (keymap key def)
  "Defines KEY in KEYMAP to be DEF"
  (cond
   ((eq 'cons (type-of def))
    (let (found)
      (if (condition-case err
              (stringp (nth 0 def))
            (error nil))
          (progn
            (eval
             (macroexpand
              `(progn
                 (ergoemacs-keyboard-shortcut
                  ,(intern (concat "ergoemacs-shortcut---"
                                   (md5 (format "%s; %s" (nth 0 def)
                                                (nth 1 def))))) ,(nth 0 def)
                                                ,(nth 1 def))
                 (define-key keymap key
                   ',(intern (concat "ergoemacs-shortcut---"
                                     (md5 (format "%s; %s" (nth 0 def)
                                                  (nth 1 def))))))))))
        (mapc
         (lambda(new-def)
           (unless found
             (setq found
                   (ergoemacs-setup-keys-for-keymap---internal keymap key new-def))))
         def))
      (symbol-value 'found)))
   ((condition-case err
        (fboundp def)
      (error nil))
    (define-key keymap key def)
    t)
   ((condition-case err
        (keymapp (symbol-value def))
      (error nil))
    (define-key keymap key (symbol-value def))
    t)
   ((condition-case err
	(stringp def)
      (error nil))
    (eval (macroexpand `(progn
                          (ergoemacs-keyboard-shortcut
                           ,(intern (concat "ergoemacs-shortcut---"
                                            (md5 (format "%s; nil" def)))) ,def)
                          (define-key keymap key
                            ',(intern (concat "ergoemacs-shortcut---"
                                              (md5 (format "%s; nil" def))))))))
    t)
   (t nil)))

(defmacro ergoemacs-setup-keys-for-keymap (keymap)
  "Setups ergoemacs keys for a specific keymap"
  `(let ((no-ergoemacs-advice t)
         (case-fold-search t)
         key
         trans-key
         cmd cmd-tmp)
     (setq ,keymap (make-sparse-keymap))
     (if (eq ',keymap 'ergoemacs-keymap)
         (ergoemacs-debug "Theme: %s" ergoemacs-theme))
     ;; Fixed layout keys
     (mapc
      (lambda(x)
        (when (and (eq 'string (type-of (nth 0 x))))
          (setq trans-key (ergoemacs-get-kbd-translation (nth 0 x)))
          (condition-case err
              (setq key (read-kbd-macro
                         trans-key))
            (error
             (setq key (read-kbd-macro
                        (encode-coding-string
                         trans-key
                         locale-coding-system)))))
          (if (ergoemacs-global-changed-p trans-key)
              (progn
                (ergoemacs-debug "!!!Fixed %s has changed globally." trans-key) 
                (define-key ,keymap key  (lookup-key (current-global-map) key)))
            (setq cmd (nth 1 x))
	    (if (eq ',keymap 'ergoemacs-keymap)
                (ergoemacs-debug "Fixed: %s -> %s %s" trans-key cmd key))
            (when (not (ergoemacs-setup-keys-for-keymap---internal ,keymap key cmd))
	      (ergoemacs-debug "Not loaded")))))
       (symbol-value (ergoemacs-get-fixed-layout)))
     
     ;; Variable Layout Keys
     (mapc
      (lambda(x)
        (when (and (eq 'string (type-of (nth 0 x))))
          (setq trans-key
                (ergoemacs-get-kbd-translation (nth 0 x)))
          (setq key (ergoemacs-kbd trans-key nil (nth 3 x)))
          (if (ergoemacs-global-changed-p trans-key t)
              (progn
                (ergoemacs-debug "!!!Variable %s (%s) has changed globally."
                                 trans-key (ergoemacs-kbd trans-key t (nth 3 x))))
            ;; Add M-O and M-o handling for globally defined M-O and
            ;; M-o.
            ;; Only works if ergoemacs-mode is on...
            (setq cmd (nth 1 x))
            
            (if (and ergoemacs-fix-M-O (string= (ergoemacs-kbd trans-key t t) "M-O"))
                (progn
                  (define-key ,keymap key  'ergoemacs-M-O)
                  (ergoemacs-setup-keys-for-keymap---internal ergoemacs-M-O-keymap [timeout] cmd)
                  (if (eq ',keymap 'ergoemacs-keymap)
                      (ergoemacs-debug "Variable: %s (%s) -> %s %s via ergoemacs-M-O" trans-key (ergoemacs-kbd trans-key t (nth 3 x)) cmd key)))
              (if (and ergoemacs-fix-M-O
                       (string= (ergoemacs-kbd trans-key t t) "M-o"))
                  (progn
                    (define-key ,keymap key  'ergoemacs-M-o)
                    (ergoemacs-setup-keys-for-keymap---internal ergoemacs-M-o-keymap [timeout] cmd)
                    (if (eq ',keymap 'ergoemacs-keymap)
                        (ergoemacs-debug "Variable: %s (%s) -> %s %s via ergoemacs-M-o" trans-key
                                 (ergoemacs-kbd trans-key t (nth 3 x)) cmd key)))
                (when cmd
                  (ergoemacs-setup-keys-for-keymap---internal ,keymap key cmd)
                  (if (eq ',keymap 'ergoemacs-keymap)
                      (ergoemacs-debug "Variable: %s (%s) -> %s %s" trans-key (ergoemacs-kbd trans-key t (nth 3 x)) cmd key))))))))
      (symbol-value (ergoemacs-get-variable-layout)))
     (when ergoemacs-fix-M-O
       (let ((M-O (lookup-key ,keymap (read-kbd-macro "M-O")))
             (g-M-O (lookup-key global-map (read-kbd-macro "M-O")))
             (M-o (lookup-key ,keymap (read-kbd-macro "M-o")))
             (g-M-o (lookup-key global-map (read-kbd-macro "M-o"))))
         (ergoemacs-debug "M-O %s; Global M-O: %s; M-o %s; Global M-o: %s" M-O g-M-O M-o g-M-o)
         (when (and (not (functionp M-O))
                    (functionp g-M-O))
           (ergoemacs-debug "Fixed M-O")
           (define-key ,keymap (read-kbd-macro "M-O") 'ergoemacs-M-O)
           (define-key ergoemacs-M-O-keymap [timeout] g-M-O))
         (when (and (not (functionp M-o))
                    (functionp g-M-o))
           (ergoemacs-debug "Fixed M-o")
           (define-key ,keymap (read-kbd-macro "M-o") 'ergoemacs-M-o)
           (define-key ergoemacs-M-o-keymap [timeout] g-M-o))))))

(defun ergoemacs-setup-keys-for-layout (layout &optional base-layout)
  "Setup keys based on a particular LAYOUT. All the keys are based on QWERTY layout."
  (ergoemacs-setup-translation layout base-layout)
  (ergoemacs-setup-fast-keys)
  (ergoemacs-setup-keys-for-keymap ergoemacs-keymap)
  
  ;; Now change `minor-mode-map-alist'.
  (let ((x (assq 'ergoemacs-mode minor-mode-map-alist)))
    ;; Install keymap
    (if x
        (setq minor-mode-map-alist (delq x minor-mode-map-alist)))
    (add-to-list 'minor-mode-map-alist
                 `(ergoemacs-mode  ,(symbol-value 'ergoemacs-keymap))))
  (easy-menu-define ergoemacs-menu ergoemacs-keymap
    "ErgoEmacs menu"
    `("ErgoEmacs"
      ,(ergoemacs-get-layouts-menu)
      ,(ergoemacs-get-themes-menu)
      "--"
      ["Make Bash aware of ergoemacs keys"
       (lambda () (interactive)
         (call-interactively 'ergoemacs-bash)) t]
      "--"
      ["Use Menus"
       (lambda() (interactive)
         (setq ergoemacs-use-menus (not ergoemacs-use-menus))
         (if ergoemacs-use-menus
             (progn
               (require 'ergoemacs-menus)
               (ergoemacs-menus-on))
           (when (featurep 'ergoemacs-menus)
             (ergoemacs-menus-off))))
       :style toggle :selected (symbol-value 'ergoemacs-use-menus)]
      "--"
      ;; ["Generate Documentation"
      ;;  (lambda()
      ;;    (interactive)
      ;;    (call-interactively 'ergoemacs-extras)) t]
      ["Customize Ergoemacs"
       (lambda ()
         (interactive)
         (customize-group 'ergoemacs-mode)) t]
      ["Save Settings for Future Sessions"
       (lambda ()
         (interactive)
         (customize-save-variable 'ergoemacs-use-menus ergoemacs-use-menus)
         (customize-save-variable 'ergoemacs-theme ergoemacs-theme)
         (customize-save-variable 'ergoemacs-keyboard-layout ergoemacs-keyboard-layout)
         (customize-save-customized)) t]
      ["Exit ErgoEmacs"
       (lambda ()
         (interactive)
         (ergoemacs-mode -1)) t]))
  
  (let ((existing (assq 'ergoemacs-mode minor-mode-map-alist)))
    (if existing
        (setcdr existing ergoemacs-keymap)
      (push (cons 'ergoemacs-mode ergoemacs-keymap) minor-mode-map-alist)))
  
  ;; Set appropriate mode-line indicator
  (setq minor-mode-alist
        (mapcar (lambda(x)
                  (if (not (eq 'ergoemacs-mode (nth 0 x)))
                      x
                    `(ergoemacs-mode ,(concat
                                       (if (not ergoemacs-theme)
                                           " ErgoEmacs"
                                         (concat " Ergo"
                                                 (upcase (substring ergoemacs-theme 0 1))
                                                 (substring ergoemacs-theme 1)))
                                       "[" ergoemacs-keyboard-layout "]"))))
                minor-mode-alist))
  (ergoemacs-setup-backward-compatability))

(require 'lookup-word-on-internet nil "NOERROR")
(require 'ergoemacs-extras)

;; ErgoEmacs hooks
(defun ergoemacs-key-fn-lookup (function &optional use-apps)
  "Looks up the key binding for FUNCTION based on `ergoemacs-get-variable-layout'."
  (let ((ret nil))
    (mapc
     (lambda(x)
       (when (and (equal (nth 1 x) function)
                  (if use-apps
                      (string-match "<apps>" (nth 0 x))
                    (not (string-match "<apps>" (nth 0 x)))))
         (setq ret (ergoemacs-kbd (nth 0 x) nil (nth 3 x)))))
     (symbol-value (ergoemacs-get-variable-layout)))
    (symbol-value 'ret)))

(defun ergoemacs-hook-define-key (keymap key-def definition translate)
  "Ergoemacs `define-key' in hook."
  (if (or (not (condition-case err
                   (keymapp keymap)
                 (error nil)))
          (not key-def)) nil
    (let ((fn definition))
      (when (stringp definition)
        (eval (macroexpand `(progn
                              (ergoemacs-keyboard-shortcut
                               ,(intern (concat "ergoemacs-shortcut---"
                                                (md5 (format "%s" definition)))) ,definition)
                              (setq fn ',(intern (concat "ergoemacs-shortcut---"
                                                         (md5 (format "%s" definition)))))))))
      (if (and (eq translate 'remap)
               (functionp key-def)
               (functionp fn))
          (let ((no-ergoemacs-advice t))
            (define-key keymap
              (eval (macroexpand `[remap ,(intern (symbol-name key-def))]))
              fn))
        (let* ((no-ergoemacs-advice t)
               (key-code
                (cond
                 ((and translate (eq 'string (type-of key-def)))
                  (ergoemacs-kbd key-def))
                 ((eq 'string (type-of key-def))
                  (condition-case err
                      (read-kbd-macro key-def)
                    (error (read-kbd-macro
                            (encode-coding-string key-def locale-coding-system)))))
                 ((ergoemacs-key-fn-lookup key-def)
                  ;; Also define <apps> key
                  (when (ergoemacs-key-fn-lookup key-def t)
                    (define-key keymap (ergoemacs-key-fn-lookup key-def t) fn))
                  (ergoemacs-key-fn-lookup key-def))
                 ;; Define <apps>  key
                 ((ergoemacs-key-fn-lookup key-def t)
                  (ergoemacs-key-fn-lookup key-def t)
                  nil)
                 (t
                  (if (and (functionp key-def)
                           (functionp fn))
                      (eval
                       (macroexpand `[remap ,(intern (symbol-name key-def))]))
                    nil)))))
          (ergoemacs-debug "hook: %s->%s %s %s"
                           key-def key-code
                           fn translate)
          (when key-code
            (define-key keymap key-code fn)))))))

(defmacro ergoemacs-create-hook-function (hook keys &optional global)
  "Creates a hook function based on the HOOK and the list of KEYS defined."
  (let ((is-override (make-symbol "is-override"))
        (minor-mode-p (make-symbol "minor-mode-p"))
        (old-keymap (make-symbol "old-keymap"))
        (override-keymap (make-symbol "override-keymap")))
    (setq is-override (eq 'minor-mode-overriding-map-alist (nth 2 (nth 0 keys))))
    (setq minor-mode-p (eq 'override (nth 2 (nth 0 keys))))
    `(progn
       ,(if (or is-override minor-mode-p)
            (progn
	      (setq old-keymap nil)
	      `(progn
		 (defvar ,(intern (concat "ergoemacs-" (symbol-name hook) "-keymap")) nil
		   ,(concat "Ergoemacs overriding keymap for `" (symbol-name hook) "'"))))
	  (setq old-keymap t)
          (setq override-keymap (nth 2 (nth 0 keys)))
          `(defvar ,(intern (concat "ergoemacs-" (symbol-name hook) "-old-keymap")) nil
             ,(concat "Old keymap for `" (symbol-name hook) "'.")))
       
       ,(when minor-mode-p
         `(define-minor-mode ,(intern (concat "ergoemacs-" (symbol-name hook) "-mode"))
            ,(concat "Minor mode for `" (symbol-name hook) "' so ergoemacs keybindings are not lost.
This is an automatically generated function derived from `ergoemacs-get-minor-mode-layout'. See `ergoemacs-mode'.")
	    nil
	    :lighter ""
	    :global nil
	    :keymap ,(intern (concat "ergoemacs-" (symbol-name hook) "-keymap"))))

       (defun ,(intern (concat "ergoemacs-" (symbol-name hook))) ()
         ,(concat "Hook for `" (symbol-name hook) "' so ergoemacs keybindings are not lost.
This is an automatically generated function derived from `ergoemacs-get-minor-mode-layout'.")
         ;; Only generate keymap if it hasn't previously been generated.
         (unless ,(if (or minor-mode-p is-override) nil
                    (intern (concat "ergoemacs-" (symbol-name hook) "-old-keymap")))
           
           ,(if (or is-override minor-mode-p)
                `(ergoemacs-setup-keys-for-keymap ,(intern (concat "ergoemacs-" (symbol-name hook) "-keymap")))
              `(setq ,(intern (concat "ergoemacs-" (symbol-name hook) "-old-keymap"))
                     (copy-keymap ,(nth 2 (nth 0 keys)))))
           ,@(mapcar
              (lambda(def)
                `(ergoemacs-hook-define-key
                  ,(if (or minor-mode-p
                           (and is-override
                                (equal (nth 2 def)
                                       'minor-mode-overriding-map-alist)))
                       (intern (concat "ergoemacs-" (symbol-name hook) "-keymap"))
                     (nth 2 def))
                  ,(if (eq (type-of (nth 0 def)) 'string)
                       `,(nth 0 def)
                     `(quote ,(nth 0 def)))
                  ',(nth 1 def)
                  ',(nth 3 def)))
              keys)
           ,(when minor-mode-p
              `(progn
                 (let ((x (assq ',(intern (concat "ergoemacs-" (symbol-name hook) "-mode"))
                                minor-mode-map-alist)))
                   ;; Delete keymap.
                   (if x
                       (setq minor-mode-map-alist (delq x minor-mode-map-alist)))
                 (add-to-list 'minor-mode-map-alist
                              (cons ',(intern (concat "ergoemacs-" (symbol-name hook) "-mode"))
                                    ,(intern (concat "ergoemacs-" (symbol-name hook) "-keymap"))))
                 (funcall ',(intern (concat "ergoemacs-" (symbol-name hook) "-mode")) 1))))
           ,(if is-override
                `(add-to-list 'minor-mode-overriding-map-alist
                              (cons 'ergoemacs-mode ,(intern (concat "ergoemacs-" (symbol-name hook) "-keymap")))
                              nil ,(if (equal hook 'minibuffer-setup-hook)
                                       '(lambda (x y)
                                          (equal (car y) (car x)))
                                     nil))
              nil)
           (ergoemacs-debug-flush)
           t))
       (ergoemacs-add-hook ',hook ',(intern (concat "ergoemacs-" (symbol-name hook))) ',(if old-keymap (intern (concat "ergoemacs-" (symbol-name hook) "-old-keymap"))) ',override-keymap))))

(defun ergoemacs-pre-command-install-minor-mode-overriding-map-alist ()
  "Install `minor-mode-overriding-map-alist' if it didn't get installed (like in some `org-mode')."
  (let ((hook (intern-soft (format "ergoemacs-%s-hook" major-mode))))
    (when hook
      (funcall hook))))

(defvar ergoemacs-hook-list (list)
"List of hook and hook-function pairs.")

(defun ergoemacs-add-hook (hook hook-function old-keymap keymap-name)
  "Adds a pair of HOOK and HOOK-FUNCTION to the list `ergoemacs-hook-list'."
  (add-to-list 'ergoemacs-hook-list (list hook hook-function old-keymap keymap-name)))

(defvar ergoemacs-advices '()
  "List of advices to enable and disable when ergoemacs is running.")

(defun ergoemacs-hook-modes ()
  "Installs/Removes ergoemacs minor mode hooks from major modes
depending the state of `ergoemacs-mode' variable.  If the mode
is being initialized, some global keybindings in current-global-map
will change."
  (let ((modify-advice (if (and (boundp 'ergoemacs-mode) ergoemacs-mode) 'ad-enable-advice 'ad-disable-advice)))    
    ;; when ergoemacs-mode is on, activate hooks and unset global keys, else do inverse
    (if (and (boundp 'ergoemacs-mode) ergoemacs-mode (not (equal ergoemacs-mode 0)))
        (progn
          (ergoemacs-unset-redundant-global-keys)
          ;; alt+n is the new "Quit" in query-replace-map
          (when (ergoemacs-key-fn-lookup 'keyboard-quit)
            (ergoemacs-unset-global-key query-replace-map "\e")
            (define-key query-replace-map (ergoemacs-key-fn-lookup 'keyboard-quit) 'exit-prefix)))
      ;; if ergoemacs was disabled: restore original keys
      (ergoemacs-restore-global-keys))
    
    ;; install the mode-hooks
    (dolist (hook ergoemacs-hook-list)
      (if (and (boundp 'ergoemacs-mode) ergoemacs-mode)
          (add-hook (nth 0 hook) (nth 1 hook) t)
        (remove-hook (nth 0 hook) (nth 1 hook)))
      ;; Restore original keymap
      (when (and (not (and (boundp 'ergoemacs-mode) ergoemacs-mode))
                 (nth 2 hook)
                 (nth 3 hook)
                 (symbol-value (nth 2 hook))
                 (symbol-value (nth 3 hook)))
        (set (nth 3 hook)
             (copy-keymap (symbol-value (nth 2 hook))))
        (set (nth 2 hook) nil)))
    
    ;; enable advices
    (mapc
     (lambda(advice)
       (condition-case err
           (let ((fn (intern (replace-regexp-in-string "\\(^ergoemacs-\\|-advice$\\)" "" (symbol-name advice)))))
             (funcall modify-advice fn 'around advice)
             (ad-activate fn))
         (error "Error modifying advice %s" (symbol-name advice))))
     ergoemacs-advices)))

(defun ergoemacs-create-hooks ()
  "Creates Ergoemacs Hooks from `ergoemacs-get-minor-mode-layout'."
  (let ((ergoemacs-mode))
    (ergoemacs-hook-modes))
  (setq ergoemacs-hook-list nil)
  (mapc
   (lambda(x)
     (let ((f (macroexpand `(ergoemacs-create-hook-function ,(car x) ,(car (cdr x))))))
       (eval f)))
   (symbol-value (ergoemacs-get-minor-mode-layout)))
  (ergoemacs-hook-modes))

(defun ergoemacs-setup-keys (&optional no-check)
  "Setups keys based on a particular layout. Based on `ergoemacs-keyboard-layout'."
  (interactive)
  (ergoemacs-debug "Ergoemacs layout: %s" ergoemacs-keyboard-layout)
  (ergoemacs-debug "Ergoemacs theme: %s" ergoemacs-theme)
  (ergoemacs-debug "Emacs Version: %s" (emacs-version))
  (let ((ergoemacs-state (if (boundp 'ergoemacs-mode) ergoemacs-mode nil))
        (cua-state cua-mode)
        (layout
         (intern-soft
          (concat "ergoemacs-layout-" ergoemacs-keyboard-layout))))
    (unless no-check
      (when ergoemacs-state
        (when (fboundp 'ergoemacs-mode)
          (ergoemacs-mode -1)
          (when cua-state
            (cua-mode -1)))))
    (cond
     (layout
      (ergoemacs-setup-keys-for-layout ergoemacs-keyboard-layout))
     (t ; US qwerty by default
      (ergoemacs-setup-keys-for-layout "us")))
    (ergoemacs-create-hooks)
    
    (unless no-check
      (when ergoemacs-state
        (when (fboundp 'ergoemacs-mode)
          (ergoemacs-mode 1)
          (when cua-state
            (cua-mode 1)))))))

(defun ergoemacs-lookup-execute-extended-command ()
  "Lookup the execute-extended-command"
  (key-description
   (or (ergoemacs-key-fn-lookup 'execute-extended-command)
       (ergoemacs-key-fn-lookup 'smex)
       (ergoemacs-key-fn-lookup 'helm-M-x))))

(defcustom ergoemacs-translate-keys t
  "When translating extracted keymaps, attempt to translate to
the best match."
  :type 'boolean
  :group 'ergoemacs-mode)

(defvar ergoemacs-extract-map-hash (make-hash-table :test 'equal))

(defmacro ergoemacs-extract-maps (keymap &optional prefix)
  "Extracts maps."
  `(let ((buf (current-buffer))
         (normal '())
         (translations '())
         (prefixes '())
         (bound-regexp "")
         (tmp "")
         (fn nil)
         (new-key nil)
	 (start-time (float-time))
	 (last-time nil)
         (cur-prefix (or ,prefix "C-x"))
         (hashkey "")
         (prefix-regexp ""))
     (ergoemacs-debug (make-string 80 ?=))
     (ergoemacs-debug "Extracting maps for %s" cur-prefix)
     (ergoemacs-debug (make-string 80 ?=))
     (with-temp-buffer
       (describe-buffer-bindings buf (read-kbd-macro cur-prefix))
       (goto-char (point-min))
       (while (re-search-forward (format "%s \\(.*?\\)[ \t]\\{2,\\}\\(.+\\)$" cur-prefix) nil t)
         (setq new-key (match-string 1))
         (setq fn (match-string 2))
         (unless (string-match " " new-key)
           (if (string-match "Prefix Command$" (match-string 0))
               (unless (string-match "ESC" new-key)
                 (ergoemacs-debug "Prefix: %s" new-key)
                 (add-to-list 'prefixes new-key))
             (unless (string-match "ergoemacs-old-key---" fn)
               (condition-case err
                   (with-temp-buffer
                     (insert "(if (keymapp '" fn
                             ") (unless (string-match \"ESC\" \"" new-key
                             "\") (add-to-list 'prefixes \"" new-key
                             "\") (ergoemacs-debug \"Prefix (keymap): %s\" new-key)) (add-to-list 'normal '(\"" new-key
                             "\" " fn ")) (ergoemacs-debug \"Normal: %s -> %s\" new-key fn))")
                     (eval-buffer)
                     (when ergoemacs-translate-keys
                       (cond
                        ((string-match "\\( \\|^\\)C-\\([a-zA-Z'0-9{}/,.`]\\)$" new-key)
                         (add-to-list 'translations
                                      (list (replace-match "\\1\\2" t nil new-key)
                                            fn)))
                        ((string-match "\\( \\|^\\)\\([a-zA-Z'0-9{}/,.`]\\)$" new-key)
                         (add-to-list 'translations
                                      (list (replace-match "\\1C-\\2" t nil new-key)
                                            fn))))))
                 (error (setq fn nil))))))))

     (ergoemacs-debug (make-string 80 ?=))
     (ergoemacs-debug "Finished (%1f sec); Building keymap" (- (float-time) start-time))
     (setq last-time (float-time))
     (ergoemacs-debug (make-string 80 ?=))
     (setq hashkey (md5 (format "%s;%s;%s" cur-prefix normal prefixes)))
     (setq ,keymap (gethash hashkey ergoemacs-extract-map-hash))
     (unless ,keymap
       (setq ,keymap (make-keymap))
       (mapc
        (lambda(x)
          (if (not (functionp (nth 1 x)))
              (progn
                (ergoemacs-debug "Not a function: %s %s => %s" cur-prefix normal (nth 1 x)))
            (let* ((normal (nth 0 x))
                   (ctl-to-alt
                    (replace-regexp-in-string
                     "\\<W-" "M-"
                     (replace-regexp-in-string
                      "\\<M-" "C-"
                      (replace-regexp-in-string "\\<C-" "W-" normal))))
                   (unchorded
                    (replace-regexp-in-string
                     "\\<W-" ""
                     (replace-regexp-in-string
                      "\\(^\\| \\)\\([^-]\\)\\( \\|$\\)" "\\1M-\\2\\3"
                      (replace-regexp-in-string "\\<M-" "W-" ctl-to-alt)))))
              (ergoemacs-debug "<Normal> %s %s => %s" cur-prefix normal (nth 1 x))
              (define-key ,keymap
                (read-kbd-macro (format "<Normal> %s %s" cur-prefix normal))
                `(lambda(&optional arg)
                   (interactive "P")
                   (ergoemacs-menu-send-function ,cur-prefix ,normal ',(nth 1 x))))
              (define-key ,keymap
                (read-kbd-macro
                 (format "<Ctl%sAlt> %s %s" 
                         (ergoemacs-unicode-char "↔" " to ")
                         cur-prefix ctl-to-alt))
                `(lambda(&optional arg)
                   (interactive "P")
                   (ergoemacs-menu-send-function ,cur-prefix ,normal ',(nth 1 x))))
              (ergoemacs-debug "<Ctl%sAlt> %s %s => %s"
                               (ergoemacs-unicode-char "↔" " to ")
                               cur-prefix ctl-to-alt (nth 1 x))
              
              (define-key ,keymap
                (read-kbd-macro
                 (format "<Unchorded> %s %s" cur-prefix unchorded))
                `(lambda(&optional arg)
                   (interactive "P")
                   (ergoemacs-menu-send-function ,cur-prefix ,normal ',(nth 1 x))))
              (ergoemacs-debug "<Unchorded> %s %s => %s"
                               cur-prefix unchorded (nth 1 x)))))
        normal)
       (ergoemacs-debug (make-string 80 ?=))
       (ergoemacs-debug "Built (%1f s;%1f s); Adding Prefixes" 
                        (- (float-time) start-time)
                        (- (float-time) last-time))
       (setq last-time (float-time))
       (ergoemacs-debug (make-string 80 ?=))
       
       ;; Now add prefixes.
       (mapc
        (lambda(x)
          (let ((new (replace-regexp-in-string
                      "\\<W-" "M-"
                      (replace-regexp-in-string
                       "\\<M-" "C-"
                       (replace-regexp-in-string "\\<C-" "W-" x)))))

            (condition-case err
                (define-key ,keymap
                  (read-kbd-macro (format "<Normal> %s %s" cur-prefix x))
                  `(lambda(&optional arg)
                     (interactive "P")
                     (ergoemacs-menu-send-prefix ,cur-prefix ,x 'normal)))
              (error nil))

            (condition-case err
                (define-key ,keymap 
                  (read-kbd-macro
                   (format "<Ctl%sAlt> %s %s" 
                           (ergoemacs-unicode-char "↔" " to ")
                           cur-prefix new))
                  `(lambda(&optional arg)
                     (interactive "P")
                     (ergoemacs-menu-send-prefix ,cur-prefix ,x 'ctl-to-alt)))
              (error nil))
            
            (setq new
                  (replace-regexp-in-string
                   "\\<W-" ""
                   (replace-regexp-in-string
                    "\\(^\\| \\)\\([^-]\\)\\( \\|$\\)" "\\1M-\\2\\3"
                    (replace-regexp-in-string "\\<M-" "W-" new))))
            
            (condition-case err
                (define-key ,keymap 
                  (read-kbd-macro
                   (format "<Unchorded> %s %s"
                           cur-prefix new))
                  `(lambda(&optional arg)
                     (interactive "P")
                     (ergoemacs-menu-send-prefix ,cur-prefix ,x 'unchorded)))
              (error nil))))
        prefixes)

       (ergoemacs-debug (make-string 80 ?=))
       (ergoemacs-debug "Built (%1f s;%1f s); Translating keys" 
                        (- (float-time) start-time)
                        (- (float-time) last-time))
       (setq last-time (float-time))
       (ergoemacs-debug (make-string 80 ?=))
       
       ;;
       (when ergoemacs-translate-keys
         (setq bound-regexp
               (format "^%s$"
                       (regexp-opt
                        (append
                         (mapcar (lambda(x) (nth 0 x))
                                 normal) prefixes) t)))
         (ergoemacs-debug (make-string 80 ?=))
         (ergoemacs-debug "Translating keys for %s" cur-prefix)
         (ergoemacs-debug (make-string 80 ?=))
         (mapc
          (lambda(x)
            (if (string-match bound-regexp (nth 0 x))
                (ergoemacs-debug "Assume %s is already defined" x)
              (ergoemacs-debug "Testing %s; %s" x (functionp (intern (nth 1 x))))
              (when (functionp (intern (nth 1 x)))    
                (let* ((fn (intern (nth 1 x)))
                       (normal (nth 0 x))
                       (ctl-to-alt
                        (replace-regexp-in-string
                         "\\<W-" "M-"
                         (replace-regexp-in-string
                          "\\<M-" "C-"
                          (replace-regexp-in-string "\\<C-" "W-" normal))))
                       (unchorded
                        (replace-regexp-in-string
                         "\\<W-" ""
                         (replace-regexp-in-string
                          "\\(^\\| \\)\\([^-]\\)\\( \\|$\\)" "\\1M-\\2\\3"
                          (replace-regexp-in-string "\\<M-" "W-" ctl-to-alt)))))
                  (let ((curr-kbd (format "<Normal> %s %s" cur-prefix normal)))
                    (ergoemacs-debug "\tcurr-kbd: %s" curr-kbd)
                    (define-key ,keymap
                      (read-kbd-macro curr-kbd) fn)
                    (condition-case err
                        (ergoemacs-debug "<Normal> %s %s => %s" cur-prefix normal fn)
                      (error (ergoemacs-debug "%s" err)))
                    (setq curr-kbd
                          (format "<Ctl%sAlt> %s %s" 
                                  (ergoemacs-unicode-char "↔" " to ")
                                  cur-prefix ctl-to-alt))
                    (ergoemacs-debug "\tcurr-kbd: %s" curr-kbd)
                    (condition-case err
                        (define-key ,keymap
                          (read-kbd-macro curr-kbd) fn)
                      (error (ergoemacs-debug "%s" err)))
                    (ergoemacs-debug "<Ctl%sAlt> %s %s => %s"
                                     (ergoemacs-unicode-char "↔" " to ")
                                     cur-prefix ctl-to-alt fn)
                    (setq curr-kbd (format "<Unchorded> %s %s" cur-prefix unchorded))
                    (ergoemacs-debug "\tcurr-kbd: %s" curr-kbd)
                    (condition-case err
                        (define-key ,keymap
                          (read-kbd-macro curr-kbd) fn)
                      (error (ergoemacs-debug "%s" err)))
                    (ergoemacs-debug "<Unchorded> %s %s => %s"
                                     cur-prefix unchorded fn))))))
          translations))

       (ergoemacs-debug (make-string 80 ?=))
       (ergoemacs-debug "Built (%1f s;%1f s); Adding swap" 
                        (- (float-time) start-time)
                        (- (float-time) last-time))
       (setq last-time (float-time))
       (ergoemacs-debug (make-string 80 ?=))
       
       ;; Now add root level swap.
       (ergoemacs-debug "Root: %s <%s>" cur-prefix (if (eq system-type 'windows-nt) "apps" "menu"))
       
       (condition-case err
           (define-key ,keymap
             (read-kbd-macro (format "<Normal> %s <%s>" cur-prefix
                                     (if (eq system-type 'windows-nt) "apps" "menu")))
             `(lambda(&optional arg)
                (interactive "P")
                (ergoemacs-menu-swap ,cur-prefix "" 'normal)))
         (error nil))
       
       (condition-case err
           (define-key ,keymap 
             (read-kbd-macro
              (format "<Ctl%sAlt> %s <%s>" 
                      (ergoemacs-unicode-char "↔" " to ")
                      cur-prefix
                      (if (eq system-type 'windows-nt) "apps" "menu")))
             `(lambda(&optional arg)
                (interactive "P")
                (ergoemacs-menu-swap ,cur-prefix "" 'ctl-to-alt)))
         (error nil))

       (condition-case err
           (define-key ,keymap 
             (read-kbd-macro
              (format "<Unchorded> %s <%s>"
                      cur-prefix
                      (if (eq system-type 'windows-nt) "apps" "menu")))
             `(lambda(&optional arg)
                (interactive "P")
                (ergoemacs-menu-swap ,cur-prefix "" 'unchorded)))
         (error nil))
       (puthash hashkey ,keymap ergoemacs-extract-map-hash))
     (ergoemacs-debug (make-string 80 ?=))
     (ergoemacs-debug-flush)))

(defun ergoemacs-menu-send-function (prefix-key untranslated-key fn)
  "Sends actual key for translation maps or runs function FN"
  (setq this-command last-command) ; Don't record this command.
  (setq prefix-arg current-prefix-arg)
  (condition-case err
      (progn
        (call-interactively fn)
        (message "%s%s: %s" (ergoemacs-pretty-key prefix-key) (ergoemacs-pretty-key untranslated-key) fn))
    (error
     (message "Error %s" err))))

(defun ergoemacs-menu-send-prefix (prefix-key untranslated-key type)
  "Extracts maps for PREFIX-KEY UNTRANSLATED-KEY of TYPE."
  (setq this-command last-command) ; Don't record this command.
  (setq prefix-arg current-prefix-arg)
  (let ((fn (concat "ergoemacs-shortcut---"
                    (md5 (format "%s %s; %s" prefix-key untranslated-key
                                 type)))))
    (eval
     (macroexpand
      `(progn
         (ergoemacs-keyboard-shortcut
          ,(intern fn) ,(format "%s %s" prefix-key untranslated-key) ,type))))
    (call-interactively (intern fn))))

(defun ergoemacs-menu-swap (prefix-key untranslated-key type)
  "Swaps what <menu> key translation is in effect"
  (let* ((new-type nil)
         (new-key nil)
         (kbd-code nil)
         (normal untranslated-key)
         (ctl-to-alt (replace-regexp-in-string
                      "\\<W-" "M-"
                      (replace-regexp-in-string
                       "\\<M-" "C-"
                       (replace-regexp-in-string "\\<C-" "W-" normal))))
         (unchorded (replace-regexp-in-string
                     "\\<W-" ""
                     (replace-regexp-in-string
                      "\\(^\\| \\)\\([^-]\\)\\( \\|$\\)" "\\1M-\\2\\3"
                      (replace-regexp-in-string "\\<M-" "W-" ctl-to-alt)))))
    (cond
     ((member ergoemacs-first-extracted-variant '(ctl-to-alt normal))
      (cond
       ((eq type 'ctl-to-alt)
        (setq new-type 'unchorded))
       ((eq type 'unchorded)
        (setq new-type 'normal))
       ((eq type 'normal)
        (setq new-type 'ctl-to-alt))))
     ((equal ergoemacs-first-extracted-variant 'unchorded)
      (cond
       ((eq type 'ctl-to-alt)
        (setq new-type 'normal))
       ((eq type 'unchorded)
        (setq new-type 'ctl-to-alt))
       ((eq type 'normal)
        (setq new-type 'unchorded)))))
    (setq kbd-code
          (cond
           ((eq new-type 'normal)
            (format "<Normal> %s %s" prefix-key normal))
           ((eq new-type 'ctl-to-alt)
            (format "<Ctl%sAlt> %s %s"
                    (ergoemacs-unicode-char "↔" " to ")
                    prefix-key
                    ctl-to-alt))
           ((eq new-type 'unchorded)
            (format "<Unchorded> %s %s" prefix-key
                    unchorded))))
    (setq new-key (listify-key-sequence (read-kbd-macro kbd-code)))
    (setq this-command last-command) ; Don't record this command.
    (setq prefix-arg current-prefix-arg)
    (set-temporary-overlay-map ergoemacs-current-extracted-map)
    (reset-this-command-lengths)
    (setq unread-command-events new-key)
    (save-match-data
      (when (string-match "<\\(.*?\\)> \\(.*\\)" kbd-code)
        (message (replace-regexp-in-string "<Normal> +" ""
                  (format "<%s> %s" (match-string 1 kbd-code)
                         (ergoemacs-pretty-key (match-string 2 kbd-code)))))))))


(defvar ergoemacs-repeat-shortcut-keymap (make-keymap)
  "Keymap for repeating often used shortcuts like C-c C-c.")

(defvar ergoemacs-repeat-shortcut-msg ""
  "Message for repeating keyboard shortcuts like C-c C-c")

(defun ergoemacs-shortcut-timeout ()
  (message ergoemacs-repeat-shortcut-msg)
  (set-temporary-overlay-map ergoemacs-repeat-shortcut-keymap))

(defvar ergoemacs-current-extracted-map nil
  "Current extracted map for `ergoemacs-keyboard-shortcut' defined functions")

(defvar ergoemacs-first-extracted-variant nil
  "Current extracted variant")

(defvar ergoemacs-)
;;;###autoload
(defmacro ergoemacs-keyboard-shortcut (name key &optional chorded repeat)
  "Creates a function NAME that issues a keyboard shortcut for KEY.
CHORDED is a variable that alters to keymap to allow unchorded
key sequences.

If CHORDED is nil, the NAME command will just issue the KEY sequence.

If CHORDED is 'unchorded or the NAME command will translate the control
bindings to be unchorded.  For example:

For example for the C-x map,

Original Key   Translated Key  Function
C-k C-n     -> k n             (kmacro-cycle-ring-next)
C-k a       -> k M-a           (kmacro-add-counter)
C-k M-a     -> k C-a           not defined
C-k S-a     -> k S-a           not defined

If CHORDED is 'ctl-to-alt or the NAME command will translate the control
bindings to be unchorded.  For example:

C-k C-n     -> M-k M-n             (kmacro-cycle-ring-next)
C-k a       -> M-k a           (kmacro-add-counter)
C-k M-a     -> k C-a           not defined
C-k S-a     -> k S-a           not defined

When REPEAT is a variable name, then an easy repeat is setup for the command.

For example if you bind <apps> m to Ctrl+c Ctrl+c, this allows Ctrl+c Ctrl+c to be repeated by m.
"
  `(progn
     ,(cond
       ((eq chorded 'unchorded))
       ((eq chorded 'ctl-to-alt))
       (t
        (when repeat
            `(defcustom ,(intern (symbol-name repeat)) t
               ,(format "Allow %s to be repeated." (ergoemacs-pretty-key key))
               :group 'ergoemacs-mode
               :type 'boolean))))
     (defun ,(intern (symbol-name name)) (&optional arg)
       ,(cond
         ((eq chorded 'unchorded)
          (format "Creates a keymap that extracts the unchorded %s combinations and then issues %s.  Also allows unbound or normal variants by pressing the <menu> key." key key))
         ((eq chorded 'ctl-to-alt)
          (format "Creates a keymap that extracts the %s combinations and translates Ctl+ to Alt+. Also allows the unbound or Ctl to alt variants by pressing the <menu>" key))
         ((eq chorded 'normal)
          (format "Creates a keymap that extracts the %s keymap. Also allows the unbound or Ctl+ to Alt+ and unbound variants by pressing the <menu>" key))
         (t
          (format "A shortcut to %s." (ergoemacs-pretty-key key))))
       (interactive "P")
       (setq this-command last-command) ; Don't record this command.
       (setq prefix-arg current-prefix-arg)
       (let (key-seq (key ,key))
         (eval (macroexpand '(ergoemacs-extract-maps ergoemacs-current-extracted-map key)))
         ,(cond
           ((eq chorded 'unchorded)
            `(progn
               (setq ergoemacs-first-extracted-variant 'unchorded)
               (setq key-seq  (read-kbd-macro (format "<Unchorded> %s" ,key)))
               (set-temporary-overlay-map ergoemacs-current-extracted-map)
               (setq key-seq (listify-key-sequence key-seq))
               (reset-this-command-lengths)
               (setq unread-command-events key-seq)
               (princ ,(format "<Unchorded> %s " (ergoemacs-pretty-key key)))))
           ((eq chorded 'normal)
            `(progn
               (setq ergoemacs-first-extracted-variant 'normal)
               (setq key-seq  (read-kbd-macro (format "<Normal> %s" ,key)))
               (set-temporary-overlay-map ergoemacs-current-extracted-map)
               (setq key-seq (listify-key-sequence key-seq))
               (reset-this-command-lengths)
               (setq unread-command-events key-seq)
               (princ ,(format "<Normal> %s " (ergoemacs-pretty-key key)))))
           ((eq chorded 'ctl-to-alt)
            `(progn
               (setq ergoemacs-first-extracted-variant 'ctl-to-alt)
               (setq key-seq (read-kbd-macro (format "<Ctl%sAlt> %s" 
                                                     (ergoemacs-unicode-char "↔" " to ")
                                                     ,key)))
               (setq key-seq (listify-key-sequence key-seq))
               (set-temporary-overlay-map ergoemacs-current-extracted-map)
               (reset-this-command-lengths)
               (setq unread-command-events key-seq)
               (princ ,(format "<Ctl%sAlt> %s " (ergoemacs-unicode-char "↔" " to ") (ergoemacs-pretty-key key)))))
           (t
            `(let ((ctl-c-keys (key-description (this-command-keys))))
               (setq prefix-arg current-prefix-arg)
               (reset-this-command-lengths)
               (setq unread-command-events (listify-key-sequence (read-kbd-macro ,key)))
               ,(when repeat
                  `(when ,(intern (symbol-name repeat))
                     (when (and (key-binding (read-kbd-macro ,key))
                                (string-match "[A-Za-z]$" ctl-c-keys))
                       (setq ctl-c-keys (match-string 0 ctl-c-keys))
                       (setq ergoemacs-repeat-shortcut-keymap (make-keymap))
                       (define-key ergoemacs-repeat-shortcut-keymap (read-kbd-macro ctl-c-keys)
                         'ergoemacs-ctl-c-ctl-c)
                       (setq ergoemacs-repeat-shortcut-msg
                             (format ,(format "Repeat %s with %%s" (ergoemacs-pretty-key key))
                                     (ergoemacs-pretty-key ctl-c-keys)))
                       ;; Allow time to process the unread command events before
                       ;; installing temporary keymap
                       (run-with-timer ergoemacs-M-O-delay nil #'ergoemacs-shortcut-timeout)))))))))))


(ergoemacs-keyboard-shortcut ergoemacs-ctl-c-ctl-c "C-c C-c" nil ergoemacs-repeat-ctl-c-ctl-c)


(require 'cus-edit)

(defun ergoemacs-check-for-new-version ()
  "This allows the user to keep an old-version of keybindings if they change."
  (condition-case err
      (progn
        (when ergoemacs-mode
          ;; Apply any settings...
          (ergoemacs-debug "Reset ergoemacs-mode.")
          (ergoemacs-mode -1)
          (ergoemacs-mode 1))
        (when (and
               (custom-file t) ;; Make sure a custom file exists.
               (not ergoemacs-theme) ;; Ergoemacs default used.
               (or (not ergoemacs-mode-used)
                   (not (string= ergoemacs-mode-used ergoemacs-mode-version))))
          (if (yes-or-no-p
               (format "Ergoemacs keybindings changed, %s; Would you like to change as well?"
                       ergoemacs-mode-changes))
              (progn
                (setq ergoemacs-mode-used ergoemacs-mode-version)
                (customize-save-variable 'ergoemacs-mode-used (symbol-value 'ergoemacs-mode-used))
                (customize-save-variable 'ergoemacs-theme (symbol-value 'ergoemacs-theme))
                (customize-save-customized))
            (when (not ergoemacs-mode-used)
              (setq ergoemacs-mode-used "5.7.5"))
            (setq ergoemacs-theme ergoemacs-mode-used)
            (customize-save-variable 'ergoemacs-mode-used (symbol-value 'ergoemacs-mode-used))
            (customize-save-variable 'ergoemacs-theme (symbol-value 'ergoemacs-theme))
            (customize-save-customized))))
    (error nil)))

(add-hook 'emacs-startup-hook 'ergoemacs-check-for-new-version)
(defvar ergoemacs-old-ns-command-modifier nil)
(defvar ergoemacs-old-ns-alternate-modifier nil)

(defcustom ergoemacs-use-mac-command-as-meta t
  "Use Mac's command/apple key as emacs meta-key when enabled."
  :type 'boolean
  :group 'ergoemacs-mode)

(defcustom ergoemacs-use-menus t
  "Use ergoemacs menus"
  :type 'boolean
  :set 'ergoemacs-set-default
  :group 'ergoemacs-mode)

;; ErgoEmacs minor mode
;;;###autoload
(define-minor-mode ergoemacs-mode
  "Toggle ergoemacs keybinding minor mode.
This minor mode changes your emacs keybinding.

Without argument, toggles the minor mode.
If optional argument is 1, turn it on.
If optional argument is 0, turn it off.

Home page URL `http://ergoemacs.github.io/ergoemacs-mode/'

For the standard layout, with A QWERTY keyboard the `execute-extended-command' M-x is now M-a.

The layout and theme changes the bindings.  For the current
bindings the keymap is:

\\{ergoemacs-keymap}
"
  nil
  :lighter " ErgoEmacs"
  :global t
  :group 'ergoemacs-mode
  :keymap ergoemacs-keymap
  (ergoemacs-setup-keys t)
  (ergoemacs-debug "Ergoemacs Keys have loaded.")
  (if ergoemacs-use-menus
      (progn
        (require 'ergoemacs-menus)
        (ergoemacs-menus-on))
    (when (featurep 'ergoemacs-menus)
      (ergoemacs-menus-off)))
  (when (and (eq system-type 'darwin))
    (if ergoemacs-mode
        (progn
          (setq ergoemacs-old-ns-command-modifier ns-command-modifier)
          (setq ergoemacs-old-ns-alternate-modifier ns-alternate-modifier)
          (setq ns-command-modifier 'meta)
          (setq ns-alternate-modifier nil))
      (setq ns-command-modifier ergoemacs-old-ns-command-modifier)
      (setq ns-alternate-modifier ergoemacs-old-ns-alternate-modifier)))
  (if ergoemacs-mode
      (define-key cua--cua-keys-keymap (read-kbd-macro "M-v") nil)
    (define-key cua--cua-keys-keymap (read-kbd-macro "M-v") 'cua-repeat-replace-region))
  (condition-case err
      (when ergoemacs-cua-rect-modifier
        (if ergoemacs-mode
            (progn
              (setq cua--rectangle-modifier-key ergoemacs-cua-rect-modifier)
              (setq cua--rectangle-keymap (make-sparse-keymap))
              (setq cua--rectangle-initialized nil)
              (cua--init-rectangles)
              (setq cua--keymap-alist
                    `((cua--ena-prefix-override-keymap . ,cua--prefix-override-keymap)
                      (cua--ena-prefix-repeat-keymap . ,cua--prefix-repeat-keymap)
                      (cua--ena-cua-keys-keymap . ,cua--cua-keys-keymap)
                      (cua--ena-global-mark-keymap . ,cua--global-mark-keymap)
                      (cua--rectangle . ,cua--rectangle-keymap)
                      (cua--ena-region-keymap . ,cua--region-keymap)
                      (cua-mode . ,cua-global-keymap))))
          (setq cua--rectangle-modifier-key ergoemacs-cua-rect-modifier-orig)
          (setq cua--rectangle-modifier-key ergoemacs-cua-rect-modifier)
          (setq cua--rectangle-keymap (make-sparse-keymap))
          (setq cua--rectangle-initialized nil)
          (cua--init-rectangles)
          (setq cua--keymap-alist
                `((cua--ena-prefix-override-keymap . ,cua--prefix-override-keymap)
                  (cua--ena-prefix-repeat-keymap . ,cua--prefix-repeat-keymap)
                  (cua--ena-cua-keys-keymap . ,cua--cua-keys-keymap)
                  (cua--ena-global-mark-keymap . ,cua--global-mark-keymap)
                  (cua--rectangle . ,cua--rectangle-keymap)
                  (cua--ena-region-keymap . ,cua--region-keymap)
                  (cua-mode . ,cua-global-keymap))))
        (ergoemacs-debug "CUA rectangle mode modifier changed."))
    (error (message "CUA rectangle modifier wasn't changed.")))
  
  (when ergoemacs-change-smex-M-x
    (if ergoemacs-mode
        (setq smex-prompt-string (concat (ergoemacs-pretty-key "M-x") " "))
      (setq smex-promt-string "M-x ")))
  (if ergoemacs-mode
      (mapc ;; Now install hooks.
       (lambda(buf)
         (with-current-buffer buf
           (when (and (intern-soft (format "ergoemacs-%s-hook" major-mode)))
             (funcall (intern-soft (format "ergoemacs-%s-hook" major-mode))))))
       (buffer-list))
    (mapc ;; Remove overriding keys.
     (lambda(buf)
       (with-current-buffer buf
         (when (and (intern-soft (format "ergoemacs-%s-hook-mode" major-mode))
                    (symbol-value (intern-soft (format "ergoemacs-%s-hook-mode" major-mode))))
           (funcall (intern-soft (format "ergoemacs-%s-hook-mode" major-mode)) -1))
         (let ((x (assq 'ergoemacs-mode minor-mode-overriding-map-alist)))
           (if x
               (setq minor-mode-overriding-map-alist (delq x minor-mode-overriding-map-alist))))))
     (buffer-list)))
  (ergoemacs-debug-flush))



;; ErgoEmacs replacements for local-set-key

(defvar ergoemacs-local-keymap nil
  "Local ergoemacs keymap")
(make-variable-buffer-local 'ergoemacs-local-keymap)

(defun ergoemacs-local-set-key (key command)
  "Set a key in the ergoemacs local map."
  ;; install keymap if not already installed
  (interactive)
  (progn
    (unless ergoemacs-local-keymap
      (ergoemacs-setup-keys-for-keymap ergoemacs-local-keymap)
      (add-to-list 'minor-mode-overriding-map-alist (cons 'ergoemacs-mode ergoemacs-local-keymap)))
    ;; add key
    (define-key ergoemacs-local-keymap key command)))

(defun ergoemacs-local-unset-key (key)
  "Unset a key in the ergoemacs local map."
  (ergoemacs-local-set-key key nil))



(require 'ergoemacs-advices)

(defcustom ergoemacs-ignore-prev-global t
  "If non-nil, the ergoemacs-mode will ignore previously defined global keybindings."
  :type 'boolean
  :group 'ergoemacs-mode)

(when ergoemacs-ignore-prev-global
  (ergoemacs-ignore-prev-global))

;;; Frequently used commands as aliases

(defcustom ergoemacs-use-aliases t
  "Use aliases defined by `ergoemacs-aliases' to abbreviate commonly used commands.
Depending on how you use the completion engines, this may or may not be useful.
However instead of using M-a `eval-buffer', you could use M-a `eb'"
  :type 'boolean
  :group 'ergoemacs-mode)

(defcustom ergoemacs-aliases
  '((ar    align-regexp)
    (c     toggle-case-fold-search)
    (cc    calc)
    (dml   delete-matching-lines)
    (dnml  delete-non-matching-lines)
    (dtw   delete-trailing-whitespace)
    (eb    eval-buffer)
    (ed    eval-defun)
    (eis   elisp-index-search)
    (er    eval-region)
    (fb    flyspell-buffer)
    (fd    find-dired)
    (g     grep)
    (gf    grep-find)
    (lcd   list-colors-display)
    (lf    load-file)
    (lml   list-matching-lines)
    (ps    powershell)
    (qrr   query-replace-regexp)
    (rb    revert-buffer)
    (rof   recentf-open-files)
    (rr    reverse-region)
    (rs    replace-string)
    (sbc   set-background-color)
    (sh    shell)
    (sl    sort-lines)
    (ws    whitespace-mode))
  "List of aliases defined by `ergoemacs-mode'."
  :type '(repeat
          (list
           (sexp :tag "alias")
           (symbol :tag "actual function")))
  :group 'ergoemacs-mode)

(defun ergoemacs-load-aliases ()
  "Loads aliases defined in `ergoemacs-aliases'."
  (mapc
   (lambda(x)
     (eval (macroexpand `(defalias ',(nth 0 x) ',(nth 1 x)))))
   ergoemacs-aliases))

(when ergoemacs-use-aliases
  (ergoemacs-load-aliases))

(provide 'ergoemacs-mode)

;;; ergoemacs-mode.el ends here
;; Local Variables:
;; coding: utf-8-emacs
;; End:
