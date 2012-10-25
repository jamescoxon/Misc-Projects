# Upload script to push data from PBH to spacenear.us

use LWP::UserAgent;
use Time::Local;

$count = 0;
$oldlatitude = 0;
$password = 'aurora';

while(1)
{
	my $ua = new LWP::UserAgent;
	$ua->timeout(120);
	my $url='http://www.projectbluehorizon.com/httpapi/createFromPoints.php?mid=18';
	my $request = new HTTP::Request('GET', $url);
	my $response = $ua->request($request);
	my $content = $response->content();
	print "$content\n";

	@splitlines = split(/\n/, $content);

	$numlines = @splitlines;

	$string = $splitlines[$numlines - 2];

	@components = split(/,/, $string);

	$latitude = $components[1];
	$longitude = $components[0];
	$altitude = $components[2];

	print "$latitude: $longitude: $altitude\n";

	my $time = time;
	my ($sec, $min, $hour, $day, $month, $year) = (gmtime($time))[0,1,2,3,4,5,6];

	if($latitude != $oldlatitude){
		$oldlatitude = $latitude;
		$count = $count + 1;
		
		print "$hour";
		
		if($hour < 10){
			$hour = "0$hour";
		}
		if($min < 10){
			$min = "0$min";
		}
		if($sec < 10){
			$sec = "0$sec";
		}
		$datastring = "PBH,$count,$hour:$min:$sec,$latitude,$longitude,$altitude";

		print "$datastring\n";
		
		my $spacenear = LWP::UserAgent->new;
		$spacenear->timeout(120);
		my $url='http://spacenear.us/tracker/track.php';
		my $response = $spacenear->post($url);
		my $response = $spacenear->post(
		$url, 
		[
		"vehicle" => "PBH", 
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
	sleep(30);
}