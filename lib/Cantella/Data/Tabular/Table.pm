package Cantella::Data::Tabular::Table;

use Moose;
use List::Util ();
use Cantella::Data::Tabular::Row;

has header_row => (
  isa => 'Cantella::Data::Tabular::Row',
  reader => 'get_header_row',
  writer => 'set_header_row',
  predicate => 'has_header_row',
);

has rows => (
  is => 'ro',
  isa => 'ArrayRef[Cantella::Data::Tabular::Row]',
  required => 1,
  default => sub { [] },
);

sub height {
  my $self = shift;
  return ($self->has_header_row ? 1 : 0) + $self->row_count;
}

sub width {
  my $self = shift;
  return List::Util::max( 0, map { $_->width } @{ $self->rows } );
}

sub row_count {
  return scalar @{ shift->rows };
}

sub pad {
  my($self, $y, $x) = @_;
  return if $y < $self->row_count;
  for my $i ( $self->row_count .. $y ){
    $self->rows->[$i] = Cantella::Data::Tabular::Row->new;
  }
  return unless defined $x;
  map{ $_->pad($x) } @{ $self->rows };
}

sub get_row {
  my($self, $y) = @_;
  die("OUT OF RANGE: row ${y}") unless $self->row_count > $y;
  return $self->rows->[ $y ];
}

sub get_cell {
  my($self, $y, $x) = @_;
  return $self->get_row($y)->get_cell($x);
}

sub set_cell {
  my($self, $y, $x, $cell) = @_;
  $self->pad($y) unless $self->row_count > $y;
  return $self->get_row($y)->set_cell($x, $cell);
}

sub has_value {
  my($self, $y, $x) = @_;
  $self->get_row($y)->has_value($x);
}

sub get_value {
  my($self, $y, $x) = @_;
  $self->get_row($y)->get_value($x);
}

sub set_value {
  my($self, $y, $x, $value) = @_;
  $self->pad($y) unless $self->row_count > $y;
  return $self->get_row($y)->set_value($x, $value);
}

##Should header cells be forced to have 'Str' as a constraint?

around get_header_row => sub {
  my $orig = shift;
  my $self = shift;
  die('OUT OF RANGE: No header row') unless $self->has_header_row;
  return $self->$orig(@_);
};

sub _build_header_row {
  return Cantella::Data::Tabular::Row->new;
}

sub get_header_cell {
  my($self, $x) = @_;
  return $self->get_header_row->get_cell($x);
}

sub set_header_cell {
  my($self, $x, $cell) = @_;
  $self->set_header_row( $self->_build_header_row ) if ! $self->has_header_row;
  return $self->get_header_row->set_cell($x, $cell);
}

sub has_header_value {
  my($self, $x) = @_;
  $self->get_header_cell($x)->has_value($x);
}

sub get_header_value {
  my($self, $x) = @_;
  $self->get_header_row->get_value($x);
}

sub set_header_value {
  my($self, $x, $value) = @_;
  $self->set_header_row( $self->_build_header_row ) if ! $self->has_header_row;
  return $self->get_header_row->set_value($x, $value);
}

__PACKAGE__->meta->make_immutable;

1;

__END__;

=head1 NAME

Cantella::Data::Tabular::Table - Table object

=head1 SYNOPSYS

=head1 ATTRIBUTES

=head2 rows

A read-only attribute composed of an ArrayRef of zero or more
L<Row|Cantella::Data::Tabular::Row> objects. This is a private attribute
and should not be accessed directly.

The following methods are associated with this attribute:

=over 4

=item B<rows> - reader

=back

=head2 header_row

An optional read-write attribute which may contain a
L<Row|Cantella::Data::Tabular::Row> object. The cells here will be treated
as the table header. You do not have to use C<set_header_row> to set this
attribute, it cab be accessed through the methods outlined in
L<HEADER-RELATED METHODS>.

The following methods are associated with this attribute:

=over 4

=item B<get_header_row> - reader

=item B<set_header_row> - writer

=item B<has_header_row> - predicate

=back

=head1 METHODS

=head2 new

=over 4

=item B<arguments:> C<\%arguments>

=item B<return value:> C<$object_instance>

=back

Constructor.

=head2 width

=over 4

=item B<arguments:> none;

=item B<return value:> C<$with_of_widest_row>

=back

=head2 height

Similar to L</row_count>, this method will return the number of rows in the
table including the header row, i applicable.

=over 4

=item B<arguments:> none;

=item B<return value:> C<$table_height>

=back

=head2 row_count

Similar to L</height>, this method will return the number of rows in the
table not including the header row.

=over 4

=item B<arguments:> none;

=item B<return value:> C<$table_row_count>

=back

=head2 pad

=over 4

=item B<arguments:> C<$max_y_index>, C<$max_x_index>

=item B<return value:> none;

=back

Creates rows up to an including C<$max_y_index> if they don't already exist.
If the optional C<$max_x_index> argument is given, it will call each row's
L<pad|Cantella::Data::Tabular::Row/pad> method. Index numbers start at zero.

=head2 get_row

=over 4

=item B<arguments:> C<$y_index>

=item B<return value:> C<$cell>

=back

Get the row located at the position given. If the row does not exist an
exception will be thrown.

=head1 CELL-RELATED METHODS

=head2 get_cell

=over 4

=item B<arguments:> C<$y_index>, C<$x_index>

=item B<return value:> C<$cell>

=back

Get the cell located at the position given. If the cell does not exist an
exception will be thrown.

=head2 set_cell

=over 4

=item B<arguments:> C<$y_index>, C<$x_index>, <$cell>

=item B<return value:>

=back

Set the cell located at the position given. If the location does not exist,
L</pad> will be used to fill in any resulting gap.

=head2 has_value

=over 4

=item B<arguments:> C<$y_index>, C<$x_index>

=item B<return value:> boolean C<$value_exists>

=back

Predicate for whether the cell at the position given has a value. If the cell
does not exist, an exception will be thrown.

=head2 get_value

=over 4

=item B<arguments:> C<$y_index>, C<$x_index>

=item B<return value:> $value

=back

Get the value of the cell at the position given. If the cell does not
exist, an exception will be thrown.

=head2 set_value

=over 4

=item B<arguments:> C<$y_index>, C<$x_index>, <$value>

=item B<return value:>

=back

Set the value of the cell located at the position given. If the location does
not exist, L</pad> will be used to fill in any resulting gap.
=head2 get_cell

=head1 HEADER-RELATED METHODS

These methods are simply proxies for the row methods in the header row. The
only difference being that L</set_header_value> and L</set_header_cell> will

=head2 get_header_cell

=over 4

=item B<arguments:> C<$x_index>

=item B<return value:> C<$cell>

=back

Get the cell located at the position given in the L</header_row>. If the cell
does not exist an exception will be thrown.

=head2 set_header_cell

=over 4

=item B<arguments:> C<$x_index>, <$cell>

=item B<return value:>

=back

Set the cell located at the position given. If the location does not exist,
L</pad> will be used to fill in any resulting gap.

=head2 has_header_value

=over 4

=item B<arguments:> C<$x_index>

=item B<return value:> boolean C<$value_exists>

=back

Predicate for whether the cell at the position given has a value. If the cell
does not exist, an exception will be thrown.

=head2 get_header_value

=over 4

=item B<arguments:> C<$x_index>

=item B<return value:> $value

=back

Get the value of the cell at the position given. If the cell does not
exist, an exception will be thrown.

=head2 set_header_value

=over 4

=item B<arguments:> C<$x_index>, <$value>

=item B<return value:>

=back

Set the value of the cell located at the position given. If the location does
not exist, L</pad> will be used to fill in any resulting gap.

=head1 AUTHOR

Guillermo Roditi (groditi) E<lt>groditi@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Guillermo Roditi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

# I'm not sure this belongs in this layer, but I'd like to have this somewhere.
# This is most likely a part of a renderer. The idea being that you can size columns
# to a set width, for which to need to find out the widest item in each column.

#sample ...

sub col_width {
  my ($self, $x);
  my $find_width = sub { return length(shift) };

  my @widths;
  for my $row ( ($self->has_header_row ? $self->header_row : () ), @{ $self->_rows } ){
    next unless $row->width > $x;
    next unless $row->has_value($x);
    push(@widths, $find_width->($row->get_value($x)));
  }

  return List::Util::max(@widths);
}



