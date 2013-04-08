#DETERMINA LA CRITICITA' PER I DATI DI MONITORAGGIO DELLE PRECIPITAZIONI: 
#CARICA I DATI DI PRECIPITAZIONE, DI ZERO TERMICO E SUPERAMENTO DELLA CANCELLINOVA, PER LE 36 ORE PRECEDENTI:
#il numero di ore può essere modificato senza modificare la procedura, a patto che tutti i file siano coerenti

percorso_input=paste(CONF$Options$base_path, "input/", sep="/")
percorso_output= paste(CONF$Options$base_path, "output/", sep="/") 
 
#nomi dei file con i dati di precipitazione:
nomefile=c('monitoraggio_prec_A.txt','monitoraggio_prec_B.txt','monitoraggio_prec_C.txt','monitoraggio_prec_D.txt')

cancellinova=read.table(paste0(percorso_input,'cancellinova_36ore.txt'),sep='\t',header=TRUE,na.string=NA) #percentuale superamento della cancellinova nelle ultime 36 ore per una zona (senza date)

Qneve=read.table(paste0(percorso_input,'zero_termVDA_36ore.txt'),sep='\t',header=TRUE,na.string=NA) #zero termico delle ultime 36 ore (dato unico per VDA)(senza date)

soglie=read.table(paste0(percorso_input,'soglie_prec.txt'),sep='\t',header=TRUE) #soglie di riferimento di precipitazione e quota neve

#-----------------------------------

#CARATTERISTICHE GRAFICI:
data_sistema=Sys.Date()
larghezza=1024
altezza=768
unita='px'
sfondo='white' 
risoluzione=NA #in dpi

#-----------------------------------------------
#CREO UNA TABELLA IN CUI MEMORIZZARE I RISULTATI
tabella=matrix(NA,4,9) 
colnames(tabella)=c("Zone","perc_sup_CancNova","sup_CancNova","Pmed24h","Pmax12h","Pmax24h","QNeve_ord","QNeve_mod","Criticita")
tabella=data.frame(tabella)
tabella$Zone=c('A','B','C','D')

#COMPLETAMENTO DEI VALORI DELLA CANCELLINOVA, IN CASO DI VALORI MANCANTI:
if(sum(is.na(cancellinova))>0)
{for(h in 1:4)
	{for(c in which(is.na(cancellinova[,h])))
		{if(c>1){precedente=cancellinova[c-1,h]}else{precedente=0}
		 k=c
		 while(is.na(cancellinova[k,h]))
				{k=k+1 
				 if(k>length(cancellinova[,h])){break}
				}
		 successivo=cancellinova[k,h]
		 cancellinova[c,h]=max(precedente,successivo,na.rm=TRUE)
		}
	}
}
#VERIFICA IL SUPERAMENTO DELLA CANCELLINOVA
tabella$perc_sup_CancNova=apply(cancellinova,2,max,na.rm=TRUE)
tabella$sup_CancNova=tabella$perc_sup_CancNova>0

#QUOTA NEVE MEDIA: calcolo la quota neve media per la VDA 
Qneve=Qneve-300 #abbasso lo zero termico di 300 metri per ottenere la quota neve teorica
Qneve_med=colMeans(Qneve,na.rm=TRUE)

#VERIFICA SUPERAMENTO QUOTA NEVE: confronto la quota neve media con le soglie associate ad ogni zona 
tabella$QNeve_ord=Qneve_med>=soglie$Qneve_ord 
tabella$QNeve_mod=Qneve_med>=soglie$Qneve_mod

#-------------------------------------------------------------------------------------------------------------------------------------------------
#PARTE DI PROCEDURA DA RIPETERE PER OGNI ZONA:

for(zona in 1:4) #zona A=1, B=2, C=3, D=4
{
#CARICA I DATI DI PRECIPITAZIONE DELLE STAZIONI
Prec=read.table(paste0(percorso_input,nomefile[zona]),sep='\t',header=TRUE, skip=1) #monitoraggio precipitazioni per una zona (numero variabile di stazioni)

#SEPARO LA COLONNA CON LE DATE DAI DATI DI PRECIPITAZIONE(la riga dei codici non è stata caricata)
date_prec=as.POSIXct(Prec[,1],format='%d/%m/%Y %H.%M')
Prec=Prec[,-1]

#SOMMA DELLE PRECIPITAZIONI DELLE 12/24 ORE:
Ndati=nrow(Prec)
Nstaz=ncol(Prec)
P12h=matrix(NA,Ndati-11,Nstaz) #matrice con le prec di 12 ore, per ogni stazione
P24h=matrix(NA,Ndati-23,Nstaz) #matrice con le prec di 24 ore, per ogni stazione
date12h=as.POSIXct(matrix(NA,Ndati-11))
date24h=as.POSIXct(matrix(NA,Ndati-23))
for(h in 1:(Ndati-11))
	{P12h[h,]=apply(Prec[h:(h+11),],2,sum,na.rm=TRUE)
	date12h[h]=date_prec[[h+11]]}
for(h in 1:(Ndati-23))
	{P24h[h,]=apply(Prec[h:(h+23),],2,sum,na.rm=TRUE)
	date24h[h]=date_prec[h+23]}

#PRECIPITAZIONI MASSIME/MEDIE DELLE 12 E 24 ORE
Pmax12h=apply(P12h,1,max,na.rm=TRUE)
Pmax24h=apply(P24h,1,max,na.rm=TRUE)
Pmed24h=apply(P24h,1,mean,na.rm=TRUE)

#VERIFICA SUPERAMENTO DELLE SOGLIE DI PRECIPITAZIONE
tabella[zona,4]=max(Pmed24h)>=soglie$Pmed24[zona] #superamento della soglia di prec media aggregata a 24 ore
#costruisco il vettore soglia per P12h e P24h variabile nel tempo:
soglieP12=matrix(NA,Ndati-11,1)
soglieP24=matrix(NA,Ndati-23,1)
for(h in 1:(Ndati-11))
	{if(cancellinova[h+11,zona]>0)
		{soglieP12[h,1]=soglie$Pmax12canc[zona]}
	 else{soglieP12[h,1]=soglie$Pmax12[zona]}
	}
for(h in 1:(Ndati-23))
	{if(cancellinova[h+23,zona]>0)
		{soglieP24[h,1]=soglie$Pmax24canc[zona]}
	 else{soglieP24[h,1]=soglie$Pmax24[zona]}
	}
tabella[zona,5]=any(Pmax12h>=soglieP12) #superamento della soglia di criticità di prec 12 ore
tabella[zona,6]=any(Pmax24h>=soglieP24) #superamento della soglia di criticità di prec 24 ore

#GRAFICI:
#caratteristiche:
zona_char=switch(zona,'A','B','C','D')
etichette=substr(names(Prec),1,20) #estrae le etichette per il grafico dai nomi delle colonne del dataframe (primi 20 caratteri)

#GRAFICO DELLA PREC MASSIMA A 12 ORE
nome_file=paste0(percorso_output,data_sistema,'_prec_max12h_zona',zona_char,'.png')
png(filename=nome_file,width=larghezza, height=altezza,unit=unita, bg=sfondo, res=risoluzione)
titolo=paste('Zona ',zona_char,' - Prec MAX 12 ore ',data_sistema)#titolo del grafico
par(font.axis=1,font.lab=2,font.main=2,cex.axis=1.2,cex.lab=1.5,cex.main=3)#settaggio parametri del grafico corrente
grafico=barplot(Pmax12h,width=0.5,space=1,col='skyblue2',ylim=c(0,max(Pmax12h,soglieP12)+15),axisnames=FALSE)#grafico a barre delle prec
axis(1,at=grafico[seq(1,24,3)],labels=format(date12h[seq(1,24,3)],'%d-%b %H:%S'),las=0) #posiziona le etichette
lines(soglieP12,col='red3',lty=1,lwd=2) #linea della soglia di riferimento
title(main=titolo,ylab='prec [mm]')  #titolo e etichetta asse y
legend('top',c('precipitazione','soglia'),lty=c(1,1),lwd=c(5,2),col=c('skyblue2','red3'),bty='n',ncol=2,cex=1.5)
grid(nx=NA,ny=NULL) #griglia per l'asse y
box(lty=1) #racchiude il grafico in un box
dev.off()

#GRAFICO PREC MASSIMA 24 ORE
nome_file=paste0(percorso_output,Sys.Date(),'_prec_max24h_zona',zona_char,'.png')
png(filename=nome_file,width=larghezza, height=altezza,unit=unita, bg=sfondo, res=risoluzione)
titolo=paste('Zona ',zona_char,' - Prec MAX 24 ore ',data_sistema) #titolo del grafico
par(font.axis=1,font.lab=2,font.main=2,cex.axis=1.2,cex.lab=1.5,cex.main=3)#settaggio parametri del grafico corrente
grafico=barplot(Pmax24h,width=0.5,space=1,col='skyblue2',ylim=c(0,max(Pmax24h,soglieP24)+20),axisnames=FALSE) #grafico a barre delle prec
axis(1,at=grafico[seq(1,12,3)],labels=format(date24h[seq(1,12,3)],'%d-%b %H:%S'),las=0) #posiziona le etichette
lines(soglieP24,col='red3',lty=1,lwd=2) #linea della soglia di riferimento
title(main=titolo,ylab='prec [mm]') #titolo e etichetta asse y
legend('top',c('precipitazione','soglia'),lty=c(1,1),lwd=c(5,2),col=c('skyblue2','red3'),bty='n',ncol=2,cex=1.5)
grid(nx=NA,ny=NULL) #griglia per l'asse y
box(lty=1) #racchiude il grafico in un box
dev.off()

#GRAFICO PREC MEDIA 24 ORE
nome_file=paste0(percorso_output,Sys.Date(),'_prec_med24h_zona',zona_char,'.png')
png(filename=nome_file,width=larghezza, height=altezza,unit=unita, bg=sfondo, res=risoluzione)
titolo=paste('Zona ',zona_char,' - Prec MEDIA 24 ore ',data_sistema)
par(font.axis=1,font.lab=2,font.main=2,cex.axis=1.2,cex.lab=1.5,cex.main=3)#settaggio parametri del grafico corrente
grafico=barplot(Pmed24h,width=0.5,space=1,col='skyblue2',ylim=c(0,max(Pmed24h,soglie$Pmed24[zona])+15),axisnames=FALSE) #grafico a barre delle prec
axis(1,at=grafico[seq(1,12,3)],labels=format(date24h[seq(1,12,3)],'%d-%b %H:%S'),las=0) #posiziona le etichette
abline(h=soglie$Pmed24[zona],col='red3',lty=1,lwd=2) #linea della soglia di riferimento
title(main=titolo,ylab='prec [mm]')
legend('top',c('precipitazione','soglia'),lty=c(1,1),lwd=c(5,2),col=c('skyblue2','red3'),bty='n',ncol=2,cex=1.5)
grid(nx=NA,ny=NULL) #griglia per l'asse y
box(lty=1) #racchiude il grafico in un box
dev.off()

#GRAFICO QUOTA NEVE
nome_file=paste0(percorso_output,Sys.Date(),'_quota_neve_zona',zona_char,'.png')
png(filename=nome_file,width=larghezza, height=altezza,unit=unita, bg=sfondo, res=risoluzione)
titolo=paste('Zona ',zona_char,' - Quota neve ',data_sistema)
par(font.axis=1,font.lab=2,font.main=2,cex.axis=1.2,cex.lab=1.5,cex.main=3,lty=1,lwd=2)#settaggio parametri del grafico corrente
plot(Qneve[,],type="l",col='skyblue2',ylim=c(200,max(Qneve,soglie$Qneve_mod[zona],na.rm=TRUE)+100),ann=FALSE,xaxt = "n")
abline(h=soglie$Qneve_ord[zona],col='gold2',ann=FALSE) #linea della soglia ORDINARIA di riferimento
abline(h=soglie$Qneve_mod[zona],col='red3',ann=FALSE) #linea della soglia MODERATA di riferimento
axis(1,at=seq(1,36,6),labels=format(date_prec[seq(1,36,6)],'%d-%b %H:%S'),las=0)
title(main=titolo,ylab='quota neve [m s.l.m.]')
legend('bottom',c('quota neve','soglia ordinaria','soglia moderata'),lty=c(1,1,1),lwd=c(2,2,2),col=c('skyblue2','gold2','red3'),bty='n',ncol=3,cex=1.5)
grid(nx=NA,ny=NULL) #griglia per l'asse y
abline(v=seq(1,36,6),col = "lightgray", lty = "dotted",lwd = par("lwd"))#griglia asse y
box(lty=1) #racchiude il grafico in un box
dev.off()

#GRAFICO PREC MAX 12 ORE PER STAZIONE
P=apply(P12h,2,max,na.rm=TRUE)#calcola il massimo per ogni stazione
nome_file=paste0(percorso_output,Sys.Date(),'_prec_max12h_staz_zona',zona_char,'.png')
png(filename=nome_file,width=larghezza, height=altezza,unit=unita, bg=sfondo, res=risoluzione)
titolo=paste('Zona ',zona_char,' - Prec MAX 12 ore ',data_sistema)
par(font.axis=1,font.lab=2,font.main=2,cex.axis=1.2,cex.lab=1.5,cex.main=3,mai=c(1.6,1,0.82,0.42))#settaggio parametri del grafico corrente
grafico=barplot(P,width=0.5,space=1,ylim=c(0,max(P)+2),col='skyblue2') #grafico a barre delle prec
text(grafico,par("usr")[3],labels=etichette,srt=40,adj=c(1,1),xpd=TRUE,font=2,cex=1.2) #ruota le etichette di 45°
title(main=titolo,ylab='prec [mm]')
grid(nx=NA,ny=NULL) #griglia per l'asse y
box(lty=1) #racchiude il grafico in un box
dev.off()

#GRAFICO PREC MAX 24 ORE PER STAZIONE
P=apply(P24h,2,max,na.rm=TRUE)#calcola il massimo per ogni stazione
nome_file=paste0(percorso_output,Sys.Date(),'_prec_max24h_staz_zona',zona_char,'.png')
png(filename=nome_file,width=larghezza, height=altezza,unit=unita, bg=sfondo, res=risoluzione)
titolo=paste('Zona ',zona_char,' - Prec MAX 24 ore ',data_sistema)
par(font.axis=1,font.lab=2,font.main=2,cex.axis=1.2,cex.lab=1.5,cex.main=3,mai=c(1.6,1,0.82,0.42))#settaggio parametri del grafico corrente
grafico=barplot(P,width=0.5,space=1,ylim=c(0,max(P)+2),col='skyblue2') #grafico a barre delle prec
text(grafico,par("usr")[3],labels=etichette,srt=40,adj=c(1,1),xpd=TRUE,font=2,cex=1.2) #scrive etichette asse x e le ruota di 45°
title(main=titolo,ylab='prec [mm]')
grid(nx=NA,ny=NULL) #griglia per l'asse y
box(lty=1) #racchiude il grafico in un box
dev.off()
}
#------------------------------------------------------------------------------------------------------------------------------------------------
# RISULTATI TABELLA:
for(h in 1:4)
{if(tabella$Pmed24h[h] && (tabella$Pmax12h[h] || tabella$Pmax24h[h]) && tabella$QNeve_mod[h])
	{tabella$Criticita[h]='MODERATA'}
 else {if((tabella$Pmed24h[h] || tabella$Pmax12h[h] || tabella$Pmax24h[h]) && tabella$QNeve_ord[h])
		{tabella$Criticita[h]='ORDINARIA'}
	 else {tabella$Criticita[h]='NON CRITICA'}
	}
}

#SCRITTURA DELLA TABELLA CON I RISULTATI
nome_file=paste0(percorso_output,data_sistema,'_tab_criticita_monitoraggio.txt')
write.table(tabella,file=nome_file,append=FALSE,sep='\t',row.names=FALSE,col.names=TRUE)


