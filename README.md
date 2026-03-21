# lua_fun

lua开发和运行时环境搭建


## 解释器和常用库编译

### 解释器编译打包

1. 编译前确认下编译机中的GLIBC的版本，建议使用 ：`GentOS7/RHEL 7` 的 `2.17`，这样编译出来的兼容性才最好。


```bash
ldd --version
```

| 发行版                   | GLIBC 版本 | 备注                   |
|--------------------------|------------|------------------------|
| RHEL 9 / Ubuntu 21+      | 2.34+      | 太新了，不适合做编译机 |
| Ubuntu 20.04 / Debian 11 | 2.31       | 相对较新               |
| CentOS 8 / RHEL 8        | 2.28       | 很多嵌入式环境的标准   |
| Ubuntu 18.04             | 2.27       | 较老                   |
| CentOS 7 / RHEL 7        | 2.17       | 兼容性之王（推荐）     |

如果有: `2.28` 的也是不错的，大部分的情况下都能兼容。

如果有容器，可以在容器中部署编译构建环境：

```bash
docker run -it --name lua_builder -v $(pwd):/work centos:7 /bin/bash
yum install -y gcc make tar gzip
```

没有容器就用一个很老的OS：

| IP            | 端口 | 用户名 | 密码 | 进入交叉编译环境                 |
|---------------|------|--------|------|----------------------------------|
| 10.30.219.116 | 22   | xx     | xx   | cd /xx/yy/zz ; sudo sh chroot.sh |


2. 去[官网](https://www.lua.org/download.html)下载源码包，当前版本：`5.5.0`。
3. 在编译环境的自己的目录下创建一个目录：`lua`。
4. 把 `lua` 的源码拷贝到上面的目录中。
5. 把 `lua` 的解释器安装到一个临时目录中，不要安装到系统的默认路径下。


### 常用库编译打包

#### JSON

##### dkjson

1. 下载 [dkjson](https://dkolf.de/dkjson-lua/) 的源码，我们使用：[v2.8](https://dkolf.de/dkjson-lua/dkjson-2.8.lua) 稳定版本。

##### cjson

暂时不考虑，我们不涉及几十M的超级大JSON的解析。

#### 外部命令发送

##### luv

1. 下载[luv](https://github.com/luvit/luv/releases)编译包。
2. 下载：`luv-1.51.0-2.tar.gz`，我们当前使用版本：`1.51.0-2`，千万不要直接下载源码包。

#### LFS文件系统操作

##### lfs

1. [lfs](https://github.com/lunarmodules/luafilesystem/tags) 源码获取。
2. 我们使用：`v1_9_0`版本。

#### 正则和模式匹配

##### Lpeg

这个库是 `lua` 语言的首席架构师开发的，质量极高。

1. [Lpeg](https://www.inf.puc-rio.br/~roberto/lpeg/)官方下载链接。
2. 我们使用：`lpeg-1.1.0.tar.gz` 版本。

#### 标准库增强

##### Penlight

1. [Penlight](https://github.com/lunarmodules/Penlight/tags) 官方下载链接。
2. 我们使用：`1.15.0`版本。

#### utf8增强

##### lua-utf8

1. [lua-utf8](https://github.com/starwing/luautf8/releases) 下载链接。
2. 我们使用：`0.2.0` 版本。

#### 多主机消息同步与分发

##### zeromq

下载：[zeromq-4.3.5.tar.gz](https://github.com/zeromq/libzmq/releases/tag/v4.3.5)。

##### lzmq

下载：[lzmq-0.4.4.tar.gz](https://github.com/zeromq/lzmq/releases/tag/v0.4.4)

### 全自动打包

上面的所有库下载后放到目录中的文件列表是：

- dkjson.lua
- lpeg-1.1.0.tar.gz
- lua-5.5.0.tar.gz
- luafilesystem-1_9_0.zip
- luv-1.51.0-2.tar.gz
- Penlight-1.15.0.zip
- luautf8-0.2.0.zip
- zeromq-4.3.5.tar.gz
- lzmq-0.4.4.tar.gz

或者直接下载附件中的编译包，解压后把脚本：`lua55_toolkit_build.sh` 放到解压后的目录中。

注意还是应该使用 `GLIBC` 版本比较低的编译机来进行编译。

```bash
bash lua55_toolkit_build.sh
```

## 执行环境安装和启动脚本

- lua55_toolkit.tar.gz
- lua55_toolkit_check.lua
- lua55_toolkit_check.sh
- lua55_toolkit_install.sh

上面的文件放到环境中，先执行：`lua55_toolkit_install.sh`，然后再执行：`lua55_toolkit_check.sh`。

如果所有的用例都执行成功，那么证明问题不大。

如果想测试 `LPeg` 模块的完整功能，那么可以手动运行：`${lua安装目录}/share/lua/5.5/test_lpeg.lua` 脚本。

业务脚本运行前的环境设置可以参考：`lua55_toolkit_check.sh`脚本中设置三个环境变量的方法。

## 代码自动格式化

### stylue 二进制安装

1. 安装代码[格式化器](https://github.com/JohnnyMorganz/StyLua)。
2. 安装位置建议和开发环境中的语言服务器的二进制的目录放置到一起。

```txt
D:\lua_language_server\bin
并且记得把上面的路径加入到系统的环境变量中。
```

### vim 配置

```vim
" 设置格式化器
let g:ale_fixers = {
\   'lua': ['stylua'],
\}

" " 开启保存时自动格式化 (非常推荐)
" let g:ale_fix_on_save = 1

" 如果你想手动触发格式化，可以映射一个快捷键
nnoremap <F9> :ALEFix<CR>
```

### 格式化风格配置

如果使用的是 `vim` 并且使用了 `ale` 语言检查插件，那么可以直接在配置中配置：

```vim
" --- StyLua  ---
let g:ale_lua_stylua_options = '--indent-type Spaces'
    \ . ' --indent-width 4'
    \ . ' --column-width 100'
    \ . ' --call-parentheses Always'
    \ . ' --quote-style AutoPreferDouble'
    \ . ' --preserve-block-newline-gaps Preserve'
    \ . ' --line-endings Unix'
    \ . ' --collapse-simple-statement Always'
    \ . ' --no-editorconfig'

" 这里的注释只是对上面的说明，VIM的跨行语句中不能写注释！
" let g:ale_lua_stylua_options = '--indent-type Spaces'
"     \ . ' --indent-width 4'
"     \ . ' --column-width 100'                     " 行宽
"     \ . ' --call-parentheses Always'              " 强制括号：这是对齐的基石
"     \ . ' --quote-style AutoPreferDouble'         " 双引号优先
"     \ . ' --preserve-block-newline-gaps Preserve' " 如果你手动在块前后留了空行，不许删
"     \ . ' --line-endings Unix'                    " 强制 Unix 换行符
"     \ . ' --collapse-simple-statement Always'     " 允许把 if ... then return end 挤在一行
"     \ . ' --no-editorconfig'                      " 屏蔽掉所有隐藏的配置文件干扰
```

如果是要限制具体的项目的格式，可以在项目的根目录下配置相关的配置文件，具体参考工具的说明。

不过建议还是通过配置编辑器来实现，避免污染项目文件。



## Teal 2.0 类型编译器

我们的代码比较简单，暂时不需要。通过编写合适的注释，也能获得很好的类型提示。

