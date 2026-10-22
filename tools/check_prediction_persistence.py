#!/usr/bin/env python3
"""Compile a producer, then a separate consumer with models and new rows only."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys

ROOT=Path(__file__).resolve().parent.parent

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--compiler',default='fpc')
    parser.add_argument('--work-dir',type=Path,default=ROOT/'build-temp/prediction-persistence')
    args=parser.parse_args()
    work=args.work_dir.resolve(); work.mkdir(parents=True,exist_ok=True)
    def run(name,command,cwd):
        result=subprocess.run([str(x) for x in command],cwd=cwd,
            stdin=subprocess.DEVNULL,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,
            encoding='utf-8',errors='replace',timeout=180,check=False)
        (work/(name+'.log')).write_text(result.stdout,encoding='utf-8')
        if result.returncode: raise RuntimeError(name+' failed:\n'+result.stdout[-6000:])
        return result.stdout
    def compile_program(name,source,directory):
        units=directory/'units'; units.mkdir(parents=True,exist_ok=True)
        run(name+'-compile',[args.compiler,'-B','-O2','-FcUTF8',
            '-Fu'+str(ROOT/'src'),'-FU'+str(units),'-FE'+str(directory),source],directory)
        return directory/(source.stem+('.exe' if os.name=='nt' else ''))
    evidence={'status':'failed','checks':[]}
    try:
        producer_dir=work/'producer'; consumer_dir=work/'consumer'
        producer_dir.mkdir(exist_ok=True); consumer_dir.mkdir(exist_ok=True)
        producer=compile_program('producer',ROOT/'examples/51_prediction_persistence.pas',producer_dir)
        artifacts=producer_dir/'artifacts'
        output=run('producer-run',[producer,artifacts],producer_dir)
        if 'prediction persistence: success' not in output: raise RuntimeError('producer marker missing')
        source=consumer_dir/'PredictionConsumer.lpr'
        shutil.copyfile(ROOT/'tests/consumers/PredictionConsumer.lpr',source)
        models=[]
        for name in ['glm.mfpmodel','pls.mfpmodel']:
            target=consumer_dir/name; shutil.copyfile(artifacts/name,target); models.append(target)
        consumer=compile_program('consumer',source,consumer_dir)
        output=run('consumer-run',[consumer,*models],consumer_dir)
        if 'artifact-only predictions: GLM=8.000000; PLS=223.000000' not in output or \
            'prediction-only consumer: success' not in output:
            raise RuntimeError('consumer numerical output or marker missing')
        evidence={'status':'passed','checks':['separate compiled consumer',
            'artifacts and new observations only; no training data copied',
            'GLM expected count with new exposure','PLS original-unit prediction'],
            'consumer_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
            'artifacts':{p.name:{'bytes':p.stat().st_size,
                'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in models}}
    except (OSError,RuntimeError,subprocess.TimeoutExpired) as error:
        evidence['error']=str(error)
        print(error,file=sys.stderr)
    (work/'results.json').write_text(json.dumps(evidence,indent=2)+'\n',encoding='utf-8')
    if evidence['status']!='passed': return 1
    print('Prediction persistence consumer passed; results written to',work/'results.json')
    return 0

if __name__=='__main__':
    raise SystemExit(main())
