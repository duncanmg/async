use v5.30.0;
use warnings;

use AnyEvent;
 
# This is an attempt to have two timers running at the same time.
# It works, but the call to $cv1->send stops both timers.

my $cv1 = AnyEvent->condvar;
 
my $i = 0;
my $j = 0;

my ($repeater1, $repeater2);
 
sub make_timer {
   my ($wait_secs, $callback) = @_;
   return AnyEvent->timer (
     after => $wait_secs,  # after how many seconds to invoke the cb?
     interval => $wait_secs, # how often to invoke the cb?
     cb    => $callback
   );
}

sub callback1 {
	say 'callback1: ' . localtime();
	$cv1->send if $i > 10;
	$i++
}

sub callback2 {
	say "\tcallback2: " . localtime();
	$cv1->send if $j > 10;
	$j++
}

$repeater1 = make_timer(2, \&callback1);
$repeater2 = make_timer(5, \&callback2);

say 'Starting at ' . localtime();
$cv1->recv;

say 'End';
