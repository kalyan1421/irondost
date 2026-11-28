from PIL import Image,ImageDraw,ImageFont
from pathlib import Path
import textwrap
root=Path('/Users/kalyan/Client-project/Irondost'); out=root/'docs/marketing/november-1-7-creatives'; out.mkdir(exist_ok=True)
font=root/'docs/ui-ux-audit/fonts/Outfit.ttf'; logo=root/'apps/customer/assets/brand/irondost-logo.png'; reverse=root/'apps/customer/assets/brand/irondost-logo-reverse.png'; iron=root/'apps/customer/assets/services/ironing-3d.png'; wash=root/'apps/customer/assets/services/wash-and-iron-3d.png'
ink='#0E1E3D'; blue='#1F4FD1'; light='#E6EEF8'; gold='#FFC93C'; white='#FFFFFF'
def f(sz):
 x=ImageFont.truetype(str(font),sz); x.set_variation_by_name("Bold" if sz>=70 else "Medium"); return x
def asset(im,path,box):
 img=Image.open(path).convert('RGBA'); img.thumbnail(box[2:],Image.Resampling.LANCZOS); im.alpha_composite(img,(box[0]+(box[2]-img.width)//2,box[1]+(box[3]-img.height)//2))
def text(d,xy,s,size,color,spacing=12):d.multiline_text(xy,s,font=f(size),fill=color,spacing=spacing,stroke_width=0)
def base(bg,day):
 im=Image.new('RGBA',(1080,1350),bg); d=ImageDraw.Draw(im); dark=bg==ink or bg==blue; asset(im,reverse if dark else logo,(60,55,370,110)); d.rounded_rectangle((785,75,1015,130),27,fill=gold); text(d,(820,82),day,27,ink); return im,d,white if dark else ink

def save(name,bg,day,kicker,title,desc,img=None,cta='WHATSAPP  90632 90012'):
 im,d,fg=base(bg,day); text(d,(70,215),kicker,28,fg); text(d,(70,285),title,83,fg,8); text(d,(72,565),desc,34,fg,9)
 if img:asset(im,img,(125,690,820,390))
 d.rounded_rectangle((65,1130,1015,1220),25,fill=gold); text(d,(105,1149),cta,39,ink); text(d,(75,1260),'LB NAGAR  •  CHECK SERVICE AVAILABILITY',25,fg); im.convert('RGB').save(out/name,quality=94)
save('nov-01-launch-cover.jpg',ink,'01 NOV','MEET YOUR LAUNDRY DOST','Laundry day,\nmade simpler.','Doorstep pickup for ironing\nand everyday laundry.',wash)
save('nov-02-services-01.jpg',light,'02 NOV','IRONING  /  WASH & IRON','What does your\nlaundry need?','Choose the service that fits\nyour clothes.',wash)
save('nov-02-services-02.jpg',white,'02 NOV','SERVICE 01','Already clean?\nJust iron.','Give your everyday clothes\na crisp finish.',iron)
save('nov-02-services-03.jpg',light,'02 NOV','SERVICE 02','Wash & iron,\nmade simple.','For clothes that need\na wash and a neat finish.',wash)
save('nov-02-services-04.jpg',blue,'02 NOV','LET’S GET STARTED','Tell us your\nlocality.','We’ll check your area, prices\nand available pickup slots.',None)
save('nov-03-how-to-book.jpg',white,'03 NOV','A FEW SIMPLE STEPS','Book your\npickup.','01  Share your locality\n02  Choose your service\n03  Confirm price & slots',iron)
save('nov-04-care.jpg',light,'04 NOV','CLOTHES DESERVE CARE','Care for the\nclothes you love.','Questions about your items?\nTalk to us before booking.',iron)
save('nov-05-faq.jpg',blue,'05 NOV','YOUR QUESTIONS, ANSWERED','What will my\norder cost?','Share your item list and locality.\nWe’ll provide the applicable quote.',None)
save('nov-06-diwali.jpg',ink,'06 NOV','DIWALI IS ALMOST HERE','Ready for\nthe festivities?','Ask about available pickup\nand return dates.',wash)
save('nov-07-lb-nagar.jpg',light,'07 NOV','HELLO, LB NAGAR','Your local\nlaundry dost.','Check service availability\nin your neighbourhood.',wash)
# Story adaptations contain the same message, formatted to 9:16.
for fp in sorted(p for p in out.glob('nov-*.jpg') if not p.stem.endswith('-story')):
 im=Image.open(fp).convert('RGB'); canvas=Image.new('RGB',(1080,1920),ink); im.thumbnail((1080,1350)); canvas.paste(im,(0,250)); d=ImageDraw.Draw(canvas); text(d,(90,1680),'MESSAGE US TO CHECK YOUR AREA',32,white); canvas.save(out/(fp.stem+'-story.jpg'),quality=94)
