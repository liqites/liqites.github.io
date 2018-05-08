#!/bin/bash

git status
git add . ; git commit -m "Update source at `date`"
git push origin source

echo "`date` 更新完成..."
