-- INDENT_LEN: 自定义缩进宽度，默认4个空格
-- WORD_SPACE: 符号之间空格数量，默认1个空格
-- NEW_LINE_CHAR: 新行连接符号换行符
-- T_QUOTA_MARK: 转化表时字符串标点符号，默认单引号
-- E_QUOTA_MARK: 转化各个元素时标点符号，默认空串
-- MAX_LEVEL: 序列化表的层次限制，达到最大层级时会显示{['!'] = '!',}，为nil时表示不限制（不建议）

local INDENT_LEN = 4
local WORD_SPACE = 1
local NEW_LINE_CHAR = '\n'
local T_QUOTA_MARK = '\"'
local E_QUOTA_MARK = ''
local ELEMENT_MSTR = ''
local MAX_LEVEL = 3

local insert = table.insert
local concat = table.concat
local rep = string.rep

local tTransFun = {
    ['nil'] = function() return 'nil' end,
    ['boolean'] = tostring,
    ['number'] = tostring,
    ['string'] = function(v, str)
        return (str .. tostring(v) .. str)
    end,
    ['function'] = function(v, str)
        return (str .. tostring(v) .. str)
    end,
}

local function dtrans(v)
    return tostring(v)
end

local function trans(v, t)
    local str = t == 'T' and T_QUOTA_MARK or E_QUOTA_MARK or ''
    return (tTransFun[type(v)] or dtrans)(v, str)
end

local space = rep(' ', WORD_SPACE)
local transTk = function(k) return trans(k, 'T') end
local function addLine(tLine, level, k, v)
    insert(tLine, rep(' ', level * INDENT_LEN) ..
        (k and '[' .. k .. ']' .. space .. '=' .. space or '') ..
        (v or '') .. NEW_LINE_CHAR)
end

local function parseTab(tLine, level)
    if not level then
        level = 0
        addLine(tLine, level, nil, '{')
    end
    level = level + 1

    if MAX_LEVEL and level == MAX_LEVEL then
        return function()
            addLine(tLine, level, '!', '!,')
            addLine(tLine, level - 1, nil, (level > 1) and '},' or '}')
        end
    end
    local trans = transTk

    return function(t)
        for k, v in pairs(t) do
            if type(v) == 'table' then
                if v == t then -- 当表等于自身就不要递归遍历，如_index = self
                    addLine(tLine, level, trans(k), 'self,')
                else
                    addLine(tLine, level, trans(k), '{')
                    parseTab(tLine, level)(v)
                end
            else
                addLine(tLine, level, trans(k), trans(v) .. ',')
            end
        end
        addLine(tLine, level - 1, nil, (level > 1) and '},' or '}')
    end
end

return function(...)
    local tElement = {}
    for i = 1, select('#', ...) do
        if i ~= 1 then
            insert(tElement, ELEMENT_MSTR)
        end

        local v = select(i, ...)
        if type(v) == 'table' then
            local tLine = {}
            parseTab(tLine)(v)
            insert(tElement, concat(tLine, ''))
        else
            insert(tElement, trans(v))
        end
    end
    return concat(tElement, '')
end
