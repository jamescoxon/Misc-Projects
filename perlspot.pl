
use LWP::UserAgent;
use Time::Local;
use POSIX;

$glId = "02vhBoDslO1BaEqCUR9sUikleajn0x2u4";
$count = 0;
$oldtime = 1301760620;
$altencoded = 1;

while (1)
{
	my $ua = LWP::UserAgent->new;
	$ua->timeout(120);
	my $url='http://share.findmespot.com/messageService/guestlinkservlet';
	my $response = $ua->post(
	$url, 
	[
	"glId" => $glId, 
	"limit" => "", 
	"linkPw" => "", 
	"mode" => "none", 
	"start" => "", 
	]);
	
	print $response;
	#my $response = $ua->post($request);
	my $content = $response->content();
	print "$content\n";
	
	@splitsections = split(/<message>/, $content);
	
	 @Rsplitsections = reverse(@splitsections); 
	foreach $sections (@Rsplitsections) {
		print "$sections\n";
		@components = split(/<\//, $sections);
		foreach $subsections (@components) {
			#print "$subsections\n";
			@subcomp = split(/<latitude>/, $subsections);
			if ($subcomp[1] ne "") {
				$latitude = $subcomp[1];
			}
			#print "$subcomp[1]\n";
			@subcomp = split(/<longitude>/, $subsections);
			if ($subcomp[1] ne "") {
				$longitude = $subcomp[1];
			}
			#print "$subcomp[1]\n";
			
			@subcomp = split(/<timeInGMTSecond>/, $subsections);
			if ($subcomp[1] ne "") {
				$time = $subcomp[1];
			}
			#print "$subcomp[1]\n";
		}
	}
	
	if($latitude > 0 && $longitude > 0) {$altTThousand = 0;} #NE
	if($latitude < 0 && $longitude > 0) {$altTThousand = 1;} #SE
	if($latitude < 0 && $longitude < 0) {$altTThousand = 2;} #SW
	if($latitude < 0 && $longitude < 0) {$altTThousand = 3;} #NW
	
	if ($altencoded) {
		# Extract encoded coordinates and altitude
		$latitude  /= 90.0 / 99.0;
		$longitude /= 180.0 / 99.0;
		
		$altitude  = $altTThousand * 10000; # TODO - extract this digit from NSEW
		$altitude += floor($latitude) * 100;
		$altitude += floor($longitude);
		
		$latitude -= floor($latitude);
		$latitude *= 90.0;
		
		$longitude -= floor($longitude);
		$longitude *= 180.0;
		
		# Round the results to something sensible
		$latitude = sprintf("%.4f", $latitude);
		$longitude = sprintf("%.4f", $longitude);
	}
	
	print "Time = $time, Latitude = $latitude, Longitude = $longitude, Altitude = $altitude\n";
	
	if ($time > $oldtime) {
		$oldtime = $time;
		$count = $count + 1;
		
		my $time1 = time; #real time
		my ($sec, $min, $hour, $day,$month,$year) = (gmtime($time))[0,1,2,3,4,5,6];
		
		$longitude = $longitude * -1;
		$datastring = "SPOT,$count,$hour:$min:$sec,$latitude,$longitude,$altitude,0,0,0";
		
		print "$datastring\n";
		
		my $rh = new LWP::UserAgent;
		$rh->timeout(120);
		my $response = $rh->post( "http://www.robertharrison.org/listen/listen.php", { 'string' => $datastring, 'identity' => "SPOT" } );
	}
	sleep(60);
}
