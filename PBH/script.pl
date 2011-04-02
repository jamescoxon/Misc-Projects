# Upload script to push data from PBH to spacenear.us

use LWP::UserAgent;
use Time::Local;

$count = 171;
$oldlatitude = 0;

while(1)
{
	my $ua = new LWP::UserAgent;
	$ua->timeout(120);
	my $url='http://www.projectbluehorizon.com/httpapi/createFromPoints.php?mid=14';
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
	my ($sec, $min, $hour, $day,$month,$year) = (gmtime($time))[0,1,2,3,4,5,6];

	if($latitude != $oldlatitude){
		$oldlatitude = $latitude;
		$count = $count + 1;

		$datastring = "PBH,$count,$hour:$min:$sec,$latitude,$longitude,$altitude";

		print "$datastring\n";

		my $rh = new LWP::UserAgent;
		$rh->timeout(120);
		my $response = $rh->post( "http://www.robertharrison.org/listen/listen.php", { 'string' => $datastring, 'identity' => "PBH_Team" } );
	}
	sleep(30);
}