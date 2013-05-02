R_projects
==========

R Scripts Used By CF Vda


--
-- install
--
sudo apt-get install r-base
* R version 3.0.0 (2012-03-30)

--install.packages("timeDate", lib='/usr/lib/R/library')

--
-- postgres
--
https://github.com/pgexperts/add-pgdg-apt-repo/blob/master/add-pgdg-apt-repo.sh
sudo apt-get install libpq-dev


sudo R
install.packages("RPostgreSQL")
install.packages("futile.logger")


--
-- setup
--
setwd("/home/ubuntu/bin/tool_denise/soglie_monitoraggio_livelli/")
external_program='/home/ubuntu/bin/tool_denise/soglie_monitoraggio_livelli/verifica_soglie_livelli_idro.R'




--
-- run
--
-- todo
(R --slave --vanilla < /home/ubuntu/bin/tool_denise/soglie_monitoraggio_livelli/verifica_soglie_livelli_db.R) 2>> ~/bin/tool_indicatori/log/indicatori_`/bin/date +\%Y\%m\%d`.log 1>/dev/null
-- todo


R --slave --vanilla < soglie_monitoraggio_livelli/verifica_soglie_livelli_db.R
R --slave --vanilla < soglie_monitoraggio_prec/verifica_soglie_monitoraggio_db.R
R --slave --vanilla < soglie_previsioni/verifica_soglie_previsione_db.R
