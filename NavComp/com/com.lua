--[[
	Communications
	
	Contains all functions for exchanging data between 2 NC plugins
]]

navcomp.com = {}
dofile ("com/ui/ui.lua")
dofile ("com/receivers.lua")

-- Comm Variables
local tag = "NAVCOMP#"
local sendState = 0
local receiveState = 0
local senderName = 0
local receiverName = 0
local delay = 150
--local delay = 500
local timer = Timer ()
local dataSize = 200
local sendData = ""
local sendIndex = 1
local receiveData = ""
local selectionData, tempData

--[[
	Basic Communication
	
	A -> B : Request to communicate (A stores B's charId)
	B -> A : Yes / No Acknowledge (B stores A's charId)
	A -> B : Sends data
	B -> A : Received data successfully
	A, B   : Both clear connection settings
	
	Send / Receive States
	0 = No communication
	10 = Send request, Ok to receive
	20 = Start sending data, Start receiving data
	30 = Continuing to send data / Continuing to receive data
]]

-- Called after sending data/path, or after receipt of data/path, or when request is refused
local function Clear ()
	senderName = 0
	receiverName = 0
	sendState = 0
	receiveState = 0
	sendData = ""
	receiveData = ""
end

function Send (receiver, op, args, data)
	op = op or "NONE"
	args = args or ""
	data = data or ""
	if receiver then
		timer:SetTimeout (delay, function ()
			SendChat (string.format ("%s%s(%s):%s", tag, op, args, data), "PRIVATE", receiver)
		end)
	end
end

-- Sends: NAVCOMP#SEND(<transmission type>):<send data with array payload>
-- Sends: NAVCOMP#DONE(): when completed
local function SendPacket (name, op)
	if name == receiverName then
		if sendState == 20 then
			local strlen = sendData:len ()
			if strlen == 0 then
				-- Nothing to send -> Done
				Send (name, "DONE")
				navcomp.com:Close ()
			elseif strlen <= dataSize then
				Send (name, "SEND", op, sendData)
				sendData = ""
			else
				Send (name, "SEND", op, sendData:sub (1, dataSize))
				sendData = sendData:sub (dataSize+1)
			end
		end
	end
end

-- Sends: NAVCOMP#REQ(<charId>):
function navcomp.com:RequestConnection (data)
	if data.name and sendState == 0 then
		selectionData = data
		sendState = 10
		receiverName = data.name
		selectionData.name = nil
		Send (receiverName, "REQ")
	end
end

-- Processes request.  Pops up dialog or accepts auto requests
-- Calls SendAcknowledge (name)

local function RequestReceived (name, args, data)
	if name and receiveState == 0 then
		receiveState = 10
		local id = GetCharacterIDByName (name)
		
		-- Check if the sender is a buddy or guild member
		-- Otherwise ask for approval to communicate
		if navcomp.data.confirmBuddyCom and (IsGuildMember (id) or GetBuddyInfo (id)) then
			navcomp.com:SendAcknowledge (name, true)
		else
			navcomp.com.ui:CreateComApproveUI (name)
		end
	end
end

-- Sends: NAVCOMP#ACKYES(): or NAVCOMP#ACKNO():
function navcomp.com:SendAcknowledge (name, ok)
	if ok then
		receiveData = ""
		senderName = name
		receiveState = 20
		Send (name, "ACKYES")
	else
		Send (name, "ACKNO")
		Clear ()
	end
end

-- Processes receipt of Acknowledgement.  SendPacket
local function AcknowledgeReceived (name, args, data)
	if name == receiverName and sendState == 10 then
		if selectionData.payload then
			sendState = 20
			sendData = spickle (selectionData)
			SendPacket (name, "DATA")
		end
	end
end

-- Processes receipt of RESP
local function ResponseReceived (name, args, data)
	if name == receiverName then
		if sendState == 20 then
			SendPacket (name, "DATA")
		end
	end
end

-- Receives Data Packet
local function ReceivePacket (name, args, data)
	if name == senderName and receiveState == 20 then
		receiveData = receiveData .. data
		Send (name, "RESP")
	end
end

-- Closes out any successful communication
function navcomp.com:Close (msg)
	Clear ()
	if not msg then
		navcomp.ui:CreateAlertUI ("Communication Complete")
	elseif type (msg) == "string" then
		navcomp.ui:CreateAlertUI (msg)
	else
		navcomp.ui:CreateAlertUI ("Communication Refused")
	end
end

-- Data is complete
local processData = {
	["data"] = navcomp.com.DataReceived,
	["path"] = navcomp.com.PathReceived,
	["anchors"] = navcomp.com.AnchorsReceived
}

local function Complete (name, args, data)
	if name == senderName and receiveState == 20 then
		tempData = unspickle (receiveData) or {type=nil, payload=nil}
		local receive = processData [tempData.type] or function () end
		receive (navcomp.com, senderName, tempData.payload)
		navcomp.com:Close ()
	else
		error (string.format ("Unspecified communications error:\n\tname=%s\n\treceiverState=%d\n\tdata=%d", tostring (name), receiverState, receiveData))
	end
end

local operations = {
	req = RequestReceived,
	ackyes = AcknowledgeReceived,
	ackno = function () navcomp.com.Close (true) end,
	send = ReceivePacket,
	resp = ResponseReceived,
	done = Complete
}

local function CheckMessage (m)
	if string.sub (m.msg, 1, tag:len ()) == tag then
		local cmd = m.msg
		local op, args, data = string.match (cmd, tag .. "(%w+)%((.*)%):(.*)")
		args = args or ""
		data = data or ""
		op = operations [op:lower ()] or function () end
		op (m.name, args, data)
	end
end

-- Event Handling
function navcomp.com:OnEvent (event, data)
	CheckMessage (data)
end