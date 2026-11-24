local C,S=TRSConfig,SunnyConfigServ
local fish=S.Fishing.fishList
local cooldown, deliveries, deaths={}, {}, {}
local function delay(src,key,seconds)
    local id=src..':'..key; local now=os.time()
    if (cooldown[id] or 0)>now then return false end
    cooldown[id]=now+seconds; return true
end
local function register(list)
    for k,v in pairs(list) do TRS.Items[v.name or k]=v.label or k end
end
register(C.Shop); register(C.IllegalShop); register(fish.permit); register(fish.FishingRod); register(fish.FishingLures)
for _,list in pairs(fish.FishList) do register(list) end
for k in pairs(S.IllegalItem) do TRS.Items[k]=TRS.Items[k] or k end
for k in pairs(S.PermanentItem) do TRS.Items[k]=k end
TRS.Items[C.Steel.raw]='Acier brut'; TRS.Items[C.Steel.processed]='Acier'
local function buy(src,p,item,price)
    if p.cash<price then return TRS.notify(src,'Fonds insuffisants') end
    if not TRS.add(p,item,1) then return TRS.notify(src,'Inventaire plein') end
    p.cash=p.cash-price
end
TRS.action('identity',function(src,p,d)
    if p.name then return end
    if type(d.name)~='string' or #d.name<3 or #d.name>50 or d.name:find('[%c]') then return end
    p.name=d.name; p.sex=d.sex=='female' and 'female' or 'male'; TRS.notify(src,'Identité enregistrée')
    TriggerClientEvent('trs:identityDone',src,p.sex)
end)
TRS.action('bank',function(src,p,d)
    if not TRS.near(src,C.BankPosition) or not TRS.amount(d.amount) then return end
    local from,to=d.deposit==true and 'cash' or 'bank',d.deposit==true and 'bank' or 'cash'
    if p[from]>=d.amount then p[from]=p[from]-d.amount; p[to]=p[to]+d.amount end
end)
TRS.action('buy',function(src,p,d)
    if type(d.item)~='string' then return end
    local list=TRS.near(src,S.LegalShops.SuperMarket) and C.Shop or TRS.near(src,S.IllegalShops.Pos) and C.IllegalShop
    if list and list[d.item] then return buy(src,p,d.item,list[d.item].price) end
    if TRS.near(src,S.Fishing.PosShop) then
        for _,v in ipairs(fish.FishingRod) do if v.name==d.item and not v.boutique then return buy(src,p,v.name,v.price) end end
        for _,v in pairs(fish.FishingLures) do if v.name==d.item then return buy(src,p,v.name,v.price) end end
        for _,v in ipairs(fish.permit) do if v.name==d.item then return buy(src,p,v.name,v.price) end end
    end
end)
TRS.action('use',function(src,p,d)
    if d.item=='water' or d.item=='bread' then
        if TRS.remove(p,d.item,1) then local k=d.item=='water' and 'thirst' or 'hunger'; p[k]=math.min(100,p[k]+35) end
    elseif d.item=='kevlar' and TRS.remove(p,'kevlar',1) then TriggerClientEvent('trs:armour',src) end
end)
TRS.action('give',function(src,p,d)
    local t=tonumber(d.target); local q=TRS.Players[t]
    if not q or t==src or type(d.item)~='string' or S.PermanentItem[d.item] or not TRS.amount(d.count,100) or (p.inventory[d.item] or 0)<d.count then return end
    local ped=GetPlayerPed(t); if ped==0 or not TRS.near(src,GetEntityCoords(ped),3) then return end
    if TRS.add(q,d.item,d.count) then TRS.remove(p,d.item,d.count); TRS.sync(t) end
end)
TRS.action('teleport',function(src,p,d)
    local t=S.Teleporters[d.key]; if not t or (t.Job~='none' and t.Job~=p.job) then return end
    local from,to=d.exit==true and t.Exit or t.Enter,d.exit==true and t.Enter or t.Exit
    if TRS.near(src,from,3) then TriggerClientEvent('trs:teleport',src,to) end
end)
TRS.action('elevator',function(src,p,d)
    local a,b=S.Elevator.positions[d.from],S.Elevator.positions[d.to]
    if a and b and a.t==b.t and TRS.near(src,a.position,3) then TriggerClientEvent('trs:teleport',src,{x=b.position.x,y=b.position.y,z=b.position.z}) end
end)
TRS.action('reception',function(src,p,d)
    local v=S.Elevator.acceuil.pos[d.key]; if not v or not TRS.near(src,v.pos) or not delay(src,'reception',60) then return end
    for id,q in pairs(TRS.Players) do if q.job==v.job then TRS.notify(id,v.message) end end
    TRS.notify(src,'Appel envoyé')
end)
TRS.action('steel',function(src,p,d)
    local zones=S.Activity[d.phase]; if d.phase~='Acier' and d.phase~='TAcier' and d.phase~='VAcier' then return end
    local near=false; for _,pos in ipairs(zones) do if TRS.near(src,pos,4) then near=true break end end
    if not near or not delay(src,'steel',5) then return end
    if d.phase=='Acier' then TRS.add(p,C.Steel.raw,1)
    elseif d.phase=='TAcier' and (p.inventory[C.Steel.raw] or 0)>0 then if TRS.remove(p,C.Steel.raw,1) then if not TRS.add(p,C.Steel.processed,1) then TRS.add(p,C.Steel.raw,1) end end
    elseif d.phase=='VAcier' and TRS.remove(p,C.Steel.processed,1) then p.cash=p.cash+C.Steel.price end
end)
TRS.action('fish',function(src,p,d)
    local kind=d.kind; if type(kind)~='string' or not fish.Zones[kind] then return end
    local near=false; for _,z in ipairs(fish.Zones[kind]) do if TRS.near(src,z.position,z.radius) then near=true break end end
    if not near or not p.inventory[kind] or not p.inventory[fish.FishingLures[kind].name] then return TRS.notify(src,'Permis et appât requis') end
    local rod=false; for _,v in ipairs(fish.FishingRod) do if p.inventory[v.name] then rod=true end end
    if not rod or not delay(src,'fish',15) then return end
    local list=fish.FishList[kind]; local sum=0; for _,v in ipairs(list) do sum=sum+v.rarity end
    local r=math.random()*sum; local catch=list[#list]
    for _,v in ipairs(list) do r=r-v.rarity; if r<=0 then catch=v break end end
    if TRS.remove(p,fish.FishingLures[kind].name,1) then
        if TRS.add(p,catch.name,1) then TRS.notify(src,'Poisson : '..catch.label) else TRS.add(p,fish.FishingLures[kind].name,1) end
    end
end)
TRS.action('sellfish',function(src,p)
    if not TRS.near(src,S.Fishing.PosSell) or not delay(src,'sellfish',2) then return end
    for _,list in pairs(fish.FishList) do for _,v in ipairs(list) do local n=math.min(p.inventory[v.name] or 0,100); if n>0 and TRS.remove(p,v.name,n) then p.cash=p.cash+n*v.price end end end
end)
TRS.action('delivery',function(src,p)
    if not TRS.near(src,S.Activity.Peds.START_LIVRAISONS.pos) or deliveries[src] then return end
    local i=math.random(#S.Activity.Livraisons.Market); deliveries[src]=i
    local v=S.Activity.Livraisons.Market[i]; TriggerClientEvent('trs:delivery',src,v.x,v.y,v.z)
end)
TRS.action('deliver',function(src,p)
    local i=deliveries[src]; if not i or not TRS.near(src,S.Activity.Livraisons.Market[i],5) then return end
    deliveries[src]=nil; p.cash=p.cash+C.DeliveryPay; p.xp=p.xp+5; TRS.notify(src,'Livraison terminée')
    TriggerClientEvent('trs:deliveryDone',src)
end)
TRS.action('vehicleBuy',function(src,p,d)
    if not TRS.near(src,C.Garage) or type(d.model)~='string' or not C.Vehicles[d.model] or p.vehicles[d.model] then return end
    local price=C.Vehicles[d.model]; if p.cash>=price then p.cash=p.cash-price; p.vehicles[d.model]=true end
end)
local spawned={}
TRS.action('vehicleSpawn',function(src,p,d)
    if not TRS.near(src,C.Garage) or type(d.model)~='string' or not p.vehicles[d.model] or not C.Vehicles[d.model] or not delay(src,'garage',5) then return end
    if spawned[src] and DoesEntityExist(spawned[src]) then return TRS.notify(src,'Range ton véhicule avant de le ressortir') end
    local v=C.GarageSpawn; local e=CreateVehicleServerSetter(joaat(d.model),d.model=='bati' and 'bike' or 'automobile',v.x,v.y,v.z,v.w)
    if e~=0 then spawned[src]=e; TRS.notify(src,'Véhicule sorti') end
end)
TRS.action('vehicleStore',function(src,p)
    local e=spawned[src]; if e and DoesEntityExist(e) and TRS.near(src,GetEntityCoords(e),5) and TRS.near(src,C.Garage,40) then DeleteEntity(e); spawned[src]=nil end
end)
RegisterNetEvent('trs:death',function()
    local src=source; local p=TRS.Players[src]; local ped=GetPlayerPed(src)
    if not p or p.dead or ped==0 or GetEntityHealth(ped)>0 then return end
    p.dead=true; deaths[src]=os.time(); TRS.sync(src)
end)
TRS.action('respawn',function(src,p)
    if not p.dead or not deaths[src] or os.time()-deaths[src]<C.RespawnDelay then return end
    if S.RemoveIllegalItemsOnRespawn then for item in pairs(S.IllegalItem) do if not S.PermanentItem[item] and math.random(100)<=50 then p.inventory[item]=nil end end end
    p.dead=false; deaths[src]=nil; p.hunger=100; p.thirst=100
    TriggerClientEvent('trs:revive',src,{x=C.Respawn.x,y=C.Respawn.y,z=C.Respawn.z,w=C.Respawn.w})
end)
RegisterCommand('trsjob',function(src,args)
    if src~=0 and not IsPlayerAceAllowed(src,'trs.admin') then return end
    local id=tonumber(args[1]); local p=TRS.Players[id]; if p and C.Jobs[args[2]] then p.job=args[2]; p.grade=0; TRS.sync(id) end
end,false)
RegisterCommand('trsmoney',function(src,args)
    if src~=0 and not IsPlayerAceAllowed(src,'trs.admin') then return end
    local id=tonumber(args[1]); local p=TRS.Players[id]; local n=tonumber(args[2]); if p and TRS.amount(n) then p.cash=p.cash+n; TRS.sync(id) end
end,false)
RegisterCommand('trsrevive',function(src,args)
    if src~=0 and not IsPlayerAceAllowed(src,'trs.admin') then return end
    local id=tonumber(args[1]); local p=TRS.Players[id]; if not p then return end
    p.dead=false; deaths[id]=nil; TriggerClientEvent('trs:revive',id); TRS.sync(id)
end,false)
RegisterCommand(S.PileOuFace.Command,function(src)
    if src>0 and delay(src,'coin',2) then TRS.notify(src,math.random(2)==1 and S.PileOuFace.TextPile or S.PileOuFace.TextFace) end
end,false)
AddEventHandler('playerDropped',function()
    local src=source; deliveries[src]=nil; deaths[src]=nil
    if spawned[src] and DoesEntityExist(spawned[src]) then DeleteEntity(spawned[src]) end; spawned[src]=nil
    for k in pairs(cooldown) do if k:sub(1,#tostring(src)+1)==src..':' then cooldown[k]=nil end end
end)
CreateThread(function()
    while true do
        GlobalState.trsWeather=S.weatherCFG.weathers[math.random(#S.weatherCFG.weathers)]
        Wait(C.WeatherInterval)
    end
end)
