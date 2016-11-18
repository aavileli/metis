(in-package :metis)

;;(ql:quickload :manardb)

(defun init-manard()
  (unless (boundp 'manardb:use-mmap-dir)
    (manardb:use-mmap-dir "~/ct-manardb/")))

(manardb:defmmclass files ()
  ((file :type STRING :initarg :file)))

(manardb:defmmclass ct ()
  ((additionalEventData :type STRING :initarg :additionalEventData :accessor additionalEventData)
   (awsRegion :type STRING :initarg :awsRegion :accessor awsRegion)
   (errorCode :type STRING :initarg :errorCode :accessor errorCode)
   (errorMessage :type STRING :initarg :errorMessage :accessor errorMessage)
   (eventID :type STRING :initarg :eventID :accessor eventID)
   (eventName :type STRING :initarg :eventName :accessor eventName)
   (eventSource :type STRING :initarg :eventSource :accessor eventSource)
   (eventTime :type STRING :initarg :eventTime :accessor eventTime)
   (eventType :type STRING :initarg :eventType :accessor eventType)
   (eventVersion :type STRING :initarg :eventVersion :accessor eventVersion)
   (recipientAccountId :type STRING :initarg :recipientAccountId :accessor recipientAccountId)
   (requestID :type STRING :initarg :requestID :accessor requestID)
   (requestParameters :type STRING :initarg :requestParameters :accessor requestParameters)
   (resources :type STRING :initarg :resources :accessor resources)
   (responseElements :type STRING :initarg :responseElements :accessor responseElements)
   (sourceIPAddress :type STRING :initarg :sourceIPAddress :accessor sourceIPAddress)
   (userAgent :type STRING :initarg :userAgent :accessor userAgent)
   (userIdentity :type STRING :initarg :userIdentity :accessor userIdentity)
   (userName :type STRING :initarg :userName :accessor username)
   ))

(defun manardb-have-we-seen-this-file (file)
  (unless (boundp '*manard-files*)
    (allocate-file-hash))
  (multiple-value-bind (id seen)
      (gethash (file-namestring file) *manard-files*)
    seen))

(defun manardb-get-files (file)
  (remove-if-not
   (lambda (x) (string-equal (file-namestring file) (slot-value x 'file)))
   (manardb:retrieve-all-instances 'metis::files)))

(defun manardb-mark-file-processed (file)
  (let ((name (ignore-errors (file-namestring file))))
    (format t "mark: ~A~%" name)
    (setf (gethash name *manard-files*) t)
    (make-instance 'files :file name)))

(defun print-record-a (x)
  (format t "|~A|~A|~A|~A|~A|~A|~A|~%"
	  (slot-value x 'eventTime)
	  (slot-value x 'eventName)
	  (slot-value x 'eventSource)
	  (slot-value x 'sourceIPAddress)
	  (slot-value x 'userAgent)
	  (slot-value x 'errorMessage)
	  (slot-value x 'errorCode)
	  ;;(slot-value x 'userIdentity)
	  ))

(defun allocate-file-hash ()
  (print "allocate-file-hash")
  (defvar *manard-files* (make-hash-table :test 'equalp))
  (init-manard)
  (mapc
   #'(lambda (x)
       (setf (gethash (slot-value x 'file) *manard-files*) t))
   (manardb:retrieve-all-instances 'metis::files)))

(defun get-by-name (name)
  (manardb:doclass (x 'metis::ct :fresh-instances nil)
		   (if (string-equal name (slot-value x 'userName))
		       (with-slots (userName eventTime eventName eventSource sourceIPAddress userAgent errorMessage errorCode) x
			 (format t "|~A|~A|~A|~A|~A|~A|~A|~%" eventTime eventName eventSource sourceIPAddress userAgent errorMessage errorCode)))))

(defun get-by-event (name)
  (manardb:doclass (x 'metis::ct :fresh-instances nil)
		   (if (string-equal name (slot-value x 'eventName))
		       (with-slots (userName eventTime eventName eventSource sourceIPAddress userAgent errorMessage errorCode) x
			 (format t "|~A|~A|~A|~A|~A|~A|~A|~%" eventTime userName eventSource sourceIPAddress userAgent errorMessage errorCode)))))

(defun get-by-errorcode (name)
  (manardb:doclass (x 'metis::ct :fresh-instances nil)
		   (if (string-equal name (slot-value x 'errorCode))
		       (with-slots (userName eventTime eventName eventSource sourceIPAddress userAgent errorMessage errorCode userIdentity) x
			 (format t "|~A|~A|~A|~A|~A|~A|~A|~%" eventTime userName eventName eventSource sourceIPAddress userAgent errorMessage)))))


(defun get-all-errorcodes ()
  (manardb:doclass (x 'metis::ct :fresh-instances nil)
		   (unless (string-equal "NIL" (slot-value x 'errorCode))
		       (with-slots (userName eventTime eventName eventSource sourceIPAddress userAgent errorMessage errorCode userIdentity) x
			 (if (string-equal "NIL" userName)
			     (format t "|~A|~A|~A|~A|~A|~A|~A|~A|~%" eventTime errorCode (fetch-value '(:|sessionContext| :|sessionIssuer| :|userName|) userIdentity) eventName eventSource sourceIPAddress userAgent errorMessage)
  			     (format t "|~A|~A|~A|~A|~A|~A|~A|~A|~%" eventTime errorCode userName eventName eventSource sourceIPAddress userAgent errorMessage))))))

  ;;(cl-ppcre:regex-replace #\newline 'userIdentity " "))))))

(defun get-errorcode-list ()
  "Return uniqure list of users"
  (let ((names (make-hash-table :test 'equalp)))
    (manardb:doclass (x 'metis::ct :fresh-instances nil)
		     (with-slots (errorCode) x
		       (unless (gethash errorCode names)
			 (setf (gethash errorCode names) t))))
    (format t "~{~A~^, ~}" (sort (alexandria:hash-table-keys names) #'string-lessp))))

(defun get-name-list ()
  "Return uniqure list of users"
  (let ((names (make-hash-table :test 'equalp)))
    (manardb:doclass (x 'metis::ct :fresh-instances nil)
		     (with-slots (userName) x
		       (unless (gethash userName names)
			 (setf (gethash userName names) t))))
    (format t "~{~A~^, ~}" (sort (alexandria:hash-table-keys names) #'string-lessp))))

(defun get-event-list ()
  "Return uniqure list of events"
  (let ((names (make-hash-table :test 'equalp)))
    (manardb:doclass (x 'metis::ct :fresh-instances nil)
		     (with-slots (eventName) x
		       (unless (gethash eventName names)
			 (setf (gethash eventName names) t))))
    (format t "~{~A~^, ~}" (sort (alexandria:hash-table-keys names) #'string-lessp))))

(defun manardb-recreate-tables ()
  (format t "manardb-recreate-tables~%"))

(defun manardb-normalize-insert (record)
  ;;manardb-nomalize-insert (NIL us-west-1 NIL NIL 216e957f-230e-42ea-bfc7-e0d07d321a8b DescribeDBInstances rds.amazonaws.com 2015-08-07T19:04:52Z AwsApiCall 1.03 224108527019 2f1d4165-3d37-11e5-aae4-c1965b0823e9 NIL NIL NIL bogus.example.com signin.amazonaws.com (invokedBy signin.amazonaws.com sessionContext (attributes (creationDate 2015-08-07T11:17:07Z mfaAuthenticated true)) userName meylor accessKeyId ASIAIOHLZS2V2QON52LA accountId 224108527019 arn arn:aws:iam::224108527019:user/meylor principalId AIDAJVKKNU5BSTZIOF3EU type IAMUser) meylor)
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
    (make-instance 'ct
  		   :additionalEventData additionalEventData
  		   :awsRegion awsRegion
  		   :errorCode errorCode
  		   :errorMessage errorMessage
  		   :eventID eventID
  		   :eventName eventName
  		   :eventSource eventSource
  		   :eventTime eventTime
  		   :eventType eventType
  		   :eventVersion eventVersion
  		   :recipientAccountId recipientAccountId
  		   :requestID requestID
  		   :requestParameters requestParameters
  		   :resources resources
  		   :responseElements responseElements
  		   :sourceIPAddress sourceIPAddress
  		   :userAgent userAgent
  		   :userIdentity userIdentity
  		   :userName userName
  		   )
    )
  ;;  (print (length (manardb:retrieve-all-instances 'ct)))
  )


(defun manardb-get-or-insert-id (table value)
  (format t "manard-get-or-insert-id table:~A value:~A~%" table value)
  )

(defun manardb-drop-table (query)
  (format t "manardb-drop-table query:~A~%" query)
  )

(defun manardb-do-query (query)
  (format nil "manardb-do-query query:~A~%" query)
  )
