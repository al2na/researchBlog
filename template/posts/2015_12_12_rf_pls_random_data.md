% R, randomforest, pls

# Random Forest vs PLS on Random Data

## TL;DR

Partial least squares (PLS) discriminant-analysis (DA) can ridiculously over fit
even on completely random data. The quality of the PLS-DA model can be assessed
using cross-validation, but cross-validation is not typically performed in many
metabolomics publications. Random forest, in contrast, because of the *forest* of
decision tree learners, and the out-of-bag (OOB) samples used for testing each tree, 
automatically provides an indication of the quality of the model.

## Why?

I've recently been working on some machine learning work using **random forests**
(RF) [Breimann, 2001](https://www.stat.berkeley.edu/~breiman/randomforest2001.pdf) on metabolomics data. This has been relatively successful,
with decent sensitivity and specificity, and hopefully I'll be able to post more
soon. However, PLS (Wold, 1975) is a standard technique used in metabolomics
due to the prevalence of analytical chemists in metabolomics and a long familiarity
with the method. Importantly, my collaborators frequently use PLS-DA to generate
plots to show that the various classes of samples are separable.

However, it has long been known that PLS (and all of it's variants, PLS-DA, OPLS,
OPLS-DA, etc) can easily generate models that over fit the data, and that over fitting
of the model needs to be assessed if the model is going to be used in subsequent
analyses. 

## Random Data

To illustrate the behavior of both RF and PLS-DA, we will generate some random data
where each of the samples are randomly assigned to one of two classes.

### Feature Intensities

We will generate a data set with 1000 features, where each feature's mean value
is from a uniform distribution with a range of 1-10000.


```r
library(cowplot)
library(fakeDataWithError)
set.seed(1234)
n_point <- 1000
max_value <- 10000
init_values <- runif(n_point, 0, max_value)
```


```r
init_data <- data.frame(data = init_values)
ggplot(init_data, aes(x = data)) + geom_histogram() + ggtitle("Initial Data")
```

```
## stat_bin: binwidth defaulted to range/30. Use 'binwidth = x' to adjust this.
```

![plot of chunk plot_initial](/home/rmflight/Projects/personal/researchBlog/researchBlog/img/plot_initial-1.png) 

For each of these features, their distribution across samples will be based on
a random normal distribution where the mean is the initial feature value and a
standard deviation of 200. The number of samples is 100.


```r
n_sample <- 100
error_values <- add_uniform_noise(n_sample, init_values, 200)
```

Just for information, the `add_uniform_noise` function is this:


```r
add_uniform_noise
```

```
## function(n_rep, value, sd, use_zero = FALSE){
##   n_value <- length(value)
## 
##   n_sd <- n_rep * n_value
## 
##   out_sd <- rnorm(n_sd, 0, sd)
##   out_sd <- matrix(out_sd, nrow = n_value, ncol = n_rep)
## 
##   if (!use_zero){
##     tmp_value <- matrix(value, nrow = n_value, ncol = n_rep, byrow = FALSE)
##     out_value <- tmp_value + out_sd
##   } else {
##     out_value <- out_sd
##   }
## 
##   return(out_value)
## }
## <environment: namespace:fakeDataWithError>
```

I created it as part of a package that is able to add different kinds of noise
to data.

The distribution of values for a single feature looks like this:


```r
error_data <- data.frame(feature_1 = error_values[1,])
ggplot(error_data, aes(x = feature_1)) + geom_histogram() + ggtitle("Error Data")
```

```
## stat_bin: binwidth defaulted to range/30. Use 'binwidth = x' to adjust this.
```

![plot of chunk plot_error](/home/rmflight/Projects/personal/researchBlog/researchBlog/img/plot_error-1.png) 

And we will assign the first 50 samples to **class_1** and the second 50 samples
to **class_2**.


```r
sample_class <- rep(c("class_1", "class_2"), each = 50)
sample_class
```

```
##   [1] "class_1" "class_1" "class_1" "class_1" "class_1" "class_1" "class_1"
##   [8] "class_1" "class_1" "class_1" "class_1" "class_1" "class_1" "class_1"
##  [15] "class_1" "class_1" "class_1" "class_1" "class_1" "class_1" "class_1"
##  [22] "class_1" "class_1" "class_1" "class_1" "class_1" "class_1" "class_1"
##  [29] "class_1" "class_1" "class_1" "class_1" "class_1" "class_1" "class_1"
##  [36] "class_1" "class_1" "class_1" "class_1" "class_1" "class_1" "class_1"
##  [43] "class_1" "class_1" "class_1" "class_1" "class_1" "class_1" "class_1"
##  [50] "class_1" "class_2" "class_2" "class_2" "class_2" "class_2" "class_2"
##  [57] "class_2" "class_2" "class_2" "class_2" "class_2" "class_2" "class_2"
##  [64] "class_2" "class_2" "class_2" "class_2" "class_2" "class_2" "class_2"
##  [71] "class_2" "class_2" "class_2" "class_2" "class_2" "class_2" "class_2"
##  [78] "class_2" "class_2" "class_2" "class_2" "class_2" "class_2" "class_2"
##  [85] "class_2" "class_2" "class_2" "class_2" "class_2" "class_2" "class_2"
##  [92] "class_2" "class_2" "class_2" "class_2" "class_2" "class_2" "class_2"
##  [99] "class_2" "class_2"
```

## PCA

Just to show that the data is pretty random, lets use principal components
analysis (PCA) to do a decomposition, and plot the first two components:


```r
tmp_pca <- prcomp(t(error_values), center = TRUE, scale. = TRUE)
pca_data <- as.data.frame(tmp_pca$x[, 1:2])
pca_data$class <- as.factor(sample_class)
ggplot(pca_data, aes(x = PC1, y = PC2, color = class)) + geom_point(size = 4)
```

![plot of chunk pca_data](/home/rmflight/Projects/personal/researchBlog/researchBlog/img/pca_data-1.png) 


## Random Forest

Let's use RF first, and see how things look.


```r
library(randomForest)
rf_model <- randomForest(t(error_values), y = as.factor(sample_class))
```

The confusion matrix comparing actual *vs* predicted classes based on the 
out of bag (OOB) samples:


```r
knitr::kable(rf_model$confusion)
```



|        | class_1| class_2| class.error|
|:-------|-------:|-------:|-----------:|
|class_1 |      28|      22|        0.44|
|class_2 |      23|      27|        0.46|

And an overall error of 0.4866246.

## PLS-DA

So PLS-DA is really just PLS with **y** variable that is binary.


```r
library(caret)
pls_model <- plsda(t(error_values), as.factor(sample_class), ncomp = 2)
pls_scores <- data.frame(comp1 = pls_model$scores[,1], comp2 = pls_model$scores[,2], class = sample_class)
```

And plot the PLS scores:


```r
ggplot(pls_scores, aes(x = comp1, y = comp2, color = class)) + geom_point(size = 4) + ggtitle("PLS-DA of Random Data")
```

![plot of chunk plot_plsda](/home/rmflight/Projects/personal/researchBlog/researchBlog/img/plot_plsda-1.png) 

And voila! Perfectly separated data! If I didn't tell you that it was random, would
you suspect it?

## Cross-validated PLS-DA

Of course, one way to truly assess the worth of the model would be to use
cross-validation, where a fraction of data is held back, and the model trained
on the rest. Predictions are then made on the held back fraction, and because we
know the truth, we will then calculate the **area under the reciever operator curve**
(AUROC) or area under the curve (AUC) created by plotting true positives *vs* 
false positives.

To do this we will need two functions:

1. Generates all of the CV folds
2. Generates PLS-DA model, does prediction on hold out, calculates AUC


```r
library(cvTools)
library(ROCR)

gen_cv <- function(xdata, ydata, nrep, kfold){
  n_sample <- length(ydata)
  all_index <- seq(1, n_sample)
  cv_data <- cvFolds(n_sample, K = kfold, R = nrep, type = "random")
  
  rep_values <- vapply(seq(1, nrep), function(in_rep){
    use_rep <- cv_data$subsets[, in_rep]
    cv_values <- vapply(seq(1, kfold), function(in_fold){
      test_index <- use_rep[cv_data$which == in_fold]
      train_index <- all_index[-test_index]
      
      plsda_cv(xdata[train_index, ], ydata[train_index], xdata[test_index, ],
               ydata[test_index])
    }, numeric(1))
  }, numeric(kfold))
}

plsda_cv <- function(xtrain, ytrain, xtest, ytest){
  pls_model <- plsda(xtrain, ytrain, ncomp = 2)
  pls_pred <- predict(pls_model, xtest, type = "prob")
  
  use_pred <- pls_pred[, 2, 1]
  
  pred_perf <- ROCR::prediction(use_pred, ytest)
  pred_auc <- ROCR::performance(pred_perf, "auc")@y.values[[1]]
  return(pred_auc)
}
```

And now lets do a bunch of replicates (100).


```r
cv_vals <- gen_cv(t(error_values), factor(sample_class), nrep = 100, kfold = 5)

mean(cv_vals)
```

```
## [1] 0.4182644
```

```r
sd(cv_vals)
```

```
## [1] 0.1086778
```

```r
cv_frame <- data.frame(auc = as.vector(cv_vals))
ggplot(cv_frame, aes(x = auc)) + geom_histogram(binwidth = 0.01)
```

![plot of chunk rep_plsda](/home/rmflight/Projects/personal/researchBlog/researchBlog/img/rep_plsda-1.png) 

So we get an average AUC of 0.4182644, which is pretty awful. This implies
that even though there was good separation on the scores, maybe the model is
not actually that good, and we should be cautious of any predictions being made.

Of course, the PCA at the beginning of the analysis shows that there is no *real*
separation in the data in the first place. 


```r
devtools::session_info()
```

```
## Session info --------------------------------------------------------------
```

```
##  setting  value                       
##  version  R version 3.2.2 (2015-08-14)
##  system   x86_64, linux-gnu           
##  ui       RStudio (0.99.723)          
##  language (EN)                        
##  collate  en_US.UTF-8                 
##  tz       America/New_York            
##  date     2015-12-12
```

```
## Packages ------------------------------------------------------------------
```

```
##  package           * version    date      
##  bitops              1.0-6      2013-08-17
##  car                 2.1-0      2015-09-03
##  caret             * 6.0-58     2015-10-22
##  caTools             1.17.1     2014-09-10
##  codetools           0.2-14     2015-07-15
##  colorspace          1.2-6      2015-03-11
##  cowplot           * 0.5.0      2015-07-01
##  cvTools           * 0.3.2      2012-05-14
##  DEoptimR            1.0-4      2015-10-23
##  devtools            1.9.1.9000 2015-11-18
##  digest              0.6.8      2014-12-31
##  evaluate            0.8        2015-09-18
##  fakeDataWithError * 0.0.1      2015-10-19
##  foreach             1.4.3      2015-10-13
##  formatR             1.2.1      2015-09-18
##  gdata               2.17.0     2015-07-04
##  ggplot2           * 1.0.1      2015-03-17
##  gplots            * 2.17.0     2015-05-02
##  gtable              0.1.2      2012-12-05
##  gtools              3.5.0      2015-05-29
##  highr               0.5.1      2015-09-18
##  httpuv              1.3.3      2015-08-04
##  iterators           1.0.8      2015-10-13
##  KernSmooth          2.23-15    2015-06-29
##  knitr             * 1.11       2015-08-14
##  labeling            0.3        2014-08-23
##  lattice           * 0.20-33    2015-07-14
##  lme4                1.1-10     2015-10-06
##  magrittr            1.5        2014-11-22
##  markdown          * 0.7.7      2015-04-22
##  MASS                7.3-44     2015-08-30
##  Matrix              1.2-2      2015-07-08
##  MatrixModels        0.4-1      2015-08-22
##  memoise             0.2.1      2014-04-22
##  mgcv                1.8-9      2015-10-30
##  mime                0.4        2015-09-03
##  minqa               1.2.4      2014-10-09
##  munsell             0.4.2      2013-07-11
##  nlme                3.1-122    2015-08-19
##  nloptr              1.0.4      2014-08-04
##  nnet                7.3-11     2015-08-30
##  pbkrtest            0.4-2      2014-11-13
##  pls                 2.5-0      2015-08-22
##  plyr                1.8.3      2015-06-12
##  proto               0.3-10     2012-12-22
##  quantreg            5.19       2015-08-31
##  randomForest      * 4.6-12     2015-10-07
##  Rcpp                0.12.2     2015-11-15
##  reshape2            1.4.1      2014-12-06
##  RJSONIO           * 1.3-0      2014-07-28
##  robustbase        * 0.92-5     2015-07-22
##  ROCR              * 1.0-7      2015-03-26
##  rstudioapi          0.3.1      2015-04-07
##  samatha           * 0.3        2015-11-17
##  scales              0.3.0      2015-08-25
##  servr             * 0.2        2015-03-30
##  SparseM             1.7        2015-08-15
##  stringi             1.0-1      2015-10-22
##  stringr           * 1.0.0      2015-04-30
##  XML               * 3.98-1.3   2015-06-30
##  source                          
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  Github (hadley/devtools@b4edf3e)
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  local                           
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  local                           
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)                  
##  CRAN (R 3.2.2)
```

