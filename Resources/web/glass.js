// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 S3rri-dev y colaboradores.
'use strict';
(()=>{
  const root=document.documentElement,media=matchMedia('(prefers-color-scheme:dark)');
  const reduce=matchMedia('(prefers-reduced-motion:reduce)'),contrast=matchMedia('(prefers-contrast:more)'),transparency=matchMedia('(prefers-reduced-transparency:reduce)');
  let preferences={theme:'dark'},frame=0;
  function apply(){
    const theme=preferences.theme||'dark',dark=theme==='dark'||theme==='system'&&media.matches;
    root.dataset.theme=dark?'dark':'light';root.dataset.themePreference=theme;
    root.classList.toggle('reduce-transparency',!!preferences.reduceTransparency||transparency.matches);
    root.classList.toggle('reduce-motion',!!preferences.reduceMotion||reduce.matches);
    root.classList.toggle('increase-contrast',!!preferences.increaseContrast||contrast.matches);
    document.querySelectorAll('[data-theme-choice]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.themeChoice===theme)));
    const toggle=document.querySelector('[data-action="toggleTheme"]');
    if(toggle){toggle.setAttribute('aria-label','Cambiar a modo '+(dark?'claro':'oscuro'));toggle.setAttribute('title','Cambiar a modo '+(dark?'claro':'oscuro'));toggle.innerHTML=dark?'<svg class="icon" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="4"/><path d="M12 2v2 M12 20v2 M2 12h2 M20 12h2 M5 5l1.5 1.5 M17.5 17.5 19 19 M5 19l1.5-1.5 M17.5 6.5 19 5"/></svg>':'<svg class="icon" viewBox="0 0 24 24" aria-hidden="true"><path d="M20 15A8 8 0 0 1 9 4a8.5 8.5 0 1 0 11 11Z"/></svg>';}
    const status=document.querySelector('#material-status');if(status)status.textContent=root.classList.contains('reduce-transparency')||root.classList.contains('increase-contrast')?'Superficies sólidas · accesibilidad de macOS':'Cristal adaptativo · preferencias de macOS';
  }
  window.appearanceUpdate=p=>{preferences={...preferences,...p};apply();};
  window.appearancePanel=()=>`<section class="panel appearance-panel" aria-labelledby="appearance-title"><div class="appearance-title"><span class="category-icon"><svg class="icon" viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3a9 9 0 1 0 0 18V3Z M12 3a9 9 0 0 1 0 18"/></svg></span><div><h2 id="appearance-title">Apariencia</h2><p id="material-status">Cristal adaptativo · preferencias de macOS</p></div></div><div class="theme-selector" role="group" aria-label="Apariencia de la aplicación"><button data-theme-choice="system" aria-pressed="false">Sistema</button><button data-theme-choice="light" aria-pressed="false">Claro</button><button data-theme-choice="dark" aria-pressed="false">Oscuro</button></div></section>`;
  for(const m of [media,reduce,contrast,transparency])m.addEventListener('change',apply);
  window.addEventListener('blur',()=>root.classList.add('window-inactive'));
  window.addEventListener('focus',()=>root.classList.remove('window-inactive'));
  document.addEventListener('click',async event=>{
    const b=event.target.closest('[data-theme-choice],[data-action="toggleTheme"]');if(!b||!window.finance)return;
    const theme=b.dataset.themeChoice||(root.dataset.theme==='dark'?'light':'dark');b.disabled=true;
    try{const value=await finance.api('appearance',{theme});appearanceUpdate(value);if(finance.state)finance.state.appearance=value;}
    catch(error){document.querySelector('#toast').textContent=error.message;document.querySelector('#toast').hidden=false;}
    finally{b.disabled=false;}
  });
  document.addEventListener('pointermove',event=>{
    if(root.classList.contains('reduce-motion')||root.classList.contains('reduce-transparency')||root.classList.contains('increase-contrast'))return;
    const target=event.target.closest('#sidebar,#topbar');if(!target||frame)return;
    frame=requestAnimationFrame(()=>{const r=target.getBoundingClientRect();target.style.setProperty('--pointer-x',`${event.clientX-r.left}px`);target.style.setProperty('--pointer-y',`${event.clientY-r.top}px`);frame=0;});
  },{passive:true});
  apply();
})();
