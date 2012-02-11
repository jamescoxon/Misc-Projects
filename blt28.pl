use LWP::UserAgent;
use Time::Local;
use POSIX;

$callsign = 'kt5tk-11';
$password = 'aurora';
$oldtime = 0;

while (1) {

	my $ua = LWP::UserAgent->new;
	$ua->timeout(120);
	my $url="http://db.aprsworld.net/datamart/csv.php?call=$callsign% ";
	my $response = $ua->post($url);

	my $content = $response->content();
	#print "$content\n";

	@splitsections = split(/,/, $content);

	print "$splitsections[14]\n";
	$callsign = $splitsections[14];
	chop($callsign);
	substr($callsign, 0, 1, '');
	
	print "$splitsections[15]\n";
	$latitude = $splitsections[15];
	chop($latitude);
	substr($latitude, 0, 1, '');
	
	print "$splitsections[16]\n";
	$longitude = $splitsections[16];
	chop($longitude);
	substr($longitude, 0, 1, '');
	
	print "$splitsections[19]\n";
	$altitude = $splitsections[19];
	chop($altitude);
	substr($altitude, 0, 1, '');

	print "$splitsections[27]\n";
	$time = $splitsections[27];
	chop($time);
	substr($time, 0, 12, '');
	chop($time);
	print "$time\n";

	@splitTime = split(/:/, $time);

	$hour = $splitTime[0];
	$min = $splitTime[1];
	$sec = $splitTime[2];

	if($oldtime != $time) {
		$oldtime = $time;
		my $spacenear = LWP::UserAgent->new;
		$spacenear->timeout(120);
		my $url='http://spacenear.us/tracker/track.php';
		my $response = $spacenear->post($url);
		my $response = $spacenear->post(
		$url, 
		[
		"vehicle" => "$callsign", 
		"time" => "$hour$min$sec", 
		"lat" => "$latitude", 
		"lon" => "$longitude", 
		"alt" => "$altitude",
		"pass" => "$password",
		]);

		print "$response\n";
		my $content = $response->content();
		print "$content\n";
	}
	
	sleep(60);
}
