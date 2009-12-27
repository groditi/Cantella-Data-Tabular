package Cantella::Data::Tabular::Cell;

use Moose;

has value => (
  isa => 'Defined',
  reader => 'get_value',
  writer => '_set_raw_value',
  clearer => 'clear_value',
  predicate => 'has_value',
);

has constraint => (
  is => 'ro',
  isa => 'Moose::Meta::TypeConstraint',
  predicate => 'has_constraint',
);

has should_coerce => (
  is => 'rw',
  isa => 'Bool',
);


# I could have set the writer using:
#  writer => { set_value => sub { ... } },
# and I may, still, but I'm wondering whether it's too DWIMy or just right
sub set_value {
  my ($self, $value) = @_;
  if( $self->has_constraint ){
    my $type_constraint = $self->constraint;
    if ($self->should_coerce && $type_constraint->has_coercion) {
      $value = $type_constraint->coerce($value);
    }
    $type_constraint->check($value) ||
      die( "Type constraint check failed: ".$type_constraint->get_message($value) );
  }

  $self->_set_raw_value($value);
}

__PACKAGE__->meta->make_immutable;

__END__;

# We need some kind of metadata slot so we can store information about the cell,
# not the value. Like formatting information / etc so we can eventually roundtrip
# spreadsheets via WriteExcel and ReadExcel. The slots should have no meaning at the
# this level, but should be meaningful only to higher-level layers, at least for now.
# The trick here is to allow for the use-cases of specific modules without letting the
# details of their interfaces or implementations leak in to ours.

use Moosex::AttributeHelpers;

has properties => (
  metaclass => 'Collection::Hash',
  is => 'ro',
  isa => 'HashRef[Defined]',
  default => sub { {} },
  provides => {
    set => 'set_property',
    get => 'get_property',
    exists => 'has_property',
    delete => 'clear_property',

    empty => 'has_properties',
    clear => 'clear_properties',
  }
);
