---
layout: post
title:  "Mac Root Bug"
author: Tesla Lee
date:   2017-12-07 10:11:00 +0800
categories: Mac
---

前阵子 Mac 爆出了让人尴尬的安全漏洞：默认情况下，root 用户的密码为空。

<!-- more -->

### 现象

这个漏洞的现象是：在任何地方需要管理员授权时，输入 root 用户名，密码为空，连续输入三次后，就获得了 root 权限。

### 解决办法

修改 root 密码的方法，参看这篇 Apple 的[文章](https://support.apple.com/kb/PH6515?locale=zh_CN&viewlocale=zh_CN)