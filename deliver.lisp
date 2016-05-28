(defpackage :docker/misc
  (:use :common-lisp :docker/request)
  (:import-from :uiop #:copy-stream-to-stream)
  (:import-from #:yason)
  (:export #:info
           #:version
           #:ping
           #:monitor-events))


#+(or ccl clisp ecl)
(ql:quickload "trivial-dump-core")

#+sbcl
(sb-ext:save-lisp-and-die "dist/sbcl/metis" :executable t :toplevel 'ctcl::main :save-runtime-options t)
;;(sb-ext:save-lisp-and-die "dist/sbcl/metis" :compression 5 :executable t :toplevel 'ctcl::main :save-runtime-options t)

#+(or ccl ccl64 )
(trivial-dump-core:save-executable "dist/ccl/metis" #'ctcl::main)

#+cmucl
;;(save-lisp :executable t
(trivial-dump-core:save-executable "dist/cmucl/metis" #'ctcl::main)

#+clisp
(ext:saveinitmem "dist/clisp/metis" :init-function #'ctcl::main :executable t :quiet t)
;;(trivial-dump-core:save-executable "dist/clisp/metis" #'ctcl::main)

#+lispworks
(deliver 'ctcl::main "dist/lispworks/metis" 0 :multiprocessing t :keep-eval t :keep-fasl-dump t :keep-editor t :keep-foreign-symbols t :keep-function-name t :keep-gc-cursor t :keep-keyword-names t :keep-lisp-reader t :keep-macros t :keep-modules t :keep-top-level t :license-info nil  :keep-walker t :KEEP-PRETTY-PRINTER t)

#+allegro
(progn
  ;;(require :prof)
  ;;(require :profiler)
  (let ((lfiles '("pkgdcl.lisp" "allegro-prof.lisp" "collector/utils.lisp" "collector/ctcl.lisp" "collector/database.lisp" "collector/main.lisp" "collector/bench.lisp")))
    (mapcar #'compile-file lfiles)
    (generate-executable "metis" '("pkgdcl.fasl" "collector/utils.fasl" "collector/database.fasl" "collector/ctcl.fasl" "collector/main.fasl" "collector/bench.fasl"))))
