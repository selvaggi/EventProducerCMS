voms-proxy-init --rfc --voms cms

tmppath=`voms-proxy-info -path`
f="$(basename -- $tmppath)"
cp $tmppath ${HOME}/
export X509_USER_PROXY=${HOME}/$f


echo 'proxy file location: ', $X509_USER_PROXY
