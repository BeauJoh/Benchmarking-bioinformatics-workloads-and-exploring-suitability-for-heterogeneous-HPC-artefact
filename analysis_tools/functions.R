printf <- function(...) invisible(print(sprintf(...)))

#Load the data from the 'dir' folder applying the filter specified by 'expr'
loaddata <- function(dir, expr){
    data_unfolded <- ReadAllFilesInDir.Aggregate(dir.path=dir)
    if (!is.null(expr)) data_unfolded = subset(data_unfolded, eval(parse(text=expr)))
    return(data_unfolded)
}

#Shapiro-Wilk normality test
lsb_shapiro <- function(data, col){
    sampled <- as.numeric(data[[col]])
   
    #shapiro.test takes min 3 val
    if (length(sampled)<3) {
        print("The dataset contains too few rows (min. 3 are required)")
        return()
    }

    #shapiro.test takes max 5000 vals
    if (length(sampled)>5000) sampled <- sample(sampled, 5000)
    shapiro.test(sampled)
}

#ANOVA test
lsb_anova <- function(data, xcol, ycol){
    res <- aov(eval(parse(text=ycol)) ~ eval(parse(text=xcol)), data=data)
    print(res)
    summary(res)
}

#Kruskal–Wallis one-way analysis of variance
lsb_kruskal <- function(data, xcol, ycol){
    kruskal.test(eval(parse(text=ycol))~eval(parse(text=xcol)), data=data)
}

#Histogram + density plot
lsb_histo_density <- function(data, col, xlbl){
    str <- paste("mean(", col, ")")
    plot <- Create.Plot.HistoDensity(data, aes_string(col), aes_string(xintercept=str),,, xlbl, "Density")
    return(plot)
}

#Density plot
lsb_density <- function(data, col, xlbl,use_median=FALSE){
  if(use_median){ 
    str <- paste("median(",col,")")
  }else{
    str <- paste("mean(", col, ")")
  }
  plot <- Create.GGPlot.Density(data, aes_string(col), data, aes_string(xintercept=str),,, xlbl, "Density")
  return(plot)
}

#QQ-plot
lsb_qqplot <- function(data, col){
  plot <- CreateQQPlot(data, col)
  return(plot)
}

#Box Plot
lsb_boxplot <- function(d, cols, xlbl, ylbl){
  plot <- CreateBoxPlot(d,, cols , cols,, "", xlbl, ylbl)
  return(plot)
}

#Violin Plot
lsb_violinplot <- function(d, cols, xlbl, ylbl){
  plot <- Create.Plot.Violin(d,, cols , cols, "", xlbl, ylbl)
  return(plot)
}

#log-normalization on data[datacol]
lsb_lognormalize <- function(data, datacol){
  val <- data[[datacol]]
  val <- log(val)
  val <- data.frame(matrix(unlist(val),ncol=1) )
  data[]
  names(val) <- datacol
  return(val)
}

#k-normalization on data[datacol]
lsb_knormalize <- function(data, datacol, k=1){
  var <- data[[datacol]]
  max <- k
  x <- seq_along(var)
  d1 <- split(var, ceiling(x/max))
  df <- numeric(length(d1))
  i <- 1
  for(chunk in d1){
    len <- length(chunk) 
    s<-sum(chunk)
    df[i] <- s / len
    i = i +1
  }
  df <- data.frame(matrix(unlist(df),ncol=1) )
  #data[[datacol]] <- unlist(df)
  names(df) <- datacol
  return(df)
}

#Quantile Regression Plot between data1[col1] and data2[col2] 
lsb_qr <- function(data1, col1, data2, col2){
    library(quantreg)   
    data_merged = data.frame(data1[[col1]], data2[[col2]])
    colnames(data_merged) <- c("a", "b")
    pdf(file="out.pdf")
    plot(summary(rq(a~b,tau = 1:49/50,data=data_merged)))
}

directory_generator <- function(directory_path,directory_range){
    directories <- data.frame()
    for (i in directory_range){
       directories <-
           rbind(directories,data.frame("name"=gsub('##',i,directory_path),"size"=i))
    }
    return(directories)
}

load_directories_from_generator <- function(directories,lsb_event_columns){
    big_df <- data.frame()
    for(i in seq(1,nrow(directories))){
        df <- ReadAllFilesInDir.Aggregate(dir.path=as.character(directories[i,]$name),col=lsb_event_columns)
        df <- cbind(df,"size"=as.numeric(directories[i,]$size))
        big_df <- rbind(big_df,df)
    }
    return(big_df)
}

load_directories <- function(directory_path,directory_range,lsb_event_columns){
    directory_list <- directory_generator(directory_path,directory_range)
    return(load_directories_from_generator(directory_list,lsb_event_columns))
}
