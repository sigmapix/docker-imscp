=head1 NAME

 iMSCP::Dir - Library allowing to perform common operation on directories

=cut

# i-MSCP - internet Multi Server Control Panel
# Copyright (C) 2010-2017 by Laurent Declercq <l.declercq@nuxwin.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

package iMSCP::Dir;

use strict;
use warnings;
use File::Copy qw/ mv /;
use File::Path qw/ mkpath remove_tree /;
use File::Spec;
use iMSCP::Debug qw / getLastError /;
use iMSCP::File;
use parent 'Common::Object';

=head1 DESCRIPTION

 Library allowing to perform common operation on directories

=head1 PUBLIC METHODS

=over 4

=item getFiles( [ $dirname ] )

 Get list of files inside directory

 Param string $dirname OPTIONAL Directory - Default $self->{'dirname'}
 Return array representing list files or die on failure

=cut

sub getFiles
{
    my ($self, $dirname) = @_;
    $dirname //= $self->{'dirname'};

    defined $dirname or die( '$dirname parameter is not defined.' );

    opendir my $dh, $dirname or die( sprintf( "Could not open `%s' directory: %s", $dirname, $! ) );
    my @files = grep { !/^\.{1,2}\z/s && -f "$dirname/$_" } readdir( $dh ) ;
    @files = $self->{'fileType'} ? grep(/$self->{'fileType'}$/, @files) : @files;
    closedir( $dh );
    @files;
}

=item getDirs( [ $dirname ] )

 Get list of directories inside directory

 Param string $dirname OPTIONAL Directory - Default $self->{'dirname'}
 Return array representing list of directories or die on failure

=cut

sub getDirs
{
    my ($self, $dirname) = @_;
    $dirname //= $self->{'dirname'};

    defined $dirname or die( '$dirname parameter is not defined.' );

    opendir my $dh, $dirname or die( sprintf( "Could not open `%s' directory: %s", $dirname, $! ) );
    my @dirs = grep { !/^\.{1,2}\z/s && -d "$dirname/$_" } readdir( $dh );
    closedir( $dh );
    @dirs;
}

=item getAll( [ $dirname ] )

 Get list of files and directories inside directory

 Param string $dirname OPTIONAL Directory - Default $self->{'dirname'}
 Return list of files and directories or die on failure

=cut

sub getAll
{
    my ($self, $dirname) = @_;
    $dirname //= $self->{'dirname'};

    defined $dirname or die( '$dirname parameter is not defined.' );

    opendir my $dh, $dirname or die( sprintf( "Could not open `%s' directory: %s", $dirname, $! ) );
    my @files = grep( !/^\.{1,2}\z/s, readdir( $dh ) );
    closedir( $dh );
    @files;
}

=item isEmpty( [ $dirname ] )

 Is directory empty?

 Param string $dirname OPTIONAL Directory - Default $self->{'dirname'}
 Return bool TRUE if the given directory is empty, FALSE otherwise - die on failure

=cut

sub isEmpty
{
    my ($self, $dirname) = @_;
    $dirname //= $self->{'dirname'};

    defined $dirname or die( '$dirname parameter is not defined.' );

    opendir my $dh, $dirname or die( sprintf( "Could not open `%s' directory: %s", $dirname, $! ) );
    while(my $entry = readdir $dh) {
        next if $entry =~ /^\.{1,2}\z/s;
        closedir $dh;
        return 0;
    }
    closedir $dh;

    1;
}

=item mode( $mode [, $dirname ] )

 Set directory mode

 Param string $mode Directory mode
 Param string $dirname OPTIONAL Directory (default $self->{'dirname'})
 Return int 0 on success or die on failure

=cut

sub mode
{
    my ($self, $mode, $dirname) = @_;
    $dirname //= $self->{'dirname'};

    defined $mode or die( '$mode parameter is not defined.' );
    defined $dirname or die( '$dirname parameter is not defined.' );
    chmod $mode, $dirname or die(sprintf( "Could not change `%s' directory permissions: %s", $dirname, $! ));
    0;
}

=item owner( $owner, $group, [, $dirname ] )

 Set directory owner and group

 Param string $owner Owner
 Param string $group Group
 Param string $dirname OPTIONAL Directory (default $self->{'dirname'})
 Return int 0 on success, die on failure

=cut

sub owner
{
    my ($self, $owner, $group, $dirname) = @_;
    $dirname //= $self->{'dirname'};

    defined $owner or die( '$owner parameter is not defined.' );
    defined $group or die( '$group parameter is not defined.' );
    defined $dirname or die( '$dirname parameter is not defined.' );

    my $uid = $owner =~ /^\d+$/ ? $owner : getpwnam( $owner ) // - 1;
    my $gid = $group =~ /^\d+$/ ? $group : getgrnam( $group ) // - 1;

    chown $uid, $gid, $dirname or die( sprintf( "Could not change `%s' directory ownership: %s", $dirname, $! ) );
    0;
}

=item make( [ \%options ] )

 Create a directory

 Param hash \%options OPTIONAL Options:
    mode:  Directory mode
    user:  Directory owner
    group: Directory group
 Return int 0 on success, die on failure

=cut

sub make
{
    my ($self, $options) = @_;

    defined $self->{'dirname'} or die( '`dirname` attribute is not defined.' );
    $options = { } unless $options && ref $options eq 'HASH';

    unless (-d $self->{'dirname'}) {
        my @createdDirs = mkpath( $self->{'dirname'}, { error => \ my $errStack } );

        if (@{$errStack}) {
            my $errorStr = '';

            for my $diag (@{$errStack}) {
                my ($file, $message) = %{$diag};
                $errorStr .= ($file eq '') ? "general error: $message\n" : "problem unlinking $file: $message\n";
            }

            die( sprintf( "Could not create `%s' directory: %s", $self->{'dirname'}, $errorStr ) );
        }

        for my $dir(@createdDirs) {
            if (defined $options->{'user'} || defined $options->{'group'}) {
                $self->owner( $options->{'user'} // - 1, $options->{'group'} // - 1, $dir );
            }

            $self->mode( $options->{'mode'}, $dir ) if defined $options->{'mode'};
        }

        return 0;
    }

    return 0 unless $options->{'fixpermissions'};

    if (defined $options->{'user'} || defined $options->{'group'}) {
        $self->owner( $options->{'user'} // - 1, $options->{'group'} // - 1, $self->{'dirname'} );
    }

    $self->mode( $options->{'mode'} ) if defined $options->{'mode'};

    0;
}

=item remove( [ $dirname ] )

 Remove a directory recusively

 Param string $dirname OPTIONAL Directory (default $self->{'dirname'})
 Return int 0 on success, die on failure

=cut

sub remove
{
    my ($self, $dirname) = @_;
    $dirname //= $self->{'dirname'};

    defined $dirname or die( '$dirname parameter is not defined.' );

    return 0 unless -d $dirname;

    remove_tree( $dirname, { error => \ my $errStack } );

    if (@{$errStack}) {
        my $errorStr = '';
        for my $diag (@{$errStack}) {
            my ($file, $message) = %{$diag};
            $errorStr .= ($file eq '') ? "general error: $message\n" : "problem unlinking $file: $message\n";
        }

        die( sprintf( "Could not remove `%s' directory: %s", $dirname, $errorStr ) );
    }

    0;
}

=item rcopy( $destDir [, \%options ] )

 Copy a directory recusively

 Param string $destDir Destination directory
 Param hash \%options OPTIONAL Options:
   preserve: If true, preserve permissions and ownership
 Return int 0 on success, die on failure

=cut

sub rcopy
{
    my ($self, $destDir, $options) = @_;

    $options = { } unless $options && ref $options eq 'HASH';

    defined $destDir or die( '$destDir parameter is not defined' );
    defined $self->{'dirname'} or die( '`dirname` attribute is not defined' );

    unless (-d $destDir) {
        my $opts = { };
        if ($options->{'preserve'}) {
            @{$opts}{ qw / mode user group /} = (stat( $self->{'dirname'} ))[2, 4, 5];
            $opts->{'mode'} &= 07777;
        }

        iMSCP::Dir->new( dirname => $destDir )->make( $opts );
    }

    opendir my $dh, $self->{'dirname'} or die( sprintf( "Could not open `%s' directory: %s", $self->{'dirname'}, $! ) );

    while(my $entry = readdir $dh) {
        next if $entry =~ /^\.{1,2}\z/s;

        my $src = File::Spec->catfile( $self->{'dirname'}, $entry);
        my $dst = File::Spec->catfile( $destDir, $entry );

        if (-d $src) {
            iMSCP::Dir->new( dirname => $src )->rcopy( $dst, $options );
            next;
        }

        iMSCP::File->new( filename => $src )->copyFile( $dst, $options ) == 0 or die(
            sprintf( "Could not copy `%s' file to `%s': %s", $src, $dst, getLastError() )
        );
    }

    closedir $dh;
    0;
}

=item moveDir( $destDir )

 Move directory

 Param string $destDir Destination directory
 Return int 0 on success, die on failure

=cut

sub moveDir
{
    my ($self, $destDir) = @_;

    defined $destDir or die( '$destDir attribute is not defined.' );
    defined $self->{'dirname'} or die( '`dirname` attribute is not defined.' );

    -d $self->{'dirname'} or die( sprintf( "Directory %s doesn't exits", $self->{'dirname'} ) );
    mv( $self->{'dirname'}, $destDir) or die(
        sprintf( "Could not move `%s' directory to `%s': %s", $self->{'dirname'}, $destDir, $! )
    );
    0;
}

=back

=head1 PRIVATE METHODS

=over 4

=item _init()

 Initialize iMSCP::Dir object

 iMSCP::Dir

=cut

sub _init
{
    my $self = shift;

    $self->{'dirname'} //= undef;
    $self;
}

=back

=head1 AUTHOR

Laurent Declercq <l.declercq@nuxwin.com>

=cut

1;
__END__
