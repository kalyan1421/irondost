"""Build the local review gallery and contact sheets from Flutter captures."""
from pathlib import Path
from html import escape
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
screens = [p.name.removesuffix('-light.png') for p in sorted((ROOT / 'before').glob('*-light.png'))]


def title(slug):
    return slug.replace('-', ' ').capitalize().replace('Otp', 'OTP')


cards = []
for slug in screens:
    name = title(slug)
    cards.append(f'''<article data-name="{escape(name.lower())}">
      <h3>{escape(name)}</h3><div class="pair">
      <figure><figcaption>Before</figcaption><a href="before/{slug}-light.png"><img loading="lazy" src="before/{slug}-light.png" alt="{escape(name)} before the refresh, light theme" data-title="{escape(name)} before the refresh"></a></figure>
      <figure><figcaption>Updated</figcaption><a href="after/{slug}-light.png"><img loading="lazy" src="after/{slug}-light.png" alt="{escape(name)} after the refresh, light theme" data-title="{escape(name)} after the refresh"></a></figure>
      </div></article>''')

supplements = []
for folder, name in [('checkout', 'Checkout states'), ('keyboard', 'Keyboard layouts'), ('keyboard-large', 'Keyboard layouts at 200% text'), ('states', 'Loading, empty and recovery')]:
    shots = []
    for path in sorted((ROOT / 'after' / folder).glob('*-light.png')):
        slug = path.name.removesuffix('-light.png')
        label = f'{title(slug)} — {name.lower()}'
        shots.append(f'<figure><figcaption>{escape(title(slug))}</figcaption><a href="after/{folder}/{path.name}"><img loading="lazy" src="after/{folder}/{path.name}" alt="{escape(label)}" data-title="{escape(label)}"></a></figure>')
    supplements.append(f'<details><summary>{name} ({len(shots)} views per theme)</summary><div class="supplement">{"".join(shots)}</div></details>')

page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>IronDost — mobile refresh review</title>
<style>
:root{color-scheme:light;font-family:system-ui,sans-serif;background:#f7f8fa;color:#0e1e3d}*{box-sizing:border-box}body{margin:0}main{max-width:1180px;margin:auto;padding:32px 20px 80px}h1{font-size:clamp(28px,5vw,44px);line-height:1.12;margin:12px 0 20px}h2{margin-top:40px}p{max-width:76ch;line-height:1.6}a{color:#1f4fd1}a:focus-visible,input:focus-visible,select:focus-visible,summary:focus-visible{outline:3px solid #1f4fd1;outline-offset:4px}.controls{display:flex;flex-wrap:wrap;gap:20px;margin:28px 0}label{display:grid;gap:8px;font-weight:600}input,select{font:inherit;padding:12px;border:1px solid #7d8ba3;border-radius:8px;background:white;color:#0e1e3d;max-width:100%}#gallery{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,500px),1fr));gap:24px}article,details{border:1px solid #dfe5ed;border-radius:12px;padding:20px;background:white}article[hidden]{display:none}.pair{display:grid;grid-template-columns:1fr 1fr;gap:12px}figure{margin:0;min-width:0}figcaption{font-size:14px;margin-bottom:12px;color:#526078}img{display:block;width:100%;height:auto;border-radius:4px}article img{border:1px solid #dfe5ed}summary{cursor:pointer;padding:4px;font-weight:600;min-height:44px}details{margin:16px 0}.supplement{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,230px),1fr));gap:20px;margin-top:20px}.type{max-width:900px}small{line-height:1.6;display:block;color:#526078}.links{display:flex;gap:20px;flex-wrap:wrap}@media(max-width:500px){main{padding:24px 12px}article{padding:12px}.pair{gap:8px}}
</style><main>
<small>IRON DOST · FLUTTER CUSTOMER APP · 1 NOVEMBER 2026</small>
<h1>Clean, friendly.<br>Still IronDost.</h1>
<p>Junction headings give the app a friendlier voice. Figtree keeps instructions, controls and prices familiar. Blue selection fills, clear estimates and quieter optional details make the booking journey easier to scan.</p>
<p>These captures render actual Flutter widgets with fake repositories. Dates, amounts and campaigns are fixture data. They do not represent live offers or prove native sign-in, maps, payments or screen-reader operation.</p>
<div class="links"><a href="../mobile-ui-ux-update-plan.md">Update plan</a><a href="README.md">Implementation and verification</a></div>
<details><summary>Typography comparison: A and F on three working screens</summary>
<p>Top: Charis headings adapted from A. Bottom: Junction headings adapted from F. Body text, controls and the baseline layout are held constant. These compare heading treatments; the original concept compositions remain unchanged. Junction was selected for the clean, friendly direction. This was a design review, not a user study.</p><a href="typography-comparison.jpg"><img class="type" src="typography-comparison.jpg" alt="Charis and Junction heading comparisons on Home, Catalogue and Checkout"></a></details>
<h2>All 47 representative views</h2><p>Select a theme and filter by screen name. Open an image to inspect it at full resolution.</p>
<div class="controls"><label>Theme<select id="theme"><option value="light">Light</option><option value="dark">Dark</option></select></label><label>Find a screen<input id="filter" type="search" placeholder="e.g. checkout, address, order"></label></div>
<p id="count" role="status">47 views</p><section id="gallery">__CARDS__</section>
<h2>Additional states</h2>__SUPPLEMENTS__<details><summary>Native iOS simulator launch</summary><p>The development bundle opens to the offline recovery screen because its local API is unavailable. This verifies launch and the native frame only.</p><a href="native-ios.png"><img style="max-width:350px" src="native-ios.png" alt="iOS simulator showing the offline recovery screen with native safe areas"></a></details>
<script>
const theme=document.getElementById('theme');
theme.addEventListener('change',()=>{for(const img of document.querySelectorAll('img[data-title]')){img.src=img.getAttribute('src').replace(/-(light|dark)\.png$/,'-'+theme.value+'.png');img.alt=img.dataset.title+', '+theme.value+' theme';img.parentElement.href=img.src;}});
document.getElementById('filter').addEventListener('input',event=>{let count=0;for(const card of document.querySelectorAll('article[data-name]')){card.hidden=!card.dataset.name.includes(event.target.value.trim().toLowerCase());if(!card.hidden)count++;}document.getElementById('count').textContent=count+(count===1?' view':' views');});
</script></main></html>'''
(ROOT / 'index.html').write_text(page.replace('__CARDS__', ''.join(cards)).replace('__SUPPLEMENTS__', ''.join(supplements)))

for theme in ['light', 'dark']:
    files = sorted((ROOT / 'after').glob(f'*-{theme}.png'))
    for offset in range(0, len(files), 12):
        sheet = Image.new('RGB', (1000, 1380), '#dfe5ed')
        draw = ImageDraw.Draw(sheet)
        for i, path in enumerate(files[offset:offset + 12]):
            shot = Image.open(path).convert('RGB')
            shot.thumbnail((246, 422))
            x, y = (i % 4) * 250, (i // 4) * 460
            sheet.paste(shot, (x, y + 24))
            draw.text((x + 4, y + 5), path.stem, fill='#0e1e3d')
        sheet.save(ROOT / f'updated-{theme}-{offset // 12 + 1}.jpg')

preview = Image.new('RGB', (1170, 880), '#dfe5ed')
draw = ImageDraw.Draw(preview)
for col, slug in enumerate(['home', 'catalogue', 'checkout']):
    shot = Image.open(ROOT / 'after' / f'{slug}-light.png').convert('RGB')
    shot.thumbnail((386, 836))
    preview.paste(shot, (col * 390, 32))
    draw.text((col * 390 + 8, 10), title(slug), fill='#0e1e3d')
preview.save(ROOT / 'preview.jpg')
print(f'Built gallery for {len(screens)} views and supplemental captures.')
