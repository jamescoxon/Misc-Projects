
@epochsplit = split(/:/, $splitdata[4]);
$epoch = $epochsplit[1];
chop($epoch);
chop($epoch);
chop($epoch);
$epoch = substr( $epoch, 1, (length($epoch) - 1) );

@latitudesplit = split(/:/, $splitdata[0]);
$latitude = $latitudesplit[1];
chop($latitude);
$latitude = substr( $latitude, 1, (length($latitude) - 1) );

@longitudesplit = split(/:/, $splitdata[1]);
$longitude = $longitudesplit[1];
chop($longitude);
$longitude = substr( $longitude, 1, (length($longitude) - 1) );

@altitudesplit = split(/:/, $splitdata[2]);
$altitude = $altitudesplit[1];
chop($altitude);
$altitude = substr( $altitude, 1, (length($altitude) - 1) );

@fixsplit = split(/:/, $splitdata[3]);
$fix = $fixsplit[1];
chop($fix);
$fix = substr( $fix, 1, (length($fix) - 1) );

if ($fix == "ul"){
	$fix = 0;
}

if(($latitude && $longitude) > 0.1) {
	$validdata = 1;
}
else {
	$validdata = 0;
}

@timeData = gmtime(time);

print "Epoch = $epoch\n";
print "Latitude = $latitude\n";
print "Longitude = $longitude\n";
print "Altitude = $altitude\n";
print "Fix = $fix\n";

print "$datastring\n";

$fix = 1;

if($epoch > $oldepoch){
	$oldepoch = $epoch;
	if(($fix == 0) && ($validdata == 1)){
		$count = $count + 1;
		
		$datastring = "SPEEDBALL,$count,$timeData[2]:$timeData[1]:$timeData[0],$latitude,$longitude,$altitude,$fix,0,0";
		
		my $rh = new LWP::UserAgent;
		$rh->timeout(120);
		my $response = $rh->post( "http://www.robertharrison.org/listen/listen.php", { 'string' => $datastring, 'identity' => "Orbcomm" } );
		print "$res\n";
		
	}
	else {
		print "No data uploaded fix = $fix and validdata = $validdata\n";
	}
}
