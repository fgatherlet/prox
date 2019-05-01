#|
  This file is a part of prox project.
  Copyright (c) 2019 fgatherlet (fgatherlet@gmaill.com)
|#

#|
  thin proxy for dexador. useful for crawler.

  Author: fgatherlet (fgatherlet@gmaill.com)
|#

(defsystem "prox"
  :version "0.1.0"
  :author "fgatherlet"
  :license "MIT"
  :depends-on ("series"
               "dexador"
               "sha1-util"
               :quri
               :jsown
               )
  :components ((:module "src"
                :components
                ((:file "package")
                 (:file "main" :depends-on ("package"))
                 ;; (:file "prox")
                 )))
  :description "thin proxy for dexador. useful for crawler."
  :long-description
  #.(read-file-string
     (subpathname *load-pathname* "README.markdown"))
  :in-order-to ((test-op (test-op "prox-test"))))
