(in-package :metis)
;; (defvar *lmdb-files* (thread-safe-hash-table))
;; (defvar *metis-fields* (thread-safe-hash-table))
;; (defvar *metis-counters* (thread-safe-hash-table))
;; (defvar *metis-need-files* nil)
(defvar *lmdb-dir* #P"~/metis.mdb")

(defvar ct-fields '(
		    metis::additionalEventData
		    metis::awsRegion
		    metis::errorCode
		    metis::errorMessage
		    ;;metis::eventID
		    metis::eventName
		    metis::eventSource
		    ;;metis::eventTime
		    metis::eventType
		    metis::eventVersion
		    metis::recipientAccountId
		    ;;metis::requestID
		    ;;metis::requestParameters
		    metis::resources
		    ;;metis::responseElements
		    metis::sourceIPAddress
		    metis::userAgent
		    ;;metis::userIdentity
		    metis::userName
		    ))


(defmacro with-lmdb ((db) &body body)
  (alexandria:with-gensyms (env txn)
    `(let ((,env (lmdb:make-environment *lmdb-dir* :mapsize 102400000)))
       (lmdb:with-environment (,env)
	 (let ((,txn (lmdb:make-transaction ,env)))
	   (lmdb:begin-transaction ,txn)
	   (let ((db (lmdb:make-database ,txn "metis")))
	     (lmdb:with-database (,db)
	       (prog1
		   (progn
		     ,@body)
		 (lmdb:commit-transaction ,txn)))))))))


(defun lmdb-have-we-seen-this-file (file)
  nil)

(defun lmdb-mark-file-processed (file)
  nil)

(defun init-lmdb()
  (format t "Done Initializing~%")
  )

(defun init-ct-hashes ()
  nil)

(defun get-stats ()
  (format t "Totals ct:~A~%"
	  (lmdb-count)))

(defun find-username (userIdentity)
  (let ((a (fetch-value '(:|sessionContext| :|sessionIssuer| :|userName|) userIdentity))
	(b (fetch-value '(:|sessionContext| :|userName|) userIdentity))
	(c (fetch-value '(:|userName|) userIdentity))
	(d (car (last (cl-ppcre:split ":" (fetch-value '(:|arn|) userIdentity)))))
	(e (fetch-value '(:|type|) userIdentity))
	(len (length userIdentity)))
    ;;(format t "a: ~A b:~A c:~A d:~A len:~A username:~A" a b c d len username)
    (or a b c d e)))

;;(cl-ppcre:regex-replace #\newline 'userIdentity " "))))))


(defun compress-str (str)
  (when str
    (let ((store-me nil))
      (cond
	((consp str) (setf store-me (format nil "~{~A ~}" str)))
	((stringp str) (setf store-me str))
	)
      (if (< (length store-me) 10)
	  (flexi-streams:octets-to-string (thnappy:compress-string store-me))
	  store-me))))

(defun lmdb-normalize-insert (record)
  (handler-case
      (progn
	(destructuring-bind (
			     additionalEventData
			     awsRegion
			     errorCode
			     errorMessage
			     eventID
			     eventName
			     eventSource
			     eventTime
			     eventType
			     eventVersion
			     recipientAccountId
			     requestID
			     requestParameters
			     resources
			     responseElements
			     sourceIPAddress
			     userAgent
			     userIdentity
			     userName
			     )
	    record

	  (let ((key (concatenate 'string  eventTime "-" eventName "-" eventSource))
		(value (conspack:encode (list additionalEventData awsRegion errorCode errorMessage eventID eventName eventSource eventType eventVersion recipientAccountId requestID requestParameters resources responseElements sourceIPAddress userAgent userIdentity userName))))
	    (list key value))))
	    ;;(with-lmdb (db)
	    ;;(lmdb:put db key value)))))
    (t (e) (error-print "lmdb-normalize-insert" e))))

(defun cleanse (var)
  (typecase var
    (null (string var))
    (string var)
    (list (format nil "~{~s = ~s~%~}" var))))

(defun lmdb-get-or-insert-id (table value)
  (format t "lmdb-get-or-insert-id table:~A value:~A~%" table value)
  )

(defun lmdb-drop-table (query)
  (format t "lmdb-drop-table query:~A~%" query)
  )

(defun lmdb-do-query (query)
  (format nil "lmdb-do-query query:~A~%" query)
  )
