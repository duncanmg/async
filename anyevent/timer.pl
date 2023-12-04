use v5.30.0;
use warnings;

use AnyEvent;
 
# $| = 1; print "enter your name> ";
 
my $cv = AnyEvent->condvar;
 
my $wait_secs = 5;
my $wait_several_seconds = AnyEvent->timer (
   after => $wait_secs,  # after how many seconds to invoke the cb?
   cb    => sub { # the callback to invoke
      say "Time is up! ($wait_secs seconds)";
      $cv->send;
   },
);
 
# can do something else here
say "Waiting for $wait_secs seconds..."; 
# now wait till our time has come
$cv->recv;

