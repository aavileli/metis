(in-package :metis)
;;(declaim (optimize (speed 3) (debug 0) (safety 0) (compilation-speed 0)))


(defvar *manard-flow-files* (thread-safe-hash-table))
(ql:quickload :split-sequence :cl-date-time-parser :local-time)
(defvar *mytasks* (list))

(defvar vpc-fields '(
		     metis::bytez
		     metis::date
		     metis::dstaddr
		     metis::dstport
		     metis::endf
		     metis::interface-id
		     metis::packets
		     metis::protocol
		     metis::srcaddr
		     metis::srcport
		     metis::start
		     metis::status
		     ))

;;date version account_id interface-id srcaddr dstaddr srcport dstport protocol packets bytez start end action status
;;2016-08-01T00:28:14.000Z 2 224108527019 eni-0016955d 10.16.3.11 10.16.11.123 53 53573 17 2 186 1470011294 1470011354 ACCEPT OK

(manardb:defmmclass date ()
  ((file :initarg :name :reader file)))

(manardb:defmmclass interface-id ()
  ((value :initarg :value :accessor value)
   (max-id :initarg :max-id :accessor max-id)
   (idx :initarg idx :accessor idx)))

(manardb:defmmclass srcaddr ()
  ((value :initarg :value :accessor srcaddr-value)
   (max-id :initarg :max-id :accessor max-id :allocation :class)
   (idx :initarg :idx :accessor srcaddr-idx)))

(manardb:defmmclass dstaddr ()
  ((value :initarg :value :accessor value)
   (max-id :initarg :max-id :accessor max-id :allocation :class)
   (idx :initarg :idx :accessor idx)))

(manardb:defmmclass srcport ()
  ((value :initarg :value :accessor value)
   (max-id :initarg :max-id :accessor max-id :allocation :class)
   (idx :initarg :idx :accessor idx)))

(manardb:defmmclass dstport ()
  ((value :initarg :value :accessor value)
   (max-id :initarg :max-id :accessor max-id :allocation :class)
   (idx :initarg :idx :accessor idx)))

(manardb:defmmclass protocol ()
  ((value :initarg :value :accessor value)
   (max-id :initarg :max-id :accessor max-id :allocation :class)
   (idx :initarg :idx :accessor idx)))

(manardb:defmmclass packets ()
  ((value :initarg :value :accessor value)
   (max-id :initarg :max-id :accessor max-id :allocation :class)
   (idx :initarg :idx :accessor idx)))

(manardb:defmmclass bytez ()
  ((value :initarg :value :accessor value)
   (max-id :initarg :max-id :accessor max-id :allocation :class)
   (idx :initarg :idx :accessor idx)))

(manardb:defmmclass start ()
  ((value :initarg :value :accessor value)
   (max-id :initarg :max-id :accessor max-id :allocation :class)
   (idx :initarg :idx :accessor idx)))

(manardb:defmmclass endf ()
  ((value :initarg :value :accessor value)
   (max-id :initarg :max-id :accessor max-id :allocation :class)
   (idx :initarg :idx :accessor idx)))

(manardb:defmmclass action ()
  ((value :initarg :value :accessor value)
   (max-id :initarg :max-id :accessor max-id :allocation :class)
   (idx :initarg :idx :accessor idx)))

(manardb:defmmclass status ()
  ((value :initarg :value :accessor value)
   (max-id :initarg :max-id :accessor max-id :allocation :class)
   (idx :initarg :idx :accessor idx)))

(manardb:defmmclass flow ()
  ((date :initarg :date :accessor date)
   ;;(conversation :initarg :conversation :accessor conversation)
   (interface-id :initarg :interface-id :reader interface-id)
   (srcaddr :initarg :srcaddr :reader srcaddr)
   (srcport :initarg :srcport :reader srcport)
   (dstaddr :initarg :dstaddr :reader dstaddr)
   (dstport :initarg :dstport :reader dstport)
   (protocol :initarg :protocol :reader protocol)
   (packets :initarg :packets :accessor packets)
   (bytez :initarg :bytez :accessor bytez)
   (start :initarg :start :accessor start)
   (endf :initarg :endf :accessor endf)
   (action :initarg :action :accessor action)
   (status :initarg :status :accessor status)))

(manardb:defmmclass flow-files ()
  ((file :initarg :file :accessor file)))

(defun init-vpc-hashes ()
  (mapc
   #'(lambda (x)
       (allocate-klass-hash x))
   vpc-fields))
;;(time (allocate-conversation-hash)))

;; (defmethod print-object ((flow flow) stream)
;;   (format stream "#<date:~s srcaddr:~s dstaddr:~s srcport:~s dstport:~s>" (date flow) (srcaddr flow) (dstaddr flow) (srcport flow) (dstport flow)))

(defun bench-vpc-flows-report-sync (dir)
  (init-vpc-hashes)
  (let ((path (or dir "~/vpctiny")))
    ;;(defvar benching t)
    (let ((btime (get-internal-real-time))
	  (benching t))
      #+sbcl
      (progn
	(sb-sprof:with-profiling (:report :flat) (vpc-flows-report-sync path)))
      #+lispworks
      (progn
	(hcl:set-up-profiler :package '(metis))
	(hcl:profile (vpc-flows-report-sync path)))
      #+allegro (progn
		  (prof:start-profiler :type :time :count t)
		  (time (vpc-flows-report-sync path))
		  (prof::show-flat-profile))
      #+(or clozure abcl ecl) (time (vpc-flows-report-sync path))
      (let* ((etime (get-internal-real-time))
	     (delta (/ (float (- etime btime)) (float internal-time-units-per-second)))
	     (rows (manardb:count-all-instances 'metis::flow))
	     (convs (manardb:count-all-instances 'metis::conversation))
	     (files (manardb:count-all-instances 'metis::flow-files)))
	;;      (if (and delta rows)
	;;(let ((rps (/ (float rows) (float delta))))
	;;(format t "~%rps:~A delta~A rows:~A files:~A" (/ (float rows) (float delta)) delta (caar rows) (caar files)))))
	(format t "~%delta~A rows:~A files:~A convs:~A" delta (caar rows) (caar files) convs)))))

(defun bench-list-source-ports ()
  #+sbcl (progn
	   (sb-sprof:with-profiling (:report :flat) (get-vpc-srcport-list)))
  #+lispworks (progn
		(hcl:set-up-profiler :package '(metis))
		(hcl:profile (get-vpc-srcport-list)))
  #+allegro (progn
	      (prof:start-profiler :type :time :count t)
	      (time (get-vpc-srcport-list))
	      (prof::show-flat-profile))
  #+(or clozure abcl ecl)
  (time (get-vprc-srcport-list)))

(defun vpc-flows-report-async (workers path)
  (allocate-vpc-file-hash)
  (init-vpc-hashes)
  (let ((workers (parse-integer workers)))
    (setf (pcall:thread-pool-size) workers)
    (walk-ct path #'async-vf-file)
    (mapc
     #'(lambda (x)
	 (handler-case
	     (pcall:join x)
	   (t (e) (format t "~%~%Error:~A on join of ~A" e x))))
     *mytasks*)))

(defun get-unique-conversation ()
  "Return uniqure list of klass objects"
  (manardb:doclass (x 'metis::conversation :fresh-instances nil)
    (with-slots (interface-id srcaddr dstaddr srcport dstport protocol) x
      (format t "int:~A srcaddr:~A dstaddr:~A srcport:~A dstport:~A protocol:~A~%"
	      (get-val interface-id)
	      (get-val srcaddr)
	      (get-val dstaddr)
	      (get-val srcport)
	      (get-val dstport)
	      (get-val protocol)))))

(defun get-by-ip (val)
  (manardb:doclass (x 'metis::flow :fresh-instances nil)
    (with-slots (interface-id srcaddr dstaddr srcport dstport protocol) x
      (let* ((srcaddr-i (get-val srcaddr))
	     (dstaddr-i (get-val dstaddr))
	     (smatch (usocket:ip= val srcaddr-i))
	     (dmatch (usocket:ip= val dstaddr-i)))
	;;(format t "smatch:~A val:~A srcaddr-i:~A~%" smatch val srcaddr-i)
	(if (or smatch dmatch)
	    (format t "|~A|~A|~A|~A|~A|~A|~%"
		    (get-val interface-id)
		    srcaddr-i
		    dstaddr-i
		    (get-val srcport)
		    (get-val dstport)
		    (get-val protocol)
		    ))))))


(defun vpc-flows-report-sync (path)
  (init-vpc-hashes)
  (allocate-vpc-file-hash)
  (force-output)
  (unless (null path)
    (walk-ct path #'sync-vf-file)))

(defun async-vf-file (x)
  (push (pcall:pexec
	  (funcall #'process-vf-file x)) *mytasks*))

(defun sync-vf-file (x)
  (process-vf-file x))

(defun find-by-srcaddr (value)
  (manardb:doclass (x 'metis::flow :fresh-instances nil)
    (with-slots (
		 interface-id
		 srcaddr
		 dstaddr
		 srcport
		 dstport
		 protocol
		 packets
		 bytez
		 start
		 endf
		 action
		 status
		 ) x
      (if (cl-ppcre:all-matches value srcaddr)
	  (format t "|~A|~A|~A|~A|~A|~A|~A|~A|~A|~A|~A|~A~%"
		  interface-id
		  srcaddr
		  dstaddr
		  srcport
		  dstport
		  protocol
		  packets
		  bytez
		  start
		  endf
		  action
		  status)))))

(defun list-all-vpc ()
  (manardb:doclass (x 'metis::flow :fresh-instances nil)
    (with-slots (
		 interface-id
		 srcaddr
		 dstaddr
		 srcport
		 dstport
		 protocol
		 packets
		 bytez
		 start
		 endf
		 action
		 status
		 ) x
      (format t "|~A|~A|~A|~A|~A|~A|~A|~A|~A|~A|~A|~A~%"
	      interface-id
	      srcaddr
	      dstaddr
	      srcport
	      dstport
	      protocol
	      packets
	      bytez
	      start
	      endf
	      action
	      status))))

(defun allocate-vpc-file-hash ()
  (if (eql (hash-table-count *manard-flow-files*) 0)
      (init-manardb)
      (mapc
       #'(lambda (x)
	   (setf (gethash (slot-value x 'file) *manard-flow-files*) t))
       (manardb:retrieve-all-instances 'metis::flow-files))))

(defun flows-have-we-seen-this-file (file)
  (let ((name (get-full-filename file)))
    (multiple-value-bind (id seen)
	(gethash name *manard-flow-files*)
      seen)))

(defun flow-mark-file-processed (file)
  (let ((name (get-full-filename file)))
    (setf (gethash name *manard-flow-files*) t)
    (make-instance 'flow-files :file name)))

(defun get-vpc-date-list ()
  "Return uniqure list of events"
  (get-unique-values 'metis::date))

(defun get-vpc-interface-id-list ()
  "Return uniqure list of events"
  (get-unique-values 'metis::interface-id))

(defun get-vpc-srcaddr-list ()
  "Return uniqure list of events"
  (get-unique-values 'metis::srcaddr))

(defun get-vpc-dstaddr-list ()
  "Return uniqure list of events"
  (get-unique-values 'metis::dstaddr))

(defun get-vpc-srcport-list ()
  "Return uniqure list of events"
  (get-unique-values 'metis::srcport))

(defun get-vpc-dstport-list ()
  "Return uniqure list of events"
  (get-unique-values 'metis::dstport))

(defun get-vpc-protocols-list ()
  "Return uniqure list of events"
  (get-unique-values 'metis::protocol))

(defun get-vpc-action-list ()
  "Return uniqure list of events"
  (get-unique-values 'metis::action))

(defun geft-vpc-status-list ()
  "Return uniqure list of events"
  (get-unique-values 'metis::status))


(defun process-vf-file (file)
  (when (equal (pathname-type file) "gz")
    ;;(room t)
    (unless (flows-have-we-seen-this-file file)
      (handler-case
	  (progn
	    (format t "+")
	    (flow-mark-file-processed file)
	    (gzip-stream:with-open-gzip-file (in file)
	      (let ((i 0)
		    (btime (get-internal-real-time)))
		(loop
		   for line = (read-line in nil nil)
		   while line
		   collect (progn
			     (incf i)
			     (process-vf-line line)))
		(let* ((etime (get-internal-real-time))
		       (delta (/ (float (- etime btime)) (float internal-time-units-per-second)))
		       (rps (/ (float i) (float delta))))
		  (format t "~%rps:~A rows:~A delta:~A" rps i delta))
		#+sbcl (sb-ext:gc :full t) ;;ard
		)))
	(t (e) (format t "~%SHIT~%SHIT~%Error:~A~%SHIT~%SHIT~%" e)))
      (format t "-"))))

(declaim (inline process-vf-line))
(defun process-vf-line (line)
  (let* ((tokens (split-sequence:split-sequence #\Space line))
	 (length (list-length tokens)))
    (if (= 15 length)
	(destructuring-bind (date version account_id interface-id srcaddr dstaddr srcport dstport protocol packets bytez start end action status)
	    tokens
	  (insert-flows date interface-id srcaddr dstaddr srcport dstport protocol packets bytez start end action status)))))

(defun to-epoch (date)
  (local-time:timestamp-to-unix (local-time:universal-to-timestamp (cl-date-time-parser:parse-date-time date))))


(defun all-objects-have-idx (klass)


  )


(defun get-next-idx (klass)
  (let ((next 0))
    (format t "gnix: klass:~A length:~A~%" klass (length klass))
    1))
    ;;     (setf (gethash new-value klass-hash) obj)
;;        (setf
;; 	(+ 1
;; 	   (setf (slot-value obj 'max-id) (+ 1 max-id))
;; 	   (setf (slot-value obj 'idx) (+ 1 max-id))
;; 	   (setf nid (slot-value obj 'idx)))))
;; )




(fare-memoization:define-memo-function get-idx (klass new-value)
  "Return the object for a given value of klass"
  (if (and klass new-value)
      (let ((klass-hash (gethash klass *metis-fields*))
	    (nid nil))
	(multiple-value-bind (id seen)
	    (gethash new-value klass-hash)
	  (if seen
	      (setf nid id)
	      (progn ;; new item
		(setf nid (get-next-idx klass))
		(setf obj (make-instance klass :value new-value :idx nid))
		(setf (gethash new-value klass-hash) nid))))
	nid)))

(defun insert-flows (date interface-id srcaddr dstaddr srcport dstport protocol packets bytez start endf action status)
  (let (
	(date2 (to-epoch date))
	(interface-id-i (get-idx 'metis::interface-id interface-id))
	(srcaddr-i (get-idx 'metis::srcaddr srcaddr))
	(srcport-i (get-idx 'metis::srcport srcport))
	(dstaddr-i (get-idx 'metis::dstaddr dstaddr))
	(dstport-i (get-idx 'metis::dstport dstport))
	(protocol-i (get-idx 'metis::protocol protocol))
	(packets-i (get-idx 'metis::packets packets))
	(bytez-i (get-idx 'metis::bytez bytez))
	(start-i (get-idx 'metis::start start))
	(endf-i (get-idx 'metis::endf endf))
	(action-i (get-idx 'metis::action action))
	(status-i (get-idx 'metis::status status))
	)

    (format t "~{~A, ~}~%" (list date2 interface-id-i srcaddr-i dstaddr-i srcport-i dstport-i protocol-i packets-i bytez-i start-i endf-i action-i status-i))

    (make-instance 'flow
		   :date date2
		   ;;:conversation conversation-i
		   :interface-id interface-id-i
		   :srcaddr srcaddr-i
		   :srcport srcport-i
		   :dstaddr dstaddr-i
		   :dstport dstport-i
		   :protocol protocol-i
		   :packets packets-i
		   :bytez bytez-i
		   :start start-i
		   :endf endf-i
		   :action action-i
		   :status status-i)))
