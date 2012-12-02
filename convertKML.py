# Python script to convert poly files from http://downloads.cloudmade.com/ into both CSV files that could
# be used for polygons as well as a kml
# Command args:
# python convertKML.py netherlands.poly netherlands.csv netherlands.kml 10

import sys

inputfile = sys.argv[1]
outputfile_csv = sys.argv[2]
outputfile_kml = sys.argv[3]
lines_to_remove = int(sys.argv[4])


p = open(inputfile, 'r')
wf = open(outputfile_csv, 'w')
kml_file = open(outputfile_kml	, 'w')

line_num = 0

kml_file.write('<?xml version="1.0" encoding="UTF-8"?> \n')
kml_file.write('<kml xmlns="http://earth.google.com/kml/2.0"> <Document>\n')
kml_file.write('<Placemark> \n')
kml_file.write(' <Polygon> <outerBoundaryIs>  <LinearRing> \n')
kml_file.write('  <coordinates>\n')

for line in p:
	if 'END' in line:
		break

	
	if line_num == lines_to_remove:
		data = line.split('  ' );
		print data
		lat = float(data[3]) * 10000000 
		lon = float(data[2]) * 10000000
		new_string = str(int(lat)) + ',' + str(int(lon)) + '\n'
		print new_string
		wf.write(new_string)
		kml_string = str(data[2].rstrip()) + ',' + str(data[3].rstrip()) + ',0\n'
		kml_file.write(kml_string)
		line_num = 0
	else:
		line_num = line_num + 1

kml_file.write('  </coordinates>\n')
kml_file.write(' </LinearRing> </outerBoundaryIs> </Polygon>\n')
kml_file.write('</Placemark>\n')
kml_file.write('</Document> </kml>\n')
p.close
wf.close
kml_file.close
