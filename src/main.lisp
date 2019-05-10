(in-package :prox)

(defvar *cache-root* #p"/tmp/prox-cache/")

(defun ts ()
  (- (get-universal-time) #.(encode-universal-time 0 0 0 1 1 1970 0)))

#.`(progn
     ,@(collect (mapping ((level (scan '(:d :i :w :e))))
                  `(defun ,(intern (format nil "LOG~a" level)) (&rest rest)
                     "logger."
                     (format t "~&prox ~a " ,level)
                     ;;(apply #'format t rest)
                     (let* ((tmp (apply #'format nil rest)))
                       (setq tmp (ppcre:regex-replace-all "\\s+" tmp " "))
                       (princ tmp))
                     (princ #\newline)
                     (finish-output *standard-output*)))))

(defun fetch (target &key
                       (url (etypecase target
                              (string target)))
                       (sleep-sec 0.5)
                       (cachep t)
                       (referer url)
                       )
  "
return: content code.
code : http-code or internal error code.
internal error code is negavie number.
-100 : dex:get error.
"
  (let* ((quri (quri:uri url))
         (ext (string-downcase (or (pathname-type (make-pathname :defaults (quri:uri-path (quri:uri quri)))) "html"))))
    (let* ((fetcher (etypecase target
                      (string   (lambda ()
                                  (dex:get target :headers `((:referer . ,referer))
                                           )))
                      (function target)))
           (sha1 (sha1-as-hex url))
           (sha1-pre (subseq sha1 0 2))
           (sha1-post (subseq sha1 2))
           (cache-path-directory (make-pathname :defaults *cache-root* :name (format nil "~a/" sha1-pre)))
           (cache-path-meta (make-pathname :defaults *cache-root* :name (format nil "~a/~a" sha1-pre sha1-post)))
           (cache-path (make-pathname :defaults *cache-root* :name (format nil "~a/~a.~a" sha1-pre sha1-post ext))))
      
      (when (and
             cachep
             (probe-file cache-path-meta)
             (probe-file cache-path))
        (let ((meta (collect-first (scan-file cache-path-meta #'read)))
              content)
          (if (jsown:val meta "octetp")
              (setf content (collect '(vector (unsigned-byte 8)) (with-open-file (is cache-path :element-type '(unsigned-byte 8))
                                                                   (scan-stream is #'read-byte))))
            (setf content (collect 'string (scan-file cache-path #'read-char))))
          (return-from fetch (values content 200 meta))))


      (multiple-value-bind (pathspec created)
          ;; ensure-directories-exist is buggy? if argument type is pathname, directory not created...
          (ensure-directories-exist (princ-to-string cache-path-directory)))
      
      (let ((meta (list :obj)))
        (setf (jsown:val meta "url") url)
        (setf (jsown:val meta "ts") (ts))
        (logd "funcall fetcher from")
        (multiple-value-bind (content code)
            (handler-case
                (funcall fetcher)
              (dex:http-request-failed (e) (values (dex:response-body e) (dex:response-status e)))
              (error (e) (values "" -100 meta)))
          (logd "funcall fetcher to")

          (unless (= 200 code)
            (logd "prox-get-content failed url:~a code:~a" url code)
            (return-from fetch (values content code)))

          (setf (jsown:val meta "code") code)
          (cond
            ((stringp content)
             (setf (jsown:val meta "octetp") nil)
             ;;(collect-file cache-path (scan content) #'write-char)
             (with-open-file (os cache-path :direction :output :if-exists :supersede)
               (collect-stream os (scan content) #'write-char)))
            ((typep content '(array (unsigned-byte 8)))
             (setf (jsown:val meta "octetp") t)
             (with-open-file (os cache-path :direction :output :element-type '(unsigned-byte 8) :if-exists :supersede)
               (collect-stream os (scan content) #'write-byte)))
            (t (error "unknown type")))
          (with-open-file (os cache-path-meta :direction :output :if-exists :supersede)
            (write meta :stream os))
          (sleep sleep-sec)
          (values content code meta))))))

