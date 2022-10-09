#!/bin/bash
#sprawdzanie liczby parametrow
if [ $# -ne 1 ]; then
	echo "Wrong number of arguments, write:"
	echo "./projekt1.sh mail.txt"
	exit
fi

FILE=$1 #pierwszym argumentem ma być nazwa pliku w ktorym jest adres email

#sprawdzanie czy plik z mailem istnieje
if [ ! -f $FILE ]; then
	echo "File does not exist or wrong directory"
	exit
fi

#sprawdzanie czy plik konfiguracyjny ma w sobie adres email
EMAIL=$( grep @ $FILE )
if [ -z "$EMAIL" ]; then
	echo "In the file there is no email"
	exit
else
	echo "Got the email: ${EMAIL}"
fi

#pobieranie potrzebnych parametrow
IPADRESS=$( hostname -i ) #komenda zwraca adres ip
echo "Adres IP: ${IPADRESS}"
RAM=$( free -m | grep "Mem" ) #zczytanie linijki dotyczacej pamieci ram
RAM=$( echo $RAM | cut -d " " -f3) # wybranie liczby, ktory informuje o uzywanej ilosci pamieci ram
echo "Used RAM: ${RAM}"
PROCESSORS=$( cat /proc/cpuinfo | grep -c "processor" ) #komenda otwiera plik cpuinfo i zlicza wystapienia slowa procesor
echo "Number of processors: ${PROCESSORS}"

#tworzenie pliku z parametrami
PARAMS="./parameters.txt"
if [ -e $PARAMS ]; then #sprawdza czy taki plik juz istnieje
	echo "Parameters file does already exist"
else
	echo "Parameters file does not exist, creating parameters file" #tworzy plik jesli nie istnieje
	echo "Adres IP - ${IPADRESS}" >> $PARAMS
	echo "Used RAM - ${RAM}" >> $PARAMS
	echo "Number of processors - ${PROCESSORS}" >> $PARAMS
	ssmtp $EMAIL < $PARAMS
	echo "Parameters sent to the email"
	exit #wychodzi, poniewaz pierwszy raz byly pobierane parametry
fi

#sprawdzanie, czy parametry sie zmienily
COUNTER=0
TEMPIP=$(head -1 $PARAMS) #komenda zczytuje zawartosci pliku parameters.txt, ktory powstal po poprzednim wlaczeniu skryptu
TEMPRAM=$(tail -2 $PARAMS | head -1)
TEMPPROCESSORS=$(tail -1 $PARAMS)

if [ "$TEMPIP" != "Adres IP - ${IPADRESS}" ]; then #jesli zczytany z pliku parametr jest rozny od tego ktory zostal obecnie pobrany przez skrypt, to zwieksz licznik o jeden
	((COUNTER=COUNTER+1))
	echo "IP changed"
fi

if [ "$TEMPRAM" != "Used RAM - ${RAM}" ]; then
	((COUNTER=COUNTER+1))
	echo "RAM changed"
fi

if [ "$TEMPPROCESSORS" != "Number of processors - ${PROCESSORS}" ]; then
	((COUNTER=COUNTER+1))
	echo "Num of processors changed"
fi

if [ $COUNTER -gt 0 ]; then #jesli nastapila chociaz jedna zmiana ktoregos z parametru to utworz nowy plik i wyslij mejla
	echo "Adres IP - ${IPADRESS}" > $PARAMS
	echo "Used RAM - ${RAM}" >> $PARAMS
	echo "Number of processors - ${PROCESSORS}" >> $PARAMS
	ssmtp $EMAIL < $PARAMS
	echo "Email with new parameters has been sent"
else
	echo "Parameters hasn't changed"
fi
