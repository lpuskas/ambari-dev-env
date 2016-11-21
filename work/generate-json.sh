JSON_INPUT="$1.json"
echo "Generating file $JSON_INPUT ..."
echo "[" | cat > $JSON_INPUT
while read LINE
do
  USR_HOME=/user/$(echo $LINE | awk -F, '{print $1}')
  #ARGS="$ARGS $USR_HOME"

  cat <<EOF >> "$JSON_INPUT"
    {
    "target":"$USR_HOME",
    "type":"directory",
    "action":"create",
    "group":"hive"
  },
EOF

done <$1
sed -i '$ d' $JSON_INPUT
echo $'}\n]' | cat >> $JSON_INPUT
echo Generating file $JSON_INPUT DONE.
