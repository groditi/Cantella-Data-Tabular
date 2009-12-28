
use strict;
use warnings;

use Test::More tests => 9;
use Test::Exception;

use Moose::Meta::TypeConstraint;
use Moose::Meta::TypeCoercion;

use_ok('Cantella::Data::Tabular::Cell');

my $constraint = Moose::Meta::TypeConstraint->new(
  constraint => sub { ref($_) eq 'SCALAR' },
);
my $coercion = Moose::Meta::TypeCoercion->new(
  type_coercion_map => [ 'Str' => sub { \$_ } ],
  type_constraint => $constraint,
);
$constraint->coercion($coercion);

my $invalid_value = undef;
my $valid_value = 'String';
my $coercible_value = 'String';

lives_ok{
  Cantella::Data::Tabular::Cell->new(value => $valid_value);
} 'defined value on new';
dies_ok{
  Cantella::Data::Tabular::Cell->new(value => $invalid_value);
} 'invalid value on new';

dies_ok{
  Cantella::Data::Tabular::Cell->new(
    value => $coercible_value,
    constraint => $constraint,
  );
} 'constraint with no coerce on new';

lives_ok{
  Cantella::Data::Tabular::Cell->new(
    value => $coercible_value,
    constraint => $constraint,
    should_coerce => 1,
  );
} 'coerce on new';

###

lives_ok{
  my $cell = Cantella::Data::Tabular::Cell->new;
  $cell->set_value($valid_value)
} 'defined value on set_value';
dies_ok{
  my $cell = Cantella::Data::Tabular::Cell->new;
  $cell->set_value($invalid_value)
} 'invalid value on set_value';

dies_ok{
  my $cell = Cantella::Data::Tabular::Cell->new(
    constraint => $constraint,
  );
  $cell->set_value($coercible_value);
} 'constraint with no coerce on set_value';

lives_ok{
  my $cell = Cantella::Data::Tabular::Cell->new(
    constraint => $constraint,
    should_coerce => 1,
  );
  $cell->set_value($coercible_value)
} 'coerce on set_value';

