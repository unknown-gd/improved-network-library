local EntIndex, IsValid
do
	local _obj_0 = FindMetaTable("Entity")
	EntIndex, IsValid = _obj_0.EntIndex, _obj_0.IsValid
end
local ReadBit, ReadUInt, WriteUInt
do
	local _obj_0 = net
	ReadBit, ReadUInt, WriteUInt = _obj_0.ReadBit, _obj_0.ReadUInt, _obj_0.WriteUInt
end
local istable = istable
local lower = string.lower
local Entity = Entity
local TypeID = TypeID
local NULL = NULL
TYPE_COLOR = 255
require("hook")
if file.Exists("ulib/shared/hook.lua", "LUA") then
	include("ulib/shared/hook.lua")
end
local typesToWrite = net.TypesToWrite
if not istable(typesToWrite) then
	typesToWrite = { }
	net.TypesToWrite = typesToWrite
end
local writeType = nil
do
	local IsColor = IsColor
	local typeID = 0
	writeType = function(value)
		if IsColor(value) then
			typeID = 255
		else
			typeID = TypeID(value)
		end
		WriteUInt(typeID, 8)
		local func = typesToWrite[typeID]
		if func == nil then
			return
		end
		return func(value)
	end
	net.WriteType = writeType
end
local typesToRead = net.TypesToRead
if not istable(typesToRead) then
	typesToRead = { }
	net.TypesToRead = typesToRead
end
local readType = nil
do
	local TYPE_NIL = TYPE_NIL
	readType = function(typeID)
		typeID = typeID or ReadUInt(8)
		if typeID == TYPE_NIL then
			return nil
		end
		local func = typesToRead[typeID]
		if func == nil then
			return
		end
		return func()
	end
	net.ReadType = readType
end
if SERVER then
	local NetworkStringToID, AddNetworkString
	do
		local _obj_0 = util
		NetworkStringToID, AddNetworkString = _obj_0.NetworkStringToID, _obj_0.AddNetworkString
	end
	local header = 0
	local start = net.StartX
	if not isfunction(start) then
		start = net.Start
		net.StartX = start
	end
	net.Start = function(networkString)
		header = NetworkStringToID(networkString)
		if header == 0 then
			AddNetworkString(networkString)
		end
		return start(networkString)
	end
end
local receivers = net.Receivers
if not istable(receivers) then
	receivers = { }
	net.Receivers = receivers
end
do
	local isstring = isstring
	local remove = table.remove
	local length = 0
	net.Receive = function(networkString, func, identifier)
		networkString = lower(networkString)
		if not isstring(identifier) then
			identifier = "unknown"
		end
		local functions = receivers[networkString]
		if not istable(functions) then
			functions = { }
			receivers[networkString] = functions
		end
		length = #functions
		for index = 1, length do
			if functions[index].identifier == identifier then
				remove(functions, index)
				length = length - 1
				break
			end
		end
		functions[length + 1] = {
			identifier = identifier,
			func = func
		}
	end
end
do
	local NetworkIDToString = util.NetworkIDToString
	local ReadHeader = net.ReadHeader
	local Run = hook.Run
	net.Incoming = function(length, client)
		local networkString = NetworkIDToString(ReadHeader())
		if networkString == nil then
			return
		end
		if Run("IncomingNetworkMessage", networkString, length, client or NULL) == false then
			return
		end
		local functions = receivers[lower(networkString)]
		if functions == nil then
			return
		end
		length = length - 16
		for _index_0 = 1, #functions do
			local data = functions[_index_0]
			data.func(length, client)
		end
	end
end
typesToRead[TYPE_STRING] = net.ReadString
typesToRead[TYPE_NUMBER] = net.ReadDouble
typesToRead[TYPE_MATRIX] = net.ReadMatrix
typesToRead[TYPE_VECTOR] = net.ReadVector
typesToRead[TYPE_ANGLE] = net.ReadAngle
typesToWrite[TYPE_STRING] = net.WriteString
typesToWrite[TYPE_NUMBER] = net.WriteDouble
typesToWrite[TYPE_MATRIX] = net.WriteMatrix
typesToWrite[TYPE_VECTOR] = net.WriteVector
typesToWrite[TYPE_ANGLE] = net.WriteAngle
net.WriteBool = net.WriteBit
typesToWrite[TYPE_BOOL] = net.WriteBit
do
	ReadBit = net.ReadBit
	local readBool
	readBool = function()
		return ReadBit() == 1
	end
	net.ReadBool = readBool
	typesToRead[TYPE_BOOL] = readBool
end
do
	local MAX_EDICT_BITS = 14
	local writeEntity
	writeEntity = function(entity)
		if entity and IsValid(entity) then
			WriteUInt(EntIndex(entity), MAX_EDICT_BITS)
			return
		end
		WriteUInt(0, MAX_EDICT_BITS)
		return
	end
	net.WriteEntity = writeEntity
	typesToWrite[TYPE_ENTITY] = writeEntity
	local readEntity
	readEntity = function()
		local index = ReadUInt(MAX_EDICT_BITS)
		if index == nil or index == 0 then
			return NULL
		end
		return Entity(index)
	end
	net.ReadEntity = readEntity
	typesToRead[TYPE_ENTITY] = readEntity
end
net.WritePlayer = function(ply)
	if ply and IsValid(ply) and ply:IsPlayer() then
		WriteUInt(EntIndex(ply), 8)
		return
	end
	WriteUInt(0, 8)
	return
end
net.ReadPlayer = function()
	local index = ReadUInt(8)
	if index == nil or index == 0 then
		return NULL
	end
	return Entity(index)
end
do
	local writeColor
	writeColor = function(color, writeAlpha)
		WriteUInt(color.r or 255, 8)
		WriteUInt(color.g or 255, 8)
		WriteUInt(color.b or 255, 8)
		if writeAlpha == false then
			return
		end
		WriteUInt(color.a or 255, 8)
		return
	end
	typesToWrite[255] = writeColor
	net.WriteColor = writeColor
end
do
	local Color = Color
	local readColor
	readColor = function(readAlpha)
		if readAlpha == false then
			return Color(ReadUInt(8), ReadUInt(8), ReadUInt(8), 255)
		end
		return Color(ReadUInt(8), ReadUInt(8), ReadUInt(8), ReadUInt(8))
	end
	typesToRead[255] = readColor
	net.ReadColor = readColor
end
do
	local pairs = pairs
	local length = 0
	local writeTable
	writeTable = function(tbl, isSequential)
		if isSequential then
			length = #tbl
			WriteUInt(length, 32)
			for index = 1, length do
				writeType(tbl[index])
			end
			return
		end
		for key, value in pairs(tbl) do
			writeType(key)
			writeType(value)
		end
		return WriteUInt(0, 8)
	end
	typesToWrite[TYPE_TABLE] = writeTable
	net.WriteTable = writeTable
end
do
	local readTable
	readTable = function(isSequential)
		local result = { }
		if isSequential then
			for index = 1, ReadUInt(32) do
				result[index] = readType()
			end
			return result
		end
		::read::
		local key = readType()
		if key == nil then
			return result
		end
		result[key] = readType()
		goto read
	end
	typesToRead[TYPE_TABLE] = readTable
	net.ReadTable = readTable
end
