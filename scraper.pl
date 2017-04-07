use LWP::Simple;
use JSON qw( decode_json );
use Data::Dumper;

use strict;



my $key = "AIzaSyA71Kx8hnD5Dq4D56939Kbuh_qhluJa1BQ";

my $apiBaseUrl = "https://www.googleapis.com/youtube/v3/commentThreads?";
my $apiPart = "snippet";
my $videoId = @ARGV[0];

my $apiUrl = $apiBaseUrl."part=".$apiPart."&videoId=".$videoId."&key=".$key;
my $page = $apiUrl;
my @searchedPages;

my $index = 0;

my @table;

my $nextPageToken;

for(my $i=1;$i <= @ARGV[1];$i++){
	if(!grep($_ eq $nextPageToken,@searchedPages)){
	
		my $json = get($page) or die "Error downloading page";
		if($nextPageToken){
			push(@searchedPages,$nextPageToken);
		}
		my $dec_json = decode_json($json);

		my @items = @{ $dec_json->{'items'} };

		foreach my $comment ( @items ){
			$table[$index][0] = $comment->{'snippet'}{'topLevelComment'}{'snippet'}{'authorChannelId'}{'value'};
			$table[$index][1] = $comment->{'snippet'}{'topLevelComment'}{'snippet'}{'textOriginal'};
			$table[$index][2] = $comment->{'snippet'}{'topLevelComment'}{'snippet'}{'likeCount'};
			$index++;
		}
		
		$nextPageToken = $dec_json->{'nextPageToken'};

		$page = $apiUrl."&pageToken=".$nextPageToken;
		#print "Searched pages:\n";
		#foreach (@searchedPages){
		#	print $_,"\n"
		#}
		#print "Next page: ",$nextPageToken,"\n";
	}
}

print "Sorting comments by number of likes \n";
my @sortedTable = sort { $a->[2] <=> $b->[2] } @table;

###############################################################################################################################


my $channelBaseUrl = 'https://www.googleapis.com/youtube/v3/channels?';



$index = 0;
foreach (@table){
#	print "$index $sortedTable[$index][2] $sortedTable[$index][1] \n\n";
	my $channelPart = "statistics";
	my $channelUrl = $channelBaseUrl."key=".$key."&part=".$channelPart."&id=";
	$page = $channelUrl.$table[$index][0];
	#print "$page \n\n ";
	my $json = get($page) or die "Error downloading page";
	
	my $dec_json = decode_json($json);
	
	my @items = @{ $dec_json->{'items'} };

	foreach my $channel ( @items ){
		$table[$index][3] = $channel->{'statistics'}{'subscriberCount'};
		$table[$index][4] = $channel->{'statistics'}{'videoCounter'};
	}
	$channelPart = "snippet";
	$channelUrl = $channelBaseUrl."key=".$key."&part=".$channelPart."&id=";	
	$page = $channelUrl.$table[$index][0];

	$json = get($page) or die "Error downloading page";
	
	$dec_json = decode_json($json);

	my @items = @{ $dec_json->{'items'} };

	foreach my $channel ( @items ){
		$table[$index][5] = $channel->{'snippet'}{'publishedAt'};
	}

	$index++;
}

$index = 0;

my @bots;

my @years = ( "2016", "2015" );

foreach (@table){
	if(!$table[$index][4] && !$table[$index][3] && grep($_ eq substr($table[$index][5], 0, 4), @years ) ){
		#print "Number of videos: $table[$index][4] \n Date created: $table[$index][5] \n\n";
		#print "\n===========================\nSubscribers: $table[$index][3]\n $table[$index][1] \n===========================\n";
		print "\n===========================\nLikes: $table[$index][2]\n $table[$index][1] \n===========================\n";

		push(@bots,$table[$index]);
	}
	#print "Subscribers: $table[$index][3]\n Number of Videos: $table[$index][4]\n Date create: $table[$index][5]\n";
	$index++;
}

print "\n\nTotal possible bots found: ",scalar @bots,"\n";

