(in-package :ctcl)

(defun argv ()
  (or
   #+clisp (ext:argv)
   #+sbcl sb-ext:*posix-argv*
   #+abcl ext:*command-line-argument-list*
   #+clozure (ccl::command-line-arguments)
   #+gcl si:*command-args*
   #+ecl (loop for i from 0 below (si:argc) collect (si:argv i))
   #+cmu extensions:*command-line-strings*
   #+allegro (sys:command-line-arguments)
   #+lispworks sys:*line-arguments-list*
   nil))

#-allegro
(defun main ()
  ;;(ql:quickload :swank)
  (setq swank:*use-dedicated-output-stream* nil)
  ;;(swank:create-server :dont-close t :port 2221)
  ;;(declare (optimize (safety 3) (debug 3)))
  (format t "XXX: ~A~%" (type-of (argv)))
  (let* ((args (argv))
	 (verb (nth 1 args))
	 (workers (nth 2 args))
	 (dir (nth 3 args)))
    (cond
      ((equal "main" verb) (main))
      ((equal "a" verb)(time (cloudtrail-report-to-psql-async workers dir)))
      ((equal "s" verb)(time (cloudtrail-report-to-psql-sync dir)))
      (t (format t "Usage: <~A> <function> <args>~%" (nth 0 args)))))
  )

#+allegro
(in-package :cl-user)
#+allegro
(defun main (app verb workers dir)
  (format t "Got: app:~A verb:~A workers:~A dir:~A~%" app verb workers dir)
  (cond
    ((equal "s" verb) (profile (ctcl::cloudtrail-report-to-psql-sync dir)))
    ((equal "a" verb) (profile (ctcl::cloudtrail-report-to-psql-async workers dir)))
    (t (format t "Usage <~A> <p or s> <directory of logs>" app))))
