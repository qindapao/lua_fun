#!/usr/bin/env lua

-- 计算边界
local min, max = 0, 0
for k in pairs(arg) do
    if type(k) == "number" then
        if k < min then min = k end
        if k > max then max = k end
    end
end

-- 漂亮打印（Allman Style）
print(string.format("\n%s", string.rep("-", 50)))
print(string.format("%-12s | %-11s | %s", "Category", "Index", "Value"))
print(string.format("%s", string.rep("-", 50)))

for i = min, max do
    local val = arg[i]
    if val ~= nil then
        local category

        -- 逻辑判定：谁是环境，谁是主体，谁是任务
        if i < 0 then
            category = "Runtime"
        elseif i == 0 then
            category = "Self"
        else
            category = "Parameter"
        end

        -- 格式化输出：对齐就是正义
        print(string.format("%-12s | [%5d]     | %s", category, i, val))
    end
end

print(string.format("%s\n", string.rep("-", 50)))

---实现银行家舍入（五成双）
---@param x number # 待舍入值
---@return integer # 返回最近的偶数整数
local function round (x)
    local f = math.floor(x)
    if (x == f) or (x % 2.0 == 0.5) then
        return f
    else
        return math.floor(x + 0.5)
    end
end

print(round(2.5))
print(round(3.5))
print(round(-2.5))
print(round(-1.5))


local pretty = require 'pl.pretty'

local polyline = { color = "blue", width = 2 }
-- 制造一个硬核的循环引用（Self-reference）
polyline.self = polyline
-- 增加一些乱序键测试排序
polyline.alpha = "first"
polyline[10] = "ten"

-- 直接调用，它会智能检测循环引用并用 <cycle> 标记
pretty.dump(polyline)

