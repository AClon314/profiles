#!/bin/bash
#set -x 

usage() {
echo "Usage: $0 [path] [lines]"
echo "  path: local git repository"
echo "  lines: how much files to show&remove, default 100"
echo
echo "eg1: $0 ~/local_repo 200"
echo "eg2: $0 ."
}
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    exit 0
fi

# 原教程： https://www.jianshu.com/p/fe3023bdc825
cd $1
head_lines=${2:-100}

list(){
# Shows you the largest objects in your repo's pack file. Written for osx.
# @see http://stubbisms.wordpress.com/2009/07/10/git-script-to-show-largest-pack-objects-and-trim-your-waist-line/
# @author Antony Stubbs

# set the internal field spereator to line break, so that we can iterate easily over the verify-pack output
IFS=$'\n';

# list all objects including their size, sort by size, take top 10
objects=`git verify-pack -v .git/objects/pack/pack-*.idx | grep -v chain | sort -k3nr | head -n $head_lines`

output="NO.,raw,pack,SHA,path"
i=0
for y in $objects
do
    i=$((i+1))
    # extract the size in bytes
    size=$((`echo $y | cut -f 5 -d ' '`/1024))
    # extract the compressed size in bytes
    compressedSize=$((`echo $y | cut -f 6 -d ' '`/1024))
    # extract the SHA
    sha=`echo $y | cut -f 1 -d ' '`
    # find the objects location in the repository tree
    fileLoc=`git rev-list --all --objects | grep $sha`
    #lineBreak=`echo -e "\n"`
    output="${output}\n${i},${size},${compressedSize},${fileLoc}"
done

echo -e $output | column -t -s ', '
}
list_hint() {
echo "Remember the first number of files to be deleted, then press q to exit.
请记住要删除前多少个文件，然后按q退出。

All sizes are in kB's. The pack column is the size of the object, compressed, inside the pack file.
所有大小均以kB为单位。“pack”列：pack内，raw文件压缩后的大小。"
}

rm_local() {
git filter-branch --force --index-filter "git rm -rf --cached --ignore-unmatch $*" --prune-empty --tag-name-filter cat -- --all
}

rm_all() {
rm_local "${files[*]}"
set -x
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now
git gc --aggressive --prune=now
set +x

cmd_danger="pushd ${1} && \
git push origin $(git rev-parse --abbrev-ref HEAD) --force && \
git remote prune origin && \
popd"

echo "$cmd_danger" | xclip -selection clipboard && copied_en="📋 copied, " && copied_cn="📋 已复制到剪贴板，"
echo "${copied_en}please execute the below command manually to clean the remote repository: 
${copied_cn}请手动执行以下命令，以清理远程仓库："
echo -e "$cmd_danger"

}




set -e
trap 'echo "💡 Tips for line 40 error: ${head_lines} is too large, should be lesser. ${head_lines}太大了，再小点。"' EXIT
result=$(list)
trap - EXIT

echo -e "$(list_hint)\n\n$result" | less -K -S
# awk vs cut: awk可以将连续的空格视为一个分隔符，而cut则不行
files=$(echo "$result" | tail -n +2 | awk '{print $5}')

echo -n "🗑 (ENTER to delete all listed) How many largest files to delete:"
read -r lines
[ -n "$lines" ] && head_lines=$lines
files=($(echo "$files" | head -n $head_lines))
IFS=$' \t\n'
result=$(printf "%s\n" "${files[@]}")
set +e
echo -e "⚠️  即将删除以下文件，按q继续，按Ctrl+C取消\n\n$result" | less -K && rm_all $1