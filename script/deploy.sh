#!/bin/bash

# clean _deploy_path

echo "【`date +%T`】开始发布"
deploypath="./_deploy"

if [ -d $deploypath ]; then
  rm -rf $deploypath
  if [ $? -eq 0]; then
    echo "【`date +%T`】删除 ${deploypath} 成功"
  else
    echo "【`date +%T`】删除 ${deploypath} 失败"
  fi
fi

git clone -b master . _deploy --single-branch
cd ./_deploy
bundle exec jekyll build --config _config_prod.yml --destination ./_deploy
echo "【`date +%T`】生成网站成功"
echo "【`date +%T`】开始发布"
git add .
git add -u
git commit -m "Deployed at `date`"
# git push origin master
echo "【`date +%T`】发布网站成功"
