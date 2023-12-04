use v5.30.0;
use warnings;

use AnyEvent;
 
my $cv = AnyEvent->condvar;
 
my $i = 0;

my $wait_secs = 5;
my $interval_secs = 2;

my $repeater = AnyEvent->timer (
   after => $wait_secs,  # after how many seconds to invoke the cb?
   interval => $interval_secs, # how often to invoke the cb?
   cb    => sub { # the callback to invoke
      say $i . ' : ' . localtime();
      $i++;
      $cv->send if $i > 10;
   },
);
 
say 'Starting at ' . localtime();
$cv->recv;

