#!/bin/bash

DirScripts="/opt/scriptsNIS/"
DirAudios="/var/spool/asterisk/monitor/"
DirFecha=$(date -d yesterday +"%Y/%m/%d")
DirDestino=$DirAudios$DirFecha
TiempoEspera="3"

### CONVERSION DE FORMATO
cd $DirScripts
cp -rf wav2mp3SLAVE.sh $DirDestino
cd $DirDestino
echo ""
echo "- Script Copiado para ejecucion: "  $(date +"%d/%m/%Y %T")
echo ""

sleep $TiempoEspera
#sleep 2m
#echo "- Iniciando Conversion de Audios: " $(date +"%d/%m/%Y %T")
#echo ""
bash wav2mp3Slave.sh > /var/log/log_wav2mp3.log
