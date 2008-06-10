# $Id: phyloxml.pm 11507 2007-06-23 01:37:45Z jason $
#
# BioPerl module for Bio::TreeIO::phyloxml
#
# Cared for by Mira Han <mirhan@indiana.edu>
#
# Copyright Mira Han
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

Bio::TreeIO::phyloxml - TreeIO implementation for parsing 
    PhyloXML format.

=head1 SYNOPSIS

  # do not use this module directly
  use Bio::TreeIO;
  my $treeio = Bio::TreeIO->new(-format => 'phyloxml', -file => 'tree.dnd');
  my $tree = $treeio->next_tree;

=head1 DESCRIPTION

This module handles parsing and writing of phyloXML format.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to the
Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted viax the
web:

  http://bugzilla.open-bio.org/

=head1 AUTHOR - Mira Han

Email mirhan@indiana.edu

=head1 CONTRIBUTORS

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut


# Let the code begin...


package Bio::TreeIO::phyloxml;
use strict;

# Object preamble - inherits from Bio::Root::Root

use Bio::Tree::NodePhyloXML;
use XML::LibXML;
use XML::LibXML::Reader;
use base qw(Bio::TreeIO);

sub _initialize 
{
  my($self, %args) = @_;
  $args{-treetype} ||= 'Bio::Tree::Tree';
  $args{-nodetype} ||= 'Bio::Tree::NodePhyloXML';
  $self->SUPER::_initialize(%args);
  $self->debug("Creating obj phyloxml\n");

  # phyloxml TreeIO does not use SAX, 
  # therefore no need to attach EventHandler
  # instead we will define a reader that is a pull-parser of libXML
  if ($self->{'_file'}) {
    $self->{'_reader'} = XML::LibXML::Reader->new( 
                        location => $self->{'_file'},
                        no_blanks => 1
                        );
  } 

  $self->debug("libxml version: ", XML::LibXML::LIBXML_VERSION(), "\n");
  $self->treetype($args{-treetype});
  $self->nodetype($args{-nodetype});
  #$self->{'_treelevel'} = 0;
  _init_func();
}

sub _init_func
{
  my ($self) = @_;
  my %start_elements = (
    'phylogeny' => \&element_phylogeny,
    'clade' => \&element_clade, 
  );
  $self->{'_start_element'} = \%start_elements;
  my %end_elements = (
    'phylogeny' => \&end_element_phylogeny,
    'clade' => \&end_element_clade, 
  );
  $self->{'_end_element'} = \%end_elements;
}


=head2 next_tree

 Title   : next_tree
 Usage   : my $tree = $treeio->next_tree
 Function: Gets the next tree in the stream
 Returns : Bio::Tree::TreeI
 Args    : none


=cut

sub next_tree 
{
  my ($self) = @_;
  my $reader = $self->{'_reader'};
  my $tree;
  while ($reader->read) 
  {
    if ($reader->nodeType == XML_READER_TYPE_END_ELEMENT) 
    {
      if ($reader->name eq 'phylogeny') 
      {
        $tree = $self->end_element_phylogeny();
        last;
      }
    }
    processNode($self);
  }
  return $tree;
}


=head2 write_tree

 Title   : write_tree
 Usage   : $treeio->write_tree($tree);
 Function: Write a tree out to data stream in phyloxml format
 Returns : none
 Args    : Bio::Tree::TreeI object

=cut

sub write_tree{
}

sub _write_tree_Helper {
}



=head2 processNode

 Title   : processNode
 Usage   : 
 Function: 
 Returns : none
 Args    : 

=cut

sub processNode 
{
  my ($self) = @_;
  my $reader = $self->{'_reader'};
  if ($reader->nodeType == XML_READER_TYPE_ELEMENT) 
  {
    $self->debug("starting element: ",$reader->name, "\n");
    $self->{'_lastitem'}->{$reader->name}++;
    push @{$self->{'_lastitem'}->{'current'}}, $reader->name;

    if ($reader->name eq 'phylogeny') {
      $self->element_phylogeny();
    }
    elsif ($reader->name eq 'clade') {
      $self->element_clade();
    }
#    if (exists $self->{'_start_element'}->{$reader->name}) {
#      $self->{'_start_element'}->{$reader->name}->();
#    }
  }
  elsif ($reader->nodeType == XML_READER_TYPE_TEXT)
  {
    #$self->debug( $reader->depth,
    #    $reader->nodeType,
    #    $reader->name,
    #    $reader->isEmptyElement,
    #    $reader->value);
    $self->debug($reader->value, "\n");
    $self->{'_currenttext'} = $reader->value;
  } 
  elsif ($reader->nodeType == XML_READER_TYPE_END_ELEMENT)
  {
    $self->debug("ending element: ",$reader->name, "\n");
    
    if ($reader->name eq 'phylogeny') {
      $self->end_element_phylogeny();
    }
    elsif ($reader->name eq 'clade') {
      $self->end_element_clade();
    }
    elsif ($reader->name eq 'name') {
      $self->end_element_name();
    }
    #if (exists $self->{'_end_element'}->{$reader->name}) {
    #  $self->{'_end_element'}->{$reader->name}->();
    #}
    $self->{'_lastitem'}->{ $reader->name }--;
    pop @{$self->{'_lastitem'}->{'current'}};
  }
}


=head2 processAttribute

 Title   : processAttribute
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub processAttribute
{
  my ($self, $data) = @_;
  my $reader = $self->{'_reader'};

  # several ways of reading attributes:
  # read all attributes:
  if ($reader-> moveToFirstAttribute) {
    do {
       $data->{$reader->name()} = $reader->value;
    } while ($reader-> moveToNextAttribute);
    $reader-> moveToElement;
  }
  # back at the element
  # ...

  # read a specific attribute:
  #print "Attribute b: ",$reader-> getAttribute('b'),"\n";
}


=head2 element_phylogeny

 Title   : element_phylogeny
 Usage   : $handler->element_phylogeny
 Function: Begins a Tree event cycle
 Returns : none 
 Args    : none

=cut

sub element_phylogeny 
{
  my ($self) = @_;   
  $self->{'_lastitem'} = {};
  $self->{'_currentitems'} = [];
  $self->{'_currentnodes'} = [];
  $self->{'_currenttext'} = '';
  $self->{'_levelcnt'} = [];

  $self->debug("Starting phylogeny\n");
  $self->{'_treeattr'} = {};
  $self->processAttribute($self->{'_treeattr'});
  return; 
}

sub end_element_phylogeny
{
  my ($self) = @_;
  $self->debug("Ending phylogeny: nodes in stack is", scalar @{$self->{'_currentnodes'}}, "\n");

  my $root = $self->nodetype->new( -verbose => $self->verbose );
  # aggregate the nodes into trees basically ad-hoc.
  while ( @{$self->{'_currentnodes'}} ) {
    my ($node) = ( shift @{$self->{'_currentnodes'}});
    $root->add_Descendent($node);
  }
  $self->debug("Root node is " . $root->to_string()."\n");
  if( $self->verbose > 0 ) { 
    foreach my $node ( $root->get_Descendents  ) {
      $self->debug("node is ". $node->to_string(). "\n");
    }
  }

  my $tree = $self->treetype->new(
    -verbose => $self->verbose, 
    -root => $root,
    %{$self->{'_treeattr'}});
  return $tree;
}


=head2 element_clade

 Title   : element_clade
 Usage   : $->element_clade
 Function: Begins a clade cycle
 Returns : none 
 Args    : none

=cut

sub element_clade
{
  my ($self) = @_;
  my $reader = $self->{'_reader'};
  my %data = ();
  #take care of attribute
  $self->processAttribute(\%data);
  my $tnode = $self->nodetype->new( -verbose => $self->verbose, %data);
  push @{$self->{'_currentitems'}}, $tnode;
}

sub end_element_clade
{
  my ($self) = @_;
  my $reader = $self->{'_reader'};

  my $curcount = scalar @{$self->{'_currentnodes'}};
  my $level   = $reader->depth() - 2;
  my $childcnt = $self->{'_levelcnt'}->[$level+1] || 0; 
  $self->debug ("adding node: nodes in stack is $curcount, treelevel: $level, childcnt: $childcnt\n");

  my $tnode = pop @{$self->{'_currentitems'}};
  $self->debug( "new node will be ".$tnode->to_string."\n");
  if ( $childcnt > 0) {
    $self->debug(join(',', map { $_->to_string } @{$self->{'_currentnodes'}}). "\n");
    if( $childcnt > $curcount) 
    {
      $self->throw("something wrong with event construction treelevel ".
        "$level is recorded as having $childcnt nodes  ".
        "but current nodes at this level is $curcount\n");
    }
    my @childnodes = splice( @{$self->{'_currentnodes'}}, - $childcnt);
    for ( @childnodes ) {
      $self->debug("adding desc: " . $_->to_string . "\n");
      $tnode->add_Descendent($_);
    }
    $self->{'_levelcnt'}->[$level+1] = 0;
  }
  push @{$self->{'_currentnodes'}}, $tnode;
  $self->{'_levelcnt'}->[$level]++;

}


=head2 end_element_name

 Title   : end_element_name
 Usage   : $->end_element_name
 Function: 
 Returns : none 
 Args    : none

=cut

sub end_element_name
{
  my ($self) = @_;
  my $reader = $self->{'_reader'};
  my $prev = $self->prev_element();
  if ($prev eq 'phylogeny') {
    
  }
  elsif ($prev eq 'clade') {
    my $tnode = pop @{$self->{'_currentitems'}};
    $tnode->id($self->{'_currenttext'});
    push @{$self->{'_currentitems'}}, $tnode;
  }
  elsif ($prev eq 'taxonomy') {
  }
  else {

  }
}


=head2 element_id

 Title   : element_id
 Usage   : $->element_id
 Function: identifier element used by phylogeny, clade, taxonomy
 Returns : none 
 Args    : none

=cut

sub element_id
{
  my ($self) = @_;
  my $reader = $self->{'_reader'};
}


=head2 prev_element

 Title   : prev_element
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub prev_element{
   my ($self) = @_;

   return 0 if ! defined $self->{'_lastitem'} ||
       ! defined $self->{'_lastitem'}->{'current'}->[-2];
   return $self->{'_lastitem'}->{'current'}->[-2];
}


=head2 in_element

 Title   : in_element
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub in_element{
   my ($self,$e) = @_;

   return 0 if ! defined $self->{'_lastitem'} ||
       ! defined $self->{'_lastitem'}->{'current'}->[-1];
   return ($e eq $self->{'_lastitem'}->{'current'}->[-1]);

}

=head2 within_element

 Title   : within_element
 Usage   :
 Function:
 Example :
 Returns : 
 Args    :


=cut

sub within_element{
   my ($self,$e) = @_;
   return $self->{'_lastitem'}->{$e};
}

=head2 treetype

 Title   : treetype
 Usage   : $obj->treetype($newval)
 Function: 
 Returns : value of treetype
 Args    : newvalue (optional)


=cut

sub treetype{
   my ($self,$value) = @_;
   if( defined $value) {
      $self->{'treetype'} = $value; 
    }
    return $self->{'treetype'};
}

=head2 nodetype

 Title   : nodetype
 Usage   : $obj->nodetype($newval)
 Function: 
 Returns : value of nodetype
 Args    : newvalue (optional)


=cut

sub nodetype{
   my ($self,$value) = @_;
   if( defined $value) {
      $self->{'nodetype'} = $value;
    }
    return $self->{'nodetype'};
}


1;

