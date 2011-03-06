# perl

# use LWP::Simple;
use LWP::UserAgent;
use Geo::Coordinates::DecimalDegrees;


$oldepoch = 0;
$count = 0;
$validdata = 0;

while (1) {
	my $ua = new LWP::UserAgent;
	$ua->timeout(120);
	my $url='http://track.whitestarballoon.com/getSample.php?latest';
	my $request = new HTTP::Request('GET', $url);
	my $response = $ua->request($request);
	my $content = $response->content();
	print "$content\n";

	@splitdata = split(/,/, $content);
	
	foreach $datafield(@splitdata){
		@splitfield = split(/:/, $datafield);
		if($splitfield[1] ne "null"){
			$actualdata = substr( $splitfield[1], 1, - 1 );
		}
		else {
			$actualdata = $splitfield[1];
		}
		$datatitle = substr( $splitfield[0], 1, - 1 );
		
		if ($datatitle eq "epoch"){
			$epoch = $actualdata;
		}
		if ($datatitle eq "latitude"){
			$latitude = $actualdata;
			($latdegrees, $latminutes) = decimal2dm($latitude);
			$nmealatitude = "$latdegrees$latminutes";
			$nmealatitude = substr( $nmealatitude, 0, 9 );
		}
		
		if ($datatitle eq "longitude"){
			$longitude = $actualdata;
			#$longitude = -75.02361679077148;
			($londegrees, $lonminutes, $sign) = decimal2dm($longitude);
			print "$londegrees $lonminutes $sign\n";
			if ($sign == -1 && $londegrees != 0){
				$londegrees = sprintf("%04d", $londegrees);
			}
			else {
				$londegrees = sprintf("%03d", $londegrees);
			}
			
			if(int($lonminutes < 10)){
				$lonminutes = "0$lonminutes";
			}
			
			if ($sign == -1 && $londegrees == 0) {
				$londegrees = "-$londegrees";
			}
			print "$londegrees $lonminutes $sign\n";
			$nmealongitude = "$londegrees$lonminutes";
			$nmealongitude = substr( $nmealongitude, 0, 9 );
			print "$nmealongitude\n";
		}
		
		if ($datatitle eq "altitude"){
			$altitude = $actualdata;
		}
		if ($datatitle eq "fix"){
			$fix = $actualdata;
		}
		if ($datatitle eq "pressure_fc"){
			$pressure_fc = $actualdata;
		}
		if ($datatitle eq "pressure_bb"){
			$pressure_bb = $actualdata;
		}
		if ($datatitle eq "pressure_bm"){
			$pressure_bm = $actualdata;
		}
		if ($datatitle eq "pressure_bt"){
			$pressure_bt = $actualdata;
		}
		if ($datatitle eq "temp_fc"){
			$temp_fc = $actualdata;
		}
		if ($datatitle eq "temp_ext"){
			$temp_ext = $actualdata;
		}
		if ($datatitle eq "temp_bb"){
			$temp_bb = $actualdata;
		}
		if ($datatitle eq "temp_bm"){
			$temp_bm = $actualdata;
		}
		if ($datatitle eq "temp_bt"){
			$temp_bt = $actualdata;
		}
		if ($datatitle eq "temp_batt"){
			$temp_batt = $actualdata;
		}
		if ($datatitle eq "humidity"){
			$humidity = $actualdata;
		}
		if ($datatitle eq "balloonValve"){
			$balloonValve = $actualdata;
		}
		if ($datatitle eq "ice"){
			$ice = $actualdata;
		}
		if ($datatitle eq "heading"){
			$heading = $actualdata;
		}
		if ($datatitle eq "speed"){
			$speed = $actualdata;
		}
		if ($datatitle eq "hdop"){
			$hdop = $actualdata;
		}
		if ($datatitle eq "climb"){
			$climb = $actualdata;
		}
		if ($datatitle eq "status"){
			$status = $actualdata;
		}
		if ($datatitle eq "dewpoint"){
			$dewpoint = $actualdata;
		}
		if ($datatitle eq "volts"){
			$volts = $actualdata;
		}
		if ($datatitle eq "acc_cur"){
			$acc_cur = $actualdata;
		}
		if ($datatitle eq "ballastValve"){
			$ballastValve = $actualdata;
		}
		if ($datatitle eq "balastRemaining"){
			$ballastRemaining = $actualdata;
		}
	}
	
	#Do some sanity checks
	#Check that latitude/longitude is not crazy
	if( ($latitude < 0.1) && ($latitude > -0.1) || ($longitude < 0.1) && ($longitude > -0.1) ){
		$validdata = 0;
	}
	else {
		$validdata = 1;
	}
	#Convert null to 0
	if ($fix == "null"){
		$fix = 0;
	}
	
	if($epoch > $oldepoch){
		$oldepoch = $epoch;
		$count = $count + 1;
		
		if($fix == 0 && $validdata == 1){
			@timeData = gmtime(time);
			
			$datastring = "WB8ELK2,$count,$timeData[2]:$timeData[1]:$timeData[0],$nmealatitude,$nmealongitude,$altitude,$fix,$ice;$temp_ext;$humidity;$speed;$climb;$ballastRemaining,0,0";
			
			print "$datastring\n";
			
			my $rh = new LWP::UserAgent;
			$rh->timeout(120);
			my $response = $rh->post( "http://www.robertharrison.org/listen/listen.php", { 'string' => $datastring, 'identity' => "Orbcomm" } );
			print "$res\n";
		}
		else {
			print "No data uploaded fix = $fix and validdata = $validdata\n";
		}
	}
	sleep(10);
}