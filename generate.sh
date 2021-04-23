#!/bin/bash


#CMSREL="CMSSW_10_6_8"
#CMSREL_HLT="CMSSW_8_0_33_UL"


#ERA="UL18"
#EVENTS=5
#SEED=1111
#FRAGMENT="/afs/cern.ch/work/s/selvaggi/private/EventProducerCMS/fragments/cH_HToGammaGamma_NLO_MG5aMCatNLO_13TeV_cff.py"
#OUTDIR="/eos/cms/store/cmst3/user/selvaggi/samples/"
#JOBNAME="cH_HToGammaGamma_NLO_MG5aMCatNLO_13TeV"

ERA=${1}
EVENTS=${2}
SEED=${3}
FRAGMENT=${4}
OUTDIR=${5}
JOBNAME=${6}
NCPUS=${7}
HOMEDIR=${8}
PROXY=${9}
CFGDIGI=${10}


## the CMSSW releases depend on the era
CMSREL="CMSSW_10_6_4_patch1"
CMSREL_HLT="CMSSW_10_2_16_UL"
CMSREL_NANO="CMSSW_10_6_19_patch2"

### need to this to query das from condor job
echo "--------------------------------------------------------------------"
echo " CHECKING PROXY "
echo "-------------------------------------------------------------"
echo ""
echo ""

HOME=${HOMEDIR}
export X509_USER_PROXY=${PROXY}

voms-proxy-info -all
voms-proxy-info -all -file ${PROXY}


JOBID=${SEED}
JOBDIR=job_${JOBNAME}_${JOBID}
CFG="$(basename -- $FRAGMENT)"

OUTJOBDIR=${JOBNAME}_${ERA}
OUTPROCDIR=${OUTDIR}/${OUTJOBDIR}/
OUTPUTDIR_MINIAOD=${OUTPROCDIR}/MINIAOD/
OUTPUTDIR_NANOAOD=${OUTPROCDIR}/NANOAOD/
OUTFILE_MINIAOD=$OUTPUTDIR_MINIAOD/miniaod_${JOBID}.root
OUTFILE_NANOAOD=$OUTPUTDIR_NANOAOD/nanoaod_${JOBID}.root

JOBNAME="${f%.*}"

echo ""
echo ""
echo "--------------------------------------------------------------------"
echo "HOME          : " $HOME
echo "CMSREL        : " $CMSREL
echo "CMSREL_HLT    : " $CMSREL_HLT
echo "CMSREL_NANO   : " $CMSREL_NANO
echo "ERA           : " $ERA
echo "JOBID         : " $JOBID
echo "OUTPROCDIR    : " $OUTPROCDIR
echo "FRAGMENT      : " $FRAGMENT
echo "CFG           : " $CFG
echo "SEED          : " $SEED
echo "EVENTS        : " $EVENTS
echo "--------------------------------------------------------------------"

echo ""
echo ""
echo "-------------------------------------------------------------"
echo " RUNNING GEN STEP "
echo "-------------------------------------------------------------"
echo ""
echo ""


mkdir -p ${JOBDIR}
cd ${JOBDIR}

scram p CMSSW ${CMSREL}
cd ${CMSREL}/src
eval `scramv1 runtime -sh`
mkdir -p Configuration/GenProduction/python/
cp ${FRAGMENT} Configuration/GenProduction/python/
scram b -j 8


## step GEN
cmsDriver.py Configuration/GenProduction/python/${CFG} --eventcontent RAWSIM,LHE --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN,LHE --fileout file:step_GENLHE.root --conditions 106X_upgrade2018_realistic_v4 --beamspot Realistic25ns13TeVEarly2018Collision --step LHE,GEN --geometry DB:Extended --era Run2_2018  --mc -n $EVENTS  --customise_commands process.RandomNumberGeneratorService.externalLHEProducer.initialSeed="int(${SEED})" 

## step SIM

#cp ../../../step_GENLHE.root .

echo ""
echo ""
echo "-------------------------------------------------------------"
echo " RUNNING SIM STEP "
echo "-------------------------------------------------------------"
echo ""
echo ""


cmsDriver.py step1 --eventcontent RAWSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN-SIM --fileout file:step_SIM.root --conditions 106X_upgrade2018_realistic_v11_L1v1 --beamspot Realistic25ns13TeVEarly2018Collision --step SIM --geometry DB:Extended --filein file:step_GENLHE.root  --era Run2_2018 --runUnscheduled  --mc -n $EVENTS  --nThreads ${NCPUS}


##TBC: store PU file locally!

# step DIGI

echo ""
echo ""
echo "-------------------------------------------------------------"
echo " RUNNING DIGI STEP "
echo "-------------------------------------------------------------"
echo ""
echo ""


#cmsDriver.py step1 --eventcontent PREMIXRAW --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN-SIM-DIGI --fileout file:step_DIGI.root --pileup_input "dbs:/Neutrino_E-10_gun/RunIISummer19ULPrePremix-UL18_106X_upgrade2018_realistic_v11_L1v1-v2/PREMIX" --conditions 106X_upgrade2018_realistic_v11_L1v1 --step DIGI,DATAMIX,L1,DIGI2RAW --procModifiers premix_stage2 --geometry DB:Extended --filein file:step_SIM.root --datamix PreMix --era Run2_2018 --runUnscheduled --mc -n $EVENTS  --nThreads ${NCPUS}

cp ${CFGDIGI} .
cmsRun ${CFGDIGI}

## step HLT   



echo ""
echo ""
echo "-------------------------------------------------------------"
echo " RUNNING HLT STEP "
echo "-------------------------------------------------------------"

echo ""
echo ""

cd ../../
scram p CMSSW  ${CMSREL_HLT}
cd ${CMSREL_HLT}/src
eval `scramv1 runtime -sh`
scram b -j 8
cp ../../${CMSREL}/src/step_DIGI.root .


cmsDriver.py step1  --eventcontent RAWSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN-SIM-RAW --fileout file:step_HLT.root --conditions 102X_upgrade2018_realistic_v15 --customise_commands 'process.source.bypassVersionCheck = cms.untracked.bool(True)' --step HLT:2018v32 --geometry DB:Extended --filein file:step_DIGI.root --era Run2_2018 --mc -n $EVENTS  --nThreads ${NCPUS}

## step RECO  

echo ""
echo ""
echo "-------------------------------------------------------------"
echo " RUNNING RECO STEP "
echo "-------------------------------------------------------------"
echo ""
echo ""

cd ../../${CMSREL}/src
eval `scramv1 runtime -sh`
cp ../../${CMSREL_HLT}/src/step_HLT.root .

cmsDriver.py step1 --eventcontent AODSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier AODSIM --fileout file:step_RECO.root --conditions 106X_upgrade2018_realistic_v11_L1v1 --step RAW2DIGI,L1Reco,RECO,RECOSIM,EI --geometry DB:Extended --filein file:step_HLT.root --era Run2_2018 --runUnscheduled --mc -n $EVENTS  --nThreads ${NCPUS}

## step MiniAOD  


echo ""
echo ""
echo "-------------------------------------------------------------"
echo " RUNNING MINIAOD STEP "
echo "-------------------------------------------------------------"
echo ""
echo ""


cmsDriver.py step1 --eventcontent MINIAODSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier MINIAODSIM --fileout file:step_MINIAOD.root --conditions 106X_upgrade2018_realistic_v11_L1v1 --step PAT --geometry DB:Extended --filein file:step_RECO.root --era Run2_2018 --runUnscheduled --mc -n $EVENTS  --nThreads ${NCPUS}


## nano AOD


echo ""
echo ""
echo "-------------------------------------------------------------"
echo " RUNNING NANOAOD STEP "
echo "-------------------------------------------------------------"
echo ""
echo ""


cd ../../
scram p CMSSW  ${CMSREL_NANO}
cd ${CMSREL_NANO}/src
eval `scramv1 runtime -sh`
scram b -j 8
cp ../../${CMSREL}/src/step_MINIAOD.root .


cmsDriver.py step1 --eventcontent NANOEDMAODSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier NANOAODSIM --fileout file:step_NANOAOD.root --conditions 106X_upgrade2018_realistic_v15_L1v1 --step NANO --filein file:step_MINIAOD.root --era Run2_2018,run2_nanoAOD_106Xv1 --mc -n $EVENTS  --nThreads ${NCPUS}


## go back to main dir and copy here all produced root files
echo ""
echo ""
echo "copying root file in jobdir ..."

cd ../../
mv */*/*.root .

echo ""
echo "copying into ${OUTPROCDIR} ... "
## now copy on eos
mkdir -p $OUTPUTDIR_MINIAOD 
mkdir -p $OUTPUTDIR_NANOAOD

echo ${OUTFILE_MINIAOD}
echo ${OUTFILE_NANOAOD}

xrdcp -N -v step_MINIAOD.root root://eoscms.cern.ch/${OUTFILE_MINIAOD}
xrdcp -N -v step_NANOAOD.root root://eoscms.cern.ch/${OUTFILE_NANOAOD}

echo "job done." 

