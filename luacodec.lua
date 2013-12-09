-- Coder/decoder bytes into lua table.

--local ascii = _G.ascii or {}

-- Converts string with 2-digit hexadecimal numbers into table.
-- @param  s  String to convert.
-- @return Table representing string.
-- function string.totable(s)
--    if type(s) == "table" then
--       return s
--    elseif type(s) == "string" then
--       local t = {}
--       for i = 1, string.len(s) - 1, 2 do
--          t[#t + 1] = tonumber(string.sub(s, i, i + 1), 16)
--       end
--       return t
--    end
-- end

-- Converts ascii-table to string.
-- @param  t  Table to convert.
-- @return String representing table.
-- function ascii.tostring(t)
--    if type(t) == "string" then
--       return t
--    elseif type(t) == "table" then
--       local s = ""
--       for i = 1, #t do
--          s = s .. string.char(t[i])
--       end
--       return s
--    end
-- end

-- Converts string to ascii-table.
-- @param  s  String to convert.
-- @return Ascii-table representing string.
-- function string.toascii(s)
--    if type(s) == "table" then
--       return s
--    elseif type(s) == "string" then
--       local t = {}
--       for i = 1, string.len(s) do
--          t[#t + 1] = string.byte(s, i)
--       end
--       return t
--    end
-- end

-- Converts value to string.
-- @param  v  Value to convert.
-- @return String representing value.
-- function value.tostring(v)
--    if "string" == type(v) then
--       v = string.gsub(v, "\n", "\\n")
--       if string.match(string.gsub(v, "[^'\"]", ""), '^"+$') then
--          return "'" .. v .. "'"
--       else
--          return '"' .. string.gsub(v, '"', '\\"') .. '"'
--       end
--    else
--       return "table" == type(v) and table.tostring(v) or tostring(v)
--    end
-- end

-- Converts key to string.
-- @param  k  Key to convert.
-- @return String representing key.
-- function key.tostring(k)
--    if "string" == type(k) and string.match(k, "^[_%a][_%a%d]*$") then
--       return k
--    else
--       return "[" .. value.tostring(k) .. "]"
--    end
-- end

-- Converts table to string.
-- @param  t  table to convert.
-- @return String representing table.
-- function table.tostring(t)
--    local result, done = {}, {}
--    for k, v in ipairs(t) do
--       table.insert(result, value.tostring(v))
--       done[k] = true
--    end
--    for k, v in pairs(t) do
--       if not done[k] then
--          table.insert(
--             result, key.tostring(k) .. "=" .. value.tostring(v))
--       end
--    end
--    return "{" .. table.concat(result, ",") .. "}"
-- end

local protocol = {
   {name = "len", type = "u8"},
   {name = "crc", type = "u8"}
}

local C = {}

C.u8 = {
   -- Codes bytes into u8.
   code = function (b)
      local v = b[C.byte]
      C.byte, C.bit = C.byte + 1, 0
      return v
   end,

   -- Decodes bytes from u8.
   decode = function (v, b)
      b[C.byte] = v % 256
      C.byte, C.bit = C.byte + 1, 0
   end
}

-- Loads protocol.
function C.load(p)
   C.protocol = p
end

-- Codes bytes into lua table.
function C.code(b)
   local t = {}
   C.byte, C.bit = 1, 0
   for _, field in ipairs(C.protocol) do
      t[field.name] = C[field.type].code(b)
   end
   return t
end

-- Decodes lua table into bytes.
function C.decode(t)
   local b = {}
   C.byte, C.bit = 1, 0
   for _, field in ipairs(C.protocol) do
      C[field.type].decode(t[field.name], b)
   end
   return b
end

local b1 = {0, 1}

C.load(protocol)
local t = C.code(b1)

print("t")
for k, v in pairs(t) do
   print(k, v)
end

local b2 = C.decode(t)

print("b2")
for k, v in pairs(b2) do
   print(k, v)
end

return C
