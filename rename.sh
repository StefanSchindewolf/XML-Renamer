#!/bin/bash
# Skript holt sich Liste der Dateien aus dem Source Ordner, ruft anschließend ein AWK-Skript auf
# das neue Dateinamen erzeugt und moved die Dateien dann in den Target Ordner
# Test-Aufruf mit "-- test"

# Konfiguration vorweg: wo arbeiten wir denn?
#SOURCEPATH="/home/sts/Code/filerename/pathtester"
SOURCEPATH="/home/sts/Code/filerename/input"
TARGETPATH="/home/sts/Code/filerename/output"
TESTPATH="/home/sts/Code/filerename/test-examples"

# Wo liegt das AWK-Skript
SCRIPT="/home/sts/Code/filerename/rename_xml.awk"

# Schalter für Testmodus
TEST=$1

# Log-Dateiablage
LOG="/tmp/output.log"

# Natürlich berichtet das Skript, was es so tut und loggt dann nach /tmp/output.log
# Los geht's ...
echo $(date -Ins) "Starte Verarbeitung" >> $LOG
if [ "$TEST" == "--test" ]
	then 
		# Im Testmodus kopieren wir uns einige Beispiele in den Input-Ordner
		echo "Testmodus aktiviert!"
		cp $TESTPATH/* $SOURCEPATH 2>> $LOG
fi
echo "Quelldateien in      : " $SOURCEPATH >> $LOG
echo "Zieldateien in       : " $TARGETPATH >> $LOG
echo "Pfad zum Skript      : " $SCRIPT >> $LOG

# Arbeitsvorrat abrufen, also die Liste der Dateien im Source-Path
FILELIST=$(ls $SOURCEPATH);
echo "Arbeitsvorrat        :" >> $LOG
echo $FILELIST >> $LOG

# Gehen wir jede Datei durch und benennen Sie um (Ablage im Ordner "done")
for SOURCE in $FILELIST; do
	# Erzeuge die neuen Namen basierend auf den XML-Inhalten der Quelldateien
	TARGET=$(awk -f$SCRIPT  $SOURCEPATH/$SOURCE) 2>> $LOG
	echo "Alter Name: " $SOURCEPATH"/"$SOURCE >> $LOG
	echo "Neuer Name: " $TARGETPATH"/"$TARGET >> $LOG

	# Nun versuchen wir, die Datei zu bewegen
	echo "Versuche move der Datei" >> $LOG
	# Wenn eine oder mehrere Versionen der gleichen Datei vorhanden sind, dann durchnummerieren
	export VERSION_CONTROL=numbered
	# Folgende Zeile von "cp" (copy) auf "mv" (move) ändern, um Dateien nicht doppelt zu verarb.
	mv --backup -v $SOURCEPATH/$SOURCE $TARGETPATH/$TARGET >> $LOG
done
echo $(date -Ins) " Beende Verarbeitung" >> $LOG
