# Function for plotting LDA results. Put at beginning
# of R file.
plot_lda <- function(lda_model){
    lda_result <- posterior(lda_model)
    exp_props <- colMeans(lda_result$topics)
    invrank <- order(exp_props, decreasing=FALSE)
    commas <- function(text){  
        paste(text[nchar(text)>0], collapse=", ")
    }
    topic.names <- sprintf("Topic %i:", 1:ncol(lda_result$topics))
    lda_terms <- as.matrix(terms(lda_model,6))
    topic_labels <- apply(t(lda_terms), 1, commas)
    lab <- sprintf("%s %s", topic.names, topic_labels)
    y <- barplot(exp_props[invrank], main="Exp Props",
                 horiz=TRUE, yaxt="n", space=0)
    x<-0.5*exp_props[invrank]
    text(x,y,lab[invrank])
}

# Just the code for the LDA tutorial
# Ingest the data
library(topicmodels)
# In case of errors when installing topicmodels:
# http://tinyheero.github.io/2016/02/20/install-r-topicmodels.html

# For loading corpus from directory
#const_corpus <- Corpus(DirSource("constitutions"))
bayanat_corpus <- Corpus(DirSource("bayanat"))
bayanat_corpus <- Corpus(DirSource("bayanat"))
bayanat_corpus <- Corpus(DirSource("bayanat_corpus"))


# For loading corpus from csv file
comm_data <- fread("bayanat.csv", data.table = FALSE, header=TRUE)
library(data.table)
comm_data <- fread("bayanat.csv", data.table = FALSE, header=TRUE)

# Get it into tm
#blog_corpus <- Corpus(DataframeSource(blog_data))
# ok that didn't work, like everything else in R
comm_corpus <- Corpus(VectorSource(comm_data$comm_text))

## Starting here I'm copying from 
# Look at a doc
writeLines(as.character(comm_corpus[[30]]))
# Preprocessing
comm_corpus <-tm_map(comm_corpus,content_transformer(tolower))
# Note that this drops (presumably empty) documents
#remove punctuation
comm_corpus <- tm_map(comm_corpus, removePunctuation)
#Strip digits
comm_corpus <- tm_map(comm_corpus, removeNumbers)
#remove stopwords
comm_corpus <- tm_map(comm_corpus, removeWords, stopwords("english"))
#remove whitespace
comm_corpus <- tm_map(comm_corpus, stripWhitespace)
#Good practice to check every now and then
writeLines(as.character(comm_corpus[[30]]))
#Stem document
comm_corpus <- tm_map(comm_corpus,stemDocument)
#Create document-term matrix
comm_dtm <- DocumentTermMatrix(comm_corpus)
# The actual model
K <- 20
comm_lda <-LDA(comm_dtm, K, method="Gibbs")
comm_topics <- as.matrix(topics(comm_lda))
write.csv(comm_topics,file=paste0("Communiques_",K,"_DocsToTopics.csv"))
comm_terms <- as.matrix(terms(comm_lda,6))
write.csv(comm_terms,file=paste0("Communiques_",K,"_TopicsToTerms.csv"))
topic_probs <- as.data.frame(comm_lda@gamma)
write.csv(topic_probs,file=paste0("Communiques_",K,"_TopicProbabilities.csv"))

## From here onwards I'm stealing from
## https://tm4ss.github.io/docs/Tutorial_6_Topic_Models.html
# Apparently we need to explicitly tell it to calculate posteriors
comm_result <- posterior(comm_lda)
# Good time to introduce "attributes" function
attributes(comm_result)
# Now we can get the top N terms for a given topic using
topic_num <- 1
top_40 <- sort(comm_result$terms[topic_num,], decreasing=TRUE)[1:40]
top_40_words <- names(top_40)
print(top_40_words)
# extract the probabilites of each of the 40 terms
top_40_probs <- sort(comm_result$terms[topic_num,], decreasing=TRUE)[1:40]

# Visualizing, even though we don't have the stm plotting functions
library(wordcloud)
cloud_colors <- brewer.pal(8, "Dark2")
wordcloud(top_40_words, top_40_probs, random.order = FALSE, color=cloud_colors)

# Now let's try to get the expected topic proportions
# The data in blog_result$topics is what we need.
# Note that it is a 53 x 20 matrix:
dim(comm_result$topics)
# So if we compute column means we will get the expected
# proportions for each of the 20 topics over all docs
# (Btw this is stolen from the stm code at
# https://github.com/bstewart/stm/blob/master/R/plot.STM.R )
exp_props <- colMeans(comm_result$topics)
print(exp_props)
invrank <- order(exp_props, decreasing=FALSE)
print(exp_props[invrank])

commas <- function(text){  
  paste(text[nchar(text)>0], collapse=", ")
}

topic.names <- sprintf("Topic %i:", 1:ncol(comm_result$topics))
# lol I can't believe just guessing a transpose actually worked
topic_labels <- apply(t(comm_terms), 1, commas)
lab <- sprintf("%s %s", topic.names, topic_labels)

# Except the STM code DIDN'T WORK as usual
# So instead I did this barplot thing stolen from
# https://www.packtpub.com/mapt/book/big_data_and_business_intelligence/9781849513067/5/ch05lvl1sec11/placing-labels-inside-bars

y <- barplot(exp_props[invrank], main="Exp Props",
             horiz=TRUE, yaxt="n", space=0)
x<-0.5*exp_props[invrank]
text(x,y,lab[invrank])

######################################################
### NEW SECTION: Optimizing the number of topics K ###
######################################################

# You'll need to run install.packages("ldatuning")
# in the console before this line will work
library(ldatuning)
# Compute the K value "scores" from K=2 to K=15
result <- FindTopicsNumber(
    comm_dtm,
    topics = seq(from = 2, to = 15, by = 1),
    metrics = c("Griffiths2004", "CaoJuan2009", "Arun2010", "Deveaud2014"),
    method = "Gibbs",
    control = list(seed = 1948),
    mc.cores = 2L,
    verbose = TRUE
)
# Plot the scores, with graphs labeled "minimize" or
# maximize based on whether it's a metric you want
# to minimize or maximize
FindTopicsNumber_plot(result)

# Looks like 6 or 7 is optimal. Choosing 6 because
# of laziness
K <- 6
comm_lda_6 <-LDA(comm_dtm, K, method="Gibbs")

# Plot the new model results!
plot_lda(comm_lda_6)

