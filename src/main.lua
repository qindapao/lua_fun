#!/usr/bin/env lua

-- 文件系统
local lfs = require("lfs")


-- 序列化（调试神器）
local serpent = require("serpent")

-- 参数解析
local argparse = require("argparse")

-- ZIP 读写
local zip = require("brimworks.zip")


-- ZLIB 压缩
local zlib = require("zlib")

-- Penlight（标准库增强）
local path = require("pl.path")
local utils = require("pl.utils")


-- 创建命令行解析器
local parser = argparse("demo", "UCRT64 Lua 开发环境测试")
parser:option("--name", "你的名字", "world")
local args = parser:parse()

print("Hello, " .. args.name .. "!")

-- 测试文件系统
print("当前目录:")
for file in lfs.dir(".") do
    print(" - " .. file)
end

-- 测试 penlight
print("当前脚本路径:", path.currentdir())

-- 测试 zlib
local compressed = zlib.deflate()("Hello Lua!", "finish")
local uncompressed = zlib.inflate()(compressed)
print("ZLIB 解压结果:", uncompressed)

-- 测试 ZIP（读取）
local z = zip.open("test.zip")
if z then
    print("ZIP 文件内容:")
    for f in z:files() do
        print(" - " .. f.filename)
    end
else
    print("没有找到 test.zip")
end

-- 测试 serpent（序列化）
local tbl = {a = 1, b = {c = 2, d = 3}}
print("Serpent 输出:")
print(serpent.block(tbl))

-- 测试 pl.utils：执行外部命令并捕获输出
local ok, out, err = utils.executeex("echo Hello_from_utils")

print("pl.utils.executeex 输出:")
print("  ok:", ok)
print("  stdout:", out)
print("  stderr:", err)

