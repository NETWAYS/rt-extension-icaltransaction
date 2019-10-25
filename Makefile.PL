use inc::Module::Install;

RTx     'RT-Extension-ICalTransaction';
license 'gpl_2';
repository 'https://github.com/netways/rt-extension-icaltransaction';

requires_rt '4.4.2';
rt_too_new '4.6.0';

requires 'Data::ICal';
requires 'Data::ICal::DateTime';
requires 'DateTime::Span';

sign;
WriteAll;
