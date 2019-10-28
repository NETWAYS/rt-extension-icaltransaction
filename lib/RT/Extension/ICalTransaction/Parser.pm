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

            my $end = $entry->end();
            my $start = $entry->start();
            my $duration = $end->delta_ms($start);

            push(@out, {
                'url'              => $entry->url(),
                'description'      => $entry->description(),
                'summary'          => $entry->summary(),
                'start'            => $entry->start()->epoch(),
                'end'              => $entry->end()->epoch,
                'duration_seconds' => $end->epoch() - $start->epoch(),
                'duration_string'  => human_duration($duration),
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