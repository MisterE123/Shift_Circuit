-- Default chat follows current room membership; the hub is its own channel.
return function(core,member)
 local function allowed(name)
  return (core.get_player_privs(name)or {}).shout==true
 end
 local function send(name,message,global)
  if not allowed(name)then return false,'You need the shout privilege to chat.'end
  message=tostring(message or ''):gsub('[\r\n]',' '):match('^%s*(.-)%s*$')
  if message==''then return false,'Write a message after the command.'end
  local room=member[name];local label=global and 'Global'or (room and 'Room '..room or 'Lobby')
  local text='['..label..'] <'..name..'> '..message
  for _,p in ipairs(core.get_connected_players())do local recipient=p:get_player_name()
   if global or member[recipient]==room then core.chat_send_player(recipient,text)end
  end
  return true
 end
 if core.register_on_chat_message then core.register_on_chat_message(function(name,message)
  if message:sub(1,1)=='/'then return false end
  local ok,err=send(name,message,false);if not ok then core.chat_send_player(name,err)end
  return true
 end)end
 for _,alias in ipairs({'all','global','g'})do core.register_chatcommand(alias,{params='<message>',description='Send a message to every room and the lobby.',privs={shout=true},func=function(name,message)return send(name,message,true)end})end
 return {send=send}
end
