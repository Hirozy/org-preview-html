;;; org-preview-html.el --- Automatically preview org-exported HTML files within Emacs -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Jake B <jakebox0@protonmail.com>

;; Author: Jake B <jakebox0@protonmail.com>
;; Original author of org-preview-html (until 2021-09): DarkSun <lujun9972@gmail.com>
;; Url: https://github.com/jakebox/org-preview-html
;; Keywords: Org, convenience, outlines
;; Version: 0.4.0
;; Package-Requires: ((emacs "25.1") (org "8.0"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; This minor mode provides a side-by-side preview of your org-exported HTML
;; files using the either the eww or xwidget browsers. The update frequency of
;; the preview can be configured to suit your preference.
;;
;; Quick start:
;; Put this file under your load path.
;; Enable the minor mode in an Org buffer:
;;   M-x org-preview-html-mode
;; Configure options with M-x customize-group org-preview-html
;;
;; Source code
;; org-preview-html's code can be found here:
;;   http://github.com/jakebox/org-preview-html

;;; Code:

;;;; Requirements
(require 'org)

(defgroup org-preview-html nil
  "Automatically preview org-exported HTML files within Emacs."
  :group 'org-mode
  :link '(url-link :tag "Homepage" "https://github.com/jakebox/org-preview-html/"))

(defcustom org-preview-html-refresh-configuration 'save
  "Specifies how often the HTML preview will be refreshed.

If `manual', update manually by running `org-preview-html-refresh'.
If `save', update on save (default).
If `timer', update preview on timer (`org-preview-html-timer-interval')."
  :type '(choice
		  (symbol :tag "Update preview manually"   manual)
		  (symbol :tag "Update preview on save"    save)
		  (symbol :tag "Update preview on a timer" timer))
  :group 'org-preview-html)

(defcustom org-preview-html-timer-interval 2
  "Integer seconds to wait between exports when in 'timer mode."
  :type 'integer
  :group 'org-preview-html)

(defcustom org-preview-html-subtree-only nil
  "If non-nil, scope the preview to the current subtree."
  :type 'boolean
  :group 'org-preview-html)

(defcustom org-preview-export-path "/tmp"
  "Default export path of html"
  :type 'string
  :group 'org-preview-html)

;; Internal variables
(defvar org-preview-html--refresh-timer nil)
(defvar-local org-preview-html--html-file nil)

(defun org-preview-html-refresh ()
  "Exports the org file to HTML and refreshes the preview."
  (interactive)
  (org-preview-html--org-export-html))

(defun org-preview-html--org-export-html ()
  "Silently export org to HTML."
  (let ((standard-output 'ignore))
	(org-export-to-file 'html org-preview-html--html-file
	  nil org-preview-html-subtree-only nil nil nil nil)))

(defun org-preview-html--run-with-timer ()
  "Configure timer to refresh preview for `timer' mode."
  (setq org-preview-html--refresh-timer
		(run-at-time 1 org-preview-html-timer-interval #'org-preview-html-refresh)))

(defun org-preview-html--config ()
  "Configure buffer for preview: add exit hooks; configure refresh hooks."
  (let ((conf org-preview-html-refresh-configuration))
	(cond
	 ((eq conf 'manual))
	 ((eq conf 'save) ;; On save
	  (add-hook 'after-save-hook #'org-preview-html-refresh nil t))
	 ((eq conf 'timer) ;; every X seconds
	  (org-preview-html--run-with-timer)))))

(defun org-preview-html--unconfig ()
  "Unconfigure 'org-preview-html-mode' (remove hooks and advice)."
  (let ((conf org-preview-html-refresh-configuration))
	(cond ((eq conf 'save)
		   (remove-hook 'after-save-hook #'org-preview-html-refresh t))
		  ((eq conf 'timer)
		   (cancel-timer org-preview-html--refresh-timer)))))

;;;###autoload
(defun org-preview-html-open-browser ()
  "Open a browser to preview the exported HTML file."
  (interactive)
  ;; Store the exported HTML filename
  (setq-local org-preview-html--html-file
              (expand-file-name
               (concat (file-name-sans-extension (file-name-nondirectory buffer-file-name)) ".html") org-preview-export-path))
  (message org-preview-html--html-file)
  (org-preview-html--config)
  (org-preview-html-refresh)
  ;; Procedure to open the side-by-side preview
  (shell-command (format "open \"%s\"" org-preview-html--html-file)))

;;;###autoload
(defun org-preview-html-stop-refresh ()
  "Stop refresh the html files"
  (interactive)
  (org-preview-html--unconfig))

(provide 'org-preview-html)

;;; org-preview-html.el ends here
