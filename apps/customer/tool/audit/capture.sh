#!/bin/sh
# Opt-in audit renderer; does not call the real API or mutate customer accounts.
set -eu
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$script_dir/../.."
mkdir -p /tmp/irondost-audit-fonts ../../docs/ui-ux-audit/screens
python3 - <<'PY'
from pathlib import Path
from urllib.request import urlretrieve
import shutil
cache=Path('/tmp/irondost-audit-fonts')
for family,folder in [('Outfit','outfit'),('Figtree','figtree'),('Geist Mono','geistmono')]:
    filename=family.replace(' ','')+'%5Bwght%5D.ttf'
    dest=cache/(family+'.ttf')
    if not dest.exists():
        urlretrieve('https://raw.githubusercontent.com/google/fonts/main/ofl/'+folder+'/'+filename,dest)
flutter=Path(shutil.which('flutter')).resolve().parent.parent
shutil.copyfile(flutter/'bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',cache/'Roboto.ttf')
PY
flutter test tool/audit/capture_test.dart --reporter expanded "$@"
