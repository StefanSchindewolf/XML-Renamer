### Skript "rename_xml.awk"
### Datum: 10.03.2020
### Autor: Stefan Schindewolf

### Einsatzzweck
# Das Skript wird mit einem Dateinamen als Parameter aufgerufen. Es analysiert den Inhalt der Datei
# und gibt bei Erfolg einen neuen Dateinamen zurück.
# Die übergebene Datei muss eine XML-Datei sein, die nach ECP Standard 4.4 formatiert und aufgebaut 
# ist. Nur XML-Dateien, die die im Skript benannten Tags enthalten, können gelesen und aus ihnen ein
# neuer Dateiname erstellt werden.
# Im Fehlerfall bricht das Skript mit der Meldung "ERROR-[...]" ab und erzeugt einen Dateinamen, der
# einen Hinweis auf den Fehler enthält und einen aktuellen Zeitstempel.
# Bei Fehlversuchen entstehen also Dateinamen mit "ERROR" vorangestellt.

### Teil 1: Vor Auslesen der Datei 
BEGIN {
	# Variablen vorbefüllen mit 0
	notfound = 0;		# Wenn der Wert nicht 0 bleibt, dann wurde ein XML-Tag nicht gefunden
	erftag = 0;		# Erfüllungstag, entweder aus <schedule_Time_Period.timeInterval>
				# oder aus <received_MarketDocument.mRID> (die ersten 8 Zeichen)
	erstelldat = 0;		# Erstellungszeitpunkt d. Nachricht <createdDateTime>
	revnum = "000_";		# Versionsnummer der Nachricht aus <revisionNumber>
	mrid = 0;		# Die erste <mRID>, die im Dokument gefunden wird
	recdocmrid = 0;		# mRID eines erhaltenen Dokuments <received_MarketDocument.mRID>
	sendermrid = 0;		# mRID des Senders, <sender_MarketParticipant.mRID>
	receivermrid = 0;	# mRID des Nachrichten-Empfängers aus <receiver_MarketParticipant.mRID>
	type = 0;		# Typ der Nachricht aus <type>
	ack = "";		# Acknowledgement aus <Acknowledgement_MarketDocument
	# Für "sprechendere" Business Types im Dateinamen haben wir hier ein assoziatives Array
	# Immer brav an den abschließenden Unterstrich denken
	typelist["A55_"] = "CAS_"; typelist["A09_"] = "SPS_"; typelist["A08_"] = "CNF_"; typelist["MISSING_DATA_"] = "MISSING_DATA_";

	# Dateinamenserweiterung festlegen
	ext = ".xml";
}

### Teil 2: Lese Zeile für Zeile der übergebenen Datei

# a) Ist es ein Acknowledgement --> Speicher in Variable ack
/Acknowledgement_MarketDocument/ {
	ack = "ACK_";
	# Acknowledgements enthalten keinen Erfüllungstag und keine Revision-Nummer
}

# b) Notiere mRID des Dokuments
/<mRID>/ {
	# Wenn wir schon eine mRID erfolgreich auslesen konnten, dann sollten wir keine 
	# weitere übernehmen (es kann mehrere mRID Tags geben)
	if (mrid == 0) {
		mrid=$0;
		# Entferne XML-Tags, Leerzeichen und Tabs
		gsub(/\s|\t/, "", mrid);
		gsub(/<mRID>|<\/mRID>/, "", mrid);
		# Wenn jetzt nichts mehr da ist, dann haben wir einen Tag ohne Daten
		if (mrid == "") 	{
			mrid = 0;
		} else {
			mrid = mrid "_";
		}
	}
}

# c) Enthält die Datei eine REVISION NUMBER (Versionsnummer) --> revnum
/<received_MarketDocument.revisionNumber>/ || /<revisionNumber>/ {
	revnum = $0;
	# XML Tags, Zeilenumbrüche und Slashes löschen wir raus, wir lassen nur die Zahl übrig
	gsub(/<received_MarketDocument.revisionNumber>|<\/received_MarketDocument.revisionNumber>|<revisionNumber>|<\/revisionNumber>/, "", revnum);
	gsub(/\s|\t/, "", revnum);
	#Führende Nullen bei der Versionsnummer ergänzen
	while (length(revnum) <= 2) {
		revnum = "0" revnum;
		}
		revnum = revnum "_";
}

# d) Enthält die Datei einen TYPE (Dokument-Typ) --> type
/<type>/ || /<received_MarketDocument.type>/ {
	type = $0;
	# XML Tags, Zeilenumbrüche und Slashes löschen wir raus, wir lassen nur die Zahl übrig
	gsub(/<received_MarketDocument.type>|<\/received_MarketDocument.type>|<type>|<\/type>/, "", type);
	gsub(/\n|\r|\f|\s|\t/, "", type);
	# Wenn jetzt nichts mehr da ist, dann haben wir einen Tag ohne Daten
	if (type == "") {
		type = 0;
	} else {
		type = type "_";
	}
}

# e) Enthält das Dokument ein mRID eines "received" Dokuments, dann sollte es auch ein Acknowledgment
# sein. Wenn das so ist, dann nimm die ersten 8 Stellen der mRID als Erfüllungsdatum
/<received_MarketDocument.mRID>/ {
	recdocmrid=$0;
	# XML Tags, Zeilenumbrüche und Slashes löschen wir raus, wir lassen nur die Zahl übrig
	gsub(/<received_MarketDocument.mRID>|<\/received_MarketDocument.mRID>/, "", recdocmrid);
	gsub(/\s|\t/, "", recdocmrid);
	# Wenn jetzt nichts mehr da ist, dann haben wir einen Tag ohne Daten
	if (recdocmrid == "") {
		recdocmrid = 0;
	} else {
		recdocmrid = recdocmrid "_";
	}
	# Bei Acknowledgements extrahieren wir den Erfüllungstag aus den ersten 8 Stellen der
	# mRID des Ack-Dokuments
	if (ack != ""){
		erftag = substr(recdocmrid, 0, 8);
		erftag = erftag "_";
		}
	}

# f) Enthält die Datei eine SENDER MRID (EIC Code des Senders) --> sendermrid
/<sender_MarketParticipant.mRID/ {
	sendermrid =$0;
	# XML Tags, Zeilenumbrüche und Slashes löschen wir raus, wir lassen nur die Zahl übrig
	gsub(/<[^>]+>/, "", sendermrid);
	gsub(/\n|\r|\f|\s|\t/, "", sendermrid);
	# Wenn jetzt nichts mehr da ist, dann haben wir einen Tag ohne Daten
	if (sendermrid == "") {
		sendermrid = 0
	} else {
		sendermrid = sendermrid "_";
	}
}

# g) Enthältt die Datei einen mRID-Code des Empfängers? --> receivermrid
/<receiver_MarketParticipant.mRID/ {
	receivermrid=$0;
	# XML Tags, Zeilenumbrüche und Slashes löschen wir raus, wir lassen nur die Zahl übrig
	gsub(/<[^>]+>/, "", receivermrid);
	gsub(/\s|\t/, "", receivermrid);
	# Wenn jetzt nichts mehr da ist, dann haben wir einen Tag ohne Daten
	if (receivermrid == "") {
		receivermrid = 0;
	} else {
		receivermrid = receivermrid "_";
	}
}

# h) Enthält die Datei ein Erstellungsdatum? --> erstelldat
/<createdDateTime>/ {
	erstelldat = $0;
	# Lösche die Tabs und Leerzeichen
	gsub(/\s|\t/, "", erstelldat);
	# Lösche die XML-Tags (alles zwischen den <>)
	count=gsub(/<[^>]+>/, "", erstelldat);
	count=gsub(/:/, "-", erstelldat);
	# Wenn jetzt nichts mehr da ist, dann haben wir einen Tag ohne Daten
	if (erstelldat == "") {
		erstelldat = 0;
	} else {
		# Erstellungsdatum ist das letzte Feld, daher kein Unterstrich am Ende
		erstelldat = erstelldat ;
	}
}

# i) Enthält die Datei einen Erfüllungstag? --> erftag
/<schedule_Time_Period.timeInterval>/ || /<period.timeInterval>/ {
	erftag=$0;
	# Lösche die Tabs oder Leerzeichen
	gsub(/\s|\t/, "", erftag);
	# Lösche die <> und alles, was dazwischen ist, notiere Anzahl Löschungen in count
	count=gsub(/<[^>]+>/, "", erftag);
	# Wenn nur 1 Ersetzung, dann steht der Erfüllungstag in der folgenden Zeile, also spulen
	# wir zwei Zeilen (da erwarten wir <end>) weiter und wiederholen die Extraktion
	if (count == 1){ 
		getline;
		getline;
		erftag = $0;
		# Lösche die Tabs oder Leerzeichen
		gsub(/\s|\t/, "", erftag);
		# Lösche die <> und alles, was dazwischen ist, notiere Anzahl Löschungen in count
		count=gsub(/<[^>]+>/, "", erftag);
		gsub(/:/, "-", erftag);
		gsub(/T[0-9][0-9]-[0-9][0-9]Z/, "", erftag);
		gsub(/-/, "", erftag);
       	}
	# Wenn jetzt nichts mehr da ist, dann haben wir einen Tag ohne Daten
	if (erftag == "") {
		erftag = 0;
	} else {
		erftag = erftag "_";
	}
}

### Teil 3: Am Ende der Datei wird der neue Dateiname zusammengesetzt
END {
	# Letzte Prüfung: Hat der aktuelle Dateiname 5 Unterstriche?
	# Quelldateiname anhand von Unterstrichen aufteilen
	filename = FILENAME;
	counter = split(filename, splname, "_");

	# Wenn bis jetzt nur 0 in den Variablen ist, dann war es keine erfolgreiche Suche
	# Also füllen wir die Variablen mit 0_ für die Generierung des Dateinamens
	# und geben auch einen Fehlercode mit, damit man weiß wo man suchen soll
	if (sendermrid == 0) {notfound = "NO-SENDER-MRID_"; sendermrid = "0_";}
	if (mrid == 0) {notfound = "NO-DOCUM-MRID_"; mrid = "0_";}
	if (recdocmrid == 0 && ack == 0) {notfound = "NO-RECDOC-MRID_"; recdocmrid = "0_";}
	if (receivermrid == 0) {notfound = "NO-RECEIP-MRID_"; receivermrid = "0_";}
	if (erftag == 0) {notfound = "NO-ERFTAG-DATE_"; erftag = "0_";}
	if (erstelldat == 0) {notfound = "NO-CREAT-DATE_"; erstelldat = "0_";}
	if (type == 0) {notfound = "NO-DOCUM-TYPE_"; type = "0_"} 
	if (revnum == "000_" && type != "A08_") {notfound = "NO-REVIS-NUMB_"; revnum= "0_";} 

	# Ausgabe des neuen Dateinamens
	# Wenn Dateiname genau 5 oder 6 Unterstriche hat 
	# UND notfound immer noch 0 UND damit keine Variable 0 ist
	if (counter >= 5 && counter <= 6 && notfound == 0 ) {
		# dann gib den neuen Dateinamen aus
		# Bei der Reihenfolge beachten, dass die letzte Variable möglichst nicht mit "_" endet
		# Hier die gewünschte Reihenfolge der Felder eintragen zunächst einmal für 
		# die üblichen Dateien
		if (ack == ""){
			newname = erftag typelist[type] sendermrid receivermrid revnum erstelldat;
		} else {
			# dann für die Acknowledgements
			newname = erftag typelist[type] receivermrid sendermrid revnum ack erstelldat;
		}

		# Und jetzt raus damit, anschließend Return Code 0
		print newname;
		exit 0;
	} else {
		# Wenn ein Fehler auftrat und die Variable notfound gefüllt wurde, dann übernehme
		# den Fehlercode mit in den Dateinamen, sonst schreibe einfach UNDERSCORE als 
		# Fehlerursache
		if (notfound != 0) { 
			timestamp=strftime("%y-%m-%dT%H-%M-%SZ", systime());
			notfound = ack notfound mrid timestamp;
			print "ERROR_" notfound;
		} else {
			timestamp=strftime("%y-%m-%dT%H-%M-%SZ", systime());
			notfound="ERROR_UNDERSCORES_" mrid timestamp;
			print notfound;
		}
		# Im Fehlerfall geben wir Return Code 1 zurück
		exit 1
	}
}
