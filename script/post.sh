#!/bin/bash
POST_TITLE=$1
DATE=`date +%Y-%m-%d`
TIMESTAMP=`date +%s`
CREATED_TIME=`date "+%Y-%m-%d %T %z"`

TRUE_TITLE=${POST_TITLE//-/ }

FILE_NAME="$DATE-$POST_TITLE.md"

(touch ./_posts/$FILE_NAME)
echo "---
layout: post
title: $TRUE_TITLE
author: Tesla Lee
date: $CREATED_TIME
categories:
---" > ./_posts/$FILE_NAME
