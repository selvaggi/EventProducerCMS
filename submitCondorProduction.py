#!/usr/bin/env python
import os, sys, subprocess
import argparse
import commands
import time
import random

#_____________________________________________________________________________________________________________
def main():
    parser = argparse.ArgumentParser()

    parser.add_argument ('--fragment', help='MC fragment',  default='fragments/cH_HToGammaGamma_NLO_MG5aMCatNLO_13TeV_cff.py')
    parser.add_argument ('--outdir', help='output directory e.g. ', default='/eos/cms/store/cmst3/group/vhcc/hc/samples/')
    parser.add_argument ('--procname', help='process name', default='cH_HToGammaGamma_NLO_MG5aMCatNLO_13TeV')
    parser.add_argument ('--era', help='UL16/UL17/UL18', default='UL18')
    parser.add_argument ('--njobs', help='number of jobs ', type=int, default=10)
    parser.add_argument ('--nev', help='number of events per job', type=int, default=10)
    parser.add_argument ('--queue', help='run time (espresso, microcentury, longlunch, workday, tomorrow, testmatch, nextweek)',
                      dest='queue', default='tomorrow')

    parser.add_argument ('--cpu', help='number of CPUs (1 cpu = 2 gb RAM)', default='2')
    parser.add_argument('--dry', help='', dest="dry", default=False, action='store_true')


    args = parser.parse_args()

    fragment      = os.path.abspath(args.fragment)
    procname      = args.procname
    era           = args.era
    outdir        = os.path.abspath(args.outdir)+'/'
    queue         = args.queue
    cpu           = args.cpu

    #if era != 'UL16' and era != 'UL17' and era != 'UL18':
    if era != 'UL16' and era != 'UL17' and era != 'UL18':
        #print 'provide UL16/UL17/UL18 era option. '
        print 'provide UL18 era option. '
        sys.exit()

    ## setting up proxy
    print 'Getting proxy ... '
    proxyPath=os.popen('voms-proxy-info -path')
    proxyPath=proxyPath.readline().strip()
    print 'ProxyPath:',proxyPath
    if 'tmp' in proxyPath: 
        print 'Run source environment.(c)sh and make a new proxy!'
        exit(1)


    script = 'generate.sh'
    jobsdir = './BatchOutput/' + args.procname

    if not os.path.exists(jobsdir):
       os.makedirs(jobsdir)
       os.makedirs(jobsdir+'/stderr/')
       os.makedirs(jobsdir+'/stdout/')
       os.makedirs(jobsdir+'/log/')

    jobCount=0

    queuestr = '"{}"'.format(queue)

    cmdfile="""# here goes your shell script
use_x509userproxy = true
x509userproxy = {}

executable    = {}

# here you specify where to put .log, .out and .err files
output                = {}/stderr/condor.$(ClusterId).$(ProcId).err
error                 = {}/stdout/condor.$(ClusterId).$(ProcId).out
log                   = {}/log/condor.$(ClusterId).log

+AccountingGroup = "group_u_CMST3.all"
+JobFlavour = {}
RequestCpus = {}
""".format(proxyPath,script,jobsdir,jobsdir,jobsdir,queuestr,cpu)
    
    for job in xrange(args.njobs):

       seed=str(job)+1

       cmdfile += 'arguments="{} {} {} {} {} {} {}"\n'.format(era, str(args.nev), seed, fragment, outdir, procname, cpu)
       cmdfile += 'queue\n'

    condor_filename='condor_{}_{}.sub'.format(procname,era)
    with open(condor_filename, "w") as f:
        f.write(cmdfile)

    print ''
    print 'submit condor command:'
    print ''
    print 'condor_submit {}'.format(condor_filename)
    print ''
    
    # submitting jobs
    if not args.dry: 

        print 'Submitting jobs ...'
        os.system('condor_submit {}'.format(condor_filename))
        print 'done. '

#_______________________________________________________________________________________
if __name__ == "__main__":
    main()

