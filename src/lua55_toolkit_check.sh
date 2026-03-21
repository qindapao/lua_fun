#!/bin/bash

# 1. 自动探测安装位置（按优先级数组顺序查找）
source ./lua55_toolkit_common.sh

LUA_ROOT=""
for path in "${INSTALL_PATHS[@]}" ; do
    if [[ -x "$path/bin/lua" ]] ; then
        LUA_ROOT="$path"
        break
    fi
done

if [[ -z "$LUA_ROOT" ]]; then
    printf '错误: 未找到 lua55 运行环境，请先运行 lua55_toolkit_install.sh\n'
    exit 1
fi

# 2. 设置临时局部环境变量（仅对当前进程及其子进程有效）
# 确保优先使用我们自己的 bin、lua 库和 .so 扩展
if [[ ":$PATH:" != *":$LUA_ROOT/bin:"* ]]; then
    export PATH="$LUA_ROOT/bin:$PATH"
fi

if [[ "$LUA_PATH" != "$LUA_ROOT/share/lua/5.5/?.lua;$LUA_ROOT/share/lua/5.5/?/init.lua;;" ]] ; then
    export LUA_PATH="$LUA_ROOT/share/lua/5.5/?.lua;$LUA_ROOT/share/lua/5.5/?/init.lua;;"
fi

if [[ "$LUA_CPATH" != "$LUA_ROOT/lib/lua/5.5/?.so;;" ]] ; then
    export LUA_CPATH="$LUA_ROOT/lib/lua/5.5/?.so;;"
fi

# 3. 打印当前检测的环境信息（可选，调试用）
printf '>>> 正在使用环境: %s\n' "$LUA_ROOT"

# 4. 调用 Lua 自检脚本
if [[ -f "./lua55_toolkit_check.lua" ]] ; then
    lua lua55_toolkit_check.lua
else
    printf '错误: 找不到自检脚本 lua55_toolkit_check.lua\n'
    exit 1
fi

