#!/usr/bin/env lua

print("--- Lua 5.5 全家桶功能自检 ---")

-- 1. 检查 dkjson
local json = require("dkjson")
local test_obj = { status = "ok", core = 5.5 }
assert(json.decode(json.encode(test_obj)).status == "ok")
print("[✓] dkjson: 正常")

-- 2. 检查 LFS
local lfs = require("lfs")
assert(lfs.currentdir() ~= nil)
print("[✓] LFS: 正常")

-- 3. 检查 LPeg & RE
local re = require("re")
assert(re.match("123", "[0-9]+") == 4)
print("[✓] LPeg & RE: 正常")

local lpeg = require("lpeg")

-- 定义原子规则 (LPeg 算子)
local hex = lpeg.R("09", "af", "AF") ^ 1 -- 十六进制字符
local colon = lpeg.P(":")
local dot = lpeg.P(".")

-- 构造 PCIe 地址匹配模式：domain:bus:dev.func
local pcie_patt = lpeg.C(hex) * colon * lpeg.C(hex) * colon * lpeg.C(hex) * dot * lpeg.C(hex)

-- 执行匹配
local dom, bus, dev, func = pcie_patt:match("0000:01:00.0")

if dom then
    print(
        string.format(
            "[✓] LPeg 解析成功: Domain=%s, Bus=%s, Dev=%s, Func=%s",
            dom,
            bus,
            dev,
            func
        )
    )
else
    print("[X] LPeg 匹配失败")
end

-- 验证补全：输入 lpeg. 看是否弹出 R, P, S, V, C, Ct 等

-- 4. 检查 Penlight
local path = require("pl.path")
assert(path.exists("."))
print("[✓] Penlight: 正常")

-- 6. 检查 lua-utf8 (处理多字节字符)
local utf8 = require("lua-utf8")
local test_str = "你好2024"
-- 原生 string.len 返回字节数 (2*3 + 4 = 10)，utf8.len 返回字符数 (2 + 4 = 6)
assert(utf8.len(test_str) == 6)
-- 测试下基本的偏移和截取
assert(utf8.sub(test_str, 1, 2) == "你好")
print("[✓] lua-utf8: 正常")

function unpack(t, i, n)
    i = i or 1
    n = n or #t
    if i <= n then return t[i], unpack(t, i + 1, n) end
end

-- 检查 zmq 功能
local zmq = require("lzmq")
print("ZMQ 核心版本: " .. table.concat(zmq.version(), "."))

local ctx = zmq.context()
local skt = ctx:socket(zmq.PUB)
skt:bind("tcp://*:5555")

print("恭喜老铁，ZMQ 绑定在 Lua 5.5 上跑通了！")

skt:close()
ctx:destroy()

-- 5. 检查 Luv (异步测试放最后，防止输出乱序)
---下面的这行注释完全是给语言服务器看的，才能弹出补全
---因为文件名其实是uv，并不是luv，这是历史原因造成的
---@type uv
local uv = require("luv")
local stdout = uv.new_pipe(false)
local kernel_name

local handle, _ = uv.spawn("uname", {
    args = { "-s" },
    stdio = { nil, stdout, nil },
}, function(code)
    -- 业务代码中不要这么写，这会导致执行失败后直接崩溃
    assert(code == 0)
    print("[✓] Luv: 子进程调用正常 (内核: " .. (kernel_name or "未知") .. ")")
    print("--- 自检全部通过！---")
end)

uv.read_start(stdout, function(err, data)
    if data then
        kernel_name = data:gsub("\n", "")
    else
        stdout:close()
    end
end)

uv.run() -- 阻塞运行直到子进程结束

-- 5. 检查 Luv + 系统 iconv (安全异步转换测试)
local uv = require("luv")
local test_gbk = "\196\227\186\195" -- "你好" 的 GBK 编码
local converted_data = ""

local stdout = uv.new_pipe(false)
local stdin = uv.new_pipe(false)

local handle = uv.spawn("iconv", {
    args = { "-f", "GBK", "-t", "UTF-8" },
    stdio = { stdin, stdout, nil },
}, function(code)
    uv.close(handle)
    assert(code == 0, "iconv 进程返回异常")

    -- 在进程结束后验证结果
    if converted_data == "你好" then
        print("[✓] Luv + iconv: 安全转换正常 (GBK -> UTF-8)")
    else
        print("[!] Luv + iconv: 转换结果不匹配")
    end
    print("--- 自检全部通过！---")
end)

-- 异步读取 iconv 输出
uv.read_start(stdout, function(err, data)
    if data then converted_data = converted_data .. data end
end)

-- 安全地将数据写入 stdin 并关闭，触发 iconv 处理
uv.write(stdin, test_gbk, function()
    uv.shutdown(stdin, function() uv.close(stdin) end)
end)

uv.run() -- 启动事件循环，等待所有异步任务完成
