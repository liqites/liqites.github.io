#!/bin/bash

(cd ./_site; git status)
# (cd ./_site; git commit -m "Deployed at ")
(cd ./_site; git add . ; git commit -m "Deployed at `date`")
(cd ./_site; git push origin master)