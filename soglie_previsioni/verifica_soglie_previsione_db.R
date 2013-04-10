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
   setwd('C:\\Progetti_R\\soglie_previsioni')
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

x<-paste(CONF$Options$base_path, "input","precipitaz.txt", sep="/")
unlink(x, recursive = FALSE, force = TRUE)

#- ----------------------------------------------------------------------
#- user settings
flog.info("user settings")

external_program='C:/Progetti_R/soglie_previsioni/verifica_soglie_previsione.R'


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
        max(CASE WHEN id_h12=36 THEN zero_termico END) AS zt_24,
        max(CASE WHEN id_h12=12 THEN quota_neve   END) AS qn_0,
        max(CASE WHEN id_h12=24 THEN quota_neve   END) AS qn_12,
        max(CASE WHEN id_h12=36 THEN quota_neve   END) AS qn_24
    FROM bulletins_meteo.bullettin_vigilance_data_h12
    WHERE bl_id = '",jd,"' AND zona='A'
    GROUP BY 1
    UNION ALL
    SELECT
        'B' as zona,
        max(CASE WHEN id_h12=12 THEN zero_termico END) AS zt_0,
        max(CASE WHEN id_h12=24 THEN zero_termico END) AS zt_12,
        max(CASE WHEN id_h12=36 THEN zero_termico END) AS zt_24,
        max(CASE WHEN id_h12=12 THEN quota_neve   END) AS qn_0,
        max(CASE WHEN id_h12=24 THEN quota_neve   END) AS qn_12,
        max(CASE WHEN id_h12=36 THEN quota_neve   END) AS qn_24
    FROM bulletins_meteo.bullettin_vigilance_data_h12
    WHERE bl_id = '",jd,"' AND zona='B'
    GROUP BY 1
    UNION ALL
    SELECT
        'C' as zona,
        max(CASE WHEN id_h12=12 THEN zero_termico END) AS zt_0,
        max(CASE WHEN id_h12=24 THEN zero_termico END) AS zt_12,
        max(CASE WHEN id_h12=36 THEN zero_termico END) AS zt_24,
        max(CASE WHEN id_h12=12 THEN quota_neve   END) AS qn_0,
        max(CASE WHEN id_h12=24 THEN quota_neve   END) AS qn_12,
        max(CASE WHEN id_h12=36 THEN quota_neve   END) AS qn_24
    FROM bulletins_meteo.bullettin_vigilance_data_h12
    WHERE bl_id = '",jd,"' AND zona='C'
    GROUP BY 1
    UNION ALL
    SELECT
        'D' as zona,
        max(CASE WHEN id_h12=12 THEN zero_termico END) AS zt_0,
        max(CASE WHEN id_h12=24 THEN zero_termico END) AS zt_12,
        max(CASE WHEN id_h12=36 THEN zero_termico END) AS zt_24,
        max(CASE WHEN id_h12=12 THEN quota_neve   END) AS qn_0,
        max(CASE WHEN id_h12=24 THEN quota_neve   END) AS qn_12,
        max(CASE WHEN id_h12=36 THEN quota_neve   END) AS qn_24
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
#-- build the cancellinova.txt
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
    WHERE m.fulldate >= date_trunc('hour', TIMEZONE('UTC',CURRENT_TIMESTAMP) - interval '3 hour')
    ORDER BY data LIMIT 4", sep="")
dbdata <- PG.ExecuteQuery(DBH, query)
#- remove first column
dbdata <- dbdata[,-1]
if (DEBUG) dataframe_report(dbdata)

#- ----------------------------------------------------------------------
#- export file - work dir + ....
file <- paste(CONF$Options$base_path, "input","cancellinova.txt", sep="/")
dataframe_dump(dbdata, file)

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