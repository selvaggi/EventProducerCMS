# EventProducer

This repository contains a condor script that will generate and produce MINIAOD and NANOAOD samples withb setup corresponding to the UL16/UL17 and UL18 campaigns. 
The only required inputs are a generator fragment (a possibly a gridpack). 

Clone repository:


```bash
git clone git@github.com:selvaggi/EventProducerCMS.git
cd EventProducerCMS
```

Create a gen fragment (see in ```fragments``` directory for examples).


Create a proxy (need to query DBS for MinBias pile for pile-up mixing):

```bash
source init.sh
```


The script options are:

```
submitCondorProduction.py [-h] [--fragment FRAGMENT] [--outdir OUTDIR]
                                 [--procname PROCNAME] [--era ERA]
                                 [--njobs NJOBS] [--nev NEV] [--queue QUEUE]
                                 [--cpu CPU] [--dry]
```


For example, submit 1k UL18 events splitted in 10 jobs on the testmatch (2days) queue, 10 events/job, using 2cpus per jobs):

```bash
python submitCondorProduction.py --fragment fragments/cH_HToGammaGamma_NLO_MG5aMCatNLO_13TeV_cff.py \
  --outdir /eos/cms/store/cmst3/user/selvaggi/samples/ \
  --procname cH_HToGammaGamma_NLO_MG5aMCatNLO_13TeV \
  --era UL18 \
  --njobs 10 \
  --nev 10 \
  --queue testmatch \
  --cpu 2 \
  --dry
```

Add the ```--dry``` option to simply create condor submit file without executing it.
