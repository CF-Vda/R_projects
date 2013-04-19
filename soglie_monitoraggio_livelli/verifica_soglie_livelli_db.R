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
  script.dir <- dirname(sys.frame(1)$ofile)
  setwd(script.dir)
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

x<-paste(CONF$Options$base_path, "input","livelli_36ore.txt", sep="/")
unlink(x, recursive = FALSE, force = TRUE)

#- ----------------------------------------------------------------------
#- user settings
flog.info("user settings")

external_program='C:/Progetti_R/soglie_monitoraggio_livelli/verifica_soglie_livelli_idro.R'


#- ----------------------------------------------------------------------
#- disconnect all connection from db
PG.DisconnectAll()

#- ----------------------------------------------------------------------
#- connect to database server
DBH <- PG.Connect(CONF$Database)

#- get bulletin ID - year + julian day
jd <- as.numeric(format(Sys.Date(), "%Y%j"))

#- ----------------------------------------------------------------------
#-- build the livelli_36ore query
stids <- '1720,1000,1060,1560,1110,1260,1290,1320,1460,1130,1520,1550,1650,1490,1570,1640,1310,1100,1480,1430,1020'
#-- stations names
query <- paste("SELECT st_id FROM _stations WHERE st_id IN (",stids,")", sep="")
dbdata <- PG.ExecuteQuery(DBH, query)
# transpose table
dbdata <- t(dbdata)

if (DEBUG) dataframe_report(dbdata)
#- ----------------------------------------------------------------------
#- export file - work dir + ....
file <- paste(CONF$Options$base_path, "input","livelli_36ore.txt", sep="/")
dataframe_dump(dbdata, file,TRUE, FALSE)

#-- data
query <- paste("SELECT * FROM tool_meteolab.build_query_soglie_hidro_stids_hours(ARRAY[",stids,"]::smallint[], 36::smallint)", sep="")
dbdata <- PG.ExecuteQuery(DBH, query)
query2exe <- dbdata[1,1]
dbdata <- PG.ExecuteQuery(DBH, query2exe)
#- remove first column
#dbdata <- dbdata[,-1]
if (DEBUG) dataframe_report(dbdata)
#- ----------------------------------------------------------------------
#- export file - work dir + ....
file <- paste(CONF$Options$base_path, "input","livelli_36ore.txt", sep="/")
dataframe_dump(dbdata, file,FALSE, TRUE, TRUE)

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