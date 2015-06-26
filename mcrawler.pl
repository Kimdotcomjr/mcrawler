#!/usr/bin/perl -w
#
# mcrawler
# generic webcrawler 
#
#	by xor-function
#	license BSD-2
# 


use strict;
use WWW::RobotRules;
use Mojo::UserAgent;
use Mojo::URL;


my $target = $ARGV[0];

# test arguments 
if ( @ARGV > 1 || @ARGV < 1 ) {
      die "\n[!] usage: ./crawler.pl [http://www.site-domain.com] \n\n";
}

unless ($target =~ /^http/ ) {
      die "\n[!] the parameter passed is not valid.\n\n";
}


main($target);


sub main {

	my $site = $_[0];

	# access refrenced arrays using a formation "@{$var}"
	my ($seeds, $media, $xlinks, $xmedia) = get_links($site);

	# regenerating arrays from references
	my @seeds 	= filter_array(@{$seeds});
	my @media	= filter_array(@{$media});
	my @xlinks 	= filter_array(@{$xlinks});
	my @xmedia	= filter_array(@{$xmedia}); 

	print "[!] visiting seeds! \n";

	# access refrenced arrays using a formation "@{$var}"
	my ($urls, $murls, $xdurls, $xdmurls)  = harvest_link_array(@seeds);

	push (@{$urls}, @seeds); 
        push (@{$murls}, @media);
        push (@{$xdurls}, @xlinks);
        push (@{$xdmurls}, @xmedia);
	
	my @ext_urls = filter_array(@{$urls});
	my @murls    = filter_array(@{$murls});
	my @xdurls   = filter_array(@{$xdurls});
	my @xdmurls  = filter_array(@{$xdmurls});

	print "[!] final round! \n";

	my ($urls2, $murls2, $xdurls2, $xdmurls2) = harvest_link_array(@ext_urls);

 	push (@ext_urls, @{$urls2}); 
	push (@murls, @{$murls2}); 
	push (@xdurls, @{$xdurls2});
	push (@xdmurls, @{$xdmurls2});

	my @furls	= filter_array(@ext_urls);
	my @fmurls	= filter_array(@murls);
	my @fxdurls	= filter_array(@xdurls);
	my @fxdmurls	= filter_array(@xdmurls);

        # TODO
        # set up database connector for importation of the following results to a mysql-db
        # harvest html source from the following urls and save results to db.
        # for media only save general documents pdfs, docx, pictures, etc.. 
        # No videos disk images compressed files or audio (.mp3 .aac  etc...).

        print "[!] writing urls to file.\n";

        my $log1 = "domain-urls";
        open(my $fh1, '+>>', "$log1" ) or die "Could not open file $!";
                print $fh1 "[+] Inital seed domain URLs.\n";
                foreach my $d (@furls) {
                        print $fh1 "$d\n";
                }
        close $fh1;


        print "[!] writing urls containing media to file.\n";

        my $log2 = "domain-media-urls";
        open(my $fh2, '+>>', "$log2" ) or die "Could not open file $!";
                print $fh2 "[+] Seed domain URLs Containing Media.\n";
                foreach my $m (@fmurls) {
                        print $fh2 "$m\n";
                }
        close $fh2;


        print "[!] writing external domain urls to file.\n";

        my $log3 = "external-domain-urls";
        open(my $fh3, '+>>', "$log3" ) or die "Could not open file $!";
                print $fh3 "[+] External domain URLs.\n";
                foreach my $x (@fxdurls) {
                        print $fh3 "$x\n";
                }
        close $fh3;

        print "[!] writing external domain urls containing media to file.\n";

        my $log4 = "external-domain-media-urls";
        open(my $fh4, '+>>', "$log4" ) or die "Could not open file $!";
                print $fh4 "[+] External domain URLs Containing Media.\n";
                foreach my $xm (@fxdmurls) {
                        print $fh4 "$xm\n";
                }
        close $fh4;

}

# Remove duplicates from array
sub filter_array {

        my %seen;
        $seen{$_}++ for @_;

        return keys %seen;

}

sub harvest_link_array {

	my @list = @_;

	my ($llinks, $lmedia, $lxlinks, $lxmedia);
	my (@hlinks, @hmedia, @hxlinks, @hxmedia);
	foreach my $l (@list) {

		sleep (int(rand(20)) + 7);

		print "[*] fetching data from $l \n";

		($llinks, $lmedia, $lxlinks, $lxmedia) = get_links($l);

		 push (@hlinks, @{$llinks}); push (@hmedia, @{$lmedia});
		 push (@hxlinks, @{$lxlinks}); push (@hxmedia, @{$lxmedia});

	}

	my @flinks  = filter_array(@hlinks);
	my @fmedia  = filter_array(@hmedia);
	my @fxlinks = filter_array(@hxlinks);
	my @fxmedia = filter_array(@hxmedia);

	return (\@flinks, \@fmedia, \@fxlinks, \@fxmedia);

}

sub get_robots { 

	my $url = $_[0]; 

        # build Robots.txt path 
        my $uri    = Mojo::URL->new($url);
        my $scheme = $uri->scheme;
        my $host   = $uri->host;

        my $rtxt = Mojo::URL->new;
                   $rtxt->scheme($scheme);
                   $rtxt->host($host);
                   $rtxt->path('/robots.txt');

	return $rtxt;

}
	
# Constructor start agent to get html through proxy 
# then parses it using "Mojo's dom find" for all hrefs then divides the links found
# into the following lists 
# Internal domain links; (media: pics, vids, dox) (html links)
# External domain links; (media: pics, vids, dox) (html links)
 
sub get_links { 

	my $url = $_[0];

	# Insure links from target domain are seperated
	my $host = Mojo::URL->new($url)->host;
	
	# user agent constructor setting up crawler and a local proxy "TOR"
	my $ua = Mojo::UserAgent->new(max_redirects => 5);
		$ua->transactor->name('Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2227.0 Safari/537.36');
#		$ua->proxy->https('socks://127.0.0.1:9050');
#		$ua->proxy->http('socks://127.0.0.1:9050');

	# build path to robots.txt
	my $rbots_url = get_robots($url);

        # initialize Robot Rules to parse robots.txt ex: $rules->allowed($rbots_txt);
        my $rbots_txt = $ua->get($rbots_url)->res->dom;

        my $rules = WWW::RobotRules->new;
	$rules->parse($rbots_url, $rbots_txt);

        # dumping the html source from dom and loading relevant urls into array
        my $get   = $ua->get($url);
	my @hrefs = $get->res->dom('a[href]')->each;

	# filtering array
	my (@links, @media, @xdlinks, @xdmedia);
	foreach my $h (@hrefs) {

		# translate relative links to absolute ones
	    	my $link = Mojo::URL->new($h->{href});

		$link = $link->to_abs($get->req->url)->fragment(undef);
		my $proto = $link->protocol;

		# insure link is to a web server
		if(grep($proto, "http https")) {

			if ( $link =~ /(jpg|png|css|mp4|avi|flv|pdf|doc|exe|xml|msi|iso|img|tar|gz|7z|tgz|bz2)/igm) {
                        	if ( $link =~ /$host/ ) {
					if ($rules->allowed($link)) { push (@media, $link); } 
				} else { push (@xdmedia, $link); }
                	} 
			else {
				if ( $link =~ /$host/ )  { 
					if ($rules->allowed($link)) { push (@links, $link); }
				} else {  push (@xdlinks, $link); }
			}

		} else { next; }
	}

	return (\@links, \@media, \@xdlinks, \@xdmedia);

}
