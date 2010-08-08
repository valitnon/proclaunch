package App::ProcLaunch::Profile;

use strict;
use warnings;

use POSIX qw/ :sys_wait_h /;

use App::ProcLaunch::Util qw/
    read_file
    read_pid_file
    still_running
    cleanup_dead_pid_file
    diff_stats
    stat_hash
/;

use App::ProcLaunch::Log qw/
    log_info
    log_warn
    log_debug
    log_fatal
/;

use Class::Struct
    directory => '$',
    dir_stat  => '$',
    _pid_file => '$',
;

use constant SECONDS_TO_WAIT_FOR_CHILD_STOP => 7;

sub run {
    my $self = shift;
    return unless cleanup_dead_pid_file($self->pid_file());
    log_info "Starting profile " . $self->directory();

    defined(my $pid = fork()) or log_fatal "Could not fork: $!";

    if ($pid == 0) {
        $self->drop_privs();
        chdir $self->directory();
        exec("./run");
    } else {
        waitpid($pid, 0);
    }
}

sub drop_privs
{
    # TODO
}

sub pid_file_exists {
    my $self = shift;
    return -e $self->pid_file();
}

sub current_pid {
    my $self = shift;
    return read_pid_file($self->pid_file());
}

sub is_running {
    my $self = shift;
    return still_running($self->pid_file());
}

sub should_restart {
    my $self = shift;
    return -e $self->profile_file('restart');
}

sub profile_file {
    my ($self, $filename) = @_;
    return join("/", $self->directory(), $filename);
}

sub pid_file {
    my $self = shift;
    unless ($self->_pid_file()) {
        my $profile_pid_file = $self->profile_file('pid_file');
        log_fatal "No file named pid_file for profile " . $self->directory() unless -e $profile_pid_file;
        my $pid_file = read_file($profile_pid_file);
        $pid_file =~ s/\s*$//;
        $self->_pid_file($pid_file);
    }
    return $self->_pid_file();
}

sub send_signal
{
    my ($self, $signal) = @_;
    log_debug "Sending $signal to " . $self->current_pid();
    kill $signal, $self->current_pid();
}

sub stop
{
    my ($self) = @_;
    unless ($self->is_running()) {
        log_warn $self->directory() . " is not running! Thought pid was: " . $self->current_pid();
        return;
    }

    my $restart_time = time();
    my $wait_until = $restart_time + SECONDS_TO_WAIT_FOR_CHILD_STOP;

    log_info "Stopping " . $self->directory();
    $self->send_signal(15);
    log_debug "Waiting for pid " . $self->current_pid() . " to stop";

    while(time() <= $wait_until) {
        return unless $self->is_running();
        sleep 1;
    }

    log_warn $self->directory() . " did not respond to TERM. Sending KILL.";
    $self->send_signal(9);
}

sub has_changed
{
    my $self = shift;
    my $stat = stat_hash($self->directory());

    return diff_stats($stat, $self->dir_stat());
}

1;
