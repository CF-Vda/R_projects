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
CONF <- INI.Parse("indicatori_rischio.ini")

#- ----------------------------------------------------------------------
#- clean up
#rm(list=ls(all=TRUE))

x[1]<-paste(CONF$Options$base_path, "input","precipitaz.txt", sep="/")
x[2]<-paste(CONF$Options$base_path, "input","zterm_qneve.txt", sep="/")
x[3]<-paste(CONF$Options$base_path, "input","portate_indicatori.txt", sep="/")
x[4]<-paste(CONF$Options$base_path, "input","zero_termVDA_36ore.txt", sep="/")
unlink(x, recursive = FALSE, force = TRUE)

#- ----------------------------------------------------------------------
#- user settings
flog.info("user settings")

external_program='C:/Progetti_R/indicatori rischio/Indicatori_rischio.R'


#- ----------------------------------------------------------------------
#- disconnect all connection from db
PG.DisconnectAll()

#- ----------------------------------------------------------------------
#- connect to database server
DBH <- PG.Connect(CONF$Database)

#- ----------------------------------------------------------------------
#- get bulletin ID - year + julian day
jd <- as.numeric(format(Sys.Date(), "%Y%j"))

#- ----------------------------------------------------------------------
#-- check bulletin exists - 0,1
query <- paste("SELECT count(*) FROM bulletins_meteo.bullettin_vigilance 
        WHERE bl_id = '",jd,"' AND pubblicato = true", sep="")
dbdata <- PG.ExecuteQuery(DBH, query)
if (DEBUG) dataframe_report(dbdata)

if(dbdata==0)
{#- disconnect from database server
  PG.Disconnect(DBH)
  # stop script
  stop("No vigilanza data", call.=F)
}


#- ----------------------------------------------------------------------
#-- build the precipitaz.txt query
query <- paste("
    SELECT
        'A' as zona,
        max(CASE WHEN id_h12=12 THEN med END)    AS pmed0,
        max(CASE WHEN id_h12=24 THEN med END)    AS pmed12,
        max(CASE WHEN id_h12=36 THEN med END)    AS pmed24,
        max(CASE WHEN id_h12=36 THEN max_12 END) AS pmax12h,
        max(CASE WHEN id_h12=36 THEN max_24 END) AS pmax24h
    FROM bulletins_meteo.bullettin_vigilance_data_h12
    WHERE bl_id = '",jd,"' AND zona='A'
    GROUP BY 1
    UNION ALL
    SELECT
        'B' as zona,
        max(CASE WHEN id_h12=12 THEN med END)    AS pmed0,
        max(CASE WHEN id_h12=24 THEN med END)    AS pmed12,
        max(CASE WHEN id_h12=36 THEN med END)    AS pmed24,
        max(CASE WHEN id_h12=36 THEN max_12 END) AS pmax12h,
        max(CASE WHEN id_h12=36 THEN max_24 END) AS pmax24h
    FROM bulletins_meteo.bullettin_vigilance_data_h12
    WHERE bl_id = '",jd,"' AND zona='B'
    GROUP BY 1
    UNION ALL
    SELECT
        'C' as zona,
        max(CASE WHEN id_h12=12 THEN med END)    AS pmed0,
        max(CASE WHEN id_h12=24 THEN med END)    AS pmed12,
        max(CASE WHEN id_h12=36 THEN med END)    AS pmed24,
        max(CASE WHEN id_h12=36 THEN max_12 END) AS pmax12h,
        max(CASE WHEN id_h12=36 THEN max_24 END) AS pmax24h
    FROM bulletins_meteo.bullettin_vigilance_data_h12
    WHERE bl_id = '",jd,"' AND zona='C'
    GROUP BY 1
    UNION ALL
    SELECT
        'D' as zona,
        max(CASE WHEN id_h12=12 THEN med END)    AS pmed0,
        max(CASE WHEN id_h12=24 THEN med END)    AS pmed12,
        max(CASE WHEN id_h12=36 THEN med END)    AS pmed24,
        max(CASE WHEN id_h12=36 THEN max_12 END) AS pmax12h,
        max(CASE WHEN id_h12=36 THEN max_24 END) AS pmax24h
    FROM bulletins_meteo.bullettin_vigilance_data_h12
    WHERE bl_id = '",jd,"' AND zona='D'
    GROUP BY 1", sep="")
dbdata <- PG.ExecuteQuery(DBH, query)
#- remove first column
dbdata <- dbdata[,-1]
if (DEBUG) dataframe_report(dbdata)

#- ----------------------------------------------------------------------
#- export file - work dir + ....
file <- paste(CONF$Options$base_path, "input","precipitaz.txt", sep="/")
dataframe_dump(dbdata, file)

#- ----------------------------------------------------------------------
#-- build the zterm_qneve.txt
query <- paste("
    SELECT
        'A' as zona,
        max(CASE WHEN id_h12=12 THEN zero_termico END) AS zt_0,
        max(CASE WHEN id_h12=24 THEN zero_termico END) AS zt_12,
        max(CASE WHEN id_h12=36 THEN zero_termico END) AS zt_24        
    FROM bulletins_meteo.bullettin_vigilance_data_h12
    WHERE bl_id = '",jd,"' AND zona='A'
    GROUP BY 1
    UNION ALL
    SELECT
        'B' as zona,
        max(CASE WHEN id_h12=12 THEN zero_termico END) AS zt_0,
        max(CASE WHEN id_h12=24 THEN zero_termico END) AS zt_12,
        max(CASE WHEN id_h12=36 THEN zero_termico END) AS zt_24
    FROM bulletins_meteo.bullettin_vigilance_data_h12
    WHERE bl_id = '",jd,"' AND zona='B'
    GROUP BY 1
    UNION ALL
    SELECT
        'C' as zona,
        max(CASE WHEN id_h12=12 THEN zero_termico END) AS zt_0,
        max(CASE WHEN id_h12=24 THEN zero_termico END) AS zt_12,
        max(CASE WHEN id_h12=36 THEN zero_termico END) AS zt_24        
    FROM bulletins_meteo.bullettin_vigilance_data_h12
    WHERE bl_id = '",jd,"' AND zona='C'
    GROUP BY 1
    UNION ALL
    SELECT
        'D' as zona,
        max(CASE WHEN id_h12=12 THEN zero_termico END) AS zt_0,
        max(CASE WHEN id_h12=24 THEN zero_termico END) AS zt_12,
        max(CASE WHEN id_h12=36 THEN zero_termico END) AS zt_24
    FROM bulletins_meteo.bullettin_vigilance_data_h12
    WHERE bl_id = '",jd,"' AND zona='D'
    GROUP BY 1", sep="")
dbdata <- PG.ExecuteQuery(DBH, query)
#- remove first column
dbdata <- dbdata[,-1]
if (DEBUG) dataframe_report(dbdata)

#- ----------------------------------------------------------------------
#- export file - work dir + ....
file <- paste(CONF$Options$base_path, "input","zterm_qneve.txt", sep="/")
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
#-- build the CancNova_indicatori.txt
# [...]

#- ----------------------------------------------------------------------
#-- build the portate_indicatori.txt

stids <- '10050,10010,10020,10030,10040'
#-- stations names
#stationshortname
query <- paste("SELECT st_id FROM _stations WHERE st_id IN (",stids,")", sep="")
dbdata <- PG.ExecuteQuery(DBH, query)
# transpose table
dbdata <- t(dbdata)

if (DEBUG) dataframe_report(dbdata)
#- ----------------------------------------------------------------------
#- export file - work dir + ....
file <- paste(CONF$Options$base_path, "input","portate_indicatori.txt", sep="/")
dataframe_dump(dbdata, file,FALSE, FALSE,FALSE)

#-- data
query <- paste("SELECT * FROM tool_meteolab.build_query_soglie_qdora_stids_hours(ARRAY[",stids,"]::smallint[], 36::smallint)", sep="")
dbdata <- PG.ExecuteQuery(DBH, query)
query2exe <- dbdata[1,1]
dbdata <- PG.ExecuteQuery(DBH, query2exe)
#- remove first column
dbdata <- dbdata[,-1]
if (DEBUG) dataframe_report(dbdata)
#- ----------------------------------------------------------------------
#- export file - work dir + ....
file <- paste(CONF$Options$base_path, "input","portate_indicatori.txt", sep="/")
dataframe_dump(dbdata, file,FALSE, TRUE, TRUE)




#- ----------------------------------------------------------------------
#- disconnect from database server
PG.Disconnect(DBH)

#- ----------------------------------------------------------------------
#- run denise script
source(external_program)

#- ----------------------------------------------------------------------
#- end -
flog.debug("----------------------------------- E N D -----------------------------------")
flog.debug("")