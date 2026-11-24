const $=id=>document.getElementById(id);
const send=(route,data={})=>fetch('https://'+GetParentResourceName()+'/'+route,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)}).catch(()=>{});
let toastTimer;
window.addEventListener('message',({data:m})=>{
 if(m.type==='data'){const p=m.player;$('hud').hidden=false;$('cash').textContent='$ '+p.cash;$('bank').textContent='Banque $ '+p.bank;$('status').textContent='Faim '+p.hunger+'% · Soif '+p.thirst+'%';}
 if(m.type==='open'){$('panel').hidden=false;$('title').textContent=m.title;$('identity').hidden=!m.identity;$('close').hidden=!!m.identity;$('rows').replaceChildren();for(const r of m.rows){const b=document.createElement('button');b.textContent=r.label;b.onclick=()=>{send('action',{action:r.action,data:r.data});};$('rows').appendChild(b);}}
 if(m.type==='close')$('panel').hidden=true;
 if(m.type==='notify'){$('toast').hidden=false;$('toast').textContent=m.text;clearTimeout(toastTimer);toastTimer=setTimeout(()=>$('toast').hidden=true,4000);}
});
$('close').onclick=()=>send('close');
document.addEventListener('keydown',e=>{if(e.key==='Escape')send('close')});
$('identity').onsubmit=e=>{e.preventDefault();send('identity',{name:$('name').value,sex:$('sex').value});};
