// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 S3rri-dev y colaboradores.
(async()=>{
  const results=[],captures=[];
  function assert(condition,label){results.push({label,ok:!!condition});if(!condition)throw Error(label);}
  const pause=ms=>new Promise(r=>setTimeout(r,ms));
  async function waitUntil(predicate,label){for(let i=0;i<120;i++){if(predicate())return;await pause(50);}throw Error('Espera agotada: '+label);}
  async function submit(entity,values){
    finance.entityForm(entity);for(const [key,value] of Object.entries(values)){const field=document.querySelector(`[name="${key}"]`);if(!field)throw Error('Campo ausente: '+key);field.value=value;}
    document.querySelector('#editor').requestSubmit();
    await waitUntil(()=>!document.querySelector('#dialog').open||!!document.querySelector('#form-error')?.textContent,'guardar '+entity);
    if(document.querySelector('#dialog').open)throw Error(document.querySelector('#form-error').textContent);
    await finance.refresh();
  }
  try {
    await waitUntil(()=>finance.state,'primer arranque');
    assert(document.title==='Caudal','Nombre Caudal en la ventana web');
    assert(document.querySelector('.brand').textContent.includes('Caudal'),'Marca Caudal en la navegación');
    await waitUntil(()=>document.querySelector('.brand-mark img')?.naturalWidth>0,'símbolo vectorial de Caudal');
    assert(document.querySelector('.brand-mark img').naturalWidth>0,'Logo de Caudal empaquetado y visible');
    const wallpaper=new Image();wallpaper.src='backgrounds/caudal-flow.svg';await waitUntil(()=>wallpaper.naturalWidth>0,'fondo local');
    assert(wallpaper.naturalWidth===3840&&wallpaper.naturalHeight===2160,'Fondo vectorial original disponible desde el bundle');
    assert(finance.state.accounts.length===0,'Arranque vacío, sin datos inventados');
    const heading=document.querySelector('h1');window.dispatchEvent(new Event('focus'));await pause(100);
    assert(heading===document.querySelector('h1'),'Volver a la ventana conserva los controles y el foco');
    captures.push(await finance.api('uiCapture',{name:'empty'}));
    await submit('account',{name:'Cuenta principal',kind:'bank',initial_cents:'1250,00'});
    await submit('account',{name:'Cuenta de ahorro',kind:'savings',initial_cents:'800,00'});
    assert(finance.state.totals.liquid===205000,'Formulario de cuenta actualiza saldo');
    const bank=finance.state.accounts.find(a=>a.name==='Cuenta principal').id,savings=finance.state.accounts.find(a=>a.kind==='savings').id;
    async function movement(value){
      finance.movementForm({kind:value.kind,account_id:bank,...value});
      for(const [key,v] of Object.entries(value)){const field=document.querySelector(`[name="${key}"]`);if(field)field.value=v;}
      document.querySelector('#editor').requestSubmit();await waitUntil(()=>!document.querySelector('#dialog').open||!!document.querySelector('#form-error')?.textContent,'movimiento');
      if(document.querySelector('#dialog').open)throw Error(document.querySelector('#form-error').textContent);await finance.refresh();
    }
    await movement({kind:'income',amount_cents:'1400,00',category_id:'salary',note:'Nómina de demostración'});
    await movement({kind:'expense',amount_cents:'78,45',category_id:'food',note:'Compra semanal'});
    await movement({kind:'expense',amount_cents:'42,00',category_id:'leisure',note:'Cena con amigos'});
    await movement({kind:'expense',amount_cents:'29,90',category_id:'subscriptions',note:'Suscripciones'});
    await movement({kind:'expense',amount_cents:'55,00',category_id:'transport',note:'Abono transporte'});
    await movement({kind:'transfer',amount_cents:'200,00',destination_id:savings,note:'Transferencia a ahorro'});
    assert(finance.state.totals.liquid===324465,'Ingresos, gastos y transferencia cuadran desde formularios');
    await submit('budget',{amount_cents:'250,00',category_id:'food'});
    await submit('budget',{amount_cents:'150,00',category_id:'leisure'});
    await submit('goal',{name:'Fondo de emergencia',target_cents:'3000,00',saved_cents:'700,00'});
    await submit('goal',{name:'Próximo viaje',target_cents:'1200,00',saved_cents:'250,00'});
    assert(finance.state.totals.liquid===324465&&finance.state.totals.reserved===95000,'Reservar ahorro conserva saldo');
    await submit('debt',{name:'Préstamo del coche',creditor:'Banco de prueba',initial_cents:'2400,00',monthly_cents:'120,00',due_day:'5'});
    const debt=finance.state.debts[0].id;
    await movement({kind:'debt_payment',debt_id:debt,amount_cents:'120,00',principal_cents:'100,00',category_id:'interest',note:'Cuota del coche'});
    assert(finance.state.totals.debt===230000&&finance.state.totals.liquid===312465,'Pago de deuda separa principal e intereses');
    const p=finance.periodStats();
    assert(p.income===140000&&p.expenses===22535&&p.principal===10000,'Informe muestra ingresos, consumo e intereses sin duplicar principal');
    assert(p.income-p.expenses-p.principal===107465,'Variación mensual del saldo explicable');
    // Use a real previous month to verify period filters and six-month chart.
    const oldMonth=(()=>{const d=new Date(finance.state.today.slice(0,7)+'-01T12:00:00');d.setMonth(d.getMonth()-1);return d.getFullYear()+'-'+String(d.getMonth()+1).padStart(2,'0');})();
    await finance.api('save',{entity:'movement',value:{kind:'income',date:oldMonth+'-01',account_id:bank,category_id:'salary',amount_cents:135000,note:'Ingreso de prueba del mes anterior'}});
    await finance.api('save',{entity:'movement',value:{kind:'expense',date:oldMonth+'-02',account_id:bank,category_id:'food',amount_cents:18950,note:'Compra del mes anterior'}});
    await finance.refresh();
    assert(finance.periodStats().income===140000,'Filtro mensual excluye meses anteriores');
    const expense=finance.state.movements.find(m=>m.note==='Compra semanal');
    finance.entityForm('movement',expense.id);
    assert(document.querySelector('[name="amount_cents"]').value==='78,45','Edición recupera importe y decimales');
    document.querySelector('[data-action="closeDialog"]').click();
    for(const view of ['overview','movements','accounts','budgets','savings','debts','reports','settings']){
      finance.navigate(view);await pause(100);
      document.querySelector('#toast').hidden=true;
      assert(document.querySelector('h1')?.textContent.length>0,'Vista '+view+' renderizada');
      assert(document.querySelector('#workspace').scrollWidth<=document.querySelector('#workspace').clientWidth+1,'Vista '+view+' sin desbordamiento horizontal');
      captures.push(await finance.api('uiCapture',{name:view}));
    }
    finance.navigate('movements');const input=document.querySelector('#search');input.value='compra';input.dispatchEvent(new Event('input',{bubbles:true}));
    assert(document.querySelectorAll('tbody tr').length===1,'Búsqueda filtra movimientos del mes');
    input.value='';document.querySelector('#search').value='';document.querySelector('#search').dispatchEvent(new Event('input',{bubbles:true}));
    assert(finance.moneyInput('0,10')+finance.moneyInput('0,20')===30,'Entrada decimal conserva céntimos exactos');
    await finance.api('backup');finance.navigate('overview');
    const contrastResults=[];
    function ratio(fg,bg){
      function luminance(hex){const c=hex.trim().replace('#','').match(/.{2}/g).map(n=>parseInt(n,16)/255).map(n=>n<=.04045?n/12.92:((n+.055)/1.055)**2.4);return c[0]*.2126+c[1]*.7152+c[2]*.0722;}
      const a=luminance(fg),b=luminance(bg);return (Math.max(a,b)+.05)/(Math.min(a,b)+.05);
    }
    const balancesBefore=JSON.stringify(finance.state.totals);
    for(const theme of ['light','dark']){
      finance.navigate('settings');document.querySelector(`[data-theme-choice="${theme}"]`).click();
      await waitUntil(()=>document.documentElement.dataset.theme===theme,'apariencia '+theme);
      const snapshot=await finance.api('snapshot');assert(snapshot.appearance.theme===theme,'Preferencia '+theme+' persistida por el puente nativo');
      finance.navigate('overview');document.querySelector('#toast').hidden=true;await pause(250);
      captures.push(await finance.api('uiCapture',{name:theme+'-overview'}));
      const style=getComputedStyle(document.documentElement),color=k=>style.getPropertyValue(k).trim();
      assert(getComputedStyle(document.querySelector('.brand')).color===getComputedStyle(document.querySelector('h1')).color,'Marca '+theme+' mantiene el contraste del texto principal');
      for(const [fg,bg,label] of [['--ink','--panel','texto principal'],['--muted','--panel','texto secundario'],['--red','--panel','estado negativo']]){
        const value=ratio(color(fg),color(bg));contrastResults.push({theme,label,ratio:Number(value.toFixed(2))});assert(value>=4.5,'Contraste '+theme+' '+label+' ≥ 4,5:1');
      }
      const primary=ratio(color('--primary-ink'),color('--primary-bottom'));contrastResults.push({theme,label:'botón principal',ratio:Number(primary.toFixed(2))});assert(primary>=4.5,'Contraste '+theme+' botón principal ≥ 4,5:1');
      finance.movementForm({kind:'debt_payment',debt_id:debt,account_id:bank,amount_cents:12000});
      assert(document.querySelector('[name="principal_cents"]').value==='','El rediseño no inventa principal al crear una cuota');
      const box=document.querySelector('#dialog').getBoundingClientRect();assert(box.left>=0&&box.top>=0&&box.right<=innerWidth&&box.bottom<=innerHeight,'Formulario '+theme+' dentro de la ventana');
      await pause(300);
      captures.push(await finance.api('uiCapture',{name:theme+'-dialog'}));document.querySelector('[data-action="closeDialog"]').click();
    }
    for(const view of ['overview','movements','budgets','savings','debts']){finance.navigate(view);document.querySelector('#toast').hidden=true;await pause(300);captures.push(await finance.api('uiCapture',{name:'dark-'+view}));}
    finance.navigate('overview');
    const prefs=(await finance.api('snapshot')).appearance;
    appearanceUpdate({...prefs,reduceTransparency:true});
    assert(getComputedStyle(document.querySelector('#sidebar')).backdropFilter==='none','Reducir transparencia elimina el desenfoque');
    assert(getComputedStyle(document.body,'::before').display==='none','Reducir transparencia retira el fondo decorativo');
    captures.push(await finance.api('uiCapture',{name:'reduced-transparency'}));
    appearanceUpdate({...prefs,reduceMotion:true});
    assert(getComputedStyle(document.querySelector('.button')).transitionDuration==='0s','Reducir movimiento elimina transiciones');
    appearanceUpdate({...prefs,increaseContrast:true});
    assert(getComputedStyle(document.querySelector('#sidebar')).backdropFilter==='none','Aumentar contraste elimina el cristal');
    assert(getComputedStyle(document.documentElement).getPropertyValue('--line').trim()==='#ada480','Aumentar contraste refuerza bordes');
    appearanceUpdate(prefs);
    let invalidRejected=false;try{await finance.api('appearance',{theme:'invalid'});}catch{invalidRejected=true;}assert(invalidRejected,'La capa nativa rechaza una apariencia desconocida');
    await finance.refresh();assert(JSON.stringify(finance.state.totals)===balancesBefore,'Cambiar apariencia conserva todos los saldos');
    await finance.api('uiResize',{width:1100,height:740});await pause(250);
    for(const v of ['overview','movements','accounts','budgets','savings','debts','reports','settings']){
      finance.navigate(v);await pause(40);
      assert(document.querySelector('#main').scrollWidth<=document.querySelector('#main').clientWidth+1,'Vista '+v+' cabe en 1100 × 740');
    }
    assert(document.querySelector('button[data-view="settings"]').getBoundingClientRect().bottom<=innerHeight,'Ajustes sigue accesible en la ventana mínima');
    finance.navigate('overview');captures.push(await finance.api('uiCapture',{name:'minimum-window'}));
    await finance.api('uiResize',{width:1440,height:940});await pause(100);finance.navigate('overview');
    await finance.api('uiTestResult',{ok:true,checks:results.length,results,captures,contrastResults});
  } catch(error){await finance.api('uiTestResult',{ok:false,error:error.message,results,captures});}
})();
