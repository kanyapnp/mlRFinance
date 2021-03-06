#' Execute the SVM model with cross-validation.
#' Binary Selection
#' @param train A training dataframe with the binary values (-1 or +1)
#' @param valid A validation dataframe with the returns.
#' @param C Vector of costs to be validated.
#' @param kernel Type of kernel to be used.
#' @param parmMat Matrix of parameters of the kernel.
#' @param typePredict 0-Binary(-1,+1), 1-Probability, 2- Raw result
#' @return Validation results of the SVM for Portfolio Selection
#' @examples
#' add(1, 1)
#' add(10, 1)
LearningSVML1 <- function(train.y,train.X, valid.y, valid.X, C, kernel, parmMat, typePredict, freeCluster=0) {
  if (!requireNamespace("foreach", quietly = TRUE)) {
    stop("foreach needed for this function to work. Please install it.",
         call. = FALSE)
  }
  if (!requireNamespace("doParallel", quietly = TRUE)) {
    stop("doParallel needed for this function to work. Please install it.",
         call. = FALSE)
  }
  if (!requireNamespace("parallel", quietly = TRUE)) {
    stop("parallel needed for this function to work. Please install it.",
         call. = FALSE)
  }

  #Combination with parms
  matAll<-merge(C,parmMat)

  #Insert names
  colnames(matAll)<-c("C", paste0("Parm",seq(0,ncol(parmMat)-1)))

  #Get the total number of cores
  if(freeCluster==0){
    ncl<- parallel::detectCores()
  }
  else{
    ncl<- parallel::detectCores()-freeCluster
  }

  #Register the clusters
  cl <- parallel::makeCluster(ncl)
  doSNOW::registerDoSNOW(cl)

  #Progress Bar
  pb <- txtProgressBar(max = nrow(matAll), style = 3)
  progress <- function(n) setTxtProgressBar(pb, n)
  opts <- list(progress = progress)
  #Initialize the validation
  svmPort <- foreach(i=1:nrow(matAll), .combine=rbind, .errorhandling='pass', .packages="mlRFinance", .options.snow = opts) %dopar% {
    #Cost
    C0<-matAll$C[i]
    #Parms Mean
    parmsM<-as.numeric(matAll[i,2:ncol(matAll)])
    #Training the machine
    svm<-PortfolioSelectionCSVML1(train.y,train.X, valid.y, valid.X, C0,kernel, parmsM,typePredict )
    if(typePredict==0){
      res<-data.frame(matAll[i,],
                      "Prevalence" = svm$ErrorMeasureValidation$Prevalence,
                      "TruePositiveRate" = svm$ErrorMeasureValidation$TruePositiveRate,
                      "FalseNegativeRate" = svm$ErrorMeasureValidation$FalseNegativeRate,
                      "FalsePositiveRate" = svm$ErrorMeasureValidation$FalsePositiveRate,
                      "TrueNegativeRate" = svm$ErrorMeasureValidation$TrueNegativeRate,
                      "Accuracy" = svm$ErrorMeasureValidation$Accuracy,
                      "PositivePredictiveValue" = svm$ErrorMeasureValidation$PositivePredictiveValue,
                      "FalseOmissionRate" = svm$ErrorMeasureValidation$FalseOmissionRate,
                      "FalseDiscoveryRate" = svm$ErrorMeasureValidation$FalseDiscoveryRate,
                      "NegativePredictiveValue" = svm$ErrorMeasureValidation$NegativePredictiveValue,
                      "PositiveLikelihoodRatio" = svm$ErrorMeasureValidation$PositiveLikelihoodRatio,
                      "NegativeLikelihoodRatio" = svm$ErrorMeasureValidation$NegativeLikelihoodRatio,
                      "DiagnosticOddsRatio" = svm$ErrorMeasureValidation$DiagnosticOddsRatio)

    }
    else{
      res<-data.frame(matAll[i,], "MSE"=svm$ErrorMeasureValidation$MSE,
                      "MAPE"=svm$ErrorMeasureValidation$MAPE,
                      "TheilU"=svm$ErrorMeasureValidation$TheilU,
                      "ME"=svm$ErrorMeasureValidation$ME,
                      "MAE"=svm$ErrorMeasureValidation$MAE,
                      "MPE"=svm$ErrorMeasureValidation$MPE,
                      "RWR2"=svm$ErrorMeasureValidation$RWR2
      )
    }
    res
  }
  #Close Progress Bar
  close(pb)
  #Stop clusters
  stopCluster(cl)
  #Create a S3 class
  class(svmPort)<-c("data.frame","mlr")
  return(svmPort)
}


LearningSVRL1 <- function(train.y,train.X, valid.y, valid.X, C, epsilon, kernel, parmMat, freeCluster=0) {
  if (!requireNamespace("foreach", quietly = TRUE)) {
    stop("foreach needed for this function to work. Please install it.",
         call. = FALSE)
  }
  if (!requireNamespace("doParallel", quietly = TRUE)) {
    stop("doParallel needed for this function to work. Please install it.",
         call. = FALSE)
  }
  if (!requireNamespace("parallel", quietly = TRUE)) {
    stop("parallel needed for this function to work. Please install it.",
         call. = FALSE)
  }

  #Combination with parms
  matAll<-merge(C,epsilon)
  matAll<-merge(matAll, parmMat)

  #Insert names
  colnames(matAll)<-c("C","epsilon", paste0("Parm",seq(0,ncol(parmMat)-1)))

  #Get the total number of cores
  if(freeCluster==0){
    ncl<- parallel::detectCores()
  }
  else{
    ncl<- parallel::detectCores()-freeCluster
  }

  #Register the clusters
  cl <- parallel::makeCluster(ncl)
  doSNOW::registerDoSNOW(cl)

  #Progress Bar
  pb <- txtProgressBar(max = nrow(matAll), style = 3)
  progress <- function(n) setTxtProgressBar(pb, n)
  opts <- list(progress = progress)
  #Initialize the validation
  svrPort <- foreach(i=1:nrow(matAll), .combine=rbind, .errorhandling='pass', .packages="mlRFinance",  .options.snow = opts) %dopar% {
    #Cost
    C0<-matAll$C[i]
    #Epsilon
    epsilon0<-matAll$epsilon[i]
    #Parms Mean
    parmsM<-as.numeric(matAll[i,3:ncol(matAll)])
    #Training the machine
    svr<-PortfolioSelectionCSVRL1(train.y,train.X, valid.y, valid.X, C0, epsilon0, kernel, parmsM)
    res<-data.frame(matAll[i,],"MSE"=svr$ErrorMeasureValidation$MSE,
                    "MAPE"=svr$ErrorMeasureValidation$MAPE,
                    "TheilU"=svr$ErrorMeasureValidation$TheilU,
                    "ME"=svr$ErrorMeasureValidation$ME,
                    "MAE"=svr$ErrorMeasureValidation$MAE,
                    "MPE"=svr$ErrorMeasureValidation$MPE,
                    "RWR2"=svr$ErrorMeasureValidation$RWR2)

    res
  }
  #Close Progress Bar
  close(pb)
  #Stop clusters
  stopCluster(cl)
  #Create a S3 class
  class(svrPort)<-c("data.frame","mlr")
  return(svrPort)
}

LearningSVWQR1 <- function(train.y,train.X, C, tau, gamma, kernel, parmMat, freeCluster=0) {
  if (!requireNamespace("foreach", quietly = TRUE)) {
    stop("foreach needed for this function to work. Please install it.",
         call. = FALSE)
  }
  if (!requireNamespace("doParallel", quietly = TRUE)) {
    stop("doParallel needed for this function to work. Please install it.",
         call. = FALSE)
  }
  if (!requireNamespace("parallel", quietly = TRUE)) {
    stop("parallel needed for this function to work. Please install it.",
         call. = FALSE)
  }

  #Combination with parms
  matAll<-merge(C,gamma)
  matAll<-merge(matAll, parmMat)

  #Insert names
  colnames(matAll)<-c("C","gamma", paste0("Parm",seq(0,ncol(parmMat)-1)))

  #Get the total number of cores
  if(freeCluster==0){
    ncl<- parallel::detectCores()
  }
  else{
    ncl<- parallel::detectCores()-freeCluster
  }

  #Register the clusters
  cl <- parallel::makeCluster(ncl)
  doSNOW::registerDoSNOW(cl)

  #Progress Bar
  pb <- txtProgressBar(max = nrow(matAll), style = 3)
  progress <- function(n) setTxtProgressBar(pb, n)
  opts <- list(progress = progress)

  #Initialize the validation
  svwqrPort <- foreach(i=1:nrow(matAll), .combine=rbind, .errorhandling='pass', .packages="mlRFinance",  .options.snow = opts) %dopar% {
    #Cost
    C0<-matAll$C[i]
    #Epsilon
    gamma0<-matAll$gamma[i]
    #Parms Mean
    parmsM<-as.numeric(matAll[i,3:ncol(matAll)])
    #Training the machine
    svwqr<-PortfolioSelectionSVWQR1(train.y,train.X, C0, tau, gamma0, kernel, parmsM)
    res<-data.frame(matAll[i,],"Lagrangian"=svwqr$Lagrangian)
    res
  }
  #Close Progress Bar
  close(pb)
  #Stop clusters
  stopCluster(cl)
  #Create a S3 class
  class(svwqrPort)<-c("data.frame","mlr")
  return(svwqrPort)
}
