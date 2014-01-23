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

local value = _G.value or {}

-- Converts value to string.
-- @param  v  Value to convert.
-- @return String representing value.
function value.tostring(v)
   if "string" == type(v) then
      v = string.gsub(v, "\n", "\\n")
      if string.match(string.gsub(v, "[^'\"]", ""), '^"+$') then
         return "'" .. v .. "'"
      else
         return '"' .. string.gsub(v, '"', '\\"') .. '"'
      end
   else
      return "table" == type(v) and table.tostring(v) or tostring(v)
   end
end

local key = _G.key or {}

-- Converts key to string.
-- @param  k  Key to convert.
-- @return String representing key.
function key.tostring(k)
   if "string" == type(k) and string.match(k, "^[_%a][_%a%d]*$") then
      return k
   else
      return "[" .. value.tostring(k) .. "]"
   end
end

local table = _G.table or {}

-- Converts table to string.
-- @param  t  table to convert.
-- @return String representing table.
function table.tostring(t)
   local result, done = {}, {}
   for k, v in ipairs(t) do
      table.insert(result, value.tostring(v))
      done[k] = true
   end
   for k, v in pairs(t) do
      if not done[k] then
         table.insert(
            result, key.tostring(k) .. "=" .. value.tostring(v))
      end
   end
   return "{" .. table.concat(result, ",") .. "}"
end

local C = {}

-- Bits format.
C.bits = {
   -- Codes bytes.
   code = function (b)
      local v = 0
      for c = 0, C.number.size - 1 do
         v = v + b[C.byte] * 256 ^ c
         C.byte, C.bit = C.byte + 1, 0
      end
      return v
   end,

   -- Decodes bytes.
   decode = function (v, b)
      for c = 1, C.number.size do
         b[C.byte] = v % 256
         v = v / 256
         C.byte, C.bit = C.byte + 1, 0
      end
   end
}

-- Number format.
-- @todo Manage endianness.
C.number = {
   -- Codes bytes.
   code = function (b)
      local v = 0
      if C.bit > 0 then C.byte, C.bit = C.byte + 1, 0 end
      for c = 0, C.number.size - 1 do
         v = v + b[C.byte] * 256 ^ c
         C.byte, C.bit = C.byte + 1, 0
      end
      return v
   end,

   -- Decodes bytes.
   decode = function (v, b)
      for c = 1, C.number.size do
         b[C.byte] = v % 256
         v = v / 256
         C.byte, C.bit = C.byte + 1, 0
      end
   end
}

-- Enumeration format (value is a string).
C.enum = {
   -- Codes bytes.
   code = function (b)
      local t = getmetatable(C.enum)
      setmetatable(C.number, t)
      b = C.number.code(b)
      for _, e in ipairs(t) do
         if e.value == b then
            return e.name
         end
      end
   end,

   -- Decodes bytes.
   decode = function (v, b)
      local t = getmetatable(C.enum)
      for _, e in ipairs(t) do
         if e.name == v then
            setmetatable(C.number, t)
            return C.number.decode(e.value, b)
         end
      end
   end
}

-- Union format.
C.union = {
   -- Codes bytes.
   code = function (b)
   end,

   -- Decodes bytes.
   decode = function (v, b)
   end
 }

-- Loads protocol.
function C.load(p)
   C.protocol = p
end

-- Codes bytes.
function C.code(b)
   local t = {}
   C.byte, C.bit = 1, 0
   for _, f in ipairs(C.protocol) do
      local v = C[f.type] or C.protocol[f.type]
      v.__index = v
      setmetatable(C[v.type], v)
      t[f.name] = C[v.type].code(b)
   end
   return t
end

-- Decodes bytes.
function C.decode(t)
   local b = {}
   C.byte, C.bit = 1, 0
   for _, f in ipairs(C.protocol) do
      local v = C[f.type] or C.protocol[f.type]
      v.__index = v
      setmetatable(C[v.type], v)
      C[v.type].decode(t[f.name], b)
   end
   return b
end

local protocol = {

   {name = "len", type = "u8"},
   {name = "type", type = "types"},
   {name = "data", type = "u16"},
   {name = "crc", type = "u8"},

   types = {
      type = "enum", size = 1,
      {name = "temp", value = 0},
      {name = "mode", value = 1}
   },

   u8 = {
      type = "number", size = 1
   },

   u16 = {
      type = "number", size = 2
   }
}

C.load(protocol)

local b1 = {5, 1, 0, 2, 1}
local t = C.code(b1)
local b2 = C.decode(t)

print("b1 = " .. table.tostring(b1))
print("t = " .. table.tostring(t))
print("b2 = " .. table.tostring(b2))

return C
