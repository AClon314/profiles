# 进程打开的文件列表
exe=clash-verge
$exe & pgrep $exe | xargs -I % lsof -p % | less

# 追踪系统调用/信号
$exe & pgrep $exe | xargs -I % strace -p % -f -o /tmp/strace.log

# ps aux | grep $exe