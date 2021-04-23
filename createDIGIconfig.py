#!/usr/bin/env python
import os, sys, subprocess

#--pileup_input 'dbs:/Neutrino_E-10_gun/RunIISummer19ULPrePremix-UL18_106X_upgrade2018_realistic_v11_L1v1-v2/PREMIX' /

cmd_UL18 = """
CMSREL="CMSSW_10_6_4_patch1";
scram p CMSSW ${CMSREL};
cd ${CMSREL}/src;
eval `scramv1 runtime -sh`;

cmsDriver.py --python_filename='config_DIGI_UL18.py' --filein file:step_SIM.root --fileout file:step_DIGI.root --pileup_input 'dbs:/Neutrino_E-10_gun/RunIISummer19ULPrePremix-UL18_106X_upgrade2018_realistic_v11_L1v1-v2/PREMIX' --eventcontent PREMIXRAW --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN-SIM-DIGI --conditions 106X_upgrade2018_realistic_v11_L1v1 --step DIGI,DATAMIX,L1,DIGI2RAW --procModifiers premix_stage2 --geometry DB:Extended --datamix PreMix --era Run2_2018 --runUnscheduled --mc -n -1 --no_exec --nThreads 4;

cp config_DIGI_UL18.py ../../;
cd ../../;
rm -rf ${CMSREL};
"""


cmd_dict = {
    'UL18':cmd_UL18,
}


## setting up proxy
print 'Getting proxy ... '
proxyPath=os.popen('voms-proxy-info -path')
proxyPath=proxyPath.readline().strip()
print 'ProxyPath:',proxyPath
print ''
if 'tmp' in proxyPath: 
    print 'Run "source init.sh" first!'
    exit(1)


config_dir='./templates'
if not os.path.exists(config_dir):
   os.makedirs(config_dir)

os.chdir(config_dir)
for ul in cmd_dict.keys():       
    print cmd_dict[ul]
    os.system(cmd_dict[ul])
