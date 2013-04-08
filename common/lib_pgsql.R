#!/usr/bin/env Rscript
#- ----------------------------------------------------------------------
#-  Copyright (c) 1995-2013, Ecometer s.n.c.
#-  Author: Paolo Saudin.
#-
#-  RESOURCE : http://google-styleguide.googlecode.com/svn/trunk/google-r-style.html
#-             http://code.google.com/p/rpostgresql/
#-             http://rpostgresql.googlecode.com/svn/trunk/RPostgreSQL/inst/devTests/demo.r
#-
#-  POSTGRESQL LIBRARY COMMON FUNCTIONS
#-
#- ----------------------------------------------------------------------

#- ----------------------------------------------------------------------
#- load libraries
#- ----------------------------------------------------------------------
require(RPostgreSQL)

#- ----------------------------------------------------------------------
#- main database functions
#- ----------------------------------------------------------------------

#- connect to database server
PG.Connect <- function(PG.settings)
{
    #- log
    if (DEBUG) flog.info("PG.Connect: loading postgresql driver ...")
    #- loads the PostgreSQL driver
    drv <- dbDriver("PostgreSQL")
    #- log
    if (DEBUG) flog.info("Driver loaded.")

    #- log
    if (DEBUG) flog.info("Connecting to database host : %s ...", PG.settings$host)
    #- connect to database
    con <- dbConnect(drv, dbname=PG.settings$database, user=PG.settings$username,
                     password=PG.settings$password, host=PG.settings$host, port=PG.settings$port)
    #- log
    if (DEBUG) flog.info("Connected to DB host.")
    #- return connection handler
    return(con)
}

#- disconnect from database
PG.Disconnect <- function(PG.dbh)
{
    #- ----------------------------------------------------------------------
    #- -- disconnect from database
    #- ----------------------------------------------------------------------
    #- log
    if (DEBUG) flog.info("PG.Disconnect: disconnect from database ...")
    #- disconnect
    dbDisconnect(PG.dbh);
    #- log
    if (DEBUG) flog.info("Done.")
}

#- disconnect all from database
PG.DisconnectAll <- function()
{
    #- log
    if (DEBUG) flog.info("PG.DisconnectAll: disconnect all from database ...")
    #- frees all the opened connections
    drv <- dbDriver("PostgreSQL")
    #- get all cons
    all_cons <- dbListConnections(drv)
    for(con in all_cons) {
        #- disconnect
        dbDisconnect(con)
    }
    #- log
    if (DEBUG) flog.info("Done.")
}

#- execute query and return data
PG.ExecuteQuery <- function(PG.dbh, PG.query)
{
    #- log
    if (DEBUG) flog.info("PG.ExecuteQuery: executing query : %s ...", PG.query)
    #- get records
    results <- dbGetQuery(PG.dbh, PG.query)
    return(results)
}

