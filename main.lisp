(defpackage :metis/main
  (:use :common-lisp :common-lisp :fare-memoization :cl-fad :gzip-stream :cl-json)
  (:export #:argv
	   #:main))
   
(in-package :metis/main)

(defparameter *q* (make-instance 'queue))

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
  (format t "XXX: ~A~%" (type-of (argv)))
  (let* ((args (argv))
	 (verb (nth 1 args))
	 (workers (nth 2 args))
	 (dir (nth 3 args)))
    (cond
      ((equal "main" verb) (main))
      ((equal "a" verb)(time (cloudtrail-report-async workers dir)))
      ((equal "s" verb)(time (cloudtrail-report-sync dir)))
      ((equal "r" verb)(time (run-bench)))
      (t (progn
	   (format t "Usage: <~A> <function> <args>~%" (nth 0 args))
	   (format t "Function is (s) for single threaded, and (a) for multithreaded~%")
	   (format t "ex: ~A a 10 ~~/CT/ # Would run 10 works on ~~/CT/~%" (nth 0 args))
	   (format t "ex: ~A s ~~CT/ # Would run 10 works on ~~/CT/~%" (nth 0 args)))))))
  ;;(cl-store:store *q* "~/q.store"))

#+allegro
(in-package :cl-user)

#+allegro
(defun main (app verb workers dir)
  (format t "Got: app:~A verb:~A workers:~A dir:~A~%" app verb workers dir)
  (cond
    ((equal "s" verb) (time (ctcl::cloudtrail-report-sync dir)))
    ((equal "a" verb) (time (ctcl::cloudtrail-report-async workers dir)))
    ((equal "r" verb)(time (ctcl::run-bench)))
    (t (format t "Usage <~A> <p or s> <directory of logs>" app))))
;;(cl-store:store *q* "~/q.store"))
