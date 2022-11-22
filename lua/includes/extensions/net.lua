TYPE_COLOR = 255

local assert = assert
local TypeID = TypeID
local type = type
local net = net

local TYPE_NIL = TYPE_NIL
local TYPE_BOOL = TYPE_BOOL
local TYPE_NUMBER = TYPE_NUMBER
local TYPE_STRING = TYPE_STRING
local TYPE_TABLE = TYPE_TABLE
local TYPE_FUNCTION = TYPE_FUNCTION
local TYPE_ENTITY = TYPE_ENTITY
local TYPE_VECTOR = TYPE_VECTOR
local TYPE_ANGLE = TYPE_ANGLE
local TYPE_MATRIX = TYPE_MATRIX
local TYPE_COLOR = TYPE_COLOR

if (SERVER) then

	local util_NetworkStringToID = util.NetworkStringToID
	local util_AddNetworkString = util.AddNetworkString
	local net_Start = net.Start

	function net.Start( networkString )
		assert( TypeID( networkString ) == TYPE_STRING, 'net.Start: string expected, got ' .. type( networkString ) )

		local id = util_NetworkStringToID( networkString )
		if (id < 1) then
			util_AddNetworkString( networkString )
		end

		net_Start( networkString )
	end

end

local util_NetworkIDToString = util.NetworkIDToString
local string_lower = string.lower
local IsColor = IsColor
local IsValid = IsValid
local Entity = Entity
local Color = Color
local pairs = pairs
local error = error
local NULL = NULL

module( 'net' )

Receivers = {}

--
-- Set up a function to receive network messages
--
function Receive( str, func, identifier )
	assert( TypeID( str ) == TYPE_STRING, 'net.Receive: string expected, got ' .. type( str ) )
	assert( TypeID( func ) == TYPE_FUNCTION, 'net.Receive: function expected, got ' .. type( func ) )

	local networkString = string_lower( str )
	Receivers[ networkString ] = Receivers[ networkString ] or {}
	Receivers[ networkString ][ identifier or 'default' ] = func
end

--
-- A message has been received from the network..
--
function Incoming( length, ply )
	local networkStringID = net.ReadHeader()
	if TypeID( networkStringID ) == TYPE_NUMBER then
		local networkString = util_NetworkIDToString( networkStringID )
		if TypeID( networkString ) == TYPE_STRING then
			local functions = Receivers[ string_lower( networkString ) ]
			if TypeID( functions ) == TYPE_TABLE then
				length = length - 16

				for _, func in pairs( functions ) do
					func( length, ply )
				end
			end
		end
	end
end

--
-- Read/Write a boolean to the stream
--
function ReadBool()
	return net.ReadBit() == 1
end

WriteBool = net.WriteBit

--
-- Read/Write an entity to the stream
--
function ReadEntity()
	local entIndex = net.ReadUInt( 16 )
	if (entIndex > 0) then
		return Entity( entIndex )
	end

	return NULL
end

function WriteEntity( entity )
	assert( TypeID( entity ) == TYPE_ENTITY, 'net.WriteEntity: Entity expected, got ' .. type( entity ) )

	if IsValid( entity ) then
		net.WriteUInt( entity:EntIndex(), 16 )
		return
	end

	net.WriteUInt( 0, 16 )
end

--
-- Read/Write a color to/from the stream
--
function ReadColor( readAlpha )
	if (readAlpha == false) then
		return Color( net.ReadUInt( 8 ), net.ReadUInt( 8 ), net.ReadUInt( 8 ), 255 )
	else
		return Color( net.ReadUInt( 8 ), net.ReadUInt( 8 ), net.ReadUInt( 8 ), net.ReadUInt( 8 ) )
	end
end

function WriteColor( color, writeAlpha )
	assert( IsColor( color ), 'net.WriteColor: color expected, got ' .. type( color ) )
	net.WriteUInt( color.r, 8 )
	net.WriteUInt( color.g, 8 )
	net.WriteUInt( color.b, 8 )

	if (writeAlpha == false) then return end
	net.WriteUInt( color.a, 8 )
end

ReadVars = {
	[TYPE_NIL]      = function() end,
	[TYPE_STRING]   = net.ReadString,
	[TYPE_NUMBER]   = net.ReadDouble,
	[TYPE_BOOL]     = net.ReadBool,
	[TYPE_ENTITY]	= ReadEntity,
	[TYPE_VECTOR]	= net.ReadVector,
	[TYPE_ANGLE]	= net.ReadAngle,
	[TYPE_MATRIX]	= net.ReadMatrix,
	[TYPE_COLOR]	= ReadColor
}

function ReadType( typeID )
	if (typeID == nil) then
		typeID = net.ReadUInt( 8 )
	end

	local func = ReadVars[ typeID ]
	if (func) then
		return func()
	end

	error( 'net.ReadType: Couldn\'t read type ' .. typeID )
end

WriteVars = {
	[TYPE_NIL]			= function() end,
	[TYPE_STRING]		= net.WriteString,
	[TYPE_NUMBER]		= net.WriteDouble,
	[TYPE_BOOL]			= net.WriteBool,
	[TYPE_ENTITY]		= WriteEntity,
	[TYPE_VECTOR]		= net.WriteVector,
	[TYPE_ANGLE]		= net.WriteAngle,
	[TYPE_MATRIX]		= net.WriteMatrix,
	[TYPE_COLOR]		= WriteColor
}

function WriteType( value )
	local typeID = IsColor( value ) and TYPE_COLOR or TypeID( value )
	net.WriteUInt( typeID, 8 )

	local func = net.WriteVars[ typeID ]
	if (func) then
		return func( value )
	end

	error( 'net.WriteType: Couldn\'t write ' .. type( value ) .. ' (type ' .. typeID .. ')' )
end

--
-- Write a whole table to the stream
-- This is less optimal than writing each
-- item indivdually and in a specific order
-- because it adds type information before each var
--

function WriteTable( tbl )
	assert( TypeID( tbl ) == TYPE_TABLE, 'net.WriteTable: table expected, got ' .. type( tbl ) )
	for key, value in pairs( tbl ) do
		net.WriteBool( true )
		WriteType( key )
		WriteType( value )
	end

	net.WriteBool( false )
end

WriteVars[TYPE_TABLE] = WriteTable

function ReadTable()
	local tbl = {}
	while net.ReadBool() do
		tbl[ net.ReadType() ] = net.ReadType()
	end

	return tbl
end

ReadVars[TYPE_TABLE] = ReadTable