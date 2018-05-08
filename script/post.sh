#!/bin/bash
POST_TITLE=$1
DATE=`date +%Y-%m-%d`
TIMESTAMP=`date +%s`
CREATED_TIME=`date "+%Y-%m-%d %T %z"`

TRUE_TITLE=${POST_TITLE//_/ }

FILE_NAME=${POST_TITLE//-/}

FILE_NAME=$(echo "$FILE_NAME" | sed 's/\__/_/g' | sed 's/_/-/g')

FILE_NAME="$DATE-$FILE_NAME.md"

echo "文件名: $FILE_NAME"
echo "文章标题: $TRUE_TITLE"

(touch ./_posts/$FILE_NAME)
echo "---
layout: post
title: $TRUE_TITLE
author: Tesla Lee
date: $CREATED_TIME
categories:
---" > ./_posts/$FILE_NAME
