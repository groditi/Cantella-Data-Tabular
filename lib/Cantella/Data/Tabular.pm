package Cantella::Data::Tabular;

use Moose;
use List::Util ();

has _header_row => (
  is => 'ro',
  isa => 'Cantella::Data::Tabular::Row',
  lazy => 1,
  default => sub { Cantella::Data::Tabular::Row->new },  
  predicate => 'has_header_row',
);

has _rows => (
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
  return List::Util::max( map { $_->width } @{ $self->_rows } );
}

sub row_count {
  return scalar @{ shift->_rows };
}

sub pad {
  my($self, $y, $x) = @_;
  return if $y < $self->row_count;
  for my $i ( $self->row_count .. $y ){
    $self->_rows->[$i] = Cantella::Data::Tabular::Row->new;
  }
  return unless defined $x;
  map{ $_->pad($x) } @{ $self->rows };
}


sub get_row {
  my($self, $y) = @_;
  die("OUT OF RANGE: row ${y}") unless $self->row_count < $y;
  return $self->_rows->[ $y ];
}

sub get_cell {
  my($self, $y, $x) = @_;
  return $self->get_row($y)->get_cell($x);
}

sub set_cell {
  my($self, $y, $x, $cell) = @_;
  $self->pad($y) if $self->row_count < $y;
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
  $self->pad($y) if $self->row_count < $y;
  return $self->get_row($y)->set_value($x, $value);
}

__PACKAGE__->meta->make_immutable;

1;

__END__;

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

