#
# (C) Copyright 2011 Sveinbjorn Thordarson
# GNU GPL License

package SQLiteLogger;
use strict;
use DBI;
use Encode;
use DBD::SQLite;
use Encode;
use utf8;

## Our variables ##
my $VERSION = "1.0";
my $mindelay = 5;
my $db_path = "log.db";

sub new
{
    my ($class) = @_;
    my $self = {};
    bless $self, $class;
    
    # Make sure we connection to db
    $self->Initialize() or return 0;
    
    return $self;
}

sub Initialize
{
    $db_path = "$ENV{BASEDIR}$db_path";
    my ($self) = @_;
    my $exists = -e $db_path;
    my $writable = -w $db_path;
    if ($exists and !$writable) { return 0; }
    $self->{dbh} = DBI->connect("dbi:SQLite:dbname=$db_path", "", "", { sqlite_unicode => 1, RaiseError => 1, AutoCommit => 1 });
    if (!$exists)
    {
        warn "Creating SQLite database '$db_path'\n";
        $self->CreateSQLiteDatabase();
    }
    warn("Connected to SQLite database '$db_path'\n");
    return 1;
}

sub DBRef 
{ 
    my $self = shift; 
    return $self->{dbh}; 
}

sub Log
{
    my $self = shift;
    my (@args) = @_; # (status, err, date, ip, json)
    foreach (@args) { $_ = $self->{dbh}->quote($_); }
    
    my $statement = <<"EOF";
    INSERT INTO entries VALUES (NULL, $args[0], $args[1], $args[2], $args[3], $args[4]);
EOF
    $self->{dbh}->do($statement);
}

sub CreateSQLiteDatabase
{
    my $self = shift;
    
    my $sql = <<"EOF";
    CREATE TABLE entries (
    id INTEGER PRIMARY KEY,
    status VARCHAR(256),
    error BOOLEAN DEFAULT 0,
    date INTEGER,
    ip VARCHAR(15),
    json TEXT
    );
EOF

    $self->{dbh}->do($sql);
}

sub CooldownRemaining
{
    my $self = shift;
    my $ip = shift;
    
    if ($ip eq '127.0.0.1') { return 1; } # localhost is always fine
    
    my $time = time() - $mindelay;
    my $array_ref = $self->{dbh}->selectall_arrayref("SELECT ip, date FROM entries WHERE date > $time AND error!=1;");
    my @entries = @{$array_ref};
        
    foreach (@entries) 
    {
        my @arr = @{$_};
        if ($arr[0] eq $ip) { return (time() - $arr[1] - $mindelay) * -1 ; }
    }
    return 0;
}
