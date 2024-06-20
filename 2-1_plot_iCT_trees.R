#Plot tree statistics

library(ape)
library(adephylo)

args <- commandArgs(trailingOnly = T)
workdir <- args[1]
treefile <- args[2]
index <- read.table(args[3], header=F)
if(length(args) == 4){ reffile <- args[4] }

setwd(workdir)

trees <- read.tree(treefile)

bootstrap <- c()
diameter <- c()
for(i in 1:length(trees)){
  bootstrap <- c(bootstrap, mean(as.numeric(trees[[i]]$node.label[trees[[i]]$node.label != ""])))
  diameter <- c(diameter, max(distTips(trees[[i]])))
}

if(exists("reffile")){
  reftree <- read.tree(reffile)
  rfd <- c()
  for(i in 1:length(trees)){
    rfd <- c(rfd, dist.topo(trees[[i]], reftree))
  }
}

pdf("./iCT_trees_plots.pdf")

plot(index[,1], bootstrap, pch=19, type="b", xlab="iCT", ylab="mean bootstrap support", main="mean bootstrap support depending on iCT")

plot(index[,1], diameter, pch=19, type="b", xlab="iCT", ylab="tree diameter", main="tree diameter depending on iCT")

if(exists("rfd")){
  plot(index[,1], rfd, pch=19, type="b", xlab="iCT", ylab="RF distance", main="RF distance to reference tree depending on iCT")
}

dev.off()
