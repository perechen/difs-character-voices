
construct_samples <- function(x, char_set, frequencies,mfw, downsample_to_min=TRUE,const_n=NULL) {


	chrt <- x
	## Character vs. All , renaming
	v_classes <- ifelse(char_set == chrt, chrt, paste0("NOT_",chrt))

	if(downsample_to_min == TRUE) {

	## count overall samples
	tb <- v_classes %>% table() 

	## get minimal number of samples
	min_ch <- which(tb==min(tb))

	## if character samples > All
	if (!chrt %in% names(min_ch)) {
  	## get max samples from Others
  		ch_samples <- tb[min_ch]
		} else {
  	## else -> max from Character
  	  		ch_samples <- tb[chrt]}

	} else {
		ch_samples <- const_n


	}


	# character sample positions
	ch_pool <- which(v_classes == chrt) %>% sample(ch_samples)
	# other sample positions
	other_pool <- which(v_classes != chrt) %>% sample(ch_samples)
  
	# count relative frequencies
	df_class <- tibble(frequencies[,1:mfw]/rowSums(frequencies[,1:mfw])) %>% mutate(classes=v_classes)

	df_class <- df_class[c(ch_pool,other_pool),]

	# return final table

	return(df_class)



}