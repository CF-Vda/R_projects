#!/usr/bin/env Rscript
#- ----------------------------------------------------------------------
#-  Copyright (c) 1995-2013, Ecometer s.n.c. ?
#-  Author: Paolo Saudin.
#-
#-  RESOURCE : http://google-styleguide.googlecode.com/svn/trunk/google-r-style.html
#-
#-  LIBRARY COMMON FUNCTIONS
#-
#- ----------------------------------------------------------------------

#- ----------------------------------------------------------------------
#- load libraries
#- ----------------------------------------------------------------------
require(futile.logger)

#- ----------------------------------------------------------------------
#- logging function
#- ----------------------------------------------------------------------
LOG.Init <- function(LOG.level) {
    # flog.info("Will print: %s", FALSE)
    # flog.warn("Will print: %s", FALSE)
    # flog.error("Will print: %s", TRUE)
    # flog.fatal("Will print: %s", TRUE)    
    #- inizialize logger - TRACE, DEBUG, INFO, WARN, ERROR, FATAL
    flog.threshold(DEBUG)
    appender.console()
    filename <- paste("app-",format(Sys.time(),"%Y-%m-%d"),'.log',sep='')
    flog.appender(appender.file(filename))
    #- log
    if (DEBUG) flog.info("LOG inizialized")
}

#- ----------------------------------------------------------------------
#- ini file function
#- ----------------------------------------------------------------------
# Thanks to Gabor Grothendieck for helpful suggestions in the R-Help
# mailing list on how to parse the INI file.
# https://stat.ethz.ch/pipermail/r-help/2007-June/134055.html
INI.Parse <- function(INI.filename) {
    #- log
    if (DEBUG) flog.info("Reading ini file %s ...", INI.filename)
    #- ini file
    connection <- file(INI.filename)
    Lines  <- readLines(connection)
    close(connection)
    Lines <- chartr("[]", "==", Lines)  # change section headers
    connection <- textConnection(Lines)
    d <- read.table(connection, as.is = TRUE, sep = "=", fill = TRUE)
    close(connection)
    L <- d$V1 == "" # location of section breaks
    d <- subset(transform(d, V3 = V2[which(L)[cumsum(L)]])[1:3], V1 != "")
    ToParse  <- paste("INI.list$", d$V3, "$",  d$V1, " <- '", d$V2, "'", sep="")
    INI.list <- list()
    eval(parse(text=ToParse))
    #- log
    if (DEBUG) flog.info("Done.")
    return(INI.list)
}

#- ---------------------------------------------------------------------
#- - common functions
#- ---------------------------------------------------------------------
#- store a data.frame into file
dataframe_dump <- function(data_frame, file_name) {
    #- write to stdout
    #write.csv(data_frame, quote = FALSE, file = file_name, sep = "\t")
    write.table(data_frame, quote = FALSE, file = file_name, append = FALSE,
                row.names = FALSE, sep = "\t", eol = "\n", qmethod = "double")
}

#- ----------------------------------------------------------------------
#- print out a data.frame
#- ----------------------------------------------------------------------
dataframe_report <- function(data_frame) {
    #- write to stdout
    print(data_frame, na.print = "", digits = NULL,
          quote = FALSE, right = TRUE, row.names = TRUE)
}

#- ----------------------------------------------------------------------
#- profiling
#- ----------------------------------------------------------------------
PRO.Start <- function() {
    RprofDir <- file.path(getwd(),"tmp")
    if (!file.exists(RprofDir)) dir.create(RprofDir)
    RprofFile<-file.path(RprofDir,"profile.log")
    Rprof(filename = RprofFile, append = FALSE, interval = 0.01, memory.profiling=TRUE)
}
PRO.Stop <- function() {
    Rprof(NULL)
}
