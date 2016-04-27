package Teleberry::Control;

use strict;
use warnings;

use IPC::System::Simple qw(capturex systemx);
use Readonly;
use Teleberry::Cache;

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

Readonly my %RESPONSE_ICON => (
    success => 'fa-check',
    failure => 'fa-exclamation-triangle',
    update  => 'fa-cog fa-spin',
);

sub new {
    # Generate a bundle of fun
    my $self = bless {
        dl_queue => {},
        cache    => Teleberry::Cache->new($OUTPUT_DIR),
    }, shift;

    # Set initial omxplayer options
    $self->issue_command('e');

    return $self;
}

# Utility methods
# ###############

sub issue_command {
    my ($self, @args) = @_;
    eval { systemx($OMXD_BIN, @args) };
    return $@ ? 0 : 1;
}

sub capture_command {
    my ($self, @args) = @_;
    return capturex($OMXD_BIN, @args);
}

sub cache { shift->{cache} }

sub build_response {
    my ($type, $message, %extra) = @_;
    return {
        type        => $type    || 'failure',
        message     => $message || '',
        icon_class  => $RESPONSE_ICON{$type} || 'fa-question',
        %extra
    };
}

sub download {
    my ($self, $id) = @_;

    return 1 if $self->{cache}->get($id)
             or $self->{dl_queue}->{$id};

    # Prevent simultaneous downloads of the same file
    $self->{dl_queue}->{$id} = 1;

    eval { systemx($YTDL_BIN, '-x', '-f', $FORMAT_STRING, '-o', $OUTPUT_FORMAT, $id) };
    my $error = $@;

    $self->{cache}->put_id($id);
    delete $self->{dl_queue}->{$id};
    return $error ? 0 : 1;
}

# API functions
# #############

sub status {
    my ($self) = @_;
    $self->capture_command('S');
}

sub navigate {
    my ($self, $action) = @_;
    $action ||= '';

    if ($action and my $cmd = $NAVIGATE_CMD{$action}) {
        return $self->issue_command($cmd)
            ? build_response('success')
            : build_response('failure');
    } else {
        return build_response('failure', "Unknown navigate action '$action'");
    }
}

sub volume {
    my ($self, $direction) = @_;
    $direction ||= '';

    if ($direction and my $cmd = $VOLUME_CMD{$direction}) {
        return $self->issue_command($cmd)
            ? build_response('success') : build_response('failure');
    } else {
        return build_response('failure', "Unknown volume direction '$direction'");
    }
}

sub queue {
    my ($self, $id, $action) = @_;

    my $media = $self->{cache}->get($id);
    $action ||= '';

    # If we don't have the track yet, return now to keep the UI
    # responsive, but queue up a new AJAX request to do the download
    return build_response('update', "Fetching YouTube ID $id...",
        next_action => "download/$id/$action"
    ) unless $media;

    if ($action and my $cmd = $QUEUE_CMD{$action}) {
        return $self->issue_command($cmd, $media->{path})
            ? build_response('success', "Queued $media->{artist}: $media->{title}")
            : build_response('failure');
    } elsif ($action) {
        return build_response('failure', "Unknown queue action '$action'");
    }
}

sub download_and_queue {
    my ($self, $id, $action) = @_;

    $self->download($id)
        or return build_response('failure', "Failed to download YouTube ID $id");
    return $self->queue($id, $action);
}

1;

