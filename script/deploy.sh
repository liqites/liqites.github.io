#!/bin/bash

(bundle exec jekyll build --config _config_prod.yml)
(cd ./_site; git status)
# (cd ./_site; git commit -m "Deployed at ")
(cd ./_site; git add . ; git commit -m "Deployed at `date`")
(cd ./_site; git push origin master)
(bundle exec jekyll build)

echo "发布完成..."
