package Filesys::ZFS::Stat;

# Copyright (c) 2021 Gleb Smirnoff <glebius@FreeBSD.org>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.   
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

=head1 NAME

Filesys::ZFS::Stat - read ZFS statistics on FreeBSD

=head1 SYNOPSIS

=over

 use Filesys::ZFS::Stat;

 my $zstat = Filesys::ZFS::Stat->new(pools => ['zroot']);
 my $zroot = Filesys::ZFS::Stat->pool('zroot');
 my $data = Filesys::ZFS::Stat->dataset('zroot', 'data');

 $zstat->nread('zroot', 'data');
 $zroot->nread('data');
 $data->nread();

=back

=head1 CONSTRUCTORS

=cut

use 5.006;
use strict;
use warnings;
use BSD::Sysctl 0.12 'sysctl';

our $VERSION = '0.01';

use constant MIB	=> "kstat.zfs.";

=head2 new(\%args)

Create new Filesys::ZFS::Stat object that later can be used to retrieve
global statistics as well as per pool statistics, if any pools supplied.

=head3 Arguments

=over

=item pools

Points to list of ZFS pool names to be used.

=back

=cut

sub new {
	my ($class, %args) = @_;
	my $self = { __type => 'stat' };

	if (defined($args{pools})) {
		foreach my $pool (@{$args{pools}}) {
			my $s = BSD::Sysctl->iterator(MIB.$pool.'.dataset');
			while ($s->next) {
				next unless (( my $name = $s->name ) =~
				    s/dataset_name$//);
				(my $value = $s->value) =~ s/^${pool}\///;
				$self->{$pool}->{$value} = $name;
			}
		}
	}

	return bless $self, $class;
}

=head2 pool($name)

Create new Filesys::ZFS::Stat object associated with single pool.

=cut

sub pool {
	my ($class, $pool) = @_;
	my $self = { __type => 'pool' };

	my $s = BSD::Sysctl->iterator(MIB.$pool.'.dataset');
	while ($s->next) {
		next unless (( my $name = $s->name ) =~ s/dataset_name$//);
		(my $value = $s->value) =~ s/^${pool}\///;
		$self->{$value} = $name;
	}

	return bless $self, $class;
}

=head2 dataset($pool, $name)

Create new Filesys::ZFS::Stat object associated with single dataset.

=cut

sub dataset {
	my ($class, $pool, $dataset) = @_;
	my $self = { __type => 'dataset' };

	my $s = BSD::Sysctl->iterator(MIB.$pool.'.dataset');
	while ($s->next) {
		next unless (( my $name = $s->name ) =~
		    s/dataset_name$//);
		next unless (my $value = $s->value) =~ /^${pool}\/${dataset}/;
		$self->{mib} = $name;
	}
	return undef unless defined($self->{mib});

	return bless $self, $class;
}

sub __dataset_stat {
	my $self = $_[1];
	my $mib;

	if ($self->{__type} eq 'stat') {
		$mib = $self->{$_[2]}->{$_[3]};
	} elsif ($self->{__type} eq 'pool') {
		$mib = $self->{$_[2]};
	} elsif ($self->{__type} eq 'dataset') {
		$mib = $self->{mib};
	} else {
		die("unrecognized object type");
	}

	return sysctl($mib . $_[0]);
}

=head1 METHODS

=head2 Per-dataset I/O statistics

The following methods can be called on any Filesys::ZFS::Stat object.
For a dataset object they require no arguments.
For a pool object they require single argument - dataset name.
For a global object they require two arguments - pool name and dataset name.

=over

=item reads()

Returns number of read requests.

=item nread()

Returns bytes read.

=item writes()

Returns number of write requests.

=item nwritten()

Returns bytes written.

=item nunlinks()

Returns number of requests to unlink files.

=item nunlinked()

Returns number of files unlinked.

=back
=cut

sub reads	{ return __dataset_stat("reads", @_); }
sub nread	{ return __dataset_stat("nread", @_); }
sub writes	{ return __dataset_stat("writes", @_); }
sub nwritten	{ return __dataset_stat("nwritten", @_); }
sub nunlinks	{ return __dataset_stat("nunlinks", @_); }
sub nunlinked	{ return __dataset_stat("nunlinked", @_); }
1;

=head1 AUTHOR

Gleb Smirnoff C<< <glebius at glebi.us> >>

=head1 BUGS

Please report any bugs or feature requests via Github at
L<https://github.com/glebius/Filesys-ZFS-Stat>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Gleb Smirnoff.
This is free software, licensed under BSD License.
=cut
