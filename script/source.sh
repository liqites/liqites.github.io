#!/bin/bash

git status
git add . ; git commit -m "Update source at `date`"
git push origin source

echo "更新完成..."
