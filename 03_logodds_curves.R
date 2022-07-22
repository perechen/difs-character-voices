library(tidyverse)
library(tidytext)
library(tidylo)
source("src/loo_distinct.R")

allstars <- read_tsv("data/allstars_clean.tsv") %>% rename(char_id = X1)

shake <- allstars #%>% filter(corpus == "shake")

shake_t <- shake %>%
  select(char_id,label, gender,eigenvector,playName,cleanText,corpus) %>% 
  unnest_tokens(input=cleanText,output="word",token="words")

shake_t


## variable setup
n_size <- 2000 # n words per sample
n_char <- 1 # at least how many characters
n_samples <- 1 # at least how many samples per character
mfw_len <- 10000
n_resamples=50 # how many redraws/reclassify for character
feature_bag=100



## character/novels by words filter
char_count <- shake_t %>%
  count(playName,char_id,label) %>%
  filter(n>n_size*n_samples) %>%
  count(playName) %>%
  filter(n>=n_char)

## characters that are fine for classification
target_char <-  shake_t %>%
  count(playName,char_id,label) %>%
  filter(n>n_size*n_samples) %>% 
  mutate(isTarget = TRUE)

## texts that do have at least one target char
texts <- char_count$playName %>% unique()

char_fin <- shake_t %>%
  filter(playName %in% texts) %>%
  left_join(target_char %>% select(char_id, isTarget),by="char_id")

df_res=NULL

for(dr in texts) {
  
  message(paste0("----",dr))
  
  pool <- shake_t %>% filter(playName==dr)
  n_char <- pool$char_id %>% unique() %>% length()
  
  if(n_char <= 1) {
    next
  }
  

  chr_pool <-  target_char %>% filter(playName==dr)
  
  ## here loop for character should start
  for(c in 1:nrow(chr_pool)) {
    
    
    
    message(paste0("--",chr_pool$label[c]))
    
    ## number of resamples
    
    
    top_curve <- logodds_curve(pool,char=chr_pool$char_id[c],features=feature_bag,oversampling = T)
    
    auc <- calculate_auc(top_curve)
    
    df <- top_curve %>%
      mutate(d=auc,
             playName=dr,
             label=chr_pool$label[c],
             n=chr_pool$n[c])
    
    df_res <- bind_rows(df_res,df)
   
    
    
  } ## end of char loop
  
} ## end of text loop

write_tsv(df_res,file="data/logodds_curves.tsv")

meta <- allstars %>%
  select(char_id,label,yearNormalized,gender,eigenvector,corpus) %>%
  mutate(char_id=as.character(char_id)) %>% 
  group_by(label) %>% 
  mutate(idd=row_number()) %>% rowwise() %>% mutate(label=paste0(label, "_",idd)) 

df_fin <- df_res %>% select(-label) %>% left_join(meta,by="char_id") 

write_tsv(df_fin,"data/df_fin_curves.tsv")
df_fin %>% filter(label=="Cleopatra_1") %>%  ggplot(aes(rank,log_odds_weighted)) + geom_path()

library(ggrepel)

labs <- df_fin %>% group_by(label,d) %>% top_n(30,log_odds_weighted) %>% group_by(label,d) %>%   summarise(bag=paste(word,collapse = "\n")) %>% ungroup() %>% ungroup() %>% top_n(10,d)

df_fin %>% select(d,label,n,gender,corpus,eigenvector) %>% filter(gender %in% c("MALE","FEMALE")) %>% unique() %>% ggplot(aes(log(n),d,group=corpus)) + geom_point() + geom_smooth(method="gam",se=F) + facet_wrap(~corpus)
df_res$label[3]
sample_n(labs,3)

library(paletteer)

df_fin %>% filter(corpus=="shake") %>% select(d,char_id,label,n,gender,eigenvector) %>% unique() %>% ggplot(aes(d,reorder(label,d))) + theme_minimal() +
  geom_segment(aes(yend=label,x=70,xend=d),size=0.2) +
  geom_point(aes(color=n),size=2) + 
  #geom_label_repel(data=labs,aes(label=bag),nudge_y = 100,size=3) + 
  theme(axis.text.y = element_text(hjust = 1,size=6))  + facet_grid(scales = "free_y",space="free_y",rows=vars(gender)) + scale_color_paletteer_c("gameofthrones::targaryen2") +
  scale_x_continuous(limits=c(70,190),expand = c(0, 0)) 


palettes_c_names %>% filter(package=="gameofthrones")
