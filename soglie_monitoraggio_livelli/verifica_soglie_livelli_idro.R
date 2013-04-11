#CONFRONTA I DATI DI MONITORAGGIO DEI LIVELLI IDROMETRICI CON VALORI DI SOGLIA PRESTABILITI, E 
#DETERMINA LA CRITICITA' (ASSENTE-ATTENZIONE-MODERATA-ELEVATA) ASSOCIATA AD STAZIONE IDROMETRICA. 
#RESTITUISCE UNA TABELLA CON LE CRITICITA' RISULTANTI. 

#------------------------------------------------------------------------------------------------
# INPUT:

percorso_input=paste(CONF$Options$base_path, "input/", sep="/") #'C:\\Documents and Settings\\Storm\\Desktop\\Denise\\procedura soglie\\' 
percorso_output= paste(CONF$Options$base_path, "output/", sep="/") 

#CARICA I DATI DI MONITORAGGIO DEL LIVELLO IDROMETRICO
codici=read.table(paste0(percorso_input,'livelli_36ore.txt'),sep='\t',nrows=1) #monitoraggio livelli idrometrici ultime 36 ore, prima riga con i codici stazione
codici=codici[,-1] #elimino la prima colonna di codici, che non contiene un codice numerico
Liv_idro=read.table(paste0(percorso_input,'livelli_36ore.txt'),sep='\t',header=TRUE,skip=1) #monitoraggio livelli idrometrici ultime 36 ore (salto la riga con i codici stazione)
Liv_idro=Liv_idro[,-1] #elimino la colonna con le date, non utilizzata

#CARICA TABELLA CON LIVELLI DI SOGLIA
soglie=read.table(paste0(percorso_input,'soglie_liv_idro.txt'),sep='\t',header=TRUE) #soglie livelli idrometrici

#------------------------------------------------------------------------------------------------------
# ELABORAZIONE DATI:

#CALCOLA IL MASSIMO LIVELLO MONITORATO PER OGNI STAZIONE:
Liv_idro_max=apply(Liv_idro,2,max,na.rm=TRUE)
for(k in which(Liv_idro_max==-Inf)){Liv_idro_max[[k]]=NA} #sostituisco NA nel caso manchino i dati di una stazione (la funz max assegna -Inf)

#CONTROLLA LA COPERTURA DATI (PERCENTUALE) PER OGNI IDROMETRO
copertura_staz=matrix(NA,nrow=ncol(Liv_idro),ncol=1)
Ndati=nrow(Liv_idro) 
for(h in 1:ncol(Liv_idro)){copertura_staz[h,1]=sum(!is.na(Liv_idro[h]))*100/Ndati}

#INIZIALIZZA LE VARIABILI 
massimi=matrix(NA,nrow=length(soglie$StId),ncol=1)
criticita=matrix(FALSE,nrow=length(soglie$StId),ncol=1)
copertura=matrix(NA,nrow=length(soglie$StId),ncol=1)

#ORDINA I MASSIMI e I VALORI DI COPERTURA SECONDO L'ORDINE DELLE STAZIONI PRESENTE NELLA TABELLA CON I LIVELLI DI SOGLIA
h=1:length(soglie$StId)
k=match(codici[1,h],soglie$StId[h]) #controlla la corrispondenza dei codici stazione
massimi[h,1]=Liv_idro_max[k] #ordina i valori di Liv_idro_max in base ai codici stazione StId
copertura[h,1]=copertura_staz[k,1] #ordina i valori di copertura secondo i codici StId

#CONFRONTA IL LIVELLO MASSIMO ASSOCIATO AD OGNI STAZIONE CON I LIVELLI DI SOGLIA:
for(h in which(!is.na(massimi)))
	{if(!is.na(soglie$H0[h])) #VERIFICO LE CONDIZIONI DELLE STAZIONI LUNGO LE VALLI LATERALI
		{if(massimi[h,1]<soglie$H0[h])
				{criticita[h,1]='ASSENTE'}
		 else {if(massimi[h,1]<soglie$H1[h])
				{criticita[h,1]='ATTENZIONE'}
		 	else {if(massimi[h,1]<soglie$H2[h]){criticita[h,1]='MODERATA'}
		 		else{criticita[h,1]='ELEVATA'}
				}
			}
		}
	 else #VERIFICO LE CONDIZIONI PER LA DORA
		  {if(massimi[h,1]<soglie$H1[h])
				{criticita[h,1]='ASSENTE'}
		   else {if(massimi[h,1]<soglie$H2[h])
				{criticita[h,1]='ATTENZIONE'}
		 	   else {if(massimi[h,1]<soglie$H3[h]){criticita[h,1]='MODERATA'}
		 		   else{criticita[h,1]='ELEVATA'}
				  }
			  }
		   }
	}

#----------------------------------------------------------------------------------------------
# OUTPUT:

#SCRITTURA SU FILE DELLA TABELLA CON I RISULTATI 
tabella=cbind(soglie,massimi,copertura,criticita)
nomefile=paste0(percorso_output,Sys.Date(),'_tab_criticita_livelli.txt')
write.table(tabella,file=nomefile,append=FALSE,sep='\t',row.names=FALSE,col.names=TRUE)

