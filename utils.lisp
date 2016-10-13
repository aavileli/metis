(in-package :metis)

(fare-memoization:define-memo-function get-hostname-by-ip (ip)
  (if (boundp '*benching*)
      "bogus.example.com"
      (progn
	(if (cl-ppcre:all-matches "^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$" ip)
	    (let ((name
		   #+allegro
		    (ignore-errors (socket:ipaddr-to-hostname ip))
		    #+sbcl
		    (ignore-errors (sb-bsd-sockets:host-ent-name
				    (sb-bsd-sockets:get-host-by-address
				     (sb-bsd-sockets:make-inet-address ip))))
		    #+lispworks
		    (ignore-errors (comm:get-host-entry ip :fields '(:name)))
		    #+clozure
		    (ignore-errors (ccl:ipaddr-to-hostname (ccl:dotted-to-ipaddr ip)))))
	      (if (null name)
		  ip
		  name))
	    ip))))

#-clozure
(defun read-json-gzip-file (file)
  (jonathan:parse
   (uiop:run-program
    (format nil "zcat ~A" file)
    :output :string)))

#+clozure
(defun read-json-gzip-file (file)
  (with-input-from-string
      (s (apply #'concatenate 'string
		(gzip-stream:with-open-gzip-file (in file)
		  (loop for l = (read-line in nil nil)
		     while l collect l))))
    (jonathan:parse s)))

(defun cdr-assoc (item a-list &rest keys)
  (cdr (apply #'assoc item a-list keys)))

(define-setf-expander cdr-assoc (item a-list &rest keys)
  (let ((item-var (gensym))
        (a-list-var (gensym))
        (store-var (gensym)))
    (values
     (list item-var a-list-var)
     (list item a-list)
     (list store-var)
     `(let ((a-cons (assoc ,item-var ,a-list-var ,@ keys)))
        (if a-cons
            (setf (cdr a-cons) ,store-var)
            (setf ,a-list (acons ,item-var ,store-var ,a-list-var)))
        ,store-var)
     `(cdr (assoc ,item-var ,a-list-var ,@ keys)))))

(defclass queue ()
  ((list :initform nil)
   (tail :initform nil)))

(defmethod print-object ((queue queue) stream)
  (print-unreadable-object (queue stream :type t)
    (with-slots (list tail) queue
      (cond ((cddddr list)
	     ;; at least five elements, so print ellipsis
	     (format stream "(~{~S ~}... ~S)"
		     (subseq list 0 3) (first tail)))
	    ;; otherwise print whole list
	    (t (format stream "~:S" list))))))

(defmethod dequeue ((queue queue))
  (with-slots (list) queue
    (pop list)))

(defmethod queue-length ((queue queue))
  (with-slots (list) queue
    (list-length list)))

(defmethod enqueue (new-item (queue queue))
  (with-slots (list tail) queue
    (let ((new-tail (list new-item)))
      (cond ((null list) (setf list new-tail))
	    (t (setf (cdr tail) new-tail)))
      (setf tail new-tail)))
  queue)

(defun flatten (obj)
  (do* ((result (list obj))
        (node result))
       ((null node) (delete nil result))
    (cond ((consp (car node))
           (when (cdar node) (push (cdar node) (cdr node)))
           (setf (car node) (caar node)))
          (t (setf node (cdr node))))))

(defun file-string (path)
  (with-open-file (stream path)
    (let ((data (make-string (file-length stream))))
      (read-sequence data stream)
      data)))
