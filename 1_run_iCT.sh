#!/bin/bash

## DEV NOTES
# add options for demultiplexed vs. multiplexed data
# add more options for param files (data type, ect)
	
err="\n script to generate RADseq assemblies with a user specified range of intra-sample Clustering Thresholds and a fixed between-samples Clustering Threshold\n
	\n
arguments:\n 
	-h | --help : print this message and exit\n
	-d | --data : path to the demultiplexed data (in fastq format). Files names must contain _R1_ and _R2_ (or just _R1_ for SE data)\n
	-n | --name : A prefix for output files\n
	-i | --iCT : the range of intra-sample Clustering Thresholds to be tested. Values must be space-separated and given between quotation marks; e.g. -iCT '0.80 0.90' \n
	-w | --work : full path to the working directory, were the output files will be saved\n
	-D | --Depth : minimum depth of ipyrad's clusters (ipyrad parameter #11 & #12) \n
	-T | --threads : number of threads to use. Default = 1\n
	-b | --bCT [optional] : fixed between-samples Clustering Threshold\n
	-t | --type : data type (one of: rad, ddrad, gbs, pairddrad, pairgbs, 2brad, pair3rad, ipyrad parameter #7)\n
	-s | --scripts : path to a directory containing this script as well as harvest_stats.sh and 2_plot_iCT_stats.R\n
	-p | --tree : whether to infer phylogenetic trees with the assemblies\n
	-r | --ref : a reference tree to use to calculate topological distances (only used if -p is specified)\n
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
	-d | --data)
	DATA=$2
	shift
	shift
	;;
	-n | --name)
	NAME=$2
	shift
	shift
	;;
	-i | --iCT)
	iCT=$2
	shift
	shift
	;;
	-w | --work)
	WORK=$2
	shift
	shift
	;;
	-D | --depth)
	DEPTH=$2
	shift
	shift
	;;
	-b | --bCT1)
	bCT1=$2
	shift
	shift
	;;
	-T | --threads)
	THREADS=$2
	shift
	shift
	;;
	-t | --type)
	TYPE=$2
	shift
	shift
	;;
	-s | --scripts)
	SCRIPTS=$2
	shift
	shift
	;;
	-r | --ref)
	REF=$2
	shift
	shift
	;;
	-p | --tree)
	TREE=YES
	shift
	;;
	-h | --help)
	echo -e ${err}
	exit 1
	shift
	;;
esac
done
fi

#### PART 1: iCT ####

cd $WORK

echo -e "\n ipyrad will be run with the following iCTs: \n $iCT \n"
echo -e "generating the parameter files\n"

echo ${iCT} | sed 's/ /\n/g' > ict.list

# Start from scratch
# This loop generates a parameter file for each iCT
for i in $iCT
do
TN=$(echo $i | cut -d'.' -f2)
ipyrad -n ${NAME}_iCT_${TN}
sed -i -r "s/^.*([[:space:]]*\#\# \[14\])/$i   \1/" params-"$NAME"_iCT_"$TN".txt
done

# set the remaining parameters: path to sorted data, mindepth
#Note: add a / after DATA and see if it still works (should work)
sed -i -r "s@^.*([[:space:]]*\#\# \[4\])@$DATA/\*\.gz   \1@" param*
sed -i -r "s/^.*([[:space:]]*\#\# \[11\])/$DEPTH   \1/" param*
sed -i -r "s/^.*([[:space:]]*\#\# \[12\])/$DEPTH   \1/" param*
sed -i -r "s/^.*([[:space:]]*\#\# \[7\])/$TYPE   \1/" param*

mkdir stats_iCT

# this loop performs the first 3 steps of ipyrad for all the param files generated above
for i in $iCT
do
echo -e "\nStarting assembly for iCT=${i}\n"
TN=$(echo $i | cut -d'.' -f2)
ipyrad -p params-${NAME}_iCT_${TN}.txt -s 12345 -c ${THREADS}
cp ${NAME}_iCT_${TN}_clust*/s3* stats_iCT/s3_${TN}.txt
cp ${NAME}_iCT_${TN}_consens/s5* stats_iCT/s5_${TN}.txt
done


if [ -n "$bCT1"  ]
then

sed -i -r "s/^.*([[:space:]]*\#\# \[14\])/$bCT1   \1/" params-*
echo "snps seq iCT" > stats_iCT/missing_all_CT.txt

for i in ${iCT}
do
echo -e "\nCompleting the assembly of iCT=$i with bCT=$bCT1\n"
TN=$(echo $i | cut -d'.' -f2)
ipyrad -p params-${NAME}_iCT_${TN}.txt -s 67
cd ${NAME}_iCT_${TN}_outfiles
sed -n '/locus_coverage  sum_coverage/,/The distribution of SNPs (var and pis) per locus./p' *stats.txt | sed '/The distribution of SNPs (var and pis) per locus./d' | sed '/^$/d' > ../stats_iCT/${TN}_loci.txt
sed -n '/[[:space:]]*var[[:space:]]*sum_var[[:space:]]*pis[[:space:]]*sum_pis/,/## Final Sample stats summary/p' *stats.txt | sed '/## Final Sample stats summary/d' | sed '/^$/d' > ../stats_iCT/${TN}_var.txt
echo $(grep "snps matrix size" *stats.txt | cut -d',' -f3 | cut -d'%' -f1 | sed 's/ //g') $(grep "sequence matrix size" *stats.txt | cut -d',' -f3 | cut -d'%' -f1 | sed 's/ //g') ${TN} >> ../stats_iCT/missing_all_CT.txt
cd ..
done

fi

# harvest stats for all assemblies

# Is this really needed?
#cd ..

if [ -n "$bCT1" ]
then
echo "harvesting stats for steps 3,5 and 7"
bash ${SCRIPTS}/harvest_stats.sh -s 357 -i stats_iCT
else
echo "harvesting stats for steps 3"
bash ${SCRIPTS}/harvest_stats.sh -s 3 -i stats_iCT
fi

# plot stats
### Check whether it works when stats only for step 3
cd ${WORK}/stats_iCT
Rscript ${SCRIPTS}/2_plot_iCT_stats.R ${WORK}/stats_iCT 

echo "stats plots are stored in" $(ls ${WORK}/stats_iCT/*.pdf)

if [ -n "$bCT1" ] && [ -n "$TREE" ]
then
cd ${WORK}
mkdir trees_iCT
cp *iCT*outfiles/*.phy trees_iCT
cd trees_iCT
bash ${SCRIPTS}/5_infer_trees.sh -T ${THREADS} -b 3 -m GTRGAMMA
cat RAxML_bipartitions.* > iCT.trees
Rscript ${SCRIPTS}/2-1_plot_iCT_trees.R ${WORK}/trees_iCT iCT.trees ${WORK}/ict.list ${REF}
echo "trees plots are stored in" $(ls ${WORK}/trees_iCT/*.pdf)
fi

echo -e "\n iCT RUNS SUCCESSFULLY COMPLETED \n"
