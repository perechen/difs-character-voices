
construct_samples <- function(x, char_set, frequencies,mfw, different_n=TRUE,const_n=NULL) {


	chrt <- x
	## Character vs. All , renaming
	v_classes <- ifelse(char_set == chrt, chrt, paste0("NOT_",chrt))

	if(different_n == TRUE) {

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
  		ch_samples <- tb[chrt]}

	} else {
		ch_samples <- const_n


	}


	# character sample positions
	ch_pool <- which(v_classes == chrt) %>% sample(ch_samples)
	# other sample positions
	other_pool <- which(v_classes != chrt) %>% sample(ch_samples-1)
  
	# count relative frequencies
	df_class <- tibble(frequencies[,1:mfw]/rowSums(frequencies[,1:mfw])) %>% mutate(classes=v_classes)

	df_class <- df_class[c(ch_pool,other_pool),]

	# return final table

	return(df_class)



}