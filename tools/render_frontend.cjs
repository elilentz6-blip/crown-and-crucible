// Visual QA of the actual GML frontend draw function, using the repo's bitmap fonts and sprites.
// Optional dev dependency: @napi-rs/canvas. This does not emulate the GameMaker runtime.
const {createCanvas,loadImage}=require('@napi-rs/canvas');
const {createGame,ROOT}=require('../tests/harness/gml.cjs');
const fs=require('node:fs'),path=require('node:path');
async function main(){
 const g=createGame(),canvas=createCanvas(1366,768),ctx=canvas.getContext('2d');
 const records=[],lookup=new Map(),tints=new Map();let alpha=1,color=0xffffff;
 const names=['spr_front_logo','spr_front_emblem','spr_front_parchment','spr_loading_greenmere','spr_loading_oakhaven','spr_loading_dunhollow',
   'spr_ui_font_body','spr_ui_font_small','spr_ui_font_title'];
 for(const name of names){
  const folder=path.join(ROOT,'sprites',name),d=JSON.parse(fs.readFileSync(path.join(folder,name+'.yy'),'utf8'));
  const frames=await Promise.all(d.frames.map(f=>loadImage(path.join(folder,f.name+'.png'))));
  const id=records.length;records.push({d,frames});lookup.set(name,id);g[name]=id;
 }
 const rgb=c=>`rgb(${c&255},${(c>>>8)&255},${(c>>>16)&255})`;
 function imageFor(id,sub,col){
  const r=records[id];if(!r)throw Error('Unknown sprite '+id);
  const frame=r.frames[Math.floor(sub)%r.frames.length];
  if(col===0xffffff)return frame;
  const key=[id,sub,col].join(':');if(tints.has(key))return tints.get(key);
  const c=createCanvas(frame.width,frame.height),x=c.getContext('2d');x.drawImage(frame,0,0);
  x.globalCompositeOperation='source-in';x.fillStyle=rgb(col);x.fillRect(0,0,c.width,c.height);tints.set(key,c);return c;
 }
 g.asset_get_index=n=>lookup.get(n)??-1;
 g.sprite_get_width=id=>records[id].d.width;g.sprite_get_height=id=>records[id].d.height;
 g.draw_get_alpha=()=>alpha;g.draw_set_alpha=a=>{alpha=a;};g.draw_set_color=c=>{color=c;};
 g.draw_rectangle=(x1,y1,x2,y2,outline)=>{ctx.save();ctx.globalAlpha=alpha;ctx.fillStyle=ctx.strokeStyle=rgb(color);if(outline)ctx.strokeRect(x1,y1,x2-x1,y2-y1);else ctx.fillRect(x1,y1,x2-x1,y2-y1);ctx.restore();};
 g.draw_sprite_ext=(id,sub,x,y,sx,sy,rotation,col,a)=>{
  const r=records[id],img=imageFor(id,sub,col);ctx.save();ctx.globalAlpha=a;
  ctx.imageSmoothingEnabled=!r.d.name.startsWith('spr_ui_font');ctx.translate(x,y);ctx.rotate(-rotation*Math.PI/180);ctx.scale(sx,sy);
  ctx.drawImage(img,-r.d.sequence.xorigin,-r.d.sequence.yorigin);ctx.restore();
 };
 g.draw_sprite_part_ext=(id,sub,l,t,w,h,x,y,sx,sy,col,a)=>{ctx.save();ctx.globalAlpha=a;ctx.drawImage(imageFor(id,sub,col),l,t,w,h,x,y,w*sx,h*sy);ctx.restore();};
 g.frontend_init(true);
 const out=path.resolve(process.argv[2]||path.join(ROOT,'qa_artifacts/frontend'));fs.mkdirSync(out,{recursive:true});
 for(const [name,setup] of [
  ['splash',()=>{Object.assign(g.global.frontend,{phase:'splash',elapsed:1});}],
  ['title',()=>{Object.assign(g.global.frontend,{phase:'title',art:0,cursor:1,tip:15});}],
  ['loading_oakhaven',()=>{Object.assign(g.global.frontend,{phase:'loading',art:1,tip:19,status:'Preparing the roads and settlements'});}],
  ['loading_dunhollow',()=>{Object.assign(g.global.frontend,{phase:'loading',art:2,tip:22,status:'Reading the saved journey'});}],
  ['controls',()=>{Object.assign(g.global.frontend,{phase:'controls',tip:9});}],
  ['load_confirmation',()=>{Object.assign(g.global.frontend,{phase:'confirm_load',cursor:1,tip:24});}],
 ]){
  setup();const state=JSON.stringify(g.global.frontend);ctx.clearRect(0,0,1366,768);g.frontend_draw();
  if(JSON.stringify(g.global.frontend)!==state)throw Error('Drawing mutated frontend state');
  fs.writeFileSync(path.join(out,name+'.png'),canvas.toBuffer('image/png'));
 }
 console.log('Rendered six screens from the GML draw code to '+out);
}
main().catch(e=>{console.error(e);process.exit(1);});
