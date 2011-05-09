

use LWP::UserAgent;
use Time::Local;

$glId = "0VSOSac1275Xczm05gSxTBEcJcPoAf6Ix";
$count = 0;
$oldtime = 1301760620;

my $ua = LWP::UserAgent->new;
$ua->timeout(120);
my $url='http://share.findmespot.com/messageService/guestlinkservlet';
my $response = $ua->post(
	$url, 
	[
	"glId" => $glId, 
	"limit" => "50", 
	"linkPw" => "", 
	"mode" => "none", 
	"start" => "0", 
]);

print $response;
#my $response = $ua->post($request);
my $content = $response->content();
print "$content\n";

@splitsections = split(/<message>/, $content);

foreach $sections (@splitsections) {
	print "$sections\n";
	@components = split(/<\//, $sections);
	foreach $subsections (@components) {
		print "$subsections\n";
		@subcomp = split(/<latitude>/, $subsections);
		if ($subcomp[1] ne "") {
			$latitude = $subcomp[1];
		}
		print "$subcomp[1]\n";
		@subcomp = split(/<longitude>/, $subsections);
		if ($subcomp[1] ne "") {
			$longitude = $subcomp[1];
		}
		print "$subcomp[1]\n";
		
		@subcomp = split(/<timeInGMTSecond>/, $subsections);
		if ($subcomp[1] ne "") {
			$time = $subcomp[1];
		}
		print "$subcomp[1]\n";
	}

print "Time = $time, Latitude = $latitude, Longitude = $longitude\n";
	$count = $count + 1;
	
	my $time1 = time;
	my ($sec, $min, $hour, $day,$month,$year) = (gmtime($time1))[0,1,2,3,4,5,6];
	
	$datastring = "KI6YMZ,$count,$hour:$min:$sec,$latitude,$longitude,0,0,0,0";
	
	print "$datastring\n";
	
	my $rh = new LWP::UserAgent;
	$rh->timeout(120);
	my $response = $rh->post( "http://www.robertharrison.org/listen/listen.php", { 'string' => $datastring, 'identity' => "SPOT" } );
sleep(2);
}