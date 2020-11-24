### Plot ipyrad stats
args = commandArgs(trailingOnly=TRUE)
workdirectory <- args[1]
setwd(workdirectory)
loci <- read.table("./loci_all_CT.txt", sep=" ", header=T)
missing <- read.table("./missing_all_CT.txt", sep=" ", header=T)


## loci statistics ##

#number of loci
Nsamples <- max(unique(loci[,1]))

loci_4 <- loci[which(loci[,1] == Nsamples), 3]
loci_50 <- loci_4 - loci[which(loci[,1] == floor((Nsamples*0.5)-1)), 3]
loci_80 <- loci_4 - loci[which(loci[,1] == floor((Nsamples*0.8)-1)), 3]

index <- unique(loci[,4])
max_c <- max(loci_4, loci_50, loci_80)
min_c <- min(loci_4, loci_50, loci_80)

#proportion of the loci

prop_50 <- loci_50/loci_4
prop_80 <- loci_80/loci_4

max_p <- max(prop_50, prop_80)
min_p <- min(prop_50, prop_80)

#Change in the proportion of the loci

delta_p50 <- diff(prop_50)
delta_p80 <- diff(prop_80)

index_diff <- unique(loci[,4])[-1]

#Percentage of missing data

max_m <- max(missing[,1], missing[,2])
min_m <- min(missing[,1], missing[,2])

delta_m_SNP <- diff(missing[,1])
delta_m_SEQ <- diff(missing[,2])

max_dm <- max(delta_m_SNP, delta_m_SEQ)
min_dm <- min(delta_m_SNP, delta_m_SEQ)

## plots ##

pdf(file="./bCT_plots.pdf")
par(mar=c(5.1, 4.1, 4.1, 5.7), xpd=TRUE)
plot(index, loci_4, pch=19, cex=0.3, ylim=c(min_c, max_c), ylab="number of loci", xlab="iCT", 
     main="Number of loci in the assembly")
points(index, loci_50, pch=19, cex=0.3, col="red")
points(index, loci_80, pch=19, cex=0.3, col="blue")
legend("topright", inset=c(-0.28,0), legend=c("all","50%", "80%"), pch=c(19,19,19), col=c("black", "red", "blue"))

par(mar=c(5.1, 4.1, 4.1, 5.7), xpd=TRUE)
plot(index, prop_50, pch=19, cex=0.3, ylim=c(min_p, max_p), col="blue",
     ylab="proportion of the loci", xlab="iCT", main="Proportion of shared loci")
points(index, prop_80, pch=19, cex=0.3, ylim=c(min_p, max_p), col="red")
legend("topright", inset=c(-0.28,0), legend=c("50%", "80%"), pch=c(19,19), col=c("red", "blue"))

plot(delta_p50~index_diff, pch=19, cex=0.5, ylim=c(min(delta_p50), max(delta_p50)), col="blue",
     ylab="delta loci 50%", xlab="delta iCT", main="50%")
plot(delta_p80~index_diff, pch=19, cex=0.5, ylim=c(min(delta_p80), max(delta_p80)), col="red",
     ylab="delta loci 80%", xlab="delta iCT", main="80%")

par(mar=c(5.1, 4.1, 4.1, 4.1), xpd=TRUE)
plot(missing[,2]~missing[,3], pch=19, cex=0.5, ylab="% of missing data", xlab="iCT", col="blue",
     ylim=c(min_m, max_m))
points(missing[,1]~missing[,3], pch=19, cex=0.5, col="red")
legend("top", inset=c(-0.52,-0.22), legend=c("Concatenation", "SNPs"), pch=c(19,19), col=c("blue", "red"))

par(mar=c(5.1, 4.1, 4.1, 4.1), xpd=TRUE)
plot(delta_m_SNP~index_diff, pch=19, cex=0.5, ylim=c(min_dm, max_dm), ylab="delta % missing",
     xlab="delta iCT", col="red")
points(delta_m_SEQ~index_diff, pch=19, cex=0.5, col="blue")
legend("top", inset=c(-0.52,-0.22), legend=c("Concatenation", "SNPs"), pch=c(19,19), col=c("blue", "red"))

dev.off()

