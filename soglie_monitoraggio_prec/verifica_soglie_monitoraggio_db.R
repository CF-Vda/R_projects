#!/usr/bin/env Rscript
#- ----------------------------------------------------------------------
#-  Copyright (c) 1995-2013, Ecometer s.n.c.
#-  Author: Paolo Saudin.
#-
#-  RESOURCE : http://google-styleguide.googlecode.com/svn/trunk/google-r-style.html
#-
#-  SCRIPT : SOGLIE DATA COLLECTOR
#-
#- install.packages("RPostgreSQL")
#- install.packages("futile.logger")
#-
#- ssh ubuntu@192.168.182.131
#- ssh -i ~/.ssh/id_dsa_nopwd admin@cf-nas.regione.vda.it -L 5432:192.168.7.11:5432
#-
#- http://wbond.net/ : Mapping a Local Folder to a Remote Folder
#- ----------------------------------------------------------------------

#- ----------------------------------------------------------------------
#- set application working directory
 if(.Platform$OS.type == "windows") {  
   setwd('C:\\Progetti_R\\soglie_monitoraggio_prec')
} else if(.Platform$OS.type == "unix") {
   setwd("~/")
}


#- ----------------------------------------------------------------------
#- load libraries

#- ----------------------------------------------------------------------
#- load common function library
source("../common/lib_functions.R")
source("../common/lib_pgsql.R")

#- ----------------------------------------------------------------------
#- debug
DEBUG=1

#- ----------------------------------------------------------------------
#- init logging - TRACE, DEBUG, INFO, WARN, ERROR, FATAL
LOG.Init("DEBUG")

#- ----------------------------------------------------------------------
#- start up
flog.debug("----------------------------------- S T A R   U P -----------------------------------")

#- ----------------------------------------------------------------------
#- reading ini file
CONF <- INI.Parse("soglie.ini")

#- ----------------------------------------------------------------------
#- clean up
#rm(list=ls(all=TRUE)) 

x[1]=paste(CONF$Options$base_path, "input","monitoraggio_prec_A.txt", sep="/")
x[2]=paste(CONF$Options$base_path, "input","monitoraggio_prec_B.txt", sep="/")
x[3]=paste(CONF$Options$base_path, "input","monitoraggio_prec_C.txt", sep="/")
x[4]=paste(CONF$Options$base_path, "input","monitoraggio_prec_D.txt", sep="/")
x[5]=paste(CONF$Options$base_path, "input","cancellinova_36ore.txt", sep="/")
x[6]=paste(CONF$Options$base_path, "input","zero_termVDA_36ore.txt", sep="/")
unlink(x, recursive = FALSE, force = TRUE)

#- ----------------------------------------------------------------------
#- user settings
flog.info("user settings")

external_program='C:/Progetti_R/soglie_monitoraggio_prec/verifica_soglie_monitoraggio_prec.R'

#- ----------------------------------------------------------------------
#- disconnect all connection from db
PG.DisconnectAll()

#- ----------------------------------------------------------------------
#- connect to database server
DBH <- PG.Connect(CONF$Database)

#- get bulletin ID - year + julian day
jd <- as.numeric(format(Sys.Date(), "%Y%j"))

#-- build the precipitaz.txt query

#[...]


#- ----------------------------------------------------------------------
#- disconnect from database server
PG.Disconnect(DBH)

#- ----------------------------------------------------------------------
#- denise -

source(external_program)


#- ----------------------------------------------------------------------
#- end -
flog.debug("----------------------------------- E N D -----------------------------------")
flog.debug("")
