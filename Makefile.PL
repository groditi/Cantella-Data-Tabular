use inc::Module::Install;

name 'Cantella-Data-Tabular';
all_from 'lib/Cantella/Data/Tabular.pm';

#store
requires 'Moose';
requires 'MooseX::Types';
requires 'namespace::clean';
requires 'Spreadsheet::WriteExcel';

#tests
test_requires 'Test::More';

WriteAll;
