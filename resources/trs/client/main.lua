local C,S=TRSConfig,SunnyConfigServ
local P,opened,loaded,delivery,deathReported=nil,false,false,nil,false
local points={}
local function notify(msg) SendNUIMessage({type='notify',text=msg}) end
RegisterNetEvent('trs:notify',notify)
local function open(title,rows,identity)
    opened=true; SetNuiFocus(true,true); SendNUIMessage({type='open',title=title,rows=rows or {},identity=identity})
end
local function close()
    opened=false; SetNuiFocus(false,false); SendNUIMessage({type='close'})
end
local function action(name,data) TriggerServerEvent('trs:action',name,data or {}) end
local function row(label,name,data) return {label=label,action=name,data=data or {}} end
local function spawn(pos,sex)
    exports.spawnmanager:spawnPlayer({x=pos.x,y=pos.y,z=pos.z,heading=pos.w or 0,model=sex=='female' and 'mp_f_freemode_01' or 'mp_m_freemode_01',skipFade=false},function() end)
end
RegisterNetEvent('trs:loaded',function(data)
    if loaded then return end
    P=data; loaded=true
    spawn(P.position,P.sex)
    SendNUIMessage({type='data',player=P})
    if not P.name then open('Créer ton personnage',{},true) end
end)
RegisterNetEvent('trs:data',function(data) P=data; SendNUIMessage({type='data',player=P}) end)
RegisterNetEvent('trs:identityDone',function(sex) close(); spawn(P.position,sex) end)
RegisterNetEvent('trs:teleport',function(pos) SetEntityCoords(PlayerPedId(),pos.x,pos.y,pos.z,false,false,false,false) end)
RegisterNetEvent('trs:armour',function() SetPedArmour(PlayerPedId(),100) end)
RegisterNetEvent('trs:revive',function(pos)
    local ped=PlayerPedId(); local v=pos or GetEntityCoords(ped)
    NetworkResurrectLocalPlayer(v.x,v.y,v.z,pos and pos.w or GetEntityHeading(ped),true,false)
    SetEntityHealth(PlayerPedId(),200); deathReported=false
end)
RegisterNetEvent('trs:delivery',function(x,y,z) delivery=vector3(x,y,z); SetNewWaypoint(x,y); notify('Livre la marchandise au point GPS') end)
RegisterNetEvent('trs:deliveryDone',function() delivery=nil; SetWaypointOff() end)
RegisterNUICallback('close',function(_,cb) if P and P.name then close() end; cb('ok') end)
RegisterNUICallback('action',function(d,cb)
    if d.action=='localcoin' then ExecuteCommand(S.PileOuFace.Command)
    elseif d.action~='noop' and type(d.action)=='string' then action(d.action,d.data) end
    cb('ok')
end)
RegisterNUICallback('identity',function(d,cb) action('identity',d); cb('ok') end)
local function inventory()
    if not P then return end
    local rows={}
    for k,n in pairs(P.inventory) do rows[#rows+1]=row(k..' × '..n,'use',{item=k}) end
    open('Inventaire',rows)
end
RegisterCommand('trsinventory',inventory,false); RegisterKeyMapping('trsinventory','TRS · Inventaire','keyboard','TAB')
RegisterCommand('trsmenu',function()
    if P then open('Menu personnel · '..(P.name or ''),{
        row('Pile ou face','localcoin'),row('Identité : '..(P.name or 'Inconnue'),'noop'),row('Métier : '..(C.Jobs[P.job] or P.job),'noop'),row('XP : '..P.xp,'noop')}) end
end,false)
RegisterKeyMapping('trsmenu','TRS · Menu personnel','keyboard','F5')
RegisterCommand(S.XpSystems.Command,function() if P then notify('XP : '..P.xp) end end,false)
RegisterKeyMapping(S.XpSystems.Command,'TRS · Expérience','keyboard',S.XpSystems.Touche)
RegisterCommand('trsgive',function(_,args) action('give',{target=tonumber(args[1]),item=args[2],count=tonumber(args[3])}) end,false)
RegisterCommand('trsrespawn',function() action('respawn') end,false)
RegisterCommand('trsfish',function(_,args) action('fish',{kind=args[1]}) end,false)
RegisterCommand('trsbalance',function(_,args) action('bank',{deposit=args[1]=='deposit',amount=tonumber(args[2])}) end,false)
local function point(pos,label,fn) points[#points+1]={pos=vector3(pos.x,pos.y,pos.z),label=label,fn=fn} end
local function shop(title,list)
    local rows={}; for k,v in pairs(list) do if not v.boutique then rows[#rows+1]=row(v.label..' · $'..v.price,'buy',{item=v.name or k}) end end
    open(title,rows)
end
point(S.LegalShops.SuperMarket,'Supermarché',function() shop('Supermarché',C.Shop) end)
point(S.IllegalShops.Pos,'Commerce clandestin',function() shop('Commerce clandestin',C.IllegalShop) end)
point(C.BankPosition,'Banque',function() open('Banque — /trsbalance deposit|withdraw montant',{row('Déposer $100','bank',{deposit=true,amount=100}),row('Retirer $100','bank',{deposit=false,amount=100})}) end)
point(C.Garage,'Garage et concession',function()
    local rows={}
    for k,v in pairs(C.Vehicles) do if P.vehicles[k] then rows[#rows+1]=row('Sortir '..k,'vehicleSpawn',{model=k}) else rows[#rows+1]=row('Acheter '..k..' · $'..v,'vehicleBuy',{model=k}) end end
    rows[#rows+1]=row('Ranger le véhicule','vehicleStore'); open('Garage',rows)
end)
local f=S.Fishing.fishList
point(S.Fishing.PosShop,'Magasin de pêche',function()
    local list={}; for _,group in ipairs({f.permit,f.FishingRod,f.FishingLures}) do for _,v in pairs(group) do list[#list+1]=v end end
    shop('Matériel de pêche',list)
end)
point(S.Fishing.PosSell,'Vente de poissons',function() action('sellfish') end)
for name,v in pairs(S.Teleporters) do
    point(v.Enter,name,function() action('teleport',{key=name,exit=false}) end)
    point(v.Exit,name..' · sortie',function() action('teleport',{key=name,exit=true}) end)
end
for i,v in ipairs(S.Elevator.positions) do point(v.position,'Ascenseur '..v.label,function()
    local rows={}; for j,b in ipairs(S.Elevator.positions) do if i~=j and v.t==b.t then rows[#rows+1]=row(b.label,'elevator',{from=i,to=j}) end end
    open('Ascenseur',rows)
end) end
for k,v in pairs(S.Elevator.acceuil.pos) do point(v.pos,'Accueil '..v.label,function() action('reception',{key=k}) end) end
for phase,label in pairs({Acier='Récolte acier',TAcier='Traitement acier',VAcier='Vente acier'}) do for _,pos in ipairs(S.Activity[phase]) do point(pos,label,function() action('steel',{phase=phase}) end) end end
point(S.Activity.Peds.START_LIVRAISONS.pos,'Livraisons',function() action('delivery') end)
CreateThread(function()
    exports.spawnmanager:setAutoSpawn(false)
    while not NetworkIsSessionStarted() do Wait(250) end
    TriggerServerEvent('trs:load')
    while not loaded do Wait(5000); if not loaded then TriggerServerEvent('trs:load') end end
    for _,b in ipairs(S.Activity.Blips) do
        if b.text~='Chasse' and b.text~='Zonne De Chasse' and b.text~='Vente de gibier' then
            local blip=AddBlipForCoord(b.pos.x,b.pos.y,b.pos.z); SetBlipSprite(blip,b.blipid); SetBlipColour(blip,b.blipcolor); SetBlipAsShortRange(blip,true); BeginTextCommandSetBlipName('STRING'); AddTextComponentString(b.text); EndTextCommandSetBlipName(blip)
        end
    end
    while true do
        local wait=500; local ped=PlayerPedId(); local pos=GetEntityCoords(ped)
        if not opened and not IsEntityDead(ped) then
            for _,v in ipairs(points) do local dist=#(pos-v.pos); if dist<15 then wait=0
                DrawMarker(2,v.pos.x,v.pos.y,v.pos.z+0.3,0,0,0,0,0,0,0.28,0.28,0.28,155,120,255,180,false,true,2,false,nil,nil,false)
                if dist<2 then BeginTextCommandDisplayHelp('STRING'); AddTextComponentSubstringPlayerName('[E] '..v.label); EndTextCommandDisplayHelp(0,false,true,-1); if IsControlJustReleased(0,38) then v.fn(); break end end
            end end
            if delivery and #(pos-delivery)<4 then wait=0; BeginTextCommandDisplayHelp('STRING'); AddTextComponentSubstringPlayerName('[E] Livrer'); EndTextCommandDisplayHelp(0,false,true,-1); if IsControlJustReleased(0,38) then action('deliver') end end
        elseif IsEntityDead(ped) and not deathReported then deathReported=true; TriggerServerEvent('trs:death'); notify('Après '..C.RespawnDelay..' s : /trsrespawn') end
        Wait(wait)
    end
end)
CreateThread(function()
    while true do
        Wait(5000)
        if GlobalState.trsWeather then SetWeatherTypeNowPersist(GlobalState.trsWeather) end
        if P and S.AppId~=0 then SetDiscordAppId(S.AppId); SetRichPresence(S.Text) end
    end
end)
AddEventHandler('onResourceStop',function(r) if r==GetCurrentResourceName() then SetNuiFocus(false,false) end end)
