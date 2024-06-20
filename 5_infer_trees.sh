#!/bin/bash

err="\n script to generate RADseq assemblies with a user specified range of intra-sample Clustering Thresholds and a fixed between-samples Clustering Threshold\n
	\n
arguments:\n 
	-h | --help : print this message and exit\n
	-T | --threads : number of threads to use. Default = 1\n
	-b | --bootstrap : number of bootstrap replicates\n
	-m | --model : substitution model (see raxml manual)\n
	;
"

if [[ $# == 0 ]]
then
echo -e ${err}
exit 1
else
while [[ $# -gt 0 ]]
do
key="$1"
case "$key" in
	-T | --threads)
	THREADS=$2
	shift
	shift
	;;
	-b | --bootstrap)
	BOOT=$2
	shift
	shift
	;;
	-h | --help)
	echo -e ${err}
	exit 1
	shift
	shift
	;;
	-m | --model)
	MODEL=$2
	shift
	shift
	;;
esac
done
fi


RAXEX=$(compgen -c "raxml" | head -1)
if [ -z "$RAXEX" ]
then
echo "raxml was not found in the path, exiting"
exit 1
else

for i in *.phy
do
SEED1=${RANDOM}
SEED2=${RANDOM}
NAME=$(echo ${i} | sed 's/\.phy//')
echo "running ${NAME} with -p=${SEED1} and -x=${SEED2}" >> raxml_seeds.log
$RAXEX -s ${i} -m ${MODEL} -n ${NAME} -f a -# ${BOOT} -p ${SEED1} -x ${SEED2} -T ${THREADS}
done
fi

rm RAxML_bestTree* RAxML_bipartitionsBranchLabels* RAxML_bootstrap* RAxML_info*
