import sys,os
from PIL import Image
ids=sys.argv[1].split(','); col=int(sys.argv[2]) if len(sys.argv)>2 else 0
out=Image.new("RGBA",(32*4*len(ids)+8*len(ids),48*1),(98,132,74,255))
x=0
sh=Image.open("shadow.png")
for i in ids:
    s=Image.open(f"{i}/{i}_sheet.png")
    for r in range(4):
        out.alpha_composite(sh,(x,0)); out.alpha_composite(s.crop((col*32,r*48,col*32+32,r*48+48)),(x,0)); x+=32
    x+=8
out.resize((out.width*5,out.height*5),Image.NEAREST).save(sys.argv[3] if len(sys.argv)>3 else "preview/zoom.png")
