package RT::Extension::ICalTransaction::Parser;

use strict;
use warnings FATAL => 'all';
use diagnostics;

use Data::ICal::DateTime; # Use DateTime mixins
use DateTime::Span;

use subs qw(
    parse
    human_duration
    property_value
);

use Exporter 'import';
our @EXPORT_OK = qw(parse);

sub parse {
    my $data = shift;

    my @out = ();
    my $ical = Data::ICal->new(data => $data);

    if (ref($ical) eq 'Class::ReturnValue' && $ical->error_message) {
        return [], $ical->error_message;
    }

    my @events = $ical->events();

    for my $entry(@events) {
        if ($entry && ref($entry) eq 'Data::ICal::Entry::Event') {

            my $start = $entry->start();
            my $end = $entry->end();

            my $duration_seconds = '';
            my $duration_string = '';

            my $start_epoch = '';
            my $end_epoch = '';

            if (ref($start)) {
                $start_epoch = $entry->start()->epoch();
            }

            if (ref($start) && ref($end)) {
                my $duration = $end->delta_ms($start);
                $duration_seconds = $end->epoch() - $start->epoch();
                $duration_string = human_duration($duration);

                $end_epoch = $entry->end()->epoch
            }

            push(@out, {
                'url'              => $entry->url(),
                'description'      => $entry->description(),
                'summary'          => $entry->summary(),
                'start'            => $start_epoch,
                'end'              => $end_epoch,
                'duration_seconds' => $duration_seconds,
                'duration_string'  => $duration_string,
                'organizer'        => property_value($entry, 'organizer', 'CN'),
                'attendee'         => property_value($entry, 'attendee', 'CN')
            });
        }
    }

    return \@out, '';
}

sub human_duration {
    my $duration = shift;

    my @parts = ();

    for my $unit(qw(hours minutes)) {
        my $tmp = $duration->in_units($unit);
        push (@parts, $tmp . ' ' . $unit) if ($tmp);
    }

    return join(' ', @parts);
}

sub property_value {
    my $entry = shift;
    my $propertyName = shift;

    unless ($entry->property($propertyName)) {
        return '';
    }

    my @properties = @{ $entry->property($propertyName) };
    my @values;

    for my $property(@properties) {
        next unless ($property);

        my $value;
        my $parameters = $property->parameters();
        while (my $parameterName = shift( @_)){
            if (exists($parameters->{$parameterName})) {
                $value = $parameters->{$parameterName};
                last;
            }
        }

        unless ($value) {
            $value = $property->value();
        }

        $value =~ s/^MAILTO:\s*//i;

        push(@values, $value);
    }

    if (scalar(@values) eq 1) {
        return $values[0];
    }

    return \@values;
}

1;