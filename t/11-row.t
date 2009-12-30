
use strict;
use warnings;

use Test::More tests => 11;
use Test::Exception;
use Scalar::Util 'refaddr';
use Cantella::Data::Tabular::Cell;

BEGIN{ use_ok('Cantella::Data::Tabular::Row') }

my $row = Cantella::Data::Tabular::Row->new;

is($row->width, 0, 'initial zero width');

dies_ok { $row->get_cell(0) } 'Out of bounds error triggered';
dies_ok { $row->get_value(0) } 'Out of bounds error triggered';

$row->pad(3);
is($row->width, 4, 'pad works');

ok(!$row->has_value(3), 'no value');
$row->set_value(3, 'abc');
ok($row->has_value(3), 'yes value');

{
  my $cell = $row->get_cell(2);
  $row->set_value(2, 'xyz');
  is(refaddr($row->get_cell(2)), refaddr($cell), 'same cell');
}
{
  my $new_cell = Cantella::Data::Tabular::Cell->new(value => 'def');
  $row->set_cell(3, $new_cell);
  is(refaddr($row->get_cell(3)), refaddr($new_cell), 'cell replaced');
}

lives_ok {
  $row->set_value(6, 'xyz');
  is($row->width, 7, 'set_value pads correctly');
} 'set_value pads';
