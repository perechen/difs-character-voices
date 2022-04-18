library(tidyverse)
library(tidytext)
library(e1071) # for SVM

## ##
chars <- list.files("shakespeare/",full.names = T,recursive = T)

v <- str_split(chars,"/")

#### Functions ####

## sampling function
sample_bag <- function(x,
                       sample_words=1000,
                       # please don't use seed if you use the function for iteration
                       seed=NA) {
  
  
  ## max number of samples with given sample length
  max_s <- floor(x/sample_words)
  ## how many words would not make a sample
  n_na <- x - max_s*sample_words
  ## create a 1:1 vector with sample numbers and NAs
  v <- c(rep(1:max_s,sample_words), rep(NA, n_na))
  
  
  ## set seed
  if (is.numeric(seed)) {
    set.seed(seed)
  }
  
  ## one sample warning
  if (max_s < 2) {
    message("Warning! Only one sample here")
  }
  
  ## shuffle
  v_samples <- sample(v)
  
  return(v_samples)
  
}

#### Setup ####

## make a table with chars, plays,texts
df <- tibble(author=map(v,1) %>% unlist(),
       play=map(v,3) %>% unlist(),
       chrt=map(v,4) %>% unlist()) %>% 
  mutate(chrt=str_remove(chrt,".txt"),
         text=sapply(chars, read_file))

## quick tokenization
unnested <- df %>% 
  unnest_tokens(input=text,output=word, token ="words")


## look at words per character counts
total_words <- unnested %>% 
  group_by(play, chrt) %>%
  count(chrt) 

total_words %>%
  ggplot(aes(reorder(chrt,-n), n)) + 
  geom_col() + 
  facet_wrap(~play,scales = "free") + 
  theme(axis.text.x=element_text(angle=60,hjust = 1))

## variable setup
n_size <- 500
mfw_length <- 10
plays <- df$play %>% unique()

#### Iterate over plays ####

## empty df for results
df_res <- NULL

for (p in plays) {

## sampling
p1 <- unnested %>% filter(play==p)



## split by characters
c_list <- p1 %>% group_by(chrt) %>% group_split()


## empty list
s_list = vector("list",length(c_list))

## here should be another loop for sampling differently for each character/play

## assign sample numbers to available tokens (random sampling without replacement)

for(c in 1:length(c_list)) {
  
  df_char <- c_list[[c]]
  ## get sample ids for available words without replacement
  v_samples = sample_bag(nrow(df_char),sample_words = n_size)
  
  s_list[[c]] <- df_char %>%
    mutate(sample_no = v_samples) %>% 
    filter(!is.na(sample_no)) %>% # get rid of words not in the sample
    mutate(sample_id = paste(chrt, sample_no,sep="_"))
  
}



## back to one table per play, table of frequencies
freqs <- s_list %>%
  bind_rows() %>%
  group_by(chrt,sample_id) %>%
  count(word) %>%
  pivot_wider(names_from = word,values_from = n, values_fill =0)

## words in MFW order
w=colSums(freqs[,-c(1,2)])
top_w <- tibble(n=w, word=names(w)) %>% arrange(-n)

## character / sample vectors
v_id <- freqs$sample_id
v_ch <- freqs$chrt

freqs <- freqs[,-c(1,2)]
## arrange by frequency
freqs <- freqs[top_w$word]

## get character types
v_c <- v_ch %>% unique()

## patch: what are the characters with 1 sample
lows <- which(sapply(s_list,nrow) < 2*n_size)

if (length(lows) != 0) {
  v_c <- v_c[-lows]
}

#### Iterate over character ####
for (c in v_c) {
  
message(paste0("Now at: ", p, ". Character: ", c))

chrt <- c
## Character vs. All , renaming
v_classes <- ifelse(v_ch == chrt, chrt, paste0("NOT_",chrt))

## count overall samples
tb <- v_classes %>% table() 

## get minimal number of samples
min_ch <- which(tb==min(tb))

## if character samples > All
if (!chrt %in% names(min_ch)) {
  ## get character samples + 1
  ch_samples <- tb[min_ch] + 1
} else {
  ## else -> min amount
  ch_samples <- tb[chrt]
}

## this is a dirty solution to getting different samples in training/test sets

for (samp in 1:5) {
  # character sample positions
  ch_pool <- which(v_classes == chrt) %>% sample(ch_samples)
  # other sample positions
  other_pool <- which(v_classes != chrt) %>% sample(ch_samples-1)
  
  # count relative frequencies
  df_class <- tibble(freqs[,1:mfw_length]/rowSums(freqs[,1:mfw_length])) %>% mutate(classes=v_classes)


## leave-one-out cross validation
## each character-sample participates as a test set
for (i in 1:length(ch_pool)) {

## data for train vs. test (one vector)
train <- df_class[c(ch_pool[-i],other_pool),]
test <- df_class[ch_pool[i],]

## fit SVM with linear kernel 
m <- svm(as.factor(classes) ~., kernel="linear",data = train)

## predict the `test` character sample (remove the class column in the end)
pr <- predict(m,test[,-(mfw_length+1)]) %>% table()

## write results 
df_pred <- tibble(pred=pr[chrt],chr =chrt,play=p,char_samples=length(ch_pool))
## combine in overall table
df_res <- bind_rows(df_res, df_pred)

      } # leave-one-out END of loop
  
    } # resampling END of loop

  } # character END of loop

} # play END of loop

df_res %>%
  group_by(chr,play,char_samples) %>%
  summarize(mean_acc=mean(pred)) %>%
  mutate(mfw=50) %>%
  ## plotting
  ggplot(aes(chr,mean_acc)) +
  geom_col() + 
  theme_bw() + 
  facet_wrap(~play,scales = "free_x") + 
  geom_hline(aes(yintercept=0.5),color="red") + 
  labs(title="Accuracy in predicting character", subtitle=paste0("Leave-one-out cross-validation\nOne vs. all classification. \nWhite numbers = available no. of samples per character\n",mfw_length," MFW, sample size = ", n_size)) + geom_text(aes(label=char_samples),nudge_y = -0.2,color="white")

ggsave("test_acc1.png",width = 8,height = 6)

df_res %>%
  group_by(chr,play,char_samples) %>%
  summarize(mean_acc=mean(pred)) %>% ggplot(aes(char_samples,mean_acc)) + geom_point()
## clearly 2 samples per CH is not enough, it is all over the place, all > 2 are recognized well

## frequency counts


## SVM predictive test?

# take e.g. Hamlet
# classes: Hamlet vs non-Hamlets (hamlet Salad!), samples max(n)-1? (binary!)
# leave-one-out CV (guess each Hamlet sample?), accuracy as a measure. 50% baseline.

