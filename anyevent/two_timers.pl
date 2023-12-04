use v5.30.0;
use warnings;

use AnyEvent;
 
# This is an attempt to have two timers running at the same time.
# In fact it doesn't quite do that. It runs one timer, then the other.

my $cv1 = AnyEvent->condvar;
 
my $i = 0;

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
	$cv1->send;
	
}

sub callback2 {
	say 'callback2: ' . localtime();
	$cv1->send;
	
}

say 'Starting at ' . localtime();
while ($i < 10) {
	say $i;
	 $cv1 = AnyEvent->condvar;
	if (! $repeater1) {
		$repeater2 = undef;
		$repeater1 = make_timer(2, \&callback1);
	}
	else {
		$repeater1 = undef;
		$repeater2 = make_timer(10, \&callback2);
	}
	$cv1->recv;
	$i++;
}

say 'End';
