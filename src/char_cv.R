char_cross_v <- function(x,df,mfw,novel,cr,s) {
	chrt <- x
	df_res <- NULL
	v_predicted <- NULL

	# character sample positions
	ch_pool <- which(df$classes == chrt)
	# other sample positions
	other_pool <- which(df$classes != chrt)


	# remove no variation dimensions

	variance <- lapply(df,function(x) length(unique(x)))
	zerovar <- which(variance < 1)
	if(length(zerovar) > 0) {

		df <- df[,-zerovar]

	}
	





	for (i in 1:nrow(df)) {

		## data for train vs. test (one vector)
		train <- df[-i,]
		test <- df[i,]
		
	

	

		## fit SVM with linear kernel 
		m <- svm(as.factor(classes) ~., kernel="linear",data = train)

		## predict the `test` character sample (remove the class column in the end)
		pr <- predict(m,test[,-ncol(test)]) %>% table()
		
		v_predicted <- c(v_predicted,names(which(pr == 1)))


		
	







	} 
	
	
	v_expected = df$classes
	cmatrix=caret::confusionMatrix(factor(v_predicted),factor(v_expected))
	

	df_pred <- tibble(acc=cmatrix$overall[1],
	                  chr=chrt,
	                  book_id=novel,
	                  char_samples=length(df$classes==c),
	                  sample_id=s,
	                  corpus=cr)


	return(df_pred)
}
