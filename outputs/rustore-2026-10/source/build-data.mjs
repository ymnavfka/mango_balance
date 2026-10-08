import fs from 'node:fs/promises';
import path from 'node:path';
import {Workbook, SpreadsheetFile} from '@oai/artifact-tool';
const out=path.resolve(import.meta.dirname,'..');
const profiles=[[1,'Моя жизнь','Да'],[2,'Наш дом','Нет'],[3,'Творческая студия','Нет']];
const accounts=[[1,1,'На каждый день',0,'Да'],[2,1,'Наличные',0,'Нет'],[3,1,'Подушка спокойствия',0,'Нет'],[4,1,'На море',0,'Нет'],[5,2,'Общий счёт',45000,'Да'],[6,3,'Счёт студии',28000,'Да']];
const categories=[];
function cat(id,p,n,t='expense',fb='Нет'){categories.push([id,p,n,t,fb]);}
['Продукты','Кафе и кофе','Транспорт','Дом и уют','Здоровье','Впечатления','Покупки','Подписки'].forEach((n,i)=>cat(i+1,1,n));
cat(9,1,'Другое','expense','Да');cat(10,1,'Зарплата','income');cat(11,1,'Любимое дело','income');cat(12,1,'Кэшбэк','income');cat(13,1,'Другие доходы','income','Да');cat(14,1,'Перевод','transfer','Да');
cat(21,2,'Продукты');cat(22,2,'Дом');cat(23,2,'Семейные выходные');cat(24,2,'Пополнение бюджета','income','Да');cat(25,2,'Другое','expense','Да');cat(26,2,'Перевод','transfer','Да');
cat(31,3,'Проекты','income','Да');cat(32,3,'Рабочие инструменты');cat(33,3,'Обучение');cat(34,3,'Другое','expense','Да');cat(35,3,'Перевод','transfer','Да');
const cName=Object.fromEntries(categories.map(c=>[c[0],c[2]]));
const aName=Object.fromEntries(accounts.map(a=>[a[0],a[2]]));
const expenses=[],incomes=[],transfers=[];
const date=(m,d,h=12)=>new Date(Date.UTC(2026,m-1,d,h));
function tx(type,p,m,d,c,a,amount,comment,h=12){(type==='expense'?expenses:incomes).push([p,date(m,d,h),c,cName[c],a,aName[a],amount,comment]);}
function spend(m,d,c,v,comment,a=1,p=1,h=12){tx('expense',p,m,d,c,a,v,comment,h);}
function earn(m,d,c,v,comment,a=1,p=1){tx('income',p,m,d,c,a,v,comment);}
function transfer(m,d,from,to,v,comment){transfers.push([1,date(m,d,18),from,aName[from],to,aName[to],v,comment]);}
const patterns={
  1:['Продукты на неделю','Овощи на рынке','Ужин дома','Завтраки на неделю','Фрукты и ягоды','Закупка к выходным'],
  2:['Кофе по дороге','Обед с коллегами','Ужин с друзьями','Кофейня у парка','Пицца и кино дома','Завтрак в городе'],
  3:['Проездной','Такси после театра','Поездка к друзьям'],
  5:['Аптека','Абонемент в бассейн'],6:['Книга на выходные','Билеты в театр','Мастер-класс'],7:['Вещи на сезон','Подарок себе']};
function spread(m,c,total,count){let left=total;for(let i=0;i<count;i++){const v=i===count-1?left:Math.round(total/count*(0.78+(i%3)*.22)/10)*10;left-=v;spend(m,2+Math.floor(i*26/count),c,v,patterns[c][i%patterns[c].length],c===3?2:1);}}
for(let m=4;m<=9;m++){
  const i=m-4;
  earn(m,5,10,57000,'Зарплата');earn(m,20,10,38000,'Аванс');
  earn(m,18,11,[6000,8500,7000,12000,9000,10000][i],'Иллюстрации для проекта');earn(m,28,12,[640,720,580,810,760,690][i],'Кэшбэк за покупки');
  spread(m,1,[19700,21300,20600,22100,20900,19200][i],8);
  spread(m,2,[9400,8800,10200,9200,7600,6200][i],9);
  spread(m,3,4200,3);spread(m,5,[2500,4200,3500,3000,2700,3400][i],2);
  spread(m,6,[3600,4800,3200,5400,4600,5800][i],3);spread(m,7,[6000,4200,8500,4900,7200,3900][i],2);
  spend(m,1,4,32000,'Аренда квартиры');spend(m,12,4,890,'Домашний интернет');spend(m,10,8,349,'Музыка');spend(m,15,8,499,'Онлайн-кинотеатр');
  transfer(m,5,1,3,15000,'Пополняю подушку');transfer(m,20,1,4,8000,'На море без кредита');transfer(m,1,1,2,4000,'Наличные на месяц');
  earn(m,3,24,34000,'В общий бюджет',5,2);spend(m,8,21,14600,'Большая закупка',5,2);spend(m,10,22,6900,'Коммунальные услуги',5,2);spend(m,22,23,4200,'Выходные за городом',5,2);
  earn(m,10,31,24000,'Айдентика кофейни',6,3);spend(m,12,32,2400,'Сервисы для работы',6,3);spend(m,18,33,3900,'Курс по иллюстрации',6,3);
}
// Текущая неделя: ручная режиссура реальных повседневных ситуаций.
spend(10,1,4,32000,'Аренда квартиры');spend(10,1,1,2360,'Продукты на неделю');transfer(10,1,1,2,4000,'Наличные на месяц');
spend(10,2,2,420,'Кофе и круассан');spend(10,2,3,1800,'Проездной',2);spend(10,3,1,1840,'Овощи, сыр и фрукты');spend(10,3,6,2400,'Театр в субботу');
spend(10,4,5,2800,'Абонемент в бассейн');spend(10,4,2,1280,'Завтрак с друзьями');earn(10,5,10,57000,'Зарплата');
transfer(10,5,1,3,15000,'Ещё шаг к спокойствию');transfer(10,5,1,4,4000,'Ближе к морю');
spend(10,5,1,2190,'Ужины на неделю');spend(10,6,7,3490,'Кроссовки для прогулок');spend(10,6,3,380,'Такси после дождя',2);spend(10,6,2,690,'Обед с коллегами');
spend(10,7,1,1260,'Продукты к ужину',1,1,9);spend(10,7,2,290,'Капучино по дороге',1,1,8);
earn(10,3,24,34000,'В общий бюджет',5,2);spend(10,4,21,5280,'Закупка на неделю',5,2);spend(10,5,23,2200,'Семейный день в музее',5,2);
earn(10,5,31,18000,'Обложки для подкаста',6,3);spend(10,6,32,2400,'Сервисы для работы',6,3);
// Подбираем начальные остатки под внятные, сверяемые текущие суммы.
const targets={1:48500,2:3150,3:145000,4:52000};
for(const a of accounts.filter(a=>a[1]===1)){
 let delta=0;for(const r of incomes)if(r[4]===a[0])delta+=r[6];for(const r of expenses)if(r[4]===a[0])delta-=r[6];for(const r of transfers){if(r[2]===a[0])delta-=r[6];if(r[4]===a[0])delta+=r[6];}a[3]=targets[a[0]]-delta;if(a[3]<0)throw Error('Negative initial balance '+a[2]);
}
const budgets=[[1,1,'Комфортный месяц',85000,'month','Да'],[2,1,'Продукты',22000,'month','Нет'],[3,1,'Кафе без перебора',7000,'month','Нет'],[4,1,'Впечатления',8000,'month','Нет'],[5,2,'Наш месяц',34000,'month','Да']];
const links=[[2,1],[3,2],[4,6]];
const recurring=[
 [1,'Домашний интернет','expense',890,4,cName[4],1,aName[1],'month',1,date(4,12),date(10,12),'Да'],
 [1,'Музыка','expense',349,8,cName[8],1,aName[1],'month',1,date(4,10),date(10,10),'Да'],
 [1,'Онлайн-кинотеатр','expense',499,8,cName[8],1,aName[1],'month',1,date(4,15),date(10,15),'Да'],
 [1,'Аванс','income',38000,10,cName[10],1,aName[1],'month',1,date(4,20),date(10,20),'Да'],
 [1,'Аренда квартиры','expense',32000,4,cName[4],1,aName[1],'month',1,date(4,1),date(11,1),'Да'],
 [1,'Зарплата','income',57000,10,cName[10],1,aName[1],'month',1,date(4,5),date(11,5),'Да']];
const sheets={
 'Профили':[['ID','Название','Активный'],...profiles],
 'Счета':[['ID','ПрофильID','Название','Начальный баланс','По умолчанию'],...accounts],
 'Категории':[['ID','ПрофильID','Название','Тип','По умолчанию'],...categories],
 'Расходы':[['ПрофильID','Дата','КатегорияID','Категория','СчётID','Счёт','Сумма','Комментарий'],...expenses.sort((a,b)=>a[1]-b[1])],
 'Доходы':[['ПрофильID','Дата','КатегорияID','Категория','СчётID','Счёт','Сумма','Комментарий'],...incomes.sort((a,b)=>a[1]-b[1])],
 'Переводы':[['ПрофильID','Дата','Со счётаID','Со счёта','На счётID','На счёт','Сумма','Комментарий'],...transfers],
 'Бюджеты':[['ID','ПрофильID','Название','Лимит','Период','Все категории'],...budgets],
 'Бюджеты-Категории':[['БюджетID','КатегорияID'],...links],
 'Регулярные':[['ПрофильID','Название','Тип','Сумма','КатегорияID','Категория','СчётID','Счёт','Единица интервала','Шаг интервала','Дата начала','Дата следующего','Активен'],...recurring]
};
const wb=Workbook.create();
for(const [name,rows] of Object.entries(sheets)){
 const sh=wb.worksheets.add(name);sh.showGridLines=false;
 const r=sh.getRangeByIndexes(0,0,rows.length,rows[0].length);r.values=rows;r.format.font={name:'Arial',size:11};r.format.rowHeight=23;r.format.columnWidth=22;r.format.verticalAlignment='center';
 const head=sh.getRangeByIndexes(0,0,1,rows[0].length);head.format.fill='#294C3C';head.format.font={name:'Arial',bold:true,color:'#FFFFFF',size:11};head.format.rowHeight=34;
 sh.freezePanes.freezeRows(1);
 rows[0].forEach((h,i)=>{const col=sh.getRangeByIndexes(1,i,rows.length-1,1);if(h.includes('Дата')){col.setNumberFormat('dd.mm.yyyy hh:mm');col.format.columnWidth=24;}if(['Сумма','Лимит','Начальный баланс'].includes(h))col.setNumberFormat('#,##0.00');if(['Название','Категория','Счёт','Со счёта','На счёт','Комментарий'].includes(h))col.format.columnWidth=32;});
}
wb.recalculate();
await fs.writeFile(path.join(out,'source/demo-data.json'),JSON.stringify({asOf:'2026-10-07',sheets,targets},null,2));
const xlsx=await SpreadsheetFile.exportXlsx(wb);await xlsx.save(path.join(out,'mango-demo.xlsx'));
for(const name of Object.keys(sheets)){
 const n=Math.min(sheets[name].length,7),end=String.fromCharCode(64+sheets[name][0].length);
 const png=await wb.render({sheetName:name,range:`A1:${end}${n}`,scale:1,format:'png'});
 await fs.writeFile(path.join(out,'qa',name+'.png'),new Uint8Array(await png.arrayBuffer()));
}
console.log(JSON.stringify({profiles:profiles.length,accounts:accounts.length,categories:categories.length,expenses:expenses.length,incomes:incomes.length,transfers:transfers.length,budgets:budgets.length,recurring:recurring.length,targets},null,2));
