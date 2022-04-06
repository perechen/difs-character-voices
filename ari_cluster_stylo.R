###cluster analysis with stylo
shak <- stylo(gui = F,
              corpus.dir ="shakespeare/twelfth_night", 
              corpus.lang = "English.all",
              mfw.min = 200, #100 or 200
              mfw.max = 200, #100 or 200
              analyzed.features = "w",
              ngram.size = 1,
              distance.measure = "delta", #classic delta or cosine (wurzburg)
              sampling = "normal.sampling",
              sample.size = 1000, #500, 1000, and 1500/2000 if possible
              display.on.sreen = F)
#distatnce table from stylo
shak$distance.table

###calculating ari
library(mclust )
char <- sub('(.*)(_[0-9]+)','\\1', rownames(shak$distance.table), perl=T)
fit <- hclust(as.dist(shak$distance.table), method= "ward.D2")
ari <- adjustedRandIndex(cutree(fit, length(unique(char))), char)
ari

