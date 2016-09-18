ls *.sql | while read line
do
	if [ "$line" != "test.sql" ]
	then
		echo "<SqlFile file=\"sprocs/$line\" type=\"sql\"></SqlFile>"
	fi
done
