#|
  This file is a part of prox project.
  Copyright (c) 2019 fgatherlet (fgatherlet@gmaill.com)
|#

(defsystem "prox-test"
  :defsystem-depends-on ("prove-asdf")
  :author "fgatherlet"
  :license "MIT"
  :depends-on ("prox"
               "prove")
  :components ((:module "t"
                :components
                ((:test-file "test"))))
  :description "Test system for prox"

  :perform (test-op (op c) (symbol-call :prove-asdf :run-test-system c)))
