(in-package :metis)

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

;; (let ((verb (or (nth 1 args) nil))
;; 	(a (or (nth 2 args) nil))
;; 	(b (or (nth 3 args) nil))
;; 	(c (or (nth 4 args) nil)))


(defun usage ()
  (print "a - cloudtrail-report-async")
  (print "b - bench-vpc-flows-report-sync arg")
  (print "lc - get-unique-conversation")
  (print "lec - get-errorcode-list")
  (print "lev - get-event-list")
  (print "lip - get-sourceips-list")
  (print "ln - get-name-list")
  (print "lva -get-vpc-action-list")
  (print "lvd -get-vpc-date-list")
  (print "lvda -get-vpc-dstaddr-list")
  (print "lvdp -get-vpc-srcport-list")
  (print "lvi -get-vpc-interface_id-list")
  (print "lvp -get-vpc-protocols-list")
  (print "lvpc - list-all-vpc")
  (print "lvs -get-vpc-status-list")
  (print "lvsa -get-vpc-srcaddr-list")
  (print "lvsp -get-vpc-srcport-list")
  (print "r - run-bench")
  (print "s - cloudtrail-report-sync arg")
  (print "sa -find-by-srcaddr arg")
  (print "sd - get-by-date arg")
  (print "sec - get-by-errorcode arg")
  (print "seca - get-all-errorcodes")
  (print "sev - get-by-event arg")
  (print "sin - get-useridentity-by-name arg")
  (print "sip - get-by-sourceip arg")
  (print "sn - get-by-name arg")
  (print "sp - find-by-srcport arg")
  (print "st - get-stats")
  (print "va - vpc-flows-report-async arg beta")
  (print "vs - vpc-flows-report-sync arg")
)



(defun process-args (args)
  (init-manardb)

  (let (
	(verb (nth 1 args))
	(alpha (nth 2 args))
	(beta (nth 3 args))
	)
    ;;(format t "main:~A verb:~A alpha:~A beta:~A" (nth 0 args) verb alpha beta)
    (cond
      ((equal "a" verb)(time (cloudtrail-report-async alpha beta)))
      ((equal "lc" verb)(time (get-unique-conversation)))
      ((equal "vs" verb)(time (vpc-flows-report-sync alpha)))
      ((equal "va" verb)(time (vpc-flows-report-async alpha beta)))
      ((equal "b" verb)(time (bench-vpc-flows-report-sync alpha)))
      ((equal "s" verb)(time (cloudtrail-report-sync alpha)))
      ((equal "sn" verb)(time (get-by-name alpha)))
      ((equal "ln" verb)(time (get-name-list)))
      ((equal "lvpc" verb)(time (list-all-vpc)))
      ((equal "lev" verb)(time (get-event-list)))
      ((equal "seca" verb)(time (get-all-errorcodes)))
      ((equal "sa" verb)(find-by-srcaddr alpha))
      ((equal "sev" verb)(time (get-by-event alpha)))
      ((equal "sin" verb)(time (get-useridentity-by-name alpha)))
      ((equal "lip" verb)(time (get-sourceips-list)))
      ((equal "sip" verb)(time (get-by-sourceip alpha)))
      ((equal "lvd" verb)(get-vpc-date-list))
      ((equal "lvi" verb)(get-vpc-interface_id-list))
      ((equal "lvsa" verb)(get-vpc-srcaddr-list))
      ((equal "lvda" verb)(get-vpc-dstaddr-list))
      ((equal "lvsp" verb)(get-vpc-srcport-list))
      ((equal "lvdp" verb)(get-vpc-srcport-list))
      ((equal "lvp" verb)(get-vpc-protocols-list))
      ((equal "lva" verb)(get-vpc-action-list))
      ((equal "lvs" verb)(get-vpc-status-list))
      ((equal "sp" verb)(find-by-srcport alpha))
      ((equal "sd" verb)(time (get-by-date alpha)))
      ((equal "sec" verb)(time (get-by-errorcode alpha)))
      ((equal "st" verb)(get-stats))
      ((equal "lec" verb)(time (get-errorcode-list)))
      ((equal "r" verb)(time (run-bench)))
      (t (progn
	   (usage))))
  (manardb:close-all-mmaps)))


(defun main ()
  (init-manardb)
  (process-args (argv)))

#+allegro
(in-package :cl-user)

#+allegro
(defun main (&rest args)
  (metis::process-args args))
