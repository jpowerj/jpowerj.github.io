do_preprocessing <- function(corpus){
  # Preprocessing
  corpus <-tm_map(corpus,content_transformer(tolower))
  # Note that this drops (presumably empty) documents
  #remove potentially problematic symbols
  toSpace <- content_transformer(function(x, pattern) { return (gsub(pattern, " ", x))})
  corpus <- tm_map(corpus, toSpace, "-")
  corpus <- tm_map(corpus, toSpace, "’")
  corpus <- tm_map(corpus, toSpace, "‘")
  corpus <- tm_map(corpus, toSpace, "•")
  corpus <- tm_map(corpus, toSpace, "”")
  corpus <- tm_map(corpus, toSpace, "“")
  ## JJ TRYING TO REMOVE SHORT WORDS [failed]
  #removeShort <- content_transformer(function(x) { return(ifelse(length(x) < 3, "", x))})
  #corpus <- tm_map(corpus, removeShort)
  #remove punctuation
  corpus <- tm_map(corpus, removePunctuation)
  #Strip digits
  corpus <- tm_map(corpus, removeNumbers)
  #remove stopwords
  corpus <- tm_map(corpus, removeWords, stopwords("english"))
  #remove whitespace
  corpus <- tm_map(corpus, stripWhitespace)
  #Stem document
  corpus <- tm_map(corpus,stemDocument)
  # Some arabic words left that need to be manually stemmed
  corpus <- tm_map(corpus, content_transformer(gsub),
                   pattern = "mujahidun", replacement = "mujahid")
  corpus <- tm_map(corpus, content_transformer(gsub),
                   pattern = "communiqué—communiqué—communiqué", replacement = "")
  corpus <- tm_map(corpus, content_transformer(gsub),
                   pattern = "murabitun", replacement = "murabit")
  corpus <- tm_map(corpus, content_transformer(gsub),
                   pattern = "palestinian", replacement = "palestin")
  return(corpus)
}