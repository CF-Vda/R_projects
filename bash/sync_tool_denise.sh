#!/bin/bash


# soglie_monitoraggio_livelli
cd /home/ubuntu/bin/tool_denise/soglie_monitoraggio_livelli/output

files="*.txt"
# 2013-05-06_tab_criticita_livelli.txt 
regex="^[0-9]{4}-[0-9]{2}-[0-9]{2}_(.*)\.txt$"

for f in $files
do
    if [[ $f =~ $regex ]]
    then
        name="${BASH_REMATCH[1]}"

        # get names
        file="${name}.txt"
        echo ${file}

        # copy files
        cp $f sync/$file

        # move to history
        mv $f history/$f
    fi
done

# copy all data files
scp -r sync/*.txt cfuser@cluster-db1:/home/cfuser/www_data/soglie/monitoraggio_livelli/
scp -r sync/*.txt cfuser@cluster-web2:/home/cfuser/www/presidi/public/images/soglie/monitoraggio_livelli/



# soglie_previsioni 
cd /home/ubuntu/bin/tool_denise/soglie_previsioni/output

files="*.txt"
# 2013-05-06_tab_criticita_previsione.txt 
regex="^[0-9]{4}-[0-9]{2}-[0-9]{2}_(.*)\.txt$"

for f in $files
do
    if [[ $f =~ $regex ]]
    then
        name="${BASH_REMATCH[1]}"

        # get names
        file="${name}.txt"
        echo ${file}

        # copy files
        cp $f sync/$file

        # move to history
        mv $f history/$f
    fi
done

# copy all data files
scp -r sync/*.txt cfuser@cluster-db1:/home/cfuser/www_data/soglie/previsioni/
scp -r sync/*.txt cfuser@cluster-web2:/home/cfuser/www/presidi/public/images/soglie/previsioni/



# soglie_monitoraggio_prec
cd /home/ubuntu/bin/tool_denise/soglie_monitoraggio_prec/output

files="*.png"
# 2013-05-02_prec_max12h_staz_zonaA.png
regex="^[0-9]{4}-[0-9]{2}-[0-9]{2}_(.*)\.png$"

for f in $files
do
    
    #echo $f
    if [[ $f =~ $regex ]] 
    then

        name="${BASH_REMATCH[1]}"
       
        # get names
        image="${name}.png"
        thumb="${name}_thumb.png"

        echo ${image}
        echo ${thumb}

        # resize
        convert $f -resize 250 sync/$thumb

        # copy files
        cp $f sync/$image
        
        # move to history 
        mv $f history/$f

    fi

done

# copy all images files
scp -r sync/*.png cfuser@cluster-db1:/home/cfuser/www_data/soglie/monitoraggio_prec/
scp -r sync/*.png cfuser@cluster-web2:/home/cfuser/www/presidi/public/images/soglie/monitoraggio_prec/


files="*.txt"
# 2013-05-06_tab_criticita_monitoraggio.txt
regex="^[0-9]{4}-[0-9]{2}-[0-9]{2}_(.*)\.txt$"

for f in $files
do
    if [[ $f =~ $regex ]]
    then
        name="${BASH_REMATCH[1]}"

        # get names
        file="${name}.txt"
        echo ${file}

        # copy files
        cp $f sync/$file

        # move to history
        mv $f history/$f
    fi
done

# copy all data files
scp -r sync/*.txt cfuser@cluster-db1:/home/cfuser/www_data/soglie/monitoraggio_prec/
scp -r sync/*.txt cfuser@cluster-web2:/home/cfuser/www/presidi/public/images/soglie/monitoraggio_prec/

