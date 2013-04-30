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
x<-character(6)
x[1]<-paste(CONF$Options$base_path, "input","cancellinova_36ore.txt", sep="/")
x[2]<-paste(CONF$Options$base_path, "input","zero_termVDA_36ore.txt", sep="/")
x[3]<-paste(CONF$Options$base_path, "input","monitoraggio_prec_A.txt", sep="/")
x[4]<-paste(CONF$Options$base_path, "input","monitoraggio_prec_B.txt", sep="/")
x[5]<-paste(CONF$Options$base_path, "input","monitoraggio_prec_C.txt", sep="/")
x[6]<-paste(CONF$Options$base_path, "input","monitoraggio_prec_D.txt", sep="/")
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


#- ----------------------------------------------------------------------
#-- build the monitoraggio_prec_A query
stids <- '1000,1080,1230,1420,1430,1450,1480,1720,3020,3010,3080,3120,3560,4090,4000,2530'
#-- stations names
query <- paste("SELECT st_id FROM _stations WHERE st_id IN (",stids,")", sep="")
dbdata <- PG.ExecuteQuery(DBH, query)
# transpose table
dbdata <- t(dbdata)
# Set the column headings
#colnames(dbdata) <- dbdata[1,]
if (DEBUG) dataframe_report(dbdata)
#- ----------------------------------------------------------------------
#- export file - work dir + ....
file <- paste(CONF$Options$base_path, "input","monitoraggio_prec_A.txt", sep="/")
dataframe_dump(dbdata, file,TRUE,FALSE,FALSE)

#-- data
query <- paste("SELECT * FROM tool_meteolab.build_query_soglie_rain_stids_hours(ARRAY[",stids,"]::smallint[], 35::smallint)", sep="")
dbdata <- PG.ExecuteQuery(DBH, query)
query2exe <- dbdata[1,1]
dbdata <- PG.ExecuteQuery(DBH, query2exe)
#- remove first column
#dbdata <- dbdata[,-1]
if (DEBUG) dataframe_report(dbdata)
#- ----------------------------------------------------------------------
#- export file - work dir + ....
file <- paste(CONF$Options$base_path, "input","monitoraggio_prec_A.txt", sep="/")
dataframe_dump(dbdata, file, FALSE,TRUE,TRUE)


#- ----------------------------------------------------------------------
#-- build the monitoraggio_prec_B query
stids <- '1060,1090,1120,1110,1240,1270,1260,1300,1310,1320,1370,1470,3570,3000,3040,3050,3530,4110,2560,1280,1730'

#-- stations names
query <- paste("SELECT st_id FROM _stations WHERE st_id IN (",stids,")", sep="")
dbdata <- PG.ExecuteQuery(DBH, query)
# transpose table
dbdata <- t(dbdata)
# Set the column headings
#colnames(dbdata) <- dbdata[1,]
if (DEBUG) dataframe_report(dbdata)
#- ----------------------------------------------------------------------
#- export file - work dir + ....
file <- paste(CONF$Options$base_path, "input","monitoraggio_prec_B.txt", sep="/")
dataframe_dump(dbdata, file,TRUE,FALSE,FALSE)

#-- data
query <- paste("SELECT * FROM tool_meteolab.build_query_soglie_rain_stids_hours(ARRAY[",stids,"]::smallint[], 35::smallint)", sep="")
dbdata <- PG.ExecuteQuery(DBH, query)
query2exe <- dbdata[1,1]
dbdata <- PG.ExecuteQuery(DBH, query2exe)
#- remove first column
#dbdata <- dbdata[,-1]
if (DEBUG) dataframe_report(dbdata)
#- ----------------------------------------------------------------------
#- export file - work dir + ....
file <- paste(CONF$Options$base_path, "input","monitoraggio_prec_B.txt", sep="/")
dataframe_dump(dbdata, file, FALSE,TRUE,TRUE)



#- ----------------------------------------------------------------------
#-- build the monitoraggio_prec_C query
stids <- '1030,1160,1150,1140,4070,1250,1520,1530,1550,1670,1660,1650,3060,3070,2540'

#-- stations names
query <- paste("SELECT st_id FROM _stations WHERE st_id IN (",stids,")", sep="")
dbdata <- PG.ExecuteQuery(DBH, query)
# transpose table
dbdata <- t(dbdata)
# Set the column headings
#colnames(dbdata) <- dbdata[1,]
if (DEBUG) dataframe_report(dbdata)
#- ----------------------------------------------------------------------
#- export file - work dir + ....
file <- paste(CONF$Options$base_path, "input","monitoraggio_prec_C.txt", sep="/")
dataframe_dump(dbdata, file,TRUE,FALSE,FALSE)

#-- data
query <- paste("SELECT * FROM tool_meteolab.build_query_soglie_rain_stids_hours(ARRAY[",stids,"]::smallint[], 35::smallint)", sep="")
dbdata <- PG.ExecuteQuery(DBH, query)
query2exe <- dbdata[1,1]
dbdata <- PG.ExecuteQuery(DBH, query2exe)
#- remove first column
#dbdata <- dbdata[,-1]
if (DEBUG) dataframe_report(dbdata)
#- ----------------------------------------------------------------------
#- export file - work dir + ....
file <- paste(CONF$Options$base_path, "input","monitoraggio_prec_C.txt", sep="/")
dataframe_dump(dbdata, file, FALSE,TRUE,TRUE)


#- ----------------------------------------------------------------------
#-- build the monitoraggio_prec_D query
stids <- '1040,1170,1190,1220,1330,1340,1360,1390,1440,1490,1590,1620,1630,1700,1710,3030,3110,3510,3590,4050,4080,2800,1600,1200,1500'

#-- stations names
query <- paste("SELECT st_id FROM _stations WHERE st_id IN (",stids,")", sep="")
dbdata <- PG.ExecuteQuery(DBH, query)
# transpose table
dbdata <- t(dbdata)
# Set the column headings
#colnames(dbdata) <- dbdata[1,]
if (DEBUG) dataframe_report(dbdata)
#- ----------------------------------------------------------------------
#- export file - work dir + ....
file <- paste(CONF$Options$base_path, "input","monitoraggio_prec_D.txt", sep="/")
dataframe_dump(dbdata, file,TRUE,FALSE,FALSE)

#-- data
query <- paste("SELECT * FROM tool_meteolab.build_query_soglie_rain_stids_hours(ARRAY[",stids,"]::smallint[], 35::smallint)", sep="")
dbdata <- PG.ExecuteQuery(DBH, query)
query2exe <- dbdata[1,1]
dbdata <- PG.ExecuteQuery(DBH, query2exe)
#- remove first column
#dbdata <- dbdata[,-1]
if (DEBUG) dataframe_report(dbdata)
#- ----------------------------------------------------------------------
#- export file - work dir + ....
file <- paste(CONF$Options$base_path, "input","monitoraggio_prec_D.txt", sep="/")
dataframe_dump(dbdata, file, FALSE,TRUE,TRUE)


#- ----------------------------------------------------------------------
#-- build the cancellinova_36ore query
query <- paste("
               SELECT
               m.fulldate AS data,
               case when (tables_qca.tbl_zona_a.id_4_cod <= 2 ) then round(cast( tables_qca.tbl_zona_a.id_4  AS numeric), 1) end AS zonaa,
               case when (tables_qca.tbl_zona_b.id_4_cod <= 2 ) then round(cast( tables_qca.tbl_zona_b.id_4  AS numeric), 1) end AS zonab,
               case when (tables_qca.tbl_zona_c.id_4_cod <= 2 ) then round(cast( tables_qca.tbl_zona_c.id_4  AS numeric), 1) end AS zonac,
               case when (tables_qca.tbl_zona_d.id_4_cod <= 2 ) then round(cast( tables_qca.tbl_zona_d.id_4  AS numeric), 1) end AS zonad
               FROM _master m
               LEFT JOIN tables_qca.tbl_zona_a USING(fulldate)
               LEFT JOIN tables_qca.tbl_zona_b USING(fulldate)
               LEFT JOIN tables_qca.tbl_zona_c USING(fulldate)
               LEFT JOIN tables_qca.tbl_zona_d USING(fulldate)
               WHERE m.fulldate >= date_trunc('hour', TIMEZONE('UTC',CURRENT_TIMESTAMP) - interval '35 hour')
               ORDER BY data LIMIT 36", sep="")
dbdata <- PG.ExecuteQuery(DBH, query)
#- remove first column
dbdata <- dbdata[,-1]
if (DEBUG) dataframe_report(dbdata)
#- ----------------------------------------------------------------------
#- export file - work dir + ....
file <- paste(CONF$Options$base_path, "input","cancellinova_36ore.txt", sep="/")
dataframe_dump(dbdata, file)



#- ----------------------------------------------------------------------
#-- build the zero_termVDA_36ore query
query <- paste("
               SELECT m.fulldate AS fulldate,
               CASE WHEN (tables_qca.tbl_zone_vda.id_2_cod <= 2 ) 
               THEN round(cast( tables_qca.tbl_zone_vda.id_2  AS numeric), 0) END AS vda_zero_termico
               FROM _master m
               LEFT JOIN tables_qca.tbl_zone_vda USING(fulldate )
               WHERE m.fulldate  >= date_trunc('hour', TIMEZONE('UTC',CURRENT_TIMESTAMP) - interval '35 hour')
               ORDER BY 1 LIMIT 36", sep="")
dbdata <- PG.ExecuteQuery(DBH, query)
#- remove first column
dbdata <- dbdata[,-1]
if (DEBUG) dataframe_report(dbdata)

#- ----------------------------------------------------------------------
#- export file - work dir + ....
file <- paste(CONF$Options$base_path, "input","zero_termVDA_36ore.txt", sep="/")
dataframe_dump(dbdata, file,FALSE,TRUE,FALSE)


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