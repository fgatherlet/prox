(in-package :prox)

(defvar *cache-root* #p"/tmp/prox-cache/")

(defun fetch (target &key (url (etypecase target
                                 (string target))))

  (let* ((fetcher (etypecase target
                    (string   (lambda () (dex:get target)))
                    (function target)))
         (sha1 (sha1-as-hex url))
         (sha1-pre (subseq sha1 0 3))
         (sha1-post (subseq sha1 3))
         (cache-path-directory (make-pathname :defaults *cache-root* :name (format nil "~a/" sha1-pre)))
         (cache-path (make-pathname :defaults *cache-root* :name (format nil "~a/~a" sha1-pre sha1-post))))
    (when (probe-file cache-path)
      (return-from fetch (collect 'string (scan-file cache-path #'read-char))))

    (format t ">>ensure --from :~s~%" cache-path)
    (multiple-value-bind (pathspec created)
        ;; ensure-directories-exist is buggy? if argument type is pathname, directory not created...
        (ensure-directories-exist (princ-to-string cache-path-directory))
      (format t ">>ensure --toto :~s: ~s : ~s : ~s~%" cache-path-directory (probe-file cache-path-directory) pathspec created))
    (multiple-value-bind (content code) (funcall fetcher)
      (collect-file cache-path (scan content) #'write-char)
      content)))

