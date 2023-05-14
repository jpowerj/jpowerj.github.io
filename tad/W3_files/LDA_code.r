# Just the code for the LDA tutorial
# Ingest the data
library(topicmodels)
# In case of errors when installing topicmodels:
# http://tinyheero.github.io/2016/02/20/install-r-topicmodels.html
library(tm)
# For loading corpus from directory
#const_corpus <- Corpus(DirSource("constitutions"))
# For loading corpus from csv file
library(data.table)
blog_data <- fread("poliblogs2008.csv", data.table = FALSE)
# Get it into tm
#blog_corpus <- Corpus(DataframeSource(blog_data))
# ok that didn't work, like everything else in R
blog_corpus <- Corpus(VectorSource(blog_data$documents))
bayanat_corpus <- Corpus(VectorSource(bayanat$comm_text))
## Starting here I'm copying from 
# Look at a doc
writeLines(as.character(blog_corpus[[30]]))
writeLines(as.character(bayanat_corpus[[25]]))
# Preprocessing
source("preprocessing.r")
bayanat_corpus <- do_preprocessing(bayanat_corpus)
blog_corpus <-tm_map(blog_corpus,content_transformer(tolower))
writeLines(as.character(bayanat_corpus[[25]]))

# Note that this drops (presumably empty) documents
#remove punctuation
blog_corpus <- tm_map(blog_corpus, removePunctuation)
#Strip digits
blog_corpus <- tm_map(blog_corpus, removeNumbers)
#remove stopwords
blog_corpus <- tm_map(blog_corpus, removeWords, stopwords("english"))
#remove whitespace
blog_corpus <- tm_map(blog_corpus, stripWhitespace)
#Good practice to check every now and then
writeLines(as.character(blog_corpus[[30]]))
#Stem document
blog_corpus <- tm_map(blog_corpus,stemDocument)
#Create document-term matrix
blog_dtm <- DocumentTermMatrix(blog_corpus)
bayanat_dtm <- DocumentTermMatrix(bayanat_corpus)
install.packages("ldatuning")
library(ldatuning)
result <- FindTopicsNumber(
  bayanat_dtm,
  topics = seq(from = 2, to = 15, by = 1),
  metrics = c("Griffiths2004", "CaoJuan2009", "Arun2010", "Deveaud2014"),
  method = "Gibbs",
  control = list(seed = 1948),
  mc.cores = 2L,
  verbose = TRUE
)
FindTopicsNumber_plot(result)

# The actual model
K <- 20
blog_lda <-LDA(blog_dtm, K, method="Gibbs")
blog_topics <- as.matrix(topics(blog_lda))
write.csv(blog_topics,file=paste0("Blogs_",K,"_DocsToTopics.csv"))
blog_terms <- as.matrix(terms(blog_lda,6))
write.csv(blog_terms,file=paste("Blogs_",K,"TopicsToTerms.csv"))
topic_probs <- as.data.frame(blog_lda@gamma)
write.csv(topic_probs,file=paste("Blogs_",K,"TopicProbabilities.csv"))

K <- 6
bayanat_lda <-LDA(bayanat_dtm, K, method = "Gibbs")
bayanat_topics <- as.matrix(topics(bayanat_lda))
write.csv(bayanat_topics, file = paste0("bayanat", K, "_DocsToTopics.csv"))
bayanat_terms <- as.matrix(terms(bayanat_lda, 6))
write.csv(bayanat_terms, file = paste0("bayanat_", K, "TopicsToTerms.csv"))
topic_probs <- as.data.frame(bayanat_lda@gamma)
write.csv(topic_probs, file = paste0("bayanat", K, "TopicProbabilities.csv"))
plot_lda(bayanat_lda)

## From here onwards I'm stealing from
## https://tm4ss.github.io/docs/Tutorial_6_Topic_Models.html
# Apparently we need to explicitly tell it to calculate posteriors
blog_result <- posterior(blog_lda)
bayanat_result <- posterior (bayanat_lda)

# Good time to introduce "attributes" function which is the information that is inside the variable after done the posterior, such terms and topics or other categories
attributes(blog_result)
attributes (bayanat_result)

# Now we can get the top N terms for a given topic using
topic_num <- 1
top_40 <- sort(blog_result$terms[topic_num,], decreasing=TRUE)[1:40]
top_40_words <- names(top_40)
print(top_40_words)

top_40

topic_num <- 5
top_40 <- sort(bayanat_result$terms[5,], decreasing=TRUE) [1:40]
print(top_40)

# extract the probabilites of each of the 40 terms
top_40_probs <- sort(blog_result$terms[topic_num,], decreasing=TRUE)[1:40]
top_40_probs <- sort(bayanat_result$terms[5,], decreasing = FALSE) [1:40]
top_40_probs
dim(bayanat_topics)
plot_lda(bayanat_lda)

# Visualizing, even though we don't have the stm plotting functions
library(wordcloud)
cloud_colors <- brewer.pal(8, "Dark2")
wordcloud(top_40_words, top_40_probs, random.order = FALSE, color=cloud_colors)
wordcloud(top_40_words, top_40, random.order = FALSE, colors = cloud_colors)

# Now let's try to get the expected topic proportions
# The data in blog_result$topics is what we need.
# Note that it is a 13246 x 20 matrix:
dim(blog_result$topics)
# So if we compute column means we will get the expected
# proportions for each of the 20 topics over all docs
# (Btw this is stolen from the stm code at
# https://github.com/bstewart/stm/blob/master/R/plot.STM.R )
exp_props <- colMeans(blog_result$topics)
print(exp_props)
invrank <- order(exp_props, decreasing=FALSE)
print(exp_props[invrank])

commas <- function(text){  
  paste(text[nchar(text)>0], collapse=", ")
}

topic.names <- sprintf("Topic %i:", 1:ncol(blog_result$topics))
# lol I can't believe just guessing a transpose actually worked
topic_labels <- apply(t(blog_terms), 1, commas)
lab <- sprintf("%s %s", topic.names, topic_labels)

# Except the STM code DIDN'T WORK as usual
# So instead I did this barplot thing stolen from
# https://www.packtpub.com/mapt/book/big_data_and_business_intelligence/9781849513067/5/ch05lvl1sec11/placing-labels-inside-bars

y <- barplot(exp_props[invrank], main="Exp Props",
             horiz=TRUE, yaxt="n", space=0)
x<-0.5*exp_props[invrank]
text(x,y,lab[invrank])

#xlim <- c(0,min(2*max(exp_props), 1))
#ylim <- c(0,length(blog_result$topics))
#main <- "Top Topics"
#xlab <- "Expected Topic Proportions"
#ylab <- ""
#plot(c(0,0), type="n", xlim=xlim, ylim=ylim, main=main, 
#     yaxt="n", 
#     ylab=ylab, xlab=xlab)
#length(invrank)
#lines(c(0,0.05), c(1,1))
#lines(c(0,0.1), c(2,2))
#for(i in 1:length(invrank)) {
#  lines(c(0,exp_props[invrank[i]]), c(i, i))
#  text(exp_props[invrank[i]]+ min(2*max(exp_props), 1)/100, i , lab[invrank[i]],pos=4)
#}
install.packages("ldatunning")

plot_lda <- function(lda_model){lda_result <- posterior(lda_model)top_40_probs <- sort(lda_result$terms[topic_num,], decreasing=TRUE)[1:40]
  exp_props <- colMeans(lda_result$topics)
  invrank <- order(exp_props, decreasing=FALSE)
  commas <- function(text){paste(text[nchar(text)>0], collapse=", ")}
  topic.names <- sprintf("Topic %i:", 1:ncol(lda_result$topics))
  lda_terms <- as.matrix(terms(lda_model,6))
  topic_labels <- apply(t(lda_terms), 1, commas)
  lab <- sprintf("%s %s", topic.names, topic_labels)
  y <- barplot(exp_props[invrank], main="Exp Props",horiz=TRUE, yaxt="n", space=0)
  x<-0.5*exp_props[invrank]
  text(x,y,lab[invrank])}


