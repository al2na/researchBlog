% R, bioconductor, cdf

# Creating custom CDF for Affy chips in R / Bioconductor




## What?

For those who don't know, **CDF** files are chip definition format files that define which probes belong to which probesets, and are necessary to use any of the standard summarization methods such as **RMA**, and others.

## Why?

Because we can, and because custom definitions have been shown to be quite useful. See the information over at [Brainarray][linkBrain].

## Why not somewhere else?

A lot of times other people create custom **CDF** files based on their own criteria, and make it subsequently available for others to use (see the [Brainarray][linkBrain] for an example of what some are doing, as well as [PlandbAffy][linkplandb]) 


You have a really nifty idea for a way to reorganize the probesets on an Affymetrix chip to perform a custom analysis, but you don't want to go to the trouble of actually creating the CDF files and Bioconductor packages normally required to do the analysis, and yet you want to test and develop your analysis method.

## How?

It turns out you are in luck. At least for **AffyBatch** objects in Bioconductor (created by calling **ReadAffy**), the **CDF** information is stored as an attached environment that can be easily hacked and modified to your hearts content. Environments in R are quite important and useful, and I wouldn't have come up with this if I hadn't been working in R for the past couple of years, but figured someone else might benefit from this knowledge.

## The environment

In R, one can access an environment like so:


```r
get("objName", envName)  # get the value of object in the environment
ls(envName)
```


What is also very cool, is that one can extract the objects in an environment to a list, and also create their own environment from a list using `list2env`. Using this methodology, we can create our own definition of probesets that can be used by standard Bioconductor routines to summarize the probes into probesets.

A couple of disclaimers:  

* I have only tried this on 3' expression arrays
* There might be a better way to do this, but I couldn't find it (let me know in the comments)

## Example


```r
require(affy)
require(estrogen)
require(hgu95av2cdf)

datadir = system.file("extdata", package = "estrogen")

pd = read.AnnotatedDataFrame(file.path(datadir, "estrogen.txt"), header = TRUE, 
    sep = "", row.names = 1)
pData(pd)
```

```
##              estrogen time.h
## low10-1.cel    absent     10
## low10-2.cel    absent     10
## high10-1.cel  present     10
## high10-2.cel  present     10
## low48-1.cel    absent     48
## low48-2.cel    absent     48
## high48-1.cel  present     48
## high48-2.cel  present     48
```

```r

celDat = ReadAffy(filenames = rownames(pData(pd)), phenoData = pd, verbose = TRUE, 
    celfile.path = datadir)
```

```
## 1 reading /mlab/data/rmflight/RLibs_bioc213/estrogen/extdata/low10-1.cel ...instantiating an AffyBatch (intensity a 409600x8 matrix)...done.
## Reading in : /mlab/data/rmflight/RLibs_bioc213/estrogen/extdata/low10-1.cel
## Reading in : /mlab/data/rmflight/RLibs_bioc213/estrogen/extdata/low10-2.cel
## Reading in : /mlab/data/rmflight/RLibs_bioc213/estrogen/extdata/high10-1.cel
## Reading in : /mlab/data/rmflight/RLibs_bioc213/estrogen/extdata/high10-2.cel
## Reading in : /mlab/data/rmflight/RLibs_bioc213/estrogen/extdata/low48-1.cel
## Reading in : /mlab/data/rmflight/RLibs_bioc213/estrogen/extdata/low48-2.cel
## Reading in : /mlab/data/rmflight/RLibs_bioc213/estrogen/extdata/high48-1.cel
## Reading in : /mlab/data/rmflight/RLibs_bioc213/estrogen/extdata/high48-2.cel
```


This loads up the data, reads in the raw data, and gets it ready for us to use. Now, lets see what is in the actual **CDF** environment.


```r
topProbes <- head(ls(hgu95av2cdf))  # get a list of probesets
topProbes
```

```
## [1] "1000_at"   "1001_at"   "1002_f_at" "1003_s_at" "1004_at"   "1005_at"
```

```r

exSet <- get(topProbes[1], hgu95av2cdf)
exSet
```

```
##           pm     mm
##  [1,] 358160 358800
##  [2,] 118945 119585
##  [3,] 323731 324371
##  [4,] 223978 224618
##  [5,] 313420 314060
##  [6,] 349209 349849
##  [7,] 199525 200165
##  [8,] 213669 214309
##  [9,] 236739 237379
## [10,] 298099 298739
## [11,] 282744 283384
## [12,] 281443 282083
## [13,] 349198 349838
## [14,] 297953 298593
## [15,] 317054 317694
## [16,] 404069 404709
```


We can see here that the first probe set 1000_at has 16 perfect-match and mis-match probes in associated with it. 

Lets summarize the original data using RMA.


```r
rma1 <- exprs(rma(celDat))
```

```
## Background correcting
## Normalizing
## Calculating Expression
```

```r

head(rma1)
```

```
##           low10-1.cel low10-2.cel high10-1.cel high10-2.cel low48-1.cel
## 1000_at        10.398      10.254       10.004        9.904      10.375
## 1001_at         5.718       5.881        5.860        5.954       5.961
## 1002_f_at       5.513       5.802        5.571        5.608       5.390
## 1003_s_at       7.784       8.008        8.038        7.835       7.927
## 1004_at         7.289       7.604        7.489        7.772       7.522
## 1005_at         9.207       8.994        8.238        8.338       9.173
##           low48-2.cel high48-1.cel high48-2.cel
## 1000_at        10.034       10.345        9.863
## 1001_at         6.021        5.981        6.285
## 1002_f_at       5.494        5.508        5.630
## 1003_s_at       8.139        7.995        8.233
## 1004_at         7.600        7.456        7.675
## 1005_at         9.040        7.926        8.070
```


Now lets get the data as a list, and then create a new environment to be used for summarization.


```r
allSets <- ls(hgu95av2cdf)
allSetDat <- mget(allSets, hgu95av2cdf)

allSetDat[1]
```

```
## $`1000_at`
##           pm     mm
##  [1,] 358160 358800
##  [2,] 118945 119585
##  [3,] 323731 324371
##  [4,] 223978 224618
##  [5,] 313420 314060
##  [6,] 349209 349849
##  [7,] 199525 200165
##  [8,] 213669 214309
##  [9,] 236739 237379
## [10,] 298099 298739
## [11,] 282744 283384
## [12,] 281443 282083
## [13,] 349198 349838
## [14,] 297953 298593
## [15,] 317054 317694
## [16,] 404069 404709
```

```r

hgu2 <- list2env(allSetDat)
celDat@cdfName <- "hgu2"

rma2 <- exprs(rma(celDat))
```

```
## Background correcting
## Normalizing
## Calculating Expression
```

```r
head(rma2)
```

```
##           low10-1.cel low10-2.cel high10-1.cel high10-2.cel low48-1.cel
## 1000_at        10.398      10.254       10.004        9.904      10.375
## 1001_at         5.718       5.881        5.860        5.954       5.961
## 1002_f_at       5.513       5.802        5.571        5.608       5.390
## 1003_s_at       7.784       8.008        8.038        7.835       7.927
## 1004_at         7.289       7.604        7.489        7.772       7.522
## 1005_at         9.207       8.994        8.238        8.338       9.173
##           low48-2.cel high48-1.cel high48-2.cel
## 1000_at        10.034       10.345        9.863
## 1001_at         6.021        5.981        6.285
## 1002_f_at       5.494        5.508        5.630
## 1003_s_at       8.139        7.995        8.233
## 1004_at         7.600        7.456        7.675
## 1005_at         9.040        7.926        8.070
```


What about removing the **MM** columns? RMA only uses the **PM**, so it should still work.


```r
allSetDat <- lapply(allSetDat, function(x) {
    x[, 1, drop = F]
})

allSetDat[1]
```

```
## $`1000_at`
##           pm
##  [1,] 358160
##  [2,] 118945
##  [3,] 323731
##  [4,] 223978
##  [5,] 313420
##  [6,] 349209
##  [7,] 199525
##  [8,] 213669
##  [9,] 236739
## [10,] 298099
## [11,] 282744
## [12,] 281443
## [13,] 349198
## [14,] 297953
## [15,] 317054
## [16,] 404069
```

```r

hgu3 <- list2env(allSetDat)
celDat@cdfName <- "hgu3"
rma3 <- exprs(rma(celDat))
```

```
## Background correcting
## Normalizing
## Calculating Expression
```

```r
head(rma3)
```

```
##           low10-1.cel low10-2.cel high10-1.cel high10-2.cel low48-1.cel
## 1000_at        10.398      10.254       10.004        9.904      10.375
## 1001_at         5.718       5.881        5.860        5.954       5.961
## 1002_f_at       5.513       5.802        5.571        5.608       5.390
## 1003_s_at       7.784       8.008        8.038        7.835       7.927
## 1004_at         7.289       7.604        7.489        7.772       7.522
## 1005_at         9.207       8.994        8.238        8.338       9.173
##           low48-2.cel high48-1.cel high48-2.cel
## 1000_at        10.034       10.345        9.863
## 1001_at         6.021        5.981        6.285
## 1002_f_at       5.494        5.508        5.630
## 1003_s_at       8.139        7.995        8.233
## 1004_at         7.600        7.456        7.675
## 1005_at         9.040        7.926        8.070
```


What if we only want to use the first 5 probesets?


```r
allSetDat <- allSetDat[1:5]
hgu4 <- list2env(allSetDat)
celDat@cdfName <- "hgu4"
celDat
```

```
## AffyBatch object
## size of arrays=640x640 features (20 kb)
## cdf=hgu4 (5 affyids)
## number of samples=8
## number of genes=5
## annotation=hgu95av2
## notes=
```

```r
rma4 <- exprs(rma(celDat))
```

```
## Background correcting
## Normalizing
## Calculating Expression
```

```r
rma4
```

```
##           low10-1.cel low10-2.cel high10-1.cel high10-2.cel low48-1.cel
## 1000_at        10.125       9.967        9.966        9.966      10.047
## 1001_at         5.842       5.903        5.892        5.950       6.032
## 1002_f_at       5.664       5.823        5.729        5.737       5.616
## 1003_s_at       7.831       7.880        7.941        7.858       7.880
## 1004_at         7.324       7.512        7.526        7.673       7.495
##           low48-2.cel high48-1.cel high48-2.cel
## 1000_at         9.966       10.154        9.776
## 1001_at         6.038        6.028        5.984
## 1002_f_at       5.710        5.619        5.670
## 1003_s_at       7.963        7.930        7.986
## 1004_at         7.344        7.345        7.484
```

```r
dim(rma4)
```

```
## [1] 5 8
```


## Custom CDF

To generate our custom CDF, we are going to set our own names, and take random probes from all of the probes on the chip. The actual criteria of which probes should be together can be made using any method the author chooses.


```r
maxIndx <- 640 * 640

customCDF <- lapply(seq(1, 100), function(x) {
    tmp <- matrix(sample(maxIndx, 20), nrow = 20, ncol = 1)
    colnames(tmp) <- "pm"
    return(tmp)
})

names(customCDF) <- seq(1, 100)

hgu5 <- list2env(customCDF)
celDat@cdfName <- "hgu5"
rma5 <- exprs(rma(celDat))
```

```
## Background correcting
## Normalizing
## Calculating Expression
```

```r

head(rma5)
```

```
##     low10-1.cel low10-2.cel high10-1.cel high10-2.cel low48-1.cel
## 1         6.412       6.767        6.407        6.583       6.689
## 10        6.706       6.729        6.803        6.628       6.820
## 100       6.543       6.558        6.639        6.718       6.494
## 11        6.397       6.305        6.345        6.228       6.510
## 12        7.191       7.178        7.371        7.218       7.330
## 13        7.369       7.321        7.218        7.262       7.506
##     low48-2.cel high48-1.cel high48-2.cel
## 1         6.606        6.346        6.382
## 10        6.638        6.489        6.729
## 100       6.545        6.693        6.695
## 11        6.372        6.481        6.438
## 12        7.396        7.249        7.332
## 13        7.379        7.438        7.518
```


I hope this information is useful to someone else. I know it made my life a lot easier.


```r
sessionInfo()
```

```
## R version 3.0.1 (2013-05-16)
## Platform: x86_64-unknown-linux-gnu (64-bit)
## 
## locale:
##  [1] LC_CTYPE=en_US.UTF-8       LC_NUMERIC=C              
##  [3] LC_TIME=en_US.UTF-8        LC_COLLATE=en_US.UTF-8    
##  [5] LC_MONETARY=en_US.UTF-8    LC_MESSAGES=en_US.UTF-8   
##  [7] LC_PAPER=C                 LC_NAME=C                 
##  [9] LC_ADDRESS=C               LC_TELEPHONE=C            
## [11] LC_MEASUREMENT=en_US.UTF-8 LC_IDENTIFICATION=C       
## 
## attached base packages:
## [1] tools     parallel  stats     graphics  grDevices utils     datasets 
## [8] methods   base     
## 
## other attached packages:
##  [1] samatha_0.3          servr_0.1            XML_3.98-1.1        
##  [4] RJSONIO_1.0-3        markdown_0.6.3       knitr_1.5           
##  [7] stringr_0.6.2        hgu95av2cdf_2.13.0   AnnotationDbi_1.24.0
## [10] estrogen_1.8.12      affy_1.40.0          Biobase_2.22.0      
## [13] BiocGenerics_0.8.0   BiocInstaller_1.12.0
## 
## loaded via a namespace (and not attached):
##  [1] affyio_1.30.0         DBI_0.2-7             evaluate_0.5.1       
##  [4] formatR_0.10          httpuv_1.2.0          IRanges_1.20.6       
##  [7] preprocessCore_1.24.0 RSQLite_0.11.4        stats4_3.0.1         
## [10] zlibbioc_1.8.0
```


Originally published 2013/07/13, moved to http://rmflight.github.io on 2013/12/04.

[linkBrain]: http://brainarray.mbni.med.umich.edu/brainarray/Database/CustomCDF/cdfreadme.htm
[linkplandb]: http://affymetrix2.bioinf.fbb.msu.ru/
