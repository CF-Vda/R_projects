#CONFRONTA I DATI DI PREVISIONE DI PRECIPITAZIONE E QUOTA NEVE CON VALORI DI SOGLIA PRESTABILITI, E 
#DETERMINA LA CRITICITA' (NON CRITICA-ORDINARIA-MODERATA) ASSOCIATA AD OGNI ZONA. 
#RESTITUISCE UNA TABELLA CON LE CRITICITA' RISULTANTI. 

#---------------------------------------------------------------------------------------------------------------------
# INPUT:

percorso_input= paste(CONF$Options$base_path, "input/", sep="/") #'C:\\Documents and Settings\\Storm\\Desktop\\Denise\\procedura soglie\\'
percorso_output= paste(CONF$Options$base_path, "output/", sep="/") 

#CARICA I DATI DI PREVISIONE E PERCENTUALI DI SUPERAMENTO DELLA CANCELLINOVA:
cancellinova=read.table(paste0(percorso_input,'cancellinova.txt'),sep='\t',header=TRUE) #percentuale superamento della cancellinova nelle ultime ore
Prev_prec=read.table(paste0(percorso_input,'precipitaz.txt'),sep='\t',header=TRUE) #previsioni di precipitazioni medie e massime per oggi e domani
Prev_qneve=read.table(paste0(percorso_input,'zterm_qneve.txt'),sep='\t',header=TRUE,na.string=NA) #previsione dello zero termico e della quota neve per oggi e domani
#CARICA TABELLA CON LIVELLI DI SOGLIA PER PRECIPITAZIONI E QUOTA NEVE
tab_soglie=read.table(paste0(percorso_input,'soglie_prec.txt'),sep='\t',header=TRUE,na.string=NA) #soglie di precipitazione


#-------------------------------------------------------------------------------------------------------
#DETERMINA LE SOGLIE DI CRITICITA'PER Pmax12H E Pmax24H
#(in base al superamento o meno della cancellinova):

#dataframe contenente valori di soglia:
soglie=data.frame(Pmed24=tab_soglie$Pmed24,Pmax12=c(0,0,0,0),Pmax24=c(0,0,0,0),Qneve_ord=tab_soglie$Qneve_ord,Qneve_mod=tab_soglie$Qneve_mod)

#controlla superamento della cancellinova (prende il massimo delle 36 ore precedenti)
#e sceglie il valore di soglia di conseguenza:

perc_sup_CancNova=apply(cancellinova,2,max,na.rm=TRUE)

for(h in 1:4)
{	if (perc_sup_CancNova[h]>0)
	{soglie$Pmax12[h]=tab_soglie$Pmax12canc[h]
	soglie$Pmax24[h]=tab_soglie$Pmax24canc[h]} else
	{soglie$Pmax12[h]=tab_soglie$Pmax12[h]
	soglie$Pmax24[h]=tab_soglie$Pmax24[h]}
}

#--------------------------------------------------------------------------------------------------------
#VERIFICA IL SUPERAMENTO DELLE SOGLIE DI CRITICITA':

#COSTRUISCO UNA MATRICE CHE INDICA LA PRESENZA (TRUE/FALSE) DI CRITICITA' (COLONNE: CANCELLINOVA,PREC MED, PREC MAX 12H, PRECMAX 24H,QUOTA NEV ORD, QUOTA NEVE MOD)
criticita=matrix(FALSE,nrow=4,ncol=6)
dimnames(criticita)=list(Zone=c('A','B','C','D'),c('sup_CancNova','Pmed24h','Pmax12h','Pmax24h','QNeve_ord','QNeve_mod'))

#CRITICITA' CANCELLINOVA:
criticita[,1]=(perc_sup_CancNova>0)

#CRITICITA' DELLE PRECIPITAZIONI MEDIE 24 ORE:
controllo=matrix(c(Prev_prec[,1]+Prev_prec[,2],Prev_prec[,2]+Prev_prec[,3]),4,2)
controllo=controllo>=soglie$Pmed24
for(h in 1:4)
{criticita[h,2]=controllo[h,1]||controllo[h,2]}

#CRITICITA' DELLE PRECIPITAZIONI MASSIME A 12 ORE:
criticita[,3]=Prev_prec[,4]>=soglie$Pmax12

#CRITICITA' DELLE PRECIPITAZIONI MASSIME A 24 ORE:
criticita[,4]=Prev_prec[,5]>=soglie$Pmax24

#CRITICITA' QUOTA NEVE:

#abbasso lo zero termico di 300 metri, per avere una quota neve teorica (in mancanza di precipitaz)
for(h in 1:3){Prev_qneve[,h]=Prev_qneve[,h]-300} 

#se la previsione quota neve non esiste, lo sostituisce con il valore dello zero termico -300 metri
for(h in 4:6) 
	{for(k in 1:4)
		{if(is.na(Prev_qneve[k,h]))
			{Prev_qneve[k,h]=Prev_qneve[k,h-3]}
		}
	 }

#calcolo della quota neve media per ogni zona:
controllo_qneve=matrix(0,4,1)
for(h in 1:4) 
{controllo_Pmed=Prev_prec[h,c(1,2,3)]>=15 
if (sum(controllo_Pmed)>0){controllo_qneve[h,1]=sum(Prev_qneve[h,4:6]*controllo_Pmed,na.rm=TRUE)/sum(controllo_Pmed)}
else{
	controllo_Pmed=Prev_prec[h,c(1,2,3)]>0
	if (sum(controllo_Pmed)>0){controllo_qneve[h,1]=sum(Prev_qneve[h,4:6]*controllo_Pmed,na.rm=TRUE)/sum(controllo_Pmed)}
	else{controllo_qneve[h,1]=rowMeans(Prev_qneve[h,1:3])}
    }
}

#verifica superamento soglie:
criticita[,5]=(controllo_qneve>=soglie$Qneve_ord)
criticita[,6]=(controllo_qneve>=soglie$Qneve_mod)

#---------------------------------------------------------------------------------------------
# CRITICITA' RISULTANTE
risultato=matrix('NON CRITICA',4,1)
colnames(risultato)='Criticità'
for(h in 1:4)
{if(criticita[h,2]&&(criticita[h,3]||criticita[h,4])&&(criticita[h,6]))
	{risultato[h,1]='MODERATA'}
 else {if((criticita[h,2]||criticita[h,3]||criticita[h,4])&&(criticita[h,5]))
		{risultato[h,1]='ORDINARIA'}
	 }
}

#--------------------------------------------------------------------------------------------
# OUTPUT:

#SCRITTURA SU FILE DELLA TABELLA CON I RISULTATI
tabella=cbind(Zone=c('A','B','C','D'),perc_sup_CancNova,criticita,risultato)
nomefile=paste0(percorso_output,Sys.Date(),'_tab_criticita_previsione.txt')
write.table(tabella,file=nomefile,append=FALSE,sep='\t',row.names=FALSE,col.names=TRUE)

