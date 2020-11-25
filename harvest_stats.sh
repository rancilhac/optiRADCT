#!/bin/bash

HELPM="\n bash script to collect stats from ipyrad assemblies generated by the scripts 1_run_iCT.sh and 3_run_bCT.sh \n
Usage: harvest_stats.sh -s <steps to harvest> -w <assemblies dir> -o <output dir> \n
Arguments: \n
-s: ipyrad's steps from which to harvest the stats. Can be either 3, 5 or 7 or any combination of the three. Exemple: -s 357 \n
-w: directory in which the assemblies generated by the previous script are located \n
-o: directory for output files \n
-h: print this message and exit \n"

if [[ $# -eq 0 ]]
then
echo -e $HELPM
exit 1
fi

while [[ $# -gt 0 ]]
do
key="$1"

case "$key" in
	-s | --steps)
	STEPS=$2
	shift
	shift
	;;
	-w | --work)
	WORK=$2
	shift
	shift
	;;
	-o | --outdir)
	OUT=$2
	shift
	shift
	;;
	-h | --help)
	HELP="y"
	shift
	shift
	;;
esac
done

if [ $HELP == "y" ]
then
echo -e $HELPM
exit 1
fi

cd $WORK
mkdir $OUT

STEP3=$(echo $STEPS | grep 3)
STEP5=$(echo $STEPS | grep 5)
STEP7=$(echo $STEPS | grep 7)

if [ -n "$STEP3" ]
then

echo "Harvesting statistics from s3" 

for i in *clust*
do
# store the threshold value into the t variable using the name of the folders (in the form assembly-name_clust_0.85 for ex)
t=$(echo $i | cut -d'.' -f2)
# copy the s3 file to the stat directory and rename it
cp $i/s3* $OUT/s3_"$t".txt
done

cd $OUT

# this part formate and concatenate all the s3 files in a table easily readable by R
# store the header in a variable
header=$(head -1 $(ls s3* | head -1))
# write this header (+ 2 additional fields) in a file that will contain the concatenated table
echo "sample"$header" threshold" > all_s3.txt
# iterate on each file
for i in s3*
do
# find the CT and store it in a variable
t=$(echo $i | cut -d'.' -f1 | cut -d'_' -f2)
# open the file and execute the following actions : change the fields delimiter to 1 space; add a new field with the CT; remove the first line (header); add a newline character at the end of the last line (originally absent) and then write the result in the big table file
cat $i | sed -E 's/[[:space:]]+/ /g' | sed "s/$/ $t/" | sed '1d'  | sed "$ s/$/\n/" >> all_s3.txt
done

fi

if [ -n "$STEP5" ]
then

cd $WORK

echo "Harvesting statistics from s5"

# do the same thing but for the s5 files
for i in *consens*
do
t=$(echo $i | grep -o "[0-9]*")
cp $i/s5* $OUT/s5_"$t".txt
done

cd $OUT

header=$(head -1 $(ls s5* | head -1))
echo "sample"$header" threshold" > all_s5.txt
for i in s5*
do
t=$(echo $i | cut -d'.' -f1 | cut -d'_' -f2)
cat $i | sed -E 's/[[:space:]]+/ /g' | sed "s/$/ $t/" | sed '1d'  | sed "$ s/$/\n/" >> all_s5.txt
done

fi

if [ -n "$STEP7" ]
then

cd $WORK

echo "Harvesting statistics from s7"

echo "snps seq iCT" > $OUT/missing_all_CT.txt

for i in *outfiles*
do
t=$(echo $i | rev | cut -d'_' -f2 | rev)

sed -n '/    locus_coverage  sum_coverage/,/The distribution of SNPs (var and pis) per locus./p' $i/*stats.txt | sed '/The distribution of SNPs (var and pis) per locus./d' | sed '/^$/d' > $OUT/"$t"_loci.txt
sed -n '/[[:space:]]*var[[:space:]]*sum_var[[:space:]]*pis[[:space:]]*sum_pis/,/## Final Sample stats summary/p' $i/*stats.txt | sed '/## Final Sample stats summary/d' | sed '/^$/d' > $OUT/"$t"_var.txt
echo $(grep "snps matrix size" $i/*stats.txt | cut -d',' -f3 | cut -d'%' -f1 | sed 's/ //g') $(grep "sequence matrix size" $i/*stats.txt | cut -d',' -f3 | cut -d'%' -f1 | sed 's/ //g') $t >> $OUT/missing_all_CT.txt

done

head -1 $(ls $OUT/*loci.txt | head -1) > $OUT/loci_all_CT.txt
sed -i 's/$/ threshold/' $OUT/loci_all_CT.txt
sed -i 's/^/N_samples/' $OUT/loci_all_CT.txt
sed -i 's/^[[:space:]]*//' $OUT/loci_all_CT.txt

for i in $OUT/*loci.txt
do
t=$(echo $i | rev | cut -d'/' -f1 | rev | cut -d'_' -f1)
cat $i | sed '1d' | sed "s/$/ $t/" >> $OUT/loci_all_CT.txt
done

sed -i -r "s/[[:space:]]+/ /g" $OUT/loci_all_CT.txt

head -1 $(ls $OUT/*var.txt | head -1) > $OUT/var_all_CT.txt
sed -i 's/$/ threshold/' $OUT/var_all_CT.txt
sed -i 's/^[[:space:]]*//' $OUT/var_all_CT.txt

for i in $OUT/*var.txt
do
t=$(echo $i | cut -d'_' -f1 | cut -d'/' -f2)
cat $i | sed '1d' | sed "s/$/ $t/" >> $OUT/var_all_CT.txt
done

fi

echo -e "\n the stats files are in $OUT\n"