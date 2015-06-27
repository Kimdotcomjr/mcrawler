## mcrawler

A basic webcrawler that harvests 'a' href links.

requires a single parameter of the domain to be harvested.
The format of the site has to be a full url, example.

```
./crawler.pl http://www.some-domain.com
```

the results are saved in the same directory as the running script.

requires the Mojolicious framework for 
Mojo::UserAgent and Mojo::URL modules

And WWW::RobotRules from cpan 

TODO
May use WWW::Mechanize for form manipulation and replace 
the current user agent then just use Mojo::DOM for parsing.


