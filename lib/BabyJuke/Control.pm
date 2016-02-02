package BabyJuke::Control;

use strict;
use warnings;

use IPC::System::Simple qw(capturex);
use Readonly;
use BabyJuke::Cache;

Readonly my $OMXD_BIN => 'omxd';

Readonly my $YTDL_BIN => 'youtube-dl';
Readonly my $FORMAT_STRING => 'bestaudio[filesize<=5M]';
Readonly my $OUTPUT_DIR => '/home/pi/media';
Readonly my $OUTPUT_FORMAT => "$OUTPUT_DIR/%(id)s %(title)s.%(ext)s";

Readonly my %NAVIGATE_CMD => (
    next        => 'n',
    previous    => 'N',
    pause       => 'p',
    stop        => 'X',
    replay      => '.',
    forward     => 'f',
    rewind      => 'r',
);

Readonly my %VOLUME_CMD => (
    up      => '+',
    down    => '-',
);

Readonly my %QUEUE_CMD => (
    change      => 'a',
    end         => 'A',
    next        => 'L',
);

sub new {
    # Generate a bundle of fun
    my $self = bless {
        dl_queue => {},
        cache    => BabyJuke::Cache->new($OUTPUT_DIR),
    }, shift;

    # Set initial omxplayer options
    $self->issue_command('e');

    return $self;
}

sub issue_command {
    my ($self, @args) = @_;
    return capturex($OMXD_BIN, @args);
}

sub status {
    my ($self) = @_;
    $self->issue_command('S');
}

sub cache {
    my ($self) = @_;
    $self->{cache};
}

sub navigate {
    my ($self, $action) = @_;
    if (my $cmd = $NAVIGATE_CMD{$action}) {
        $self->issue_command($cmd);
    } else {
        warn "Unknown navigate action $action";
    }
}

sub volume {
    my ($self, $direction) = @_;
    if (my $cmd = $VOLUME_CMD{$direction}) {
        $self->issue_command($cmd);
    } else {
        warn "Unknown volume direction $direction";
    }
}

sub queue {
    my ($self, $id, $action) = @_;
    my $media = $self->{cache}->get($id);
    $self->download($id) unless $media;
    $media ||= $self->{cache}->get($id);

    if (my $cmd = $QUEUE_CMD{$action}) {
        $self->issue_command($cmd, $media->{path});
        return { message => "Added $media->{artist}: $media->{title}" };
    } else {
        return { error => "Unknown queue action $action" };
    }
}

sub download {
    my ($self, $id) = @_;

    return if $self->{cache}->get($id)
           or $self->{dl_queue}->{$id};

    # Prevent simultaneous downloads of the same file
    $self->{dl_queue}->{$id} = 1;

    capturex($YTDL_BIN, '-x', '-f', $FORMAT_STRING, '-o', $OUTPUT_FORMAT, $id);

    $self->{cache}->put_id($id);
    delete $self->{dl_queue}->{$id};
}

1;

