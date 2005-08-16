package Text::Identify::BoilerPlate;

use warnings;
use strict;
use Carp;
use base qw{ Exporter };
use Hash::Merge qw{ merge };
use Digest::MD5 qw{ md5 };

our $VERSION   = '0.2';
our @EXPORT_OK = qw{ rem_boilerplate };

my %config;
my %dupl;

my $LOG_FILE;

sub rem_boilerplate {

    my ( $files, $arg_ref ) = @_;

    _get_config($arg_ref);

    my @files = @$files;

    foreach my $file (@files) {

        my @lines;
        open my $INPUT_FILE, '<', $file
            or croak "Can't open $file";
        while ( my $line = <$INPUT_FILE> ) {

            $line =~ s/^\s*//g;
            $line =~ s/\s*$//g;
            $line =~ s/\t/ /g;
            $line =~ s/ +/ /g;
            $line =~ s/\r//g;

            my $line_tmp = $line;
            if ( $config{'ignore_digits'} ) {
                $line_tmp =~ s/\d+/_D_/g;
            }
            if ( $config{'digest'} ) {
                $line_tmp = md5($line_tmp);
            }

            $dupl{$line_tmp}++;
            push @lines, $line;

        }
        $file = [ $file, \@lines ];    # name + content
    }

    # find duplicated lines
    foreach my $file (@files) {

        if ( $config{'log'} ) {
            print {$LOG_FILE} "\n-- $file->[0] --\n";
        }

        my $lines = $file->[1];
        my @lines = @$lines;

        if ( $config{'only_headers_and_footers'} ) {
            @lines = _rem_first_duplicates(@lines);
            @lines = reverse @lines;
            @lines = _rem_first_duplicates(@lines);
            @lines = reverse @lines;
        }
        else {
            @lines = _rem_duplicates(@lines);
        }

        my $filename     = $file->[0];
        my $new_filename = $filename . "." . $config{'suffix'};
        open my $OUTPUT_FILE, '>', $new_filename
            or croak "Can't open $new_filename";
        print {$OUTPUT_FILE} join( "\n", @lines );

    }

}

sub _rem_first_duplicates {

    my @input = @_;

CUT:
    foreach my $line (@input) {

        my $line_tmp = $line;
        if ( $config{'ignore_digits'} ) {
            $line_tmp =~ s/\d+/_D_/g;
        }

        if ( $config{'digest'} ) {
            $line_tmp = md5($line_tmp);
        }

        if ( $line_tmp eq '' ) {
            next CUT;
        }
        elsif ( $dupl{$line_tmp} > $config{'min_dupl'} ) {
            my $cut_line = shift @input;
            if ( $config{'log'} ) {
                print {$LOG_FILE} $cut_line, "\n";
            }
        }
        else {
            last CUT;
        }

    }

    return @input;

}

sub _rem_duplicates {

    my @input = @_;

    my $i = 0;
CUT:
    foreach my $line (@input) {

        my $line_tmp = $line;
        if ( $config{'ignore_digits'} ) {
            $line_tmp =~ s/\d+/_D_/g;
        }

        if ( $config{'digest'} ) {
            $line_tmp = md5($line_tmp);
        }

        if ( $line_tmp eq '' ) {
            $i++;
            next CUT;
        }
        elsif ( $dupl{$line_tmp} > $config{'min_dupl'} ) {

            my $cut_line = splice( @input, $i, 1 );
            if ( $config{'log'} ) {
                print {$LOG_FILE} $cut_line, "\n";
            }

        }

        $i++;

    }

    return @input;

}

sub _get_config {

    my %config_default = (
        min_dupl                 => 3,
        suffix                   => 'content',
        ignore_digits            => 1,
        only_headers_and_footers => 1,
        digest                   => 0,
        log                      => 'text-identify-boilerplate.log'
    );

    my $arg_ref    = $_[0];
    my %config_arg = %$arg_ref;

    Hash::Merge::set_behavior('RIGHT_PRECEDENT');
    %config = %{ merge( \%config_default, \%config_arg ) };

    if ( $config{'log'} ) {
        open $LOG_FILE, '>', $config{'log'}
            or croak "Can't open $config{'log'}";
    }

    return;

}

1;    # End of Text::Identify::BoilerPlate

__END__

=head1 NAME

Text::Identify::BoilerPlate - Remove repeated text

=head1 VERSION

Version 0.2


=head1 SYNOPSIS

Finds boilerplate text (lines that are repeated across documents) in a 
list of plain text files. 

    use Text::Identify::BoilerPlate;

    my @files = ('file1', 'file2', 'file3');
    rem_boilerplate(\@files, { min_dupl => 4, ignore_digits => 0 });

New files are written, containing everything but the boilerplate text.

=head1 FUNCTIONS

=head2 rem_boilerplate()

C<rem_boilerplate()> takes two arguments: A reference to a list of files
to be processed, and a reference to a hash of options.

The options are:

=over

=item C<min_dupl> - the minimum number of thimes a line has to occur to
be considered boilerplate (default: 3)

=item C<ignore_digits> - lines only seperated by differences in digits
will be considered duplicates (default: yes)

=item C<suffix> - added to the new files (default: 'content')

=item C<only_headers_and_footers> - Only sets consecutive lines of 
duplicates at the start and end of documents are considered 
boilerplate (default: yes)

=item C<digest> - lines will be replaced by a MD5 digest during duplicate
compilation, saving memory (default: no)

=item C<log> - name of the log file, where deleted lines are recorded; 
if set to false, no log will be created (default: 
'./text-identify-boilerplate.log')

=back



=head1 AUTHOR

Lars Nygaard, C<< <lars.nygaard@inl.uio.no> >>

=head1 BUGS

The program needs extensive testing and tweaking
before the simple algorithm can give consistently high-quality results.

Please report any bugs or feature requests to
C<bug-text-identify-boilerplate@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Identify-BoilerPlate>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Lars Nygaard, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

