#!/bin/sh
# 获取 commit 记录，并筛选出以 "^mediainfo" 开头的记录
commits=$(git log --pretty=format:'## %ad%n提交者: %an%n%s' --date=short)
