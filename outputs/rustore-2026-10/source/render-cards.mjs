import fs from 'node:fs/promises';
import path from 'node:path';
import { chromium } from 'playwright';
const root=path.resolve(import.meta.dirname,'..');
const data=(file)=>fs.readFile(path.join(root,file)).then(b=>'data:image/png;base64,'+b.toString('base64'));
const icon=await data('../../assets/icon/store_icon_512.png');
const hero=await data('assets/mango-hero.png');
const specs=[
 ['01-money','Поймите траты.<br>Копите на важное.','Начните с нескольких операций.<br>Увидьте, куда уходят деньги.','hero'],
 ['02-private','Ваши финансы.<br>Только у вас.','Без регистрации и подключения к банкам.<br>Данные хранятся на вашем устройстве.','privacy'],
 ['03-transactions','Начните<br>с первой покупки.','Доходы, расходы и переводы —<br>понятная история ваших денег.','transactions'],
 ['04-statistics','Поймите, куда<br>уходят деньги.','Смотрите расходы по категориям<br>и сравнивайте с привычным уровнем.','statistics'],
 ['05-budgets','Планируйте<br>покупки увереннее.','Задавайте комфортные лимиты.<br>Оставляйте больше на свои планы.','budgets'],
 ['06-accounts','На каждый день.<br>И на мечту.','Карта, наличные, накопления —<br>в одной картине ваших финансов.','accounts'],
 ['07-recurring','Освободите голову<br>от дат платежей.','Добавляйте регулярные платежи<br>и настраивайте напоминания заранее.','recurring'],
 ['08-profiles','Для себя.<br>Для всей семьи.','Отдельные профили для личных,<br>семейных и рабочих финансов.','profiles'],
];
const css=`
*{box-sizing:border-box}body{margin:0;background:#e9dfcb;font-family:Arial,sans-serif;color:#263e32} .card{width:1080px;height:1920px;position:relative;overflow:hidden;background:radial-gradient(ellipse at 95% 83%,#ffe1a0 0,transparent 52%),#fff5e3}
.brand{position:absolute;left:76px;top:65px;display:flex;align-items:center;gap:20px;font-size:30px;font-weight:700;letter-spacing:-.6px}.brand img{width:62px;height:62px;border-radius:17px}.count{position:absolute;right:78px;top:82px;font-size:22px;letter-spacing:3px;color:#778374}
.copy{position:absolute;top:207px;left:76px;right:55px;z-index:2}h1{margin:0;font-size:88px;line-height:1.06;letter-spacing:-4px;font-weight:700}p{font-size:32px;line-height:1.45;margin:33px 0 0;color:#61705e;letter-spacing:-.5px}
.phone{position:absolute;width:700px;left:190px;top:595px;padding:13px;background:linear-gradient(110deg,#65645c,#151b17 30%,#252e28 75%,#89867c);border:2px solid #53594d;border-radius:65px;box-shadow:0 40px 65px #52432d32,0 4px 5px #59452425}.screen{background:#f8f9fa;padding-top:27px;border-radius:50px;overflow:hidden;position:relative}.screen:before{content:'';position:absolute;top:10px;left:50%;width:9px;height:9px;background:#30372f;border-radius:50%}.screen img{width:100%;display:block}.screen:after{content:'';display:block;margin:13px auto 11px;background:#30372f;width:160px;height:5px;border-radius:5px}.side{position:absolute;width:5px;height:100px;background:#5a6053;right:-6px;top:215px;border-radius:0 5px 5px 0}
.tag{position:absolute;bottom:42px;left:0;right:0;text-align:center;font-size:19px;letter-spacing:2px;color:#73806a}.curve{position:absolute;left:-330px;top:780px;width:1700px;height:1250px;border:2px solid #cfae5a35;border-radius:50%;transform:rotate(-29deg)}.hero h1{font-size:108px;letter-spacing:-5px}.hero .copy p{font-size:38px;color:#62705c}.hero-art{position:absolute;left:-48px;top:650px;width:1165px;mix-blend-mode:multiply}.hero-foot{position:absolute;left:76px;right:76px;bottom:100px;border-top:1px solid #263e322b;padding-top:30px;display:flex;justify-content:space-between;font-size:23px;color:#56644f}.pill{position:absolute;z-index:3;left:77px;top:594px;background:#2c4938;color:#fff7e6;padding:18px 29px;border-radius:40px;font-size:23px}.privacy .copy p{font-size:30px}.seal{position:absolute;left:140px;top:675px;width:800px;height:760px}.privacy-label{position:absolute;left:100px;right:100px;bottom:157px;display:flex;gap:24px}.feature{background:#ffffff88;border:1px solid #ffffff;border-radius:30px;flex:1;padding:35px 28px;font-size:24px;line-height:1.4;text-align:center}.feature strong{font-size:27px;display:block;margin-bottom:12px}
 .tag{display:none}.hero h1{font-size:88px;letter-spacing:-4px}.hero .copy p{font-size:32px}.hero-art{mask-image:linear-gradient(to bottom,transparent,#000 12%,#000 86%,transparent)}
`;
const shield=`<svg class="seal" viewBox="0 0 800 760"><defs><linearGradient id="g" x2="1" y2="1"><stop stop-color="#42634a"/><stop offset="1" stop-color="#173e30"/></linearGradient><linearGradient id="y" x2="1" y2="1"><stop stop-color="#ffd272"/><stop offset="1" stop-color="#f2a329"/></linearGradient><filter id="s"><feDropShadow dx="0" dy="30" stdDeviation="24" flood-color="#876b2d" flood-opacity=".18"/></filter></defs><circle cx="400" cy="350" r="300" fill="none" stroke="#dac998"/><circle cx="400" cy="350" r="355" fill="none" stroke="#e8d9b9"/><path d="M400 90 Q480 160 610 170 L610 355 Q610 530 400 628 Q190 530 190 355 L190 170 Q320 160 400 90" fill="url(#g)" filter="url(#s)"/><path d="M400 115 Q475 178 586 190 L586 350 Q586 509 400 600 Q214 509 214 350 L214 190 Q325 178 400 115" fill="none" stroke="#78917a" stroke-width="2"/><rect x="300" y="295" width="200" height="166" rx="34" fill="url(#y)"/><path d="M342 295 V261 A58 58 0 0 1 458 261 V295" fill="none" stroke="#ffd889" stroke-width="25"/><circle cx="400" cy="365" r="19" fill="#31503d"/><path d="M400 377V405" stroke="#31503d" stroke-width="16" stroke-linecap="round"/><circle cx="650" cy="508" r="61" fill="#f9c654"/><path d="m621 508 20 20 39-44" stroke="#31503d" stroke-width="11" fill="none" stroke-linecap="round" stroke-linejoin="round"/><circle cx="142" cy="210" r="20" fill="#f4b53f"/><circle cx="659" cy="180" r="10" fill="#809574"/></svg>`;
const browser=await chromium.launch({executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',headless:true});
const page=await browser.newPage({viewport:{width:1080,height:1920},deviceScaleFactor:1});
const htmls=[];
for(let i=0;i<specs.length;i++){
 const [name,title,subtitle,screen]=specs[i];
 let art=screen==='hero'?`<span class="pill">Личный учёт финансов</span><img class="hero-art" src="${hero}"><div class="hero-foot"><span>Счета и операции</span><span>Бюджеты</span><span>Статистика</span></div>`:screen==='privacy'?`${shield}<div class="privacy-label"><div class="feature"><strong>Копия в Excel</strong>Сохраните свои записи</div><div class="feature"><strong>Без интернета</strong>Ведите учёт офлайн</div></div>`:`<div class="phone"><div class="side"></div><div class="screen"><img src="${await data('screenshots/'+screen+'.png')}"></div></div><div class="tag">МАНГО БАЛАНС · ЛИЧНЫЕ ФИНАНСЫ</div>`;
 const content=`<div class="card ${screen}"><div class="curve"></div><div class="brand"><img src="${icon}">Манго Баланс</div><div class="count">0${i+1} / 08</div><div class="copy"><h1>${title}</h1><p>${subtitle}</p></div>${art}</div>`;
 htmls.push(content);
 await page.setContent(`<meta charset="utf-8"><style>${css}</style>${content}`);
 await page.evaluate(()=>Promise.all([...document.images].map(i=>i.decode())));
 const headingHeight=await page.locator('h1').evaluate(e=>e.getBoundingClientRect().height);
 if(headingHeight>210)throw new Error(name+': unexpected heading wrapping '+headingHeight);
 await page.screenshot({path:path.join(root,'cards',name+'.jpg'),type:'jpeg',quality:95});
 console.log(name);
}
await fs.writeFile(path.join(root,'source','cards.html'),`<!doctype html><html lang="ru"><meta charset="utf-8"><title>Манго Баланс — RuStore</title><style>${css}body{display:flex;gap:40px;flex-wrap:wrap;padding:40px}.card{flex:none}</style>${htmls.join('')}</html>`);
await page.setViewportSize({width:1500,height:1320});
await page.setContent(`<meta charset="utf-8"><style>${css}body{display:grid;grid-template-columns:repeat(4,360px);gap:20px;padding:0 0 20px;background:#e9dfcb}.card{zoom:0.333333333}</style>${htmls.join('')}`);
await page.evaluate(()=>Promise.all([...document.images].map(i=>i.decode())));
await page.screenshot({path:path.join(root,'preview.jpg'),type:'jpeg',quality:93,fullPage:true});
await browser.close();
