#DETERMINA GLI INDICATORI DEL RISCHIO PER I DATI DI MONITORAGGIO E DI PREVISIONE
#elabora i dati di previsione delle precipitazioni e zero termico, 
#e i dati di monitoraggio delle portate, dello zero termico e gli indicatori della cancellinova.
#Crea una tabella con gli indicatori di rischio (BASSO, MEDIO, ALTO).

#-----------------------------------------------------------------------------------------------
#INPUT:

percorso_input=paste(CONF$Options$base_path, "input/", sep="/")
percorso_output=paste(CONF$Options$base_path, "output/", sep="/")

#CARICA I DATI DI MONITORAGGIO (zero termico, cancellinova e portate):
ZTerm=read.table(paste0(percorso_input,'zero_termVDA_36ore.txt'),sep='\t',header=TRUE,na.string=NA) #zero termico delle ultime 36 ore (dato unico per VDA)
CancNova=read.table(paste0(percorso_input,'CancNova_indicatori.txt'),sep='\t',header=TRUE,na.string=NA) #indicatori per la cancellinova, ultime 4 ore
port=read.table(paste0(percorso_input,'portate_indicatori.txt'),sep='\t',skip=1,header=TRUE,na.string=NA) #portate ultime x ore di 5 idrometri lungo la Dora
codici_port=read.table(paste0(percorso_input,'portate_indicatori.txt'),sep='\t',nrow=1)#lettura codici idrometri

#CARICA I DATI DI PREVISIONE:
Prev_prec=read.table(paste0(percorso_input,'precipitaz.txt'),sep='\t',header=TRUE) #previsioni di precipitazioni medie e massime per oggi e domani
Prev_zterm=read.table(paste0(percorso_input,'zterm_qneve.txt'),sep='\t',header=TRUE,na.string=NA) #previsione dello zero termico e della quota neve per oggi e domani

# CARICA TABELLE CON I VALORI DI SOGLIA:
soglie_ind_zt=read.table(paste0(percorso_input,'soglie_indicatori_ZTerm.txt'),sep='\t',header=TRUE,na.string=NA)#soglie degli indicatori
soglie_ind_port=read.table(paste0(percorso_input,'soglie_indicatori_port.txt'),sep='\t',header=TRUE,na.string=NA)#soglie delle portate
soglie_ind_prev=read.table(paste0(percorso_input,'soglie_indicatori_prev.txt'),sep='\t',header=TRUE,na.string=NA)#soglie degli indicatori

#--------------------------------------------------------------------------------------------------

#TABELLA CHE CONTIENE GLI INDICATORI NUMERICI DI RISCHIO: 0=BASSO,1=MEDIO,2=ALTO
indicatori=matrix(NA,4,10) 
colnames(indicatori)=c("Zone","Prec_CancNova","ZTerm_m","Portate","Pmed12h","Pmed24h","Pmax12h","Pmax24h","ZTerm_p","Globale")
indicatori=data.frame(indicatori)
indicatori$Zone=c('A','B','C','D')


#----------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------
#INDICATORI PER I DATI DI MONITORAGGIO:

#INDICATORI DELLA CANCELLINOVA:
#valore massimo delle ultime x ore
indicatori$Prec_CancNova=apply(CancNova,2,max,na.rm=TRUE)
for(h in which(indicatori$Prec_CancNova==-Inf)){indicatori$Prec_CancNova[h]=NA}#in caso di vettore vuoto, ottengo NA come indicatore

#INDICATORI PER LO ZERO TERMICO:
#confronto dello zero termico (unico per VDA) con le soglie, variabili per zona 
ZTerm_med=colMeans(ZTerm,na.rm=TRUE)
for(h in 1:4)
{if(ZTerm_med>soglie_ind_zt$S2_ZT[h])
	{indicatori$ZTerm_m[h]=2} else{if(ZTerm_med>soglie_ind_zt$S1_ZT[h]){indicatori$ZTerm_m[h]=1} else{indicatori$ZTerm_m[h]=0}}
}

#INDICATORI PER LE PORTATE:
#per ogni idrometro calcola la mediana delle portate delle ultime x ore; confronta la mediana con le soglie di riferimento e associa un indicatore di rischio (numerico);
#ad ogni zona associa il massimo indicatore di rischio calcolato sull'insieme di idrometri relativi ad essa.

#controlla che i codici stazione corrispondano e riordino i valori mediani in funzione della tabella con le soglie delle portate:
port_median=apply(port,2,median,na.rm=TRUE)
indice=match(soglie_ind_port$StId,codici_port)
port_median=port_median[indice]

#controlla il superamento delle soglie di portata per ogni idrometro
Nstaz=nrow(soglie_ind_port)
controllo=matrix(NA,1,Nstaz)
for(h in which(!is.na(port_median)))
{if(port_median[[h]]<soglie_ind_port$S1_port[h])
	{controllo[h]=0}
 else{if(port_median[[h]]<soglie_ind_port$S2_port[h])
		 {controllo[h]=1}
	   else{controllo[h]=2}
	}
}
#associa l'indicatore di rischio ad ogni zona, calcolando il valore massimo per le stazioni relative ad essa
h=soglie_ind_port$zonaA==1
indicatori$Portate[1]=max(controllo[h],na.rm=TRUE)
h=soglie_ind_port$zonaB==1
indicatori$Portate[2]=max(controllo[h],na.rm=TRUE)
h=soglie_ind_port$zonaC==1
indicatori$Portate[3]=max(controllo[h],na.rm=TRUE)
h=soglie_ind_port$zonaD==1
indicatori$Portate[4]=max(controllo[h],na.rm=TRUE)


#----------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------
#INDICATORI PER I DATI DI PREVISIONE:

#INDICATORI DELLLE PREC MEDIE 12 ORE
#considera il massimo valore medio di precipitazione cumulata su 12 ore, prevista per le 36 ore successive 
controllo=apply(Prev_prec[,1:3],1,max,na.rm=TRUE)
for(h in which(controllo<=soglie_ind_prev$S1_Pmed12h)) {indicatori$Pmed12h[h]=0}
for(h in  intersect(which(controllo>soglie_ind_prev$S1_Pmed12h),which(controllo<soglie_ind_prev$S2_Pmed12h))) {indicatori$Pmed12h[h]=1}
for(h in which(controllo>soglie_ind_prev$S2_Pmed12h)) {indicatori$Pmed12h[h]=2}

#INDICATORI DELLE PRECIPITAZIONI MEDIE 24 ORE
#considera il massimo valore medio di precipitazione cumulata su 24 ore (somma di due prec medie 12 ore), prevista per le 36 ore successive 
controllo=apply(matrix(c(Prev_prec[,1]+Prev_prec[,2],Prev_prec[,2]+Prev_prec[,3]),4,2),1,max,na.rm=TRUE)
for(h in which(controllo<=soglie_ind_prev$S1_Pmed24h)) {indicatori$Pmed24h[h]=0}
for(h in  intersect(which(controllo>soglie_ind_prev$S1_Pmed24h),which(controllo<soglie_ind_prev$S2_Pmed24h))) {indicatori$Pmed24h[h]=1}
for(h in which(controllo>soglie_ind_prev$S2_Pmed24h)) {indicatori$Pmed24h[h]=2}

#INDICATORI DELLE PRECIPITAZIONI MASSIME A 12 ORE
#il valore di precipitaz max aggregate a 12 ore, previsto per le 36 ore successive, è fornito dal previsore
controllo=Prev_prec[,4]
for(h in which(controllo<=soglie_ind_prev$S1_Pmax12h)) {indicatori$Pmax12h[h]=0}
for(h in  intersect(which(controllo>soglie_ind_prev$S1_Pmax12h),which(controllo<soglie_ind_prev$S2_Pmax12h))) {indicatori$Pmax12h[h]=1}
for(h in which(controllo>soglie_ind_prev$S2_Pmax12h)) {indicatori$Pmax12h[h]=2}

#INDICATORI DELLE PRECIPITAZIONI MASSIME A 24 ORE
#il valore di precipitaz max aggregate a 24 ore, previsto per le 36 ore successive, è fornito dal previsore
controllo=Prev_prec[,5]
for(h in which(controllo<=soglie_ind_prev$S1_Pmax24h)) {indicatori$Pmax24h[h]=0}
for(h in  intersect(which(controllo>soglie_ind_prev$S1_Pmax24h),which(controllo<soglie_ind_prev$S2_Pmax24h))) {indicatori$Pmax24h[h]=1}
for(h in which(controllo>soglie_ind_prev$S2_Pmax24h)) {indicatori$Pmax24h[h]=2}

#INDICATORI ZERO TERMICO MEDIO A 24 ORE
#zero termico previsto per oggi e domani (36 ore), per le 4 zone
controllo=apply(matrix(c((Prev_zterm[,1]+Prev_zterm[,2])/2,(Prev_zterm[,2]+Prev_zterm[,3])/2),4,2),1,max,na.rm=TRUE)
for(h in which(controllo<=soglie_ind_prev$S1_ZT)) {indicatori$ZTerm_p[h]=0}
for(h in  intersect(which(controllo>soglie_ind_prev$S1_ZT),which(controllo<soglie_ind_prev$S2_ZT))) {indicatori$ZTerm_p[h]=1}
for(h in which(controllo>soglie_ind_prev$S2_ZT)) {indicatori$ZTerm_p[h]=2}

#----------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------
#INDICATORE GLOBALE:
#calcolo di un indicatore globale ottenuto pesando i diversi indicatori:

#somma delle precipitazioni previste
indicatori$Globale=apply(indicatori[,5:8],1,sum)

#se la somma delle prec previste è >0, allora valuta gli indicatori di monitoraggio, dando maggior peso alla CancNova. 
pesi=cbind(matrix(2,4,1),matrix(1,4,7))
pesi=apply(indicatori[,2:9]*pesi,1,sum,na.rm=TRUE)

for(h in which(indicatori$Globale>0))
{if(pesi[h]>10)
	{indicatori$Globale[h]=2}
 else{if(pesi[h]>=8)
		{indicatori$Globale[h]=1}
	 else{indicatori$Globale[h]=0}
	}
}

#-----------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------
#TABELLA INDICATORI: SOSTITUZIONE DEI VALORI NUMERICI DEGLI INDICATORI CON 'BASSO','MEDIO','ALTO':

for(r in 1:4)
{for(c in 2:10)
	{if(!is.na(indicatori[r,c]))
	 {if(indicatori[r,c]==0)
		{indicatori[r,c]='BASSO'}
	  else{if(indicatori[r,c]==1)
			{indicatori[r,c]='MEDIO'}
		 else{if(indicatori[r,c]==2){indicatori[r,c]='ALTO'}}
		}
	 }
	}
}

#----------------------------------------------------------------------------------------------------------------------
# OUTPUT

#SCRITTURA SU FILE DELLA TABELLA CON I RISULTATI DEGLI INDICATORI
nomefile=paste0(percorso_output,Sys.Date(),'_indicatori_di_rischio.txt')
write.table(indicatori,file=nomefile,append=FALSE,sep='\t',row.names=FALSE,col.names=TRUE)

