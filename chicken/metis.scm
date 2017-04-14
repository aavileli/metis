(use z3)
(use srfi-1)
(use medea)
(use vector-lib)
(use posix)
(use files)
(use srfi-13)
(use format)
(use list-bindings)
(use lmdb)
(use s11n)
(use srfi-19)
(use srfi-18)

(define *db* (lmdb-open (make-pathname "/Users/akkad/" "metis.mdb") mapsize: 1000000000))

;;(define *db* (lmdb-open (make-pathname "/Users/akkad/" "metis.mdb") key: (string->blob "omg") mapsize: 1000000000))

(define *fields* '(
		   "additionalEventData"
		   "awsRegion"
		   "errorCode"
		   "errorMessage"
		   "eventID"
		   "eventName"
		   "eventSource"
		   "eventTime"
		   "eventType"
		   "eventVersion"
		   "recipientAccountId"
		   "requestID"
		   "requestParameters"
		   "resources"
		   "responseElements"
		   "sourceIPAddress"
		   "userAgent"
		   "userIdentity"
		   "userName"
		   ))

(define (parse-json-gz-file file)
  (let* ((gzip-stream (z3:open-compressed-input-file file))
	 (json (read-json gzip-stream)))
    (close-input-port gzip-stream)
    json))

(define (process-ct-file file)
  (lmdb-begin *db*)
  (format #t "count:~A~%" (lmdb-count *db*))
  (parse-ct-contents file)
  (lmdb-end *db*))

(define (parse-ct-contents file)
  (let* ((btime (current-seconds))
	 (json (parse-json-gz-file file))
	 (entries (vector->list (cdr (car json))))
	 (length (list-length entries)))
    (for-each
     (lambda (x)
       (normalize-insert (process-record x '() *fields*)))
     entries)
    (format #t "length: ~A delta: ~A~%" length (- (current-seconds) btime))
    ))

(define (normalize-insert record)
  (bind (
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
	(reverse record)

	(let ((key (string-join (list eventTime eventName eventSource) "-"))
	      (value (list additionalEventData awsRegion errorCode errorMessage eventID eventName eventSource eventType eventVersion recipientAccountId requestID requestParameters resources responseElements sourceIPAddress userAgent userIdentity userName)))
	  (lmdb-set! *db*
		     (string->blob (->string key))
		     (string->blob (with-output-to-string
				     (lambda ()
				       (serialize value)))))
	)))

(define (process-record line results fields)
  (cond ((null-list? fields)
	 results)
	(else
	 (let ((value (get-value (car fields) line)))
	   ;;(format #t "PR: field:~A value:~A~%" (car fields) value)
	   (process-record line
			   (cons value results)
			   (cdr fields))))))

(define (ct-report-sync dir)
  (for-each
   (lambda (x)
     (cond ((string-suffix? ".json.gz" x)
	    (process-ct-file x)
	    )))
   (find-files dir)))



(define (type-of x)
  (cond ((number? x) "Number")
	((list? x) "list")
	((pair? x) "Pair")
	((vector? x) "Vector")
	((null? x) "null")
	((string? x) "String")
	(else "Unknown type")))

(define (get-value field record)
  (let* ((field-sym (string->symbol field))
	(value (assoc field-sym record)))
    (cond ((pair? value)
	(cdr value))
	  (else value))))

(define list-length
  (lambda (obj)
    (call-with-current-continuation
      (lambda (return)
        (letrec ((r
                  (lambda (obj)
                    (cond ((null? obj) 0)
                          ((pair? obj)
                           (+ (r (cdr obj)) 1))
                          (else (return #f))))))
          (r obj))))))

(ct-report-sync "/Users/akkad/CT")
(lmdb-close *db*)
