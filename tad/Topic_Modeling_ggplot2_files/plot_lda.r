plot_lda <- function(lda_model){
    lda_result <- posterior(lda_model)
    top_40_probs <- sort(lda_result$terms[topic_num,], decreasing=TRUE)[1:40]
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