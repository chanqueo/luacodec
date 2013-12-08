local protocol = {
   fields = {
      {name = "len", type = "u8"},
      {name = "crc", type = "u8"}},
   types = {
      u8 = {bytes = 1}}
}

local C = {}

-- Loads protocol.
function C.load(p)
   C.fields = p.fields
   C.types = p.types
end

-- Codes bytes into lua table.
function C.code(b)
   local t = {}
   C.byte = 1
   for _, field in ipairs(C.fields) do
      t[field.name] = 0
      for byte = C.types[field.type].bytes, 1, -1 do
         t[field.name] = t[field.name] + b[C.byte]
         C.byte = C.byte + 1
      end
   end
   return t
end

-- Decodes lua table into bytes.
function C.decode(t)
end

local b1 = {0, 1}

C.load(protocol)
local t = C.code(b1)
local b2 = C.decode(t)

for k, v in pairs(t) do
   print(k, v)
end

return C
