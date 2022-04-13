char_cross_v <- function(x,df,mfw,novel,s) {
	chrt <- x
	df_res <- NULL

	# character sample positions
	ch_pool <- which(df$classes == chrt)
	# other sample positions
	other_pool <- which(df$classes != chrt)

	for (i in ch_pool) {

		## data for train vs. test (one vector)
		train <- df[c(ch_pool[-i],other_pool),]
		test <- df[ch_pool[i],]

		## fit SVM with linear kernel 
		m <- svm(as.factor(classes) ~., kernel="linear",data = train)

		## predict the `test` character sample (remove the class column in the end)
		pr <- predict(m,test[,-(mfw+1)]) %>% table()

		df_pred <- tibble(pred=pr[chrt],
                  chr =chrt,
                  book_id=novel,
                  char_samples=length(df_class$classes==c),
                  sample_id=s)
		
		df_res <- bind_rows(df_res, df_pred)








	}


	return(df_res)
}