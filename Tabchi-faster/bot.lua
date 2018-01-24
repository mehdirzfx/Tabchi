redis = (loadfile "redis.lua")()
redis = redis.connect('127.0.0.1', 6379)

function dl_cb(arg, data)
end
function get_admin ()
	if redis:get('bot1adminset') then
		return true
	else
   		print("\n\27[32m  لازمه کارکرد صحیح ، فرامین و امورات مدیریتی ربات تبلیغ گر <<\n                    تعریف کاربری به عنوان مدیر است\n\27[34m                   ایدی خود را به عنوان مدیر وارد کنید\n\27[32m    شما می توانید از ربات زیر شناسه عددی خود را بدست اورید\n\27[34m        ربات:       @id_ProBot")
    		print("\n\27[32m >> Tabchi Bot need a fullaccess user (ADMIN)\n\27[34m Imput Your ID as the ADMIN\n\27[32m You can get your ID of this bot\n\27[34m                 @id_ProBot")
    		print("\n\27[36m                      : شناسه عددی ادمین را وارد کنید << \n >> Imput the Admin ID :\n\27[31m                 ")
    		admin=io.read()
		redis:del("bot1admin")
    		redis:sadd("bot1admin", admin)
		redis:set('bot1adminset',true)
  	end
  	return print("\n\27[36m     ADMIN ID |\27[32m ".. admin .." \27[36m| شناسه ادمین")
end
function get_bot (i, sami)
	function bot_info (i, sami)
		redis:set("bot1id",sami.id_)
		if sami.first_name_ then
			redis:set("bot1fname",sami.first_name_)
		end
		if sami.last_name_ then
			redis:set("bot1lanme",sami.last_name_)
		end
		redis:set("bot1num",sami.phone_number_)
		return sami.id_
	end
	tdcli_function ({ID = "GetMe",}, bot_info, nil)
end
function reload(chat_id,msg_id)
	loadfile("./bot-1.lua")()
	send(chat_id, msg_id, "<i>با موفقیت انجام شد.</i>")
end
function is_naji(msg)
    local var = false
	local hash = 'bot1admin'
	local user = msg.sender_user_id_
    local Naji = redis:sismember(hash, user)
	if Naji then
		var = true
	end
	return var
end
function writefile(filename, input)
	local file = io.open(filename, "w")
	file:write(input)
	file:flush()
	file:close()
	return true
end
function process_join(i, sami)
	if sami.code_ == 429 then
		local message = tostring(sami.message_)
		local Time = message:match('%d+')
		redis:setex("bot1maxjoin", tonumber(Time), true)
	else
		redis:srem("bot1goodlinks", i.link)
		redis:sadd("bot1savedlinks", i.link)
	end
end
function process_link(i, sami)
	if (sami.is_group_ or sami.is_supergroup_channel_) then
		redis:srem("bot1waitelinks", i.link)
		redis:sadd("bot1goodlinks", i.link)
	elseif sami.code_ == 429 then
		local message = tostring(sami.message_)
		local Time = message:match('%d+')
		redis:setex("bot1maxlink", tonumber(Time), true)
	else
		redis:srem("bot1waitelinks", i.link)
	end
end
function find_link(text)
	if text:match("https://telegram.me/joinchat/%S+") or text:match("https://t.me/joinchat/%S+") or text:match("https://telegram.dog/joinchat/%S+") then
		local text = text:gsub("t.me", "telegram.me")
		local text = text:gsub("telegram.dog", "telegram.me")
		for link in text:gmatch("(https://telegram.me/joinchat/%S+)") do
			if not redis:sismember("bot1alllinks", link) then
				redis:sadd("bot1waitelinks", link)
				redis:sadd("bot1alllinks", link)
			end
		end
	end
end
function add(id)
	local Id = tostring(id)
	if not redis:sismember("bot1all", id) then
		if Id:match("^(%d+)$") then
			redis:sadd("bot1users", id)
			redis:sadd("bot1all", id)
		elseif Id:match("^-100") then
			redis:sadd("bot1supergroups", id)
			redis:sadd("bot1all", id)
		else
			redis:sadd("bot1groups", id)
			redis:sadd("bot1all", id)
		end
	end
	return true
end
function rem(id)
	local Id = tostring(id)
	if redis:sismember("bot1all", id) then
		if Id:match("^(%d+)$") then
			redis:srem("bot1users", id)
			redis:srem("bot1all", id)
		elseif Id:match("^-100") then
			redis:srem("bot1supergroups", id)
			redis:srem("bot1all", id)
		else
			redis:srem("bot1groups", id)
			redis:srem("bot1all", id)
		end
	end
	return true
end
function send(chat_id, msg_id, text)
	tdcli_function ({
		ID = "SendMessage",
		chat_id_ = chat_id,
		reply_to_message_id_ = msg_id,
		disable_notification_ = 1,
		from_background_ = 1,
		reply_markup_ = nil,
		input_message_content_ = {
			ID = "InputMessageText",
			text_ = text,
			disable_web_page_preview_ = 1,
			clear_draft_ = 0,
			entities_ = {},
			parse_mode_ = {ID = "TextParseModeHTML"},
		},
	}, dl_cb, nil)
end
get_admin()
function tdcli_update_callback(data)
	if data.ID == "UpdateNewMessage" then
		if not redis:get("bot1maxlink") then
			if redis:scard("bot1waitelinks") ~= 0 then
				local links = redis:smembers("bot1waitelinks")
				for x,y in pairs(links) do
					if x == 11 then redis:setex("bot1maxlink", 60, true) return end
					tdcli_function({ID = "CheckChatInviteLink",invite_link_ = y},process_link, {link=y})
				end
			end
		end
		if not redis:get("bot1maxjoin") then
			if redis:scard("bot1goodlinks") ~= 0 then 
				local links = redis:smembers("bot1goodlinks")
				for x,y in pairs(links) do
					tdcli_function({ID = "ImportChatInviteLink",invite_link_ = y},process_join, {link=y})
					if x == 5 then redis:setex("bot1maxjoin", 60, true) return end
				end
			end
		end
		local msg = data.message_
		local bot_id = redis:get("bot1id") or get_bot()
		if (msg.sender_user_id_ == 777000 or msg.sender_user_id_ == 123654789) then
			for k,v in pairs(redis:smembers('bot1admin')) do
				tdcli_function({
					ID = "ForwardMessages",
					chat_id_ = v,
					from_chat_id_ = msg.chat_id_,
					message_ids_ = {[0] = msg.id_},
					disable_notification_ = 0,
					from_background_ = 1
				}, dl_cb, nil)
			end
		end
		if tostring(msg.chat_id_):match("^(%d+)") then
			if not redis:sismember("bot1all", msg.chat_id_) then
				redis:sadd("bot1users", msg.chat_id_)
				redis:sadd("bot1all", msg.chat_id_)
			end
		end
		add(msg.chat_id_)
		if msg.date_ < os.time() - 150 then
			return false
		end
		if msg.content_.ID == "MessageText" then
			local text = msg.content_.text_
			local matches
			find_link(text)
			if is_naji(msg) then
				if text:match("^(Add admin) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('bot1admin', matches) then
						return send(msg.chat_id_, msg.id_, "<i>The user is admin now.</i>")
					elseif redis:sismember('bot1mod', msg.sender_user_id_) then
						return send(msg.chat_id_, msg.id_, "You do not have access.")
					else
						redis:sadd('bot1admin', matches)
						redis:sadd('bot1mod', matches)
						return send(msg.chat_id_, msg.id_, "<i>The user promoted to admin</i>")
					end
				elseif text:match("^(Add sudo) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('bot1mod',msg.sender_user_id_) then
						return send(msg.chat_id_, msg.id_, "You do not have access.")
					end
					if redis:sismember('bot1mod', matches) then
						redis:srem("bot1mod",matches)
						redis:sadd('bot1admin'..tostring(matches),msg.sender_user_id_)
						return send(msg.chat_id_, msg.id_, "The user promoted to sudo.")
					elseif redis:sismember('bot1admin',matches) then
						return send(msg.chat_id_, msg.id_, 'The user is currently admin.')
					else
						redis:sadd('bot1admin', matches)
						redis:sadd('bot1admin'..tostring(matches),msg.sender_user_id_)
						return send(msg.chat_id_, msg.id_, "The user set as sudo.")
					end
				elseif text:match("^(Delete admin) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('bot1mod', msg.sender_user_id_) then
						if tonumber(matches) == msg.sender_user_id_ then
								redis:srem('bot1admin', msg.sender_user_id_)
								redis:srem('bot1mod', msg.sender_user_id_)
							return send(msg.chat_id_, msg.id_, "You are not admin anymore.")
						end
						return send(msg.chat_id_, msg.id_, "You do not have access.")
					end
					if redis:sismember('bot1admin', matches) then
						if  redis:sismember('bot1admin'..msg.sender_user_id_ ,matches) then
							return send(msg.chat_id_, msg.id_, "You can not demote the admin that promote you.")
						end
						redis:srem('bot1admin', matches)
						redis:srem('bot1mod', matches)
						return send(msg.chat_id_, msg.id_, "The user is demoted from being admin.")
					end
					return send(msg.chat_id_, msg.id_, "The target user can not be admin.")
				elseif text:match("^(Refresh robot)$") then
					get_bot()
					return send(msg.chat_id_, msg.id_, "<i>Robot personal profile has been updated.</i>")
				elseif text:match("report") then
					tdcli_function ({
						ID = "SendBotStartMessage",
						bot_user_id_ = 123654789,
						chat_id_ = 123654789,
						parameter_ = 'start'
					}, dl_cb, nil)
				elseif text:match("^(/reload)$") then
					return reload(msg.chat_id_,msg.id_)
				elseif text:match("^Robot update$") then
					io.popen("git fetch --all && git reset --hard origin/persian && git pull origin persian && chmod +x bot"):read("*all")
					local text,ok = io.open("bot.lua",'r'):read('*a'):gsub("BOT%-ID",1)
					io.open("bot-1.lua",'w'):write(text):close()
					return reload(msg.chat_id_,msg.id_)
				elseif text:match("^Sync with tabchi$") then
					local botid = 1 - 1
					redis:sunionstore("bot1all","tabchi:"..tostring(botid)..":all")
					redis:sunionstore("bot1users","tabchi:"..tostring(botid)..":pvis")
					redis:sunionstore("bot1groups","tabchi:"..tostring(botid)..":groups")
					redis:sunionstore("bot1supergroups","tabchi:"..tostring(botid)..":channels")
					redis:sunionstore("bot1savedlinks","tabchi:"..tostring(botid)..":savedlinks")
					return send(msg.chat_id_, msg.id_, "<b>Sync information with tabchi Number</b><code> "..tostring(botid).." </code><b>انجام شد.</b>")
				elseif text:match("^(list) (.*)$") then
					local matches = text:match("^list (.*)$")
					local sami
					if matches == "Contacts" then
						return tdcli_function({
							ID = "SearchContacts",
							query_ = nil,
							limit_ = 999999999
						},
						function (I, Naji)
							local count = Naji.total_count_
							local text = "Contacts : \n"
							for i =0 , tonumber(count) - 1 do
								local user = Naji.users_[i]
								local firstname = user.first_name_ or ""
								local lastname = user.last_name_ or ""
								local fullname = firstname .. " " .. lastname
								text = tostring(text) .. tostring(i) .. ". " .. tostring(fullname) .. " [" .. tostring(user.id_) .. "] = " .. tostring(user.phone_number_) .. "  \n"
							end
							writefile("bot1_contacts.txt", text)
							tdcli_function ({
								ID = "SendMessage",
								chat_id_ = I.chat_id,
								reply_to_message_id_ = 0,
								disable_notification_ = 0,
								from_background_ = 1,
								reply_markup_ = nil,
								input_message_content_ = {ID = "InputMessageDocument",
								document_ = {ID = "InputFileLocal",
								path_ = "bot1_contacts.txt"},
								caption_ = "Advertiser contacts number 1"}
							}, dl_cb, nil)
							return io.popen("rm -rf bot1_contacts.txt"):read("*all")
						end, {chat_id = msg.chat_id_})
					elseif matches == "Automatic answers" then
						local text = "<i>Automatic answers list :</i>\n\n"
						local answers = redis:smembers("bot1answerslist")
						for k,v in pairs(answers) do
							text = tostring(text) .. "<i>l" .. tostring(k) .. "l</i>  " .. tostring(v) .. " : " .. tostring(redis:hget("bot1answers", v)) .. "\n"
						end
						if redis:scard('bot1answerslist') == 0  then text = "<code>       EMPTY</code>" end
						return send(msg.chat_id_, msg.id_, text)
					elseif matches == "Block" then
						sami = "bot1blockedusers"
					elseif matches == "Chat" then
						sami = "bot1users"
					elseif matches == "Group" then
						sami = "bot1groups"
					elseif matches == "Supergroup" then
						sami = "bot1supergroups"
					elseif matches == "Link" then
						sami = "bot1savedlinks"
					elseif matches == "Admin" then
						sami = "bot1admin"
					else
						return true
					end
					local list =  redis:smembers(sami)
					local text = tostring(matches).." : \n"
					for i, v in pairs(list) do
						text = tostring(text) .. tostring(i) .. "-  " .. tostring(v).."\n"
					end
					writefile(tostring(sami)..".txt", text)
					tdcli_function ({
						ID = "SendMessage",
						chat_id_ = msg.chat_id_,
						reply_to_message_id_ = 0,
						disable_notification_ = 0,
						from_background_ = 1,
						reply_markup_ = nil,
						input_message_content_ = {ID = "InputMessageDocument",
							document_ = {ID = "InputFileLocal",
							path_ = tostring(sami)..".txt"},
						caption_ = "lists"..tostring(matches).."tabchi number 1"}
					}, dl_cb, nil)
					return io.popen("rm -rf "..tostring(sami)..".txt"):read("*all")
				elseif text:match("^(View state) (.*)$") then
					local matches = text:match("^View state (.*)$")
					if matches == "on" then
						redis:set("bot1markread", true)
						return send(msg.chat_id_, msg.id_, "<i>Seen<<Message state\n</i><code>(Active second check)</code>")
					elseif matches == "off" then
						redis:del("bot1markread")
						return send(msg.chat_id_, msg.id_, "<i>Unseen<<Message state\n</i><code>(Without the tick the second)</code>")
					end 
				elseif text:match("^(Add with message) (.*)$") then
					local matches = text:match("^Add with message (.*)$")
					if matches == "on" then
						redis:set("bot1addmsg", true)
						return send(msg.chat_id_, msg.id_, "<i>Message add a contact was activated</i>")
					elseif matches == "off" then
						redis:del("bot1addmsg")
						return send(msg.chat_id_, msg.id_, "<i>Message add a contact was disabled</i>")
					end
				elseif text:match("^(Add the number) (.*)$") then
					local matches = text:match("Add the number (.*)$")
					if matches == "on" then
						redis:set("bot1addcontact", true)
						return send(msg.chat_id_, msg.id_, "<i>Send number when adding a contact was activated</i>")
					elseif matches == "off" then
						redis:del("bot1addcontact")
						return send(msg.chat_id_, msg.id_, "<i>Send a number when you add a contact turn, was</i>")
					end
				elseif text:match("^(Set the message to add a contact) (.*)") then
					local matches = text:match("^Set the message to add a contact (.*)")
					redis:set("bot1addmsgtext", matches)
					return send(msg.chat_id_, msg.id_, "<i>Message add a contact was recorded </i>:\n- "..matches.."-")
				elseif text:match('^(Set answer) "(.*)" (.*)') then
					local txt, answer = text:match('^Set answer "(.*)" (.*)')
					redis:hset("bot1answers", txt, answer)
					redis:sadd("bot1answerslist", txt)
					return send(msg.chat_id_, msg.id_, "<i>The answer for | </i>" .. tostring(txt) .. "<i> | Set to :</i>\n" .. tostring(answer))
				elseif text:match("^(Delete answer) (.*)") then
					local matches = text:match("^Delete answer (.*)")
					redis:hdel("bot1answers", matches)
					redis:srem("bot1answerslist", matches)
					return send(msg.chat_id_, msg.id_, "<i>The answer for | </i>" .. tostring(matches) .. "<i> | Deleted from ausomatic answer list.</i>")
				elseif text:match("^(Autoresponder) (.*)$") then
					local matches = text:match("^Autoresponder (.*)$")
					if matches == "on" then
						redis:set("bot1autoanswer", true)
						return send(msg.chat_id_, 0, "<i>Autoresponder of tabchi has been actived</i>")
					elseif matches == "off" then
						redis:del("bot1autoanswer")
						return send(msg.chat_id_, 0, "<i>The auto responder mode of tabchi has been deactivated.</i>")
					end
				elseif text:match("^(Refresh)$")then
					local list = {redis:smembers("bot1supergroups"),redis:smembers("bot1groups")}
					tdcli_function({
						ID = "SearchContacts",
						query_ = nil,
						limit_ = 999999999
					}, function (i, sami)
						redis:set("bot1contacts", sami.total_count_)
					end, nil)
					for i, v in pairs(list) do
							for a, b in pairs(v) do 
								tdcli_function ({
									ID = "GetChatMember",
									chat_id_ = b,
									user_id_ = bot_id
								}, function (i,sami)
									if  sami.ID == "Error" then rem(i.id) 
									end
								end, {id=b})
							end
					end
					return send(msg.chat_id_,msg.id_,"<i>Refresh statics of tabchi number </i><code> 1 </code> Successfully done.")
				elseif text:match("^(situation)$") then
					local s = redis:get("bot1maxjoin") and redis:ttl("bot1maxjoin") or 0
					local ss = redis:get("bot1maxlink") and redis:ttl("bot1maxlink") or 0
					local msgadd = redis:get("bot1addmsg") and "✔️" or "✖️"
					local numadd = redis:get("bot1addcontact") and "✔️" or "✖️"
					local txtadd = redis:get("bot1addmsgtext") or  "addi pv . bzr"
					local autoanswer = redis:get("bot1autoanswer") and "✔️" or "✖️"
					local wlinks = redis:scard("bot1waitelinks")
					local glinks = redis:scard("bot1goodlinks")
					local links = redis:scard("bot1savedlinks")
					local txt = "<i>State of working tabchi</i><code> 1 </code> \n\n" .. tostring(autoanswer) .."<code> Autorespond mode</code>\n" .. tostring(numadd) .. "<code> Add contact with number </code>\n" .. tostring(msgadd) .. "<code> Add contact with message</code>\n〰〰〰ا〰〰〰\n<code>Add contact message:</code>\n- " .. tostring(txtadd) .. " -\n〰〰〰ا〰〰〰\n<code>Saved links : </code><b>" .. tostring(links) .. "</b>\n<code>Links waiting for joining: </code><b>" .. tostring(glinks) .. "</b>\n<b>" .. tostring(s) .. " </b><code>Second to rejoin</code>\n<code>Links waiting for confirmation: </code><b>" .. tostring(wlinks) .. "</b>\n <b>" .. tostring(ss) .. " </b><code>Second to confirm again link</code>\n----------\nCHNL : @UnknowCyberArmy "
					return send(msg.chat_id_, 0, txt)
				elseif text:match("^(Statistics)$") or text:match("^(Statistics)$") then
					local gps = redis:scard("bot1groups")
					local sgps = redis:scard("bot1supergroups")
					local usrs = redis:scard("bot1users")
					local links = redis:scard("bot1savedlinks")
					local glinks = redis:scard("bot1goodlinks")
					local wlinks = redis:scard("bot1waitelinks")
					tdcli_function({
						ID = "SearchContacts",
						query_ = nil,
						limit_ = 999999999
					}, function (i, sami)
					redis:set("bot1contacts", sami.total_count_)
					end, nil)
					local contacts = redis:get("bot1contacts")
					local text = [[
<i>State and statistics of tabchi</i>
      
<code> Private chats : </code>
<b>]] .. tostring(usrs) .. [[</b>
<code> Groups: </code>
<b>]] .. tostring(gps) .. [[</b>
<code> Super groups : </code>
<b>]] .. tostring(sgps) .. [[</b>
<code> Saved contacts : </code>
<b>]] .. tostring(contacts)..[[</b>
<code> Saved links : </code>
<b>]] .. tostring(links)..[[</b>
<i>by : MEHRAN_CYBER | @etehad_arazel</i>
]]
					return send(msg.chat_id_, 0, text)
				elseif (text:match("^(Send to) (.*)$") and msg.reply_to_message_id_ ~= 0) then
					local matches = text:match("^Send to (.*)$")
					local sami
					if matches:match("^(All)$") then
						sami = "bot1all"
					elseif matches:match("^(Chat)") then
						sami = "bot1users"
					elseif matches:match("^(gruop)$") then
						sami = "bot1groups"
					elseif matches:match("^(Supergroups)$") then
						sami = "bot1supergroups"
					else
						return true
					end
					local list = redis:smembers(sami)
					local id = msg.reply_to_message_id_
					for i, v in pairs(list) do
						tdcli_function({
							ID = "ForwardMessages",
							chat_id_ = v,
							from_chat_id_ = msg.chat_id_,
							message_ids_ = {[0] = id},
							disable_notification_ = 1,
							from_background_ = 1
						}, dl_cb, nil)
					end
					return send(msg.chat_id_, msg.id_, "<i>Sent successfully</i>")
				elseif text:match("^(Send to supergroup) (.*)") then
					local matches = text:match("^Send to supergroup (.*)")
					local dir = redis:smembers("bot1supergroups")
					for i, v in pairs(dir) do
						tdcli_function ({
							ID = "SendMessage",
							chat_id_ = v,
							reply_to_message_id_ = 0,
							disable_notification_ = 0,
							from_background_ = 1,
							reply_markup_ = nil,
							input_message_content_ = {
								ID = "InputMessageText",
								text_ = matches,
								disable_web_page_preview_ = 1,
								clear_draft_ = 0,
								entities_ = {},
							parse_mode_ = nil
							},
						}, dl_cb, nil)
					end
                    			return send(msg.chat_id_, msg.id_, "<i>Sent successfully</i>")
				elseif text:match("^(Block) (%d+)$") then
					local matches = text:match("%d+")
					rem(tonumber(matches))
					redis:sadd("bot1blockedusers",matches)
					tdcli_function ({
						ID = "BlockUser",
						user_id_ = tonumber(matches)
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<i>The user has been blocked</i>")
				elseif text:match("^(Unblock) (%d+)$") then
					local matches = text:match("%d+")
					add(tonumber(matches))
					redis:srem("bot1blockedusers",matches)
					tdcli_function ({
						ID = "UnblockUser",
						user_id_ = tonumber(matches)
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<i>The user has been unblocked.</i>")	
				elseif text:match('^(Setname) "(.*)" (.*)') then
					local fname, lname = text:match('^Setname "(.*)" (.*)')
					tdcli_function ({
						ID = "ChangeName",
						first_name_ = fname,
						last_name_ = lname
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<i>New name has been successfully set.</i>")
				elseif text:match("^(Set username) (.*)") then
					local matches = text:match("^Set username (.*)")
						tdcli_function ({
						ID = "ChangeUsername",
						username_ = tostring(matches)
						}, dl_cb, nil)
					return send(msg.chat_id_, 0, '<i>Try to set user name...</i>')
				elseif text:match("^(Delete username)$") then
					tdcli_function ({
						ID = "ChangeUsername",
						username_ = ""
					}, dl_cb, nil)
					return send(msg.chat_id_, 0, '<i>User name successfully deleted.</i>')
				elseif text:match('^(Send) "(.*)" (.*)') then
					local id, txt = text:match('^Send "(.*)" (.*)')
					send(id, 0, txt)
					return send(msg.chat_id_, msg.id_, "<i>Sent</i>")
				elseif text:match("^(Say) (.*)") then
					local matches = text:match("^Say (.*)")
					return send(msg.chat_id_, 0, matches)
				elseif text:match("^(My ID)$") then
					return send(msg.chat_id_, msg.id_, "<i>" .. msg.sender_user_id_ .."</i>")
				elseif text:match("^(Leave) (.*)$") then
					local matches = text:match("^Leave (.*)$") 	
					send(msg.chat_id_, msg.id_, 'Tabchi left the target group')
					tdcli_function ({
						ID = "ChangeChatMemberStatus",
						chat_id_ = matches,
						user_id_ = bot_id,
						status_ = {ID = "ChatMemberStatusLeft"},
					}, dl_cb, nil)
					return rem(matches)
				elseif text:match("^(Add to all) (%d+)$") then
					local matches = text:match("%d+")
					local list = {redis:smembers("bot1groups"),redis:smembers("bot1supergroups")}
					for a, b in pairs(list) do
						for i, v in pairs(b) do 
							tdcli_function ({
								ID = "AddChatMember",
								chat_id_ = v,
								user_id_ = matches,
								forward_limit_ =  50
							}, dl_cb, nil)
						end	
					end
					return send(msg.chat_id_, msg.id_, "<i>The target user added to all my groups</i>")
				elseif (text:match("^(Online)$") and not msg.forward_info_)then
					return tdcli_function({
						ID = "ForwardMessages",
						chat_id_ = msg.chat_id_,
						from_chat_id_ = msg.chat_id_,
						message_ids_ = {[0] = msg.id_},
						disable_notification_ = 0,
						from_background_ = 1
					}, dl_cb, nil)
				elseif text:match("^(help)$") then
					local txt = " Tabchi orders help\n\nOnline\n<i>-نمایش وضعیت تبچی-</i>\n<code>تبچی حتی اگر در محدودیت چت هم باشد باید به این پیام پاسخ بدهد</code>\n/reload\n<i>-بارگذاری مجدد ربات-</i>\n<code>-عدم استفاده بی جهت-</code>\nRobot update\n<i>-بروزرسانی ربات</i>\n\nAdd admin [ID]\n<i>-افزودن مدیر جدید با شناسه داده شده</i>\n\nAdd sudo [ID]\n<i>افزودن مدیر کل جدید با شناسه داده شده</i>\n\n<code>-تفاوت مدیر و مدیر‌کل دسترسی به دادن و یا گرفتن مقام مدیریت است-</code>\n\nDelete admin [ID]\n<i>-حذف مدیر و مدیرکل با شناسه عددی داده شده-</i>\n\nLeave\n<i>-خارج شدن از گروه و حذف آن از اطلاعات گروه ها-</i>\n\nAdd all contacts\n<i>-افزودن تمام مخاطبین به گروه-</i>\n\nMy ID\n<i>-دریافت شناسه خود-</i>\n\nSay\n<i>-دریافت متن-</i>\n\nSend "شناسه" TEXT\n<i>-ارسال متن به شناسه گروه یا کاربر داده شده-</i>\n\nSetname\n<i>-تنظیم نام ربات-️</i>\n\nRefresh robot\n<i>-تازه‌سازی اطلاعات فردی ربات-</i>\n<code>(مورد استفاده در مواردی همچون پس از تنظیم نام -جهت بروزکردن نام مخاطب اشتراکی تبچی-)</code>\n\nSet username\n<i>جایگزینی اسم با نام کاربری فعلی-محدود در بازه زمانی کوتاه-</i>\n\nDelete username\n<i>-حذف کردن نام کاربری-</i>\n\nAdd the number on|off\n<i>-تغییر وضعیت اشتراک شماره تبچی در جواب شماره به اشتراک گذاشته شده-</i>\n\nAdd with message on|off\n<i>-تغییر وضعیت ارسال پیام در جواب شماره به اشتراک گذاشته شده-</i>\n\nSet the message to add a contact\n<i>-تنظیم متن داده شده به عنوان جواب شماره به اشتراک گذاشته شده-</i>\n\nlist Contacts|Chat|Group|Supergroup|Automatic answers|Link|Admin\n<i>-دریافت لیستی از مورد خواسته شده در قالب پرونده متنی یا پیام -</i>\n\nBlockUser [id]\n<i>-بلاک کردن کاربر با شناسه داده شده از گفت و گوی خصوصی-</i>\n\nUnblock [id]\n<i>-رفع مسدودیت کاربر با شناسه داده شده-</i>\n\nView state on|off\n<i>-تغییر وضعیت مشاهده پیام‌ها توسط تبلیغ‌گر (فعال و غیر‌فعال‌کردن تیک دوم)-</i>\n\nStatistics\n<i>-دریافت آمار و وضعیت تبچی-</i>\n\nsituation\n<i>-دریافت وضعیت اجرایی تبچی-</i>\n\nRefresh\n<i>-تازه‌سازی امار تبچی-</i>\n<code>-مورد استفاده حداکثر یک بار در روز-</code>\n\nSend to All|Chat|gruop|Supergroups\n<i>-ارسال پیام جواب داده شده به مورد خواسته شده-</i>\n<code>-به نظر من از همه و خصوصی استفاده نشه-</code>\n\nSend to supergroup Text\n<i>-ارسال متن داده شده به همه سوپرگروه ها-</i>\n<code>-به نظر من از ارسال به سوپرگروه استفاده کنید-</code>\n\nSet answer text\n<i>-تنظیم جوابی به عنوان پاسخ خودکار به پیام وارد شده مطابق با متن باشد-</i>\n\nDelete answer text\n<i>-حذف جواب مربوط به متن-</i>\n\nAutoresponder on|off\n<i>-تغییر وضعیت پاسخگویی خودکار تبچی به متن های تنظیم شده-</i>\n\nAdd to all [id]\n<i>-افزودن کابر با شناسه وارد شده به همه گروه و سوپرگروه ها-</i>\n\nleave [id]n<i>-عملیات ترک کردن با استفاده از شناسه گروه-</i>\n\nhelp\n<i>-دریافت همین پیام-</i>\n〰〰〰ا〰〰〰\nSync with tabchi\n<code>-همگام سازی اطلاعات تبچی با اطلاعات تبچی از قبل نصب شده-</code>\n\nCHNL : @UnknowCyberArmy "
					return send(msg.chat_id_,msg.id_, txt)
				elseif tostring(msg.chat_id_):match("^-") then
					if text:match("^(leave)$") then
						rem(msg.chat_id_)
						return tdcli_function ({
							ID = "ChangeChatMemberStatus",
							chat_id_ = msg.chat_id_,
							user_id_ = bot_id,
							status_ = {ID = "ChatMemberStatusLeft"},
						}, dl_cb, nil)
					elseif text:match("^(Add all contacts)$") then
						tdcli_function({
							ID = "SearchContacts",
							query_ = nil,
							limit_ = 999999999
						},function(i, sami)
							local users, count = redis:smembers("bot1users"), sami.total_count_
							for n=0, tonumber(count) - 1 do
								tdcli_function ({
									ID = "AddChatMember",
									chat_id_ = i.chat_id,
									user_id_ = sami.users_[n].id_,
									forward_limit_ = 50
								},  dl_cb, nil)
							end
							for n=1, #users do
								tdcli_function ({
									ID = "AddChatMember",
									chat_id_ = i.chat_id,
									user_id_ = users[n],
									forward_limit_ = 50
								},  dl_cb, nil)
							end
						end, {chat_id=msg.chat_id_})
						return send(msg.chat_id_, msg.id_, "<i>Adding contacts to group...</i>")
					end
				end
			end
			if redis:sismember("bot1answerslist", text) then
				if redis:get("bot1autoanswer") then
					if msg.sender_user_id_ ~= bot_id then
						local answer = redis:hget("bot1answers", text)
						send(msg.chat_id_, 0, answer)
					end
				end
			end
		elseif msg.content_.ID == "MessageContact" then
			local id = msg.content_.contact_.user_id_
			if not redis:sismember("bot1addedcontacts",id) then
				redis:sadd("bot1addedcontacts",id)
				local first = msg.content_.contact_.first_name_ or "-"
				local last = msg.content_.contact_.last_name_ or "-"
				local phone = msg.content_.contact_.phone_number_
				local id = msg.content_.contact_.user_id_
				tdcli_function ({
					ID = "ImportContacts",
					contacts_ = {[0] = {
							phone_number_ = tostring(phone),
							first_name_ = tostring(first),
							last_name_ = tostring(last),
							user_id_ = id
						},
					},
				}, dl_cb, nil)
				if redis:get("bot1addcontact") and msg.sender_user_id_ ~= bot_id then
					local fname = redis:get("bot1fname")
					local lnasme = redis:get("bot1lname") or ""
					local num = redis:get("bot1num")
					tdcli_function ({
						ID = "SendMessage",
						chat_id_ = msg.chat_id_,
						reply_to_message_id_ = msg.id_,
						disable_notification_ = 1,
						from_background_ = 1,
						reply_markup_ = nil,
						input_message_content_ = {
							ID = "InputMessageContact",
							contact_ = {
								ID = "Contact",
								phone_number_ = num,
								first_name_ = fname,
								last_name_ = lname,
								user_id_ = bot_id
							},
						},
					}, dl_cb, nil)
				end
			end
			if redis:get("bot1addmsg") then
				local answer = redis:get("bot1addmsgtext") or "addi pv . bzar { tabchi by : #UnknowCyberArmy} "
				send(msg.chat_id_, msg.id_, answer)
			end
		elseif msg.content_.ID == "MessageChatDeleteMember" and msg.content_.id_ == bot_id then
			return rem(msg.chat_id_)
		elseif msg.content_.ID == "MessageChatJoinByLink" and msg.sender_user_id_ == bot_id then
			return add(msg.chat_id_)
		elseif msg.content_.ID == "MessageChatAddMembers" then
			for i = 0, #msg.content_.members_ do
				if msg.content_.members_[i].id_ == bot_id then
					add(msg.chat_id_)
				end
			end
		elseif msg.content_.caption_ then
			return find_link(msg.content_.caption_)
		end
		if redis:get("bot1markread") then
			tdcli_function ({
				ID = "ViewMessages",
				chat_id_ = msg.chat_id_,
				message_ids_ = {[0] = msg.id_} 
			}, dl_cb, nil)
		end
	elseif data.ID == "UpdateOption" and data.name_ == "my_id" then
		tdcli_function ({
			ID = "GetChats",
			offset_order_ = 9223372036854775807,
			offset_chat_id_ = 0,
			limit_ = 20
		}, dl_cb, nil)
	end
end
