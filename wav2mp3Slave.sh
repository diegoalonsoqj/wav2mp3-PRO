#!/bin/bash
nameCliente="NombreDelCliente"
hostCliente="Hostaname"

correoReceptor="aaa@bbbb.com"

MysqlUser="UsuarioMysql"
MysqlPass="PasswordMysql"
MysqlFecha=$(date -d yesterday +"%Y-%m-%d")

DirAudios="/var/spool/asterisk/monitor/"
DirFecha=$(date -d yesterday +"%Y/%m/%d")
DirDestino=$DirAudios$DirFecha

TiempoEspera="3"

let NoAudiosWav="0"

DirRaiz=$(pwd)

sleep $TiempoEspera

let TotalAudios=$(find . -maxdepth 1 -type f -iname "*.wav" | wc -l)

if [ $TotalAudios -gt $NoAudiosWav ]; then

echo "- Iniciando Conversion de Audios: " $(date +"%d/%m/%Y %T")
echo ""

mkdir formato_mp3

PesoWav=$(du -hs)

TimeInitConvert=$(date +"%d/%m/%Y %T")

### ALERTA DE INICIO POR CORREO ###
echo -e "    ###  INCIANDO CONVERSION DE AUDIOS  ###  \n\n - Cliente: " $nameCliente "\n - Host: " $hostCliente "\n - Hora y Fecha: " $TimeInitConvert "\n - Carpeta: /"$DirFecha "\n - Peso inicial: " $PesoWav | mail -s "INICIO - CONVERSION DE AUDIOS" $correoReceptor

for i in *.wav
do
    echo PROCESANDO $i
    lame -b 16 -m m -q 9 --resample 8 "$i" "formato_mp3/${i/.wav/.mp3}"
done


let TotalWav=$(find . -maxdepth 1 -type f -iname "*.wav" | wc -l)

echo ""
echo ""
echo "INICIANDO CONVERSION DE AUDIOS: " $TimeInitConvert
echo ""
echo "ARCHIVOS WAV: "
echo "- Cantidad total de audios WAV: " $TotalWav
echo "- Peso de los audios WAV: " $PesoWav
echo ""

cd formato_mp3

PesoMp3=$(du -hs)

let TotalMp3=$(find . -maxdepth 1 -type f -iname "*.mp3" | wc -l)
echo "ARCHIVOS MP3: "
echo "- Cantidad total de audios MP3: " $TotalMp3
echo "- Peso de los audios MP3: " $PesoMp3

let difWavMp3=$TotalWav-$TotalMp3


	### CONTEO DE REGITRO EN TABLAS
	regsDBIn=$(mysql --user=$MysqlUser --password=$MysqlPass --raw --batch -e "SELECT COUNT(*) from call_center.call_recording WHERE recordingfile LIKE '%.wav%' AND DATE(datetime_entry) = '$MysqlFecha';" -s)

	regsDBOut=$(mysql --user=$MysqlUser --password=$MysqlPass --raw --batch -e "SELECT COUNT(*) FROM asteriskcdrdb.cdr WHERE recordingfile LIKE '%.wav%' AND DATE(calldate) = '$MysqlFecha';" -s)


if [ $TotalWav -ne $TotalMp3 ]; then
	echo ""
	echo " ERROR - Existe un diferencia de cantidades"
	echo "- Diferencia de cantidades de archivos entre WAV y MP3: " $difWavMp3

	### ALERTA POR CORREO - ERROR ###
	echo -e "    ###  Conversion de Wav a MP3  ###  \n\n - Cliente: " $nameCliente "\n - Host: " $hostCliente "\n - Hora y Fecha: " $(date +"%T - %d/%m/%Y") "\n - Carpeta: /"$DirFecha "\n - Audios sin convertir: " $difWavMp3 "\n - Peso inicial: " $PesoWav "\n - Peso final: " $PesoMp3 "\n - Estado: ERROR" | mail -s "FIN - CONVERSION DE AUDIOS FALLIDA" $correoReceptor

else
	mv *.mp3 ../
	cd ..
	rm -rf formato_mp3
	rm -rf *.wav

	### ACTULIZACION DE TABLAS
	mysql --user=$MysqlUser --password=$MysqlPass -e "UPDATE call_center.call_recording SET recordingfile = REPLACE(recordingfile, '.wav', '.mp3') WHERE DATE(datetime_entry) = '$MysqlFecha';"

	mysql --user=$MysqlUser --password=$MysqlPass -e "UPDATE asteriskcdrdb.cdr SET recordingfile = REPLACE(recordingfile, '.wav', '.mp3')
WHERE dcontext = 'ext-queues' AND recordingfile != '' AND DATE(calldate) = '$MysqlFecha';"

	TimeFinConvert=$(date +"%d/%m/%Y %T")

	echo ""
        echo " *** CONVERSION DE AUDIOS EXITOSA ***"
	echo "- Fecha y Hora: " $TimeFinConvert
	echo "- Tablas actualizadas en las Bases de Datos."
       	echo "- Diferencia de cantidades de archivos entre WAV y MP3: " $difWavMp3

	#### ALERTA POR CORREO - EXITO #####
	echo -e "    ###  Conversion de Wav a MP3  ###  \n\n - Cliente: " $nameCliente "\n - Host: " $hostCliente "\n - Hora y Fecha de INICIO: " $TimeInitConvert "\n - Hora y Fecha de FIN: " $TimeFinConvert "\n - Carpeta: /"$DirFecha "\n - Total de Audios: " $TotalAudios "\n - Peso inicial: " $PesoWav "\n - Peso final: " $PesoMp3 "\n - Registros Entrantes: " $regsDBIn "\n - Registros Salientes: " $regsDBOut "\n - Estado: OK" | mail -s "FIN  - CONVERSION DE AUDIOS EXITOSA" $correoReceptor

fi

else
	### ALERTA POR CORREO - NO AUDIOS ###
	echo -e "    ###  Conversion de Wav a MP3  ###  \n\n - Cliente: " $nameCliente "\n - Host: " $hostCliente "\n - Hora y Fecha: " $(date +"%T - %d/%m/%Y") "\n - Carpeta: /"$DirFecha "\n - Estado: NO EXISTEN AUDIOS." | mail -s "FIN - CONVERSION DE AUDIOS" $correoReceptor	
fi


