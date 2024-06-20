#!/bin/bash

err="\n script to generate RADseq assemblies with a user specified range of between-samples Clustering Thresholds and a fixed intra-sample Clustering Threshold\n
	\n
arguments:\n 
	-h | --help : print this message and exit\n
	-n | --name : A prefix for output files\n
	-b | --bCT : the range of between-samples Clustering Thresholds to be tested. Values must be space-separated and given between quotation marks; e.g. -iCT '0.80 0.90' \n
	-w | --work : full path to the working directory, were the output files will be saved\n
	-i | --iCT : name of the parameter file used to run steps 1-6 of ipyrad (i.e. intra samples clustering) \n
	-T | --threads : number of threads to use. Default = 1\n
	-s | --scripts : path to a directory containing this script as well as harvest_stats.sh and 2_plot_iCT_stats.R\n
	-p | --tree : specify to infer ML trees\n
	-r | --ref : reference tree\n
	;
"

if [[ $# == 0 ]]
then
echo -e $err
exit 1
else
while [[ $# -gt 0 ]]
do
key="$1"

case "$key" in
	-h | --help)
	echo -e $err
	exit 1
	shift
	shift
	;;	
	-n | --name)
	NAME=$2
	shift
	shift
	;;
	-w | --work)
	WORK=$2
	shift
	shift
	;;
	-i | --iCT)
	ICT=$2
	shift
	shift
	;;
	-b | --bCT)
	BCT=$2
	shift
	shift
	;;
	-p | --tree)
	TREE=YES
	shift
	;;
	-s | --scripts)
	SCRIPTS=$2
	shift
	shift
	;;
	-T | --threads)
	THREADS=$2
	shift
	shift
	;;
	-r | --ref)
	REF=$2
	shift
	shift
	;;
	-h | --help)
	echo ${err}
	exit 1
	shift
	;;
esac
done
fi

#### PART 2: bCT ####

echo -e "\n ipyrad will be run with the following bCT(s): $BCT \n"

cd ${WORK}

echo ${BCT} | sed 's/ /\n/g' > bct.list

echo -e "generating the parameter files\n"

# This loop generates a parameter file for each bCT
for i in ${BCT}
do
t=$(echo ${i} | cut -d'.' -f2)
ipyrad -p ${ICT} -b ${NAME}_bCT_${t}

sed -r -i "s/^.*(\#\# \[14\].*)/${i} \1/" ${WORK}/params-${NAME}_bCT_${t}.txt

# these should be useless now (useful only if files are moved to a new directory) - kept just in case.
#sed -r -i "s@^.*(\#\# \[1\].*)@$WORK \1@" $WORK/params-"$NAME"_bCT_"$(echo $i | cut -d'.' -f2)"*
#sed -r -i "s@(.*_project_dir\":\").*(\"\,)@\1$WORK\2@" $WORK/"$NAME"_bCT_"$(echo $i | cut -d'.' -f2)".json
done

mkdir stats_bCT

for i in ${BCT}
do
echo -e "\n Starting steps 6 & 7 for bCT=${i}\n"
TN=$(echo ${i} | cut -d'.' -f2)
ipyrad -p params-${NAME}_bCT_${TN}.txt -s 67 -f -t ${THREADS}
cd ${NAME}_bCT_${TN}_outfiles
sed -n '/locus_coverage  sum_coverage/,/The distribution of SNPs (var and pis) per locus./p' *stats.txt | sed '/The distribution of SNPs (var and pis) per locus./d' | sed '/^$/d' > ../stats_bCT/${TN}_loci.txt
sed -n '/[[:space:]]*var[[:space:]]*sum_var[[:space:]]*pis[[:space:]]*sum_pis/,/## Final Sample stats summary/p' *stats.txt | sed '/## Final Sample stats summary/d' | sed '/^$/d' > ../stats_bCT/${TN}_var.txt
echo $(grep "snps matrix size" *stats.txt | cut -d',' -f3 | cut -d'%' -f1 | sed 's/ //g') $(grep "sequence matrix size" *stats.txt | cut -d',' -f3 | cut -d'%' -f1 | sed 's/ //g') ${TN} >> ../stats_bCT/missing_all_CT.txt
cd ..
done

bash ${SCRIPTS}/harvest_stats.sh -s 7 -i ${WORK}/stats_bCT

# plot stats

cd ${WORK}/stats_bCT
Rscript ${SCRIPTS}/4_Plot_bCT_stats.R ${WORK}/stats_bCT

echo "stats plots are stored in" $(ls ${WORK}/stats_bCT/*.pdf)

if [ -n "$TREE" ]
then
cd ${WORK}
mkdir trees_bCT
cp *bCT*outfiles/*.phy trees_bCT
cd trees_bCT
bash ${SCRIPTS}/5_infer_trees.sh -T ${THREADS} -b 3 -m GTRGAMMA
cat RAxML_bipartitions.* > bCT.trees 
Rscript ${SCRIPTS}/4-1_plot_bCT_trees.R ${WORK}/trees_bCT bCT.trees ${WORK}/bct.list ${REF}
echo "trees plots are stored in" $(ls ${WORK}/trees_bCT/*.pdf)
fi

echo -e "\n iCT RUNS SUCCESSFULLY COMPLETED \n"
