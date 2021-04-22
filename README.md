Clone:


```
git clone git@github.com:selvaggi/EventProducerCMS.git
cd EventProducerCMS
```

Create proxy (need to query DBS for MinBias pile for pile-up mixing):

```
'voms-proxy-init --rfc --voms cms'
```

Submit jobs, e.g 100k UL18 events splitted in 1k jobs on the testmatch (2days) queue, 100 events/job, using 2cpus per jobs):

```
python submitCondorProduction.py --fragment fragments/cH_HToGammaGamma_NLO_MG5aMCatNLO_13TeV_cff.py --outdir /eos/cms/store/cmst3/user/selvaggi/samples/ --procname cH_HToGammaGamma_NLO_MG5aMCatNLO_13TeV --era UL18 --njobs 1000 --nev 100 --queue testmatch --cpu 2
```

Add the ```--dry``` option to simply create condor submit file without executing it.
