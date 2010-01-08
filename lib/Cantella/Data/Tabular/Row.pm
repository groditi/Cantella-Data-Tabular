package Cantella::Data::Tabular::Row;

use Moose;

has cells => (
  is => 'ro',
  isa => 'ArrayRef[Cantella::Data::Tabular::Cell]',
  required => 1,
  default => sub { [ ] },
);

sub width {
  return scalar @{ shift->cells };
}

sub pad {
  my($self, $x) = @_;
  return if $x < $self->width;
  for my $i ( $self->width .. $x ){
    $self->cells->[$i] = Cantella::Data::Tabular::Cell->new;
  }
}

sub get_cell {
  my($self, $x) = @_;
  die("OUT OF BOUNDS: column ${x}") unless $self->width > $x;
  return $self->cells->[$x];
}

sub set_cell {
  my($self, $x, $cell) = @_;
  $self->pad($x - 1) if $self->width < $x;
  return $self->cells->[$x] = $cell;
}

#Maybe I should make has act like something between get and set and not throw
#an out of range exception, but not auto-vivify the cell either.

sub has_value {
  my($self, $x) = @_;
  my $cell = $self->get_cell($x);
  return $cell->has_value;
}

sub get_value {
  my($self, $x) = @_;
  my $cell = $self->get_cell($x);
  return $cell->has_value ? $cell->get_value : undef;
}

sub set_value {
  my($self, $x, $value) = @_;
  $self->pad($x) if $self->width < $x;
  $self->get_cell($x)->set_value($value);
}

__PACKAGE__->meta->make_immutable;

1;

__END__;

=head1 NAME

Cantella::Data::Tabular::Row - Row object

=head1 SYNOPSIS

    my $row = Cantella::Data::tabular::Row->new;
    my $x = 0;
    $row->set_value($x++, $_) for (qw/foo bar baz/);

    for my $index ( 0 .. ($row->width - 1)){
      if( $row->has_value($index)){
        my $value = $row->get_value($index);
        ...
      } else {
        #cell has no value
        ...
      }
    }

=head1 ATTRIBUTES

=head2 cells

A read-only attribute composed of an ArrayRef of zero or more
L<Cell|Cantella::Data::Tabular::Cell> objects. This is a private attribute
and should not be accessed directly.

The following methods are associated with this attribute:

=over 4

=item B<cells> - reader

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

=item B<return value:> C<$number_of_cells_in_row>

=back

=head2 pad

=over 4

=item B<arguments:> C<$max_index>

=item B<return value:> none;

=back

Creates cells for every column in the row up to and including C<$max_index>.
Index numbers start at zero.

=head2 get_cell

=over 4

=item B<arguments:> C<$index>

=item B<return value:> C<$cell>

=back

Get the cell located at C<$index>. If the cell does not exist an exception
will be thrown.

=head2 set_cell 

=over 4

=item B<arguments:> C<$index>, <$cell>

=item B<return value:>

=back

Set the cell located at C<$index>. If C<$index> is greater than the C</width>
of the row, C</pad> will be used to fill in any resulting gap.

=head2 has_value

=over 4

=item B<arguments:> <$index>

=item B<return value:> boolean C<$value_exists>

=back

Predicate for whether the cell at C<$index> has a value. If the cell does not
exist, an exception will be thrown.

=head2 get_value

=over 4

=item B<arguments:> C<$index>

=item B<return value:> $value

=back

Get the value of the cell at the given C<$index>. If the cell does not
exist, an exception will be thrown.

=head2 set_value

=over 4

=item B<arguments:> C<$index>, <$value>

=item B<return value:>

=back

Set the value of the cell located at C<$index>. If C<$index> is greater than
the C</width> of the row, C</pad> will be used to fill in any resulting gap.

=head1 AUTHOR

Guillermo Roditi (groditi) E<lt>groditi@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Guillermo Roditi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
