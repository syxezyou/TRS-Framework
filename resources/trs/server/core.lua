TRS = {Players={}, Items={}, Actions={}}
local loading, rates, owners = {}, {}, {}
local C = TRSConfig
function TRS.identifier(src) return GetPlayerIdentifierByType(src,'license') end
function TRS.notify(src,msg) TriggerClientEvent('trs:notify',src,msg) end
function TRS.sync(src)
    local p=TRS.Players[src]; if not p then return end
    TriggerClientEvent('trs:data',src,p)
end
function TRS.save(src)
    local p=TRS.Players[src]; if not p then return end
    local ped=GetPlayerPed(src)
    if ped~=0 and not p.dead then
        local pos=GetEntityCoords(ped)
        p.position={x=pos.x,y=pos.y,z=pos.z,w=GetEntityHeading(ped)}
    end
    MySQL.update.await('INSERT INTO trs_players (identifier,data) VALUES (?,?) ON DUPLICATE KEY UPDATE data=VALUES(data)',{p.identifier,json.encode(p)})
end
function TRS.near(src,pos,radius)
    local ped=GetPlayerPed(src)
    return ped~=0 and #(GetEntityCoords(ped)-vector3(pos.x,pos.y,pos.z)) <= (radius or 4.0)
end
function TRS.amount(n,max)
    return type(n)=='number' and n==math.floor(n) and n>0 and n<=(max or 1000000)
end
function TRS.add(p,item,n)
    if not TRS.Items[item] or not TRS.amount(n,100) then return false end
    local total=0; for _,v in pairs(p.inventory) do total=total+v end
    if total+n>C.InventoryLimit then return false end
    p.inventory[item]=(p.inventory[item] or 0)+n; return true
end
function TRS.remove(p,item,n)
    if not TRS.amount(n,100) or (p.inventory[item] or 0)<n then return false end
    p.inventory[item]=p.inventory[item]-n
    if p.inventory[item]==0 then p.inventory[item]=nil end
    return true
end
function TRS.action(name,fn) TRS.Actions[name]=fn end
RegisterNetEvent('trs:action',function(name,data)
    local src=source; local p=TRS.Players[src]
    if not p or type(name)~='string' or type(data)~='table' or not TRS.Actions[name] then return end
    local now=GetGameTimer(); if (rates[src] or 0)>now then return end
    rates[src]=now+350
    if p.dead and name~='respawn' then return end
    if not p.name and name~='identity' then return end
    local ok,err=pcall(TRS.Actions[name],src,p,data)
    if not ok then print(('[TRS] %s: %s'):format(name,err)); return end
    TRS.sync(src)
end)
AddEventHandler('playerConnecting',function(_,_,deferrals)
    if not SunnyConfigServ.MaintenancePerm.Active then return end
    deferrals.defer(); Wait(0)
    if IsPlayerAceAllowed(source,'trs.admin') then deferrals.done() else deferrals.done('TRS : maintenance en cours') end
end)
RegisterNetEvent('trs:load',function()
    local src=source
    if TRS.Players[src] then TriggerClientEvent('trs:loaded',src,TRS.Players[src]); return end
    if loading[src] then return end
    local id=TRS.identifier(src); if not id then return DropPlayer(src,'Licence Rockstar introuvable') end
    if owners[id] then return DropPlayer(src,'Personnage déjà connecté') end
    loading[src]=true; owners[id]=src
    local ok,row=pcall(MySQL.single.await,'SELECT data FROM trs_players WHERE identifier=?',{id})
    loading[src]=nil
    if not ok or not GetPlayerName(src) then owners[id]=nil; if not ok then DropPlayer(src,'Base de données indisponible') end; return end
    local p=row and json.decode(row.data) or {cash=C.Cash,bank=C.Bank,inventory={},job='unemployed',grade=0,xp=0,hunger=100,thirst=100,vehicles={},licenses={},position={x=C.Spawn.x,y=C.Spawn.y,z=C.Spawn.z,w=C.Spawn.w}}
    p.identifier=id; p.dead=false
    TRS.Players[src]=p
    TriggerClientEvent('trs:loaded',src,p)
end)
AddEventHandler('playerDropped',function()
    local src=source; local p=TRS.Players[src]
    if p then local ok,err=pcall(TRS.save,src); if not ok then print(err) end; owners[p.identifier]=nil end
    TRS.Players[src]=nil; rates[src]=nil; loading[src]=nil
end)
CreateThread(function()
    while true do Wait(C.SaveInterval); for src in pairs(TRS.Players) do local ok,err=pcall(TRS.save,src); if not ok then print(err) end end end
end)
CreateThread(function()
    while true do Wait(C.SalaryInterval); for src,p in pairs(TRS.Players) do p.bank=p.bank+C.Salary; TRS.sync(src) end end
end)
CreateThread(function()
    while true do Wait(Statut.UpdateInterval); for src,p in pairs(TRS.Players) do
        p.hunger=math.max(0,p.hunger-1); p.thirst=math.max(0,p.thirst-2); TRS.sync(src)
    end end
end)
CreateThread(function()
    while true do Wait(SunnyConfigServ.XpSystems.Wait); for src,p in pairs(TRS.Players) do p.xp=p.xp+10; TRS.sync(src) end end
end)
exports('GetPlayer',function(src)
    local p=TRS.Players[src]; return p and json.decode(json.encode(p))
end)
exports('AddItem',function(src,item,count)
    local p=TRS.Players[src]; if not p or not TRS.add(p,item,count) then return false end
    TRS.sync(src); return true
end)
exports('RemoveItem',function(src,item,count)
    local p=TRS.Players[src]; if not p or not TRS.remove(p,item,count) then return false end
    TRS.sync(src); return true
end)
exports('RegisterItem',function(name,label)
    if type(name)=='string' and type(label)=='string' then TRS.Items[name]=label end
end)
exports('AddMoney',function(src,account,amount)
    local p=TRS.Players[src]; if not p or (account~='cash' and account~='bank') or not TRS.amount(amount) then return false end
    p[account]=p[account]+amount; TRS.sync(src); return true
end)
exports('SetJob',function(src,job,grade)
    local p=TRS.Players[src]; if not p or not C.Jobs[job] or type(grade)~='number' or grade<0 or grade>10 or grade%1~=0 then return false end
    p.job=job; p.grade=grade; TRS.sync(src); return true
end)
