from pathlib import Path
import json,subprocess
import argparse,shutil,os
project_root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(description="Test catalog rename loading and save compatibility; run with the Godot editor closed.")
parser.add_argument('--godot', default=os.environ.get('GODOT_BIN','godot'))
args=parser.parse_args()
godot=shutil.which(args.godot) or args.godot
r=project_root/'data/catalog' 
edits={'items':{'iron_sword':{'name':'QA Goblin Blade','attack':19}},'classes':{'blade':{'name':'QA Blade Class','speed':230.0}},'rooms':{'room_0':{'name':'QA Safe Den'}},'spells':{'heal':{'name':'QA Mend','heal':45}},'monsters':{'campaign_0_2_0_iron_captain':{'name':'QA Captain','hp':195}},'npcs':{'den_keeper':{'name':'QA Den Keeper'}}}
originals={}
try:
 for cat,changes in edits.items():
  p=r/(cat+'.json');originals[p]=p.read_bytes();d=json.loads(originals[p])
  for row in d['records']:
   if row['id'] in changes:row.update(changes[row['id']])
  p.write_text(json.dumps(d,indent=2)+'\n')
 log_path=project_root/'catalog-runtime-test.log'
 with log_path.open('w') as log:
  result=subprocess.run([godot,'--headless','--path',str(project_root),'-s','tests/catalog_runtime_test.gd'],stdout=log,stderr=subprocess.STDOUT,timeout=35)
 print(log_path.read_text()[-3500:])
 print('Exit code:',result.returncode)
finally:
 for p,b in originals.items():p.write_bytes(b)

raise SystemExit(result.returncode)
