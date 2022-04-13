
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