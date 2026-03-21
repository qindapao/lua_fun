#!/usr/bin/env bash

# windows(msys2 ucrt64)的大部分的库可以使用pacman安装
# 或者使用 luarocks 安装

BASE_DIR=$(pwd)
DEST_FILE='lua55_toolkit.tar.gz'
CROSS_CC="aarch64-linux-gnu-gcc"

build_clean ()
{
    rm -rf dest
    rm -rf lpeg-1.1.0
    rm -rf lua-5.5.0
    rm -rf luafilesystem-1_9_0
    rm -rf luv-1.51.0-2
    rm -rf Penlight-1.15.0
    rm -rf luautf8-0.2.0
    rm -rf zeromq-4.3.5
    rm -rf lzmq-0.4.4
    rm -rf ${DEST_FILE}
}

# windows ucrt64 使用 pacman 安装
# pacman -S mingw-w64-ucrt-x86_64-lua
# pacman -S mingw-w64-ucrt-x86_64-lua-luarocks
build_lua ()
{
    cd ${BASE_DIR}
    mkdir dest
    tar xzvf lua-5.5.0.tar.gz
    cd lua-5.5.0
    # make linux CC="$CROSS_CC" MYLDFLAGS="-Wl,-E"
    # linux 默认就会打开 -Wl,-E，所以不加也没关系
    make linux CC="$CROSS_CC" MYLIBS="-ldl"
    make install INSTALL_TOP=${BASE_DIR}/dest
}

# windows ucrt64 使用 
# luarocks install dkjson
build_json ()
{
    cd ${BASE_DIR}
    cp dkjson.lua ./dest/share/lua/5.5/
}

build_luv ()
{
    cd ${BASE_DIR}
    tar -xzvf luv-1.51.0-2.tar.gz
    cd luv-1.51.0-2
    mkdir build && cd build
    # 配置 CMake (关键参数)
    cmake .. \
        -DCMAKE_SYSTEM_NAME=Linux \
        -DCMAKE_C_COMPILER=${CROSS_CC} \
        -DBUILD_MODULE=ON \
        -DWITH_SHARED_LIBUV=OFF \
        -DWITH_LUA_ENGINE=Lua \
        -DLUA_BUILD_TYPE=System \
        -DLUA_INCLUDE_DIR="${BASE_DIR}/dest/include" \
        -DLUA_LIBRARIES="${BASE_DIR}/dest/lib/liblua.a" \
        -DCMAKE_PREFIX_PATH="${BASE_DIR}/dest" \
        -DCMAKE_DISABLE_FIND_PACKAGE_Lua=TRUE
    make
    
    cp -f luv.so ${BASE_DIR}/dest/lib/lua/5.5/
}

build_luv_windows_ucrt64 ()
{
    cd ${BASE_DIR}
    # 安装系统级依赖
    pacman -S mingw-w64-ucrt-x86_64-libuv

    tar -xzvf luv-1.51.0-2.tar.gz
    cd luv-1.51.0-2
    mkdir build && cd build

    cmake .. -G "MinGW Makefiles" \
        -DWITH_LUA_ENGINE=Lua \
        -DLUA_BUILD_TYPE=System \
        -DWITH_SHARED_LIBUV=ON \
        -DBUILD_MODULE=ON \
        -DBUILD_SHARED_LIBS=OFF

    # 注意: 千万不要直接运行 make 命令,那个不对
    mingw32-make

    if [[ ! -s luv.dll ]] ; then
        printf '%s fail!\n' "${FUNCNAME[0]}"
        return 1
    fi
    
    # 拷贝到库地址
    # 通过下面的命令可以查看库的路径
    # lua -e "print(package.cpath)"
    cp -f luv.dll /d/msys64/ucrt64/lib/lua/5.4/
}

# 查询安装的包
# pacman -Qs lua-
#
# q00546874@DESKTOP-0KALMAH UCRT64 /d/tmp/2026-03-20/lzmq-0.4.4# pacman -Qs lua-
# local/mingw-w64-ucrt-x86_64-lua-lpeg 1.1.0-1
#     Pattern-matching library for Lua (mingw-w64)
# local/mingw-w64-ucrt-x86_64-lua-luarocks 3.12.2-1
#     the package manager for Lua modules (mingw-w64)
# 
# windows ucrt64 使用 
# luarocks install luafilesystem
# lua -e "print(require('lfs')._VERSION)"
build_lfs ()
{
    cd ${BASE_DIR}
    unzip luafilesystem-1_9_0.zip
    cd luafilesystem-1_9_0
    ${CROSS_CC} -O2 -shared -fPIC -o lfs.so src/lfs.c -I${BASE_DIR}/dest/include
    if [[ ! -s lfs.so ]] ; then
        printf '%s fail!\n' "${FUNCNAME[0]}"
        return 1
    fi
    cp -f lfs.so ${BASE_DIR}/dest/lib/lua/5.5/
}

# windows ucrt64 使用 
# pacman -S mingw-w64-ucrt-x86_64-lua-lpeg
build_lpeg ()
{
    cd ${BASE_DIR}

    tar xzvf lpeg-1.1.0.tar.gz
    cd lpeg-1.1.0
    ${CROSS_CC} -O2 -shared -fPIC -o lpeg.so \
        lpcap.c lpcode.c lpcset.c lpprint.c lptree.c lpvm.c \
        -I${BASE_DIR}/dest/include

    if [[ ! -s lpeg.so ]] ; then
        printf "%s fail!\n" "${FUNCNAME[0]}"
        return 1
    fi

    cp -f lpeg.so ${BASE_DIR}/dest/lib/lua/5.5/
    # 提供类似正则的简单语法
    cp -f re.lua ${BASE_DIR}/dest/share/lua/5.5/
    # 提供Lpeg的测试用例(在新系统上建议先运行这个测试下)
    cp -f test.lua ${BASE_DIR}/dest/share/lua/5.5/test_lpeg.lua
}

# 列出已经安装过的模块
# luarocks list
# luarocks install penlight
build_penlight ()
{
    cd ${BASE_DIR}
    unzip Penlight-1.15.0.zip
    cd Penlight-1.15.0/lua
    cp -r pl ${BASE_DIR}/dest/share/lua/5.5/
}

# luarocks install luautf8
build_lua_utf8 ()
{
    cd ${BASE_DIR}
    unzip luautf8-0.2.0.zip
    cd luautf8-0.2.0
    ${CROSS_CC} -O2 -fPIC -shared lutf8lib.c -o lua-utf8.so -I${BASE_DIR}/dest/include
    cp -f lua-utf8.so ${BASE_DIR}/dest/lib/lua/5.5/
}

build_zeromq_core ()
{
    cd ${BASE_DIR}
    tar -xzvf zeromq-4.3.5.tar.gz
    cd zeromq-4.3.5
    mkdir -p build && cd build
    
    # 交叉编译 ZMQ 核心 (静态库)
    # 注意：这里我们要用到 g++
    # # 告诉 CMake 目标系统是 Linux，触发交叉编译逻辑
    # -DCMAKE_SYSTEM_NAME=Linux \
    # # 指定 C 编译器（你的 aarch64-linux-gnu-gcc）
    # -DCMAKE_C_COMPILER=${CROSS_CC} \
    # # 指定 C++ 编译器（ZMQ 是 C++ 写的，必须用对应的 g++）
    # -DCMAKE_CXX_COMPILER="${CROSS_CC%gcc}g++" \
    # # 关闭动态库生成，我们不需要 .so 拖油瓶
    # -DBUILD_SHARED=OFF \
    # # 强制生成静态库 (.a 文件)，方便后面“吞”进 Lua 插件里
    # -DBUILD_STATIC=ON \
    # # 关掉测试程序编译，省时间，也避免缺少某些系统库导致报错
    # -DZMQ_BUILD_TESTS=OFF \
    # # 开启最高等级优化，去掉调试信息，让库文件体积更小、跑得更快
    # -DCMAKE_BUILD_TYPE=Release \
    # # 关键！强制开启 -fPIC。没有它，静态库就没法编进 Lua 的动态库 (.so) 里
    # -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    cmake .. \
        -DCMAKE_SYSTEM_NAME=Linux \
        -DCMAKE_C_COMPILER=${CROSS_CC} \
        -DCMAKE_CXX_COMPILER="${CROSS_CC%gcc}g++" \
        -DBUILD_SHARED=OFF \
        -DBUILD_STATIC=ON \
        -DZMQ_BUILD_TESTS=OFF \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON
        
    make -j$(nproc)
    # 产物：libzmq.a (在 build/lib 下)
    if [[ ! -s ./lib/libzmq.a ]] ; then
        printf '%s fail!\n' "${FUNCNAME[0]}"
        return 1
    fi
}

build_lzmq ()
{
    cd ${BASE_DIR}
    # 下载并解压 v0.4.4
    tar -xzvf lzmq-0.4.4.tar.gz
    cd lzmq-0.4.4
    
    # 核心编译命令
    # -02 开启二级优化。它会在保证代码逻辑绝对安全的前提下，尽可能提高运行速度，是生产环境的标准配置。
    # -shared：告诉编译器，我们要生成的是一个动态库（.so），这样 Lua 才能用 require 加载它。
    # -fPIC：生成“位置无关代码”。这是必须加的，否则这个库没法在内存中被动态加载
    # -o: 作用：指定输出文件名。Lua 默认会寻找和 require("lzmq") 同名的 .so 文件。
    # ${BASE_DIR}/zeromq-4.3.5/build/lib/libzmq.a: 编译器会把这个几兆大小的 libzmq.a 
    #   直接“吃”进 lzmq.so 里。这样你分发工具包时，就不需要单独带一个 libzmq.so 了，实现单文件发布。
    # -lstdc++:  因为 libzmq.a 是用 C++ 写的，所以链接时必须带上 C++ 的标准库，
    #   否则会报一堆 new/delete 找不到的错误。
    # -lpthread：ZeroMQ 是多线程的，必须链接线程库。
    # -ldl：支持动态加载（加载其他插件用）。
    # -lm：数学库（处理浮点数和计算用）。
    ${CROSS_CC} -O2 -shared -fPIC -o lzmq.so \
        src/lzmq.c     \
        src/lzutils.c  \
        src/poller.c   \
        src/zcontext.c \
        src/zerror.c   \
        src/zmsg.c     \
        src/zsocket.c  \
        src/zpoller.c  \
        src/ztimer.c   \
        -I${BASE_DIR}/dest/include \
        -I${BASE_DIR}/zeromq-4.3.5/include \
        ${BASE_DIR}/zeromq-4.3.5/build/lib/libzmq.a \
        -lstdc++ -lpthread -ldl -lm

    if [[ ! -s lzmq.so ]] ; then
        printf "%s 编译失败！检查 libzmq.a 路径！\n" "${FUNCNAME}"
        return 1
    fi

    # 搬运到你的 5.5 目录
    mkdir -p ${BASE_DIR}/dest/lib/lua/5.5/
    cp -f lzmq.so ${BASE_DIR}/dest/lib/lua/5.5/
}

build_lzmq_windows_ucrt64 ()
{
    cd ${BASE_DIR}
    pacman -S mingw-w64-ucrt-x86_64-zeromq

    tar -xzvf lzmq-0.4.4.tar.gz
    cd lzmq-0.4.4

    # -DLUABUFFER_COMPAT: 增加兼容性(如果以后代码遇到不可预知的错误，可以考虑加上)
    # -lws2_32 -liphlpapi: Windows 网络库必带！
    gcc -O2 -shared -s -o lzmq.dll \
        src/*.c     \
        -I/ucrt64/include \
        -L/ucrt64/bin \
         -lzmq -llua54 -lws2_32 -liphlpapi

    if [[ ! -s lzmq.dll ]] ; then
        printf '%s fail!\n' "${FUNCNAME[0]}"
        return 1
    fi
    
    # 拷贝到库地址
    # 通过下面的命令可以查看库的路径
    # lua -e "print(package.cpath)"
    cp -f lzmq.dll /d/msys64/ucrt64/lib/lua/5.4/
}

pack_all ()
{
    cd ${BASE_DIR}
    tar -czvf "$DEST_FILE" -C dest .
    printf 'all work down, dest file:%s\n' "$DEST_FILE"
}

build_clean        &&
build_lua          &&
build_json         &&
build_luv          &&
build_lfs          &&
build_lpeg         &&
build_penlight     &&
build_lua_utf8     &&
build_zeromq_core  &&
build_lzmq         &&
pack_all

# Linux 系统上C库的链接情况
# Storage:/lua55/lib/lua/5.5 # ls
# lfs.so  lpeg.so  lua-utf8.so  luv.so  lzmq.so
# Storage:/lua55/lib/lua/5.5 # ldd lfs.so
#         linux-vdso.so.1 (0x0000ffff8b9eb000)
#         libc.so.6 => /lib64/libc.so.6 (0x0000ffff8b827000)
#         /lib/ld-linux-aarch64.so.1 (0x0000ffff8b9ad000)
# Storage:/lua55/lib/lua/5.5 # ldd lpeg.so
#         linux-vdso.so.1 (0x0000ffff8e2e8000)
#         libc.so.6 => /lib64/libc.so.6 (0x0000ffff8e106000)
#         /lib/ld-linux-aarch64.so.1 (0x0000ffff8e2aa000)
# Storage:/lua55/lib/lua/5.5 # ldd lua-utf8.so
#         linux-vdso.so.1 (0x0000ffffa3852000)
#         libc.so.6 => /lib64/libc.so.6 (0x0000ffffa3657000)
#         /lib/ld-linux-aarch64.so.1 (0x0000ffffa3814000)
# Storage:/lua55/lib/lua/5.5 # ldd luv.so
#         linux-vdso.so.1 (0x0000ffff9bd79000)
#         librt.so.1 => /lib64/librt.so.1 (0x0000ffff9bc98000)
#         libpthread.so.0 => /lib64/libpthread.so.0 (0x0000ffff9bc63000)
#         libdl.so.2 => /lib64/libdl.so.2 (0x0000ffff9bc42000)
#         libm.so.6 => /lib64/libm.so.6 (0x0000ffff9bb71000)
#         libc.so.6 => /lib64/libc.so.6 (0x0000ffff9b9eb000)
#         /lib/ld-linux-aarch64.so.1 (0x0000ffff9bd3b000)
# Storage:/lua55/lib/lua/5.5 # ldd lzmq.so
#         linux-vdso.so.1 (0x0000ffff9ca82000)
#         libstdc++.so.6 => /lib64/libstdc++.so.6 (0x0000ffff9c7a3000)
#         libpthread.so.0 => /lib64/libpthread.so.0 (0x0000ffff9c76e000)
#         libdl.so.2 => /lib64/libdl.so.2 (0x0000ffff9c74d000)
#         libm.so.6 => /lib64/libm.so.6 (0x0000ffff9c67c000)
#         libgcc_s.so.1 => /lib64/libgcc_s.so.1 (0x0000ffff9c64b000)
#         libc.so.6 => /lib64/libc.so.6 (0x0000ffff9c4c5000)
#         /lib/ld-linux-aarch64.so.1 (0x0000ffff9ca44000)
# Storage:/lua55/lib/lua/5.5 #
#
# 重点检查:
#   1. ldd lzmq.so 不会出现 libzmq.so
#       libzmq.a 被吞进了 lzmq.so
#   2. aarch64-linux-gnu-objdump -p lzmq.so | grep GLIBCXX
#       在编译环境中检查这个
#      strings /lib64/libstdc++.so.6 | grep GLIBCXX
#       在运行的环境执行这个
#
#       只要编译环境中，lzmq.so 依赖的最高版本都在运行环境能提供的版本中，那么就
#       是稳得，没有问题
#   3. ldd --version
#       在编译的环境和运行的环境都执行这个
#       如果编译环境的GLIBC比运行的环境版本低，就是稳的
#
#   所以建议在老编译环境中编译这些东西

