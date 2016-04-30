package Teleberry::Cache;
# A simple file system hash to minimise IO ops

use strict;
use warnings;

use Encode qw(decode);

sub new {
    my ($pkg, $dir) = @_;
    my $self = bless { dir => $dir }, $pkg;

    die "Cache directory '$dir' doesn't exist" unless -d $dir;
    $self->populate;
    return $self;
}

sub populate {
    my ($self) = @_;
    opendir(my $dh, $self->{dir});
    while (readdir $dh) {
        $self->put_file(decode('UTF8', $_));
    }
    closedir($dh);
}

sub get {
    my ($self, $id) = @_;
    return $self->{cache}->{$id};
}

sub put_file {
    my ($self, $file) = @_;
    return unless -f "$self->{dir}/$file";

    if ($file =~ /^(\S+) (.*)\.([^.]+)$/) {
        my ($id, $title, $extension, $artist) = ($1, $2, $3, '');
        if ($title =~ /^(.*?) - (.*)$/) {
            ($artist, $title) = ($1, $2);
        }
        $self->{cache}->{$id} = {
            title => $title,
            artist => $artist,
            extension => $extension,
            path => "$self->{dir}/$file",
        };
    }
}

sub put_id {
    my ($self, $id) = @_;

    opendir(my $dh, $self->{dir});
    while (readdir $dh) {
        if ($_ =~ /^$id .+$/) {
            $self->put_file($_);
        }
    }
    closedir($dh);
}

sub delete {
    my ($self, $id) = @_;
    delete $self->{cache}->{$id};
}

1;

