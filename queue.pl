#!/usr/bin/perl

use strict;
use warnings;

# Modules
use Fcntl qw(:flock);
use File::Copy;
use File::Basename;

my $maximum = $ENV{'FS_QUEUE_MAXIMUM'} || 10000;
my $storage = $ENV{'FS_QUEUE_STORAGE'} || "/tmp/storage";

# Queue's LOCK-file
my $LOCK = "$storage/LOCK";

# Queue's HEAD and TAIL links
my $HEAD = "$storage/HEAD";
my $TAIL = "$storage/TAIL";

#
# System interfaces
#

sub alink($$) {
  my($old, $new) = @_;

  my $link = join("-", $new, "link");

  (symlink($new, $link) && rename($link, $old))
    or die "Can't create symlink from $old to $new";
}

sub touch($) {
  (open(F, ">$_[0]") && close(F))
    or die "Can't touch $_[0] file";
}

#
# Queue interfaces
#

sub q_size {
  return q_link_id($HEAD) - q_link_id($TAIL);
}

sub q_clean {
  while (q_size()) {
    q_dequeue_file("/dev/null");
  }
}

sub q_link_id($) {
  my $link = shift;

  return readlink($link) ? (split("/", readlink($link)))[-1] : 0;
}

sub q_link_add($$) {
  my $link = shift;

  unless (readlink($link)) {
    my $zero = join("/", $storage, "0");
    unless (-e $zero) {
      touch($zero);
    }
  }

  my $next = join("/", $storage, q_link_id($link) + $_[0]);
  unless (-e $next) {
    touch($next);
  }

  alink($link, $next);
}

sub q_enqueue_file($) {
  my $src = shift;

  unless (-e $src) {
    die "File $src doesn't exist";
  }

  if (q_size() > $maximum) {
    die "Queue size is full";
  }

  copy($src, readlink($HEAD))
    or die "Can't copy from $src to HEAD";

  q_link_add($HEAD, 1);
}

sub q_dequeue_file($) {
  my $dst = shift;

  if (q_link_id($HEAD) == q_link_id($TAIL)) {
    die "Queue size is zero";
  }

  move(readlink($TAIL), $dst)
    or die "Can't move from TAIL to $dst";

  q_link_add($TAIL, 1);
}

#
# Main and usage
#

sub main {
  my $lock;

  # Create storage depot
  unless (-d $storage) {
    mkdir($storage)
      or die "Can't create storage directory at $storage";
  }

  # Acquire the LOCK
  (open($lock, ">$LOCK") && flock($lock, LOCK_EX))
    or die "Can't acquire lock-file";

  q_link_add($HEAD, 0);
  q_link_add($TAIL, 0);

  unless ($ARGV[0]) {
    usage() && exit(1);
  } elsif ($ARGV[0] eq "size") {
    print q_size() . "\n";
  } elsif ($ARGV[0] eq "clean") {
    q_clean();
  } elsif ($ARGV[0] eq "enqueue") {
    q_enqueue_file($ARGV[1]);
  } elsif ($ARGV[0] eq "dequeue") {
    q_dequeue_file($ARGV[1]);
  } else {
    usage() && exit(1);
  }

  # Release the LOCK
  (flock($lock, LOCK_UN) && close($lock))
    or die "Can't release lock-file)";
}

sub usage {
  my $name = basename($0);
  print "Usage:\n";
  print "       $name size - Query queue size\n";
  print "       $name clean - Clear all the queued files\n";
  print "       $name enqueue <file> - Put file into the queue\n";
  print "       $name dequeue <file> - Get file from the queue\n";
}

#
# main() entry point
#

main();

__END__
