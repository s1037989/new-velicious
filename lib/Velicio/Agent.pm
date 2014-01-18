package Velicio::Agent;

use Mojo::Base 'Mojo::EventEmitter';
use Mojo::JSON 'j';
use Mojo::Util qw/slurp spurt/;

use Velicio2::Util;

use File::Spec::Functions 'catfile';
use Time::HiRes 'time';
use Math::Prime::Util;

use constant {
  FATAL => 1000,
};

my $retry = 0;
my $counter = 0;

has 'tid';
has 'ua';
has 'tx';

has 'uuid' => sub {
  my $self = shift;
  if ( -e catfile $self->app->home, 'state/registration' ) {
    return slurp(catfile $self->app->home, 'state/registration');
  } else {
    mkdir catfile $self->app->home, 'state';
    chmod 0700, catfile $self->app->home, 'state';
    return spurt(Velicio2::Util::uuid, catfile($self->app->home, 'state/registration'));
  }
};
has log => sub { Mojo::Log->new };
has app => sub { shift->{app} };
has config => sub { shift->app->config->{agent} };
has manager_url => sub {
  my $self = shift;
  my $url = 'ws://'.$self->config->{manager_url}.'/manager';
  $self->app->log->debug("Using Manager: $url");
  $url;
};

sub new {
  my $self = shift->SUPER::new(@_);
  $self->tid(Mojo::IOLoop->recurring(1 => sub {
    $self->ping and return;
    return if $self->_wait_prime;
    $self->_advance_prime;
    $self->ua(Mojo::UserAgent->new);
    $self->ua->websocket($self->manager_url => sub {
      my ($ua, $tx) = @_;
      $self->log->error(sprintf "I am an Agent (%s), Websocket handshake failed: %s", $self->uuid, $tx->error) and return unless $tx->is_websocket;
      $retry = 0;
      $self->tx($tx);
      $self->log->debug(sprintf 'I am an Agent, my New TX: %s', $self->tx);
      $self->tx->on(error => sub { $self->log->error(sprintf 'I am an Agent, TX error: %s', $_[1]) });
      $self->tx->on(finish => sub {
        my ($ws, $code, $reason) = @_;
        $self->log->debug(sprintf 'I am an Agent (%s), TX finish: %s - %s', $self->uuid, $code, $reason);
        $self->tx(undef); # This is necessary
        $retry = 10 if $code == FATAL;
      });
      #$self->tx->on(frame => sub {
      #  my ($ws, $frame) = @_;
      #  $self->app->log->debug(sprintf 'I am an Agent (%s), my MANAGER responded: %s', $self->uuid, $frame->[5]);
      #});
      $self->tx->on(json => sub {
        my ($ws, $json) = @_;
        $ws->emit($json->{_} => $json);
      });
    }) unless $self->tx && $self->tx->is_websocket;
  })) unless $self->tid;
  $self;
}

sub probe {
  my $self = shift;
  Mojo::IOLoop->recurring(4 => sub {
    say "PROBING";
  });
}

sub upload {
  Mojo::IOLoop->recurring(4 => sub {
    say "UPLOADING";
  });
}

sub ping {
  my $self = shift;
  return undef unless $self->tx && $self->tx->is_websocket;
  $self->tx->send([1, 0, 0, 0, 9, join ':', $self->app->version, time, $self->uuid]);
}

sub _wait_prime {
  my $self = shift;
  $self->log->info(sprintf "I am an Agent, attempting to connect to MANAGER (%s) in %s seconds...", $self->manager, $retry) if $retry && !$counter;
  $counter++;
  $counter < $retry;
}
sub _advance_prime {
  my ($self, $next) = @_;
  $counter = 0;
  $retry = 60*5 if $retry > 60*15;
  $retry = Math::Prime::Util::next_prime($retry);
}

1;
