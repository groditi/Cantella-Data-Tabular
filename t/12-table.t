
use strict;
use warnings;

use Test::More tests => 15;
use Test::Exception;

use Scalar::Util 'refaddr';
use Cantella::Data::Tabular::Cell;
use Cantella::Data::Tabular::Row;

BEGIN{ use_ok('Cantella::Data::Tabular::Table') }

{
  my $table = Cantella::Data::Tabular::Table->new;

  is($table->width, 0, 'initial zero width');
  is($table->height, 0, 'initial zero height');
  is($table->row_count, 0, 'initial zero row count');

  dies_ok { $table->get_row(0) } 'Out of bounds error triggered';

  $table->pad(3);
  is($table->row_count, 4, 'pad works');
  is($table->height, 4, 'height is correct');

  dies_ok { $table->get_header_row } 'No header error triggered';
  $table->set_header_value(2, 'foo');
  ok($table->has_header_value(2), 'has header value value');
  is($table->get_header_value(2), 'foo', 'correct header value value');
  is($table->height, 5, 'height is correct');
}

{
  my $table = Cantella::Data::Tabular::Table->new;
  lives_ok {
    $table->pad(3,3);
    is($table->row_count, 4, 'row pad');
    $table->get_row($_)->get_cell(3) for( 0 .. 3);
  } 'pad(y,x) works too';
  {
    my $cell = $table->get_cell(2,2);
    $table->set_value(2,2, 'xyz');
    is(refaddr($table->get_cell(2,2)), refaddr($cell), 'same cell');
  }
  {
    my $cell = Cantella::Data::Tabular::Cell->new(value => 'def');
    $table->set_cell(3,3, $cell);
    is(refaddr($table->get_cell(3,3)), refaddr($cell), 'cell replaced');
  }
}
