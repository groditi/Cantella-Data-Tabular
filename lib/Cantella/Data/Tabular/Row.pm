package Cantella::Data::Tabular::Row;

use Moose;

has _cells => (
  is => 'ro',
  isa => 'ArrayRef[Cantella::Data::Tabular::Cell]',
  required => 1,
  default => sub { [ ] },
);

sub width {
  return scalar @{ shift->_cells };
}

sub get_cell {
  my($self, $x) = @_;
  die("OUT OF BOUNDS: column ${x}") unless( $self->width > $x );
  return $self->_cells->[$x];
}

sub pad {
  my($self, $x) = @_;
  return if $x < $self->width;
  for my $i ( $self->width .. $x ){
    $self->_cells->[$i] = Cantella::Data::Tabular::Cell->new;
  }
}

sub set_cell {
  my($self, $x, $cell) = @_;
  $self->pad($x - 1) if $self->width < $x;
  return $self->_cells->[$x] = $cell;
}

sub has_value {
  my($self, $x) = @_;
  my $cell = $self->get_cell($x);
  return $cell->has_value;
}

sub get_value {
  my($self, $x) = @_;
  my $cell = $self->get_cell($x);
  return $cell->has_value ? $cell->value : undef;
}

sub set_value {
  my($self, $x, $value) = @_;
  $self->pad($x) if $self->width < $x;
  $self->get_cell($x)->set_value($value);
}

__PACKAGE__->meta->make_immutable;

1;

__END__;
