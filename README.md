# YodaChat - To chat Master Yoda invites you!

YodaChat is a simple example application to demonstrate how to use WebRocket 
(http://github.com/webrocket/webrocket) from ruby applications using the 
Kosmonaut gem (http://github.com/webrocket/kosmonaut-ruby).

## Getting started

Installation and usage is extremally simple. First start and configure your 
WebRocket server instance:

Remember! Make sure your webrocket-server node is running!

    $ sudo webrocket-server
    
Add vhost for this application. You should see the access token after vhost
will be created. Copy it!

    $ sudo webrocket-admin add_vhost /yoda
    
Run your Redis server instance:

    $ redis-server /etc/redis.conf
   
Now copy `.env.sample` file to `.env` and replace its contents with your
configuration. Place vhost token in appropriate place. Load it when you're
done:

    $ source .env

Notice! You have to load env file every time you start working with the 
project, in every terminal tab you have open. 

Install bundler gem if you don't have it yet and install dependencies:

    $ gem install bundler
    $ bundle install
    
Start the app with foreman (http://github.com/ddollar/foreman)...

    $ foreman start

Now you shall go to 'http://localhost:5000' and see an amazing yodachat
application powered by WebRocket's awesomness.

## Deploying on heroku

Deployment on heroku is extremally easy. Just follow those steps:

    $ heroku create --stack cedar
    $ heroku config:add REDIS_URL={redis URL/redistogo alias}
    $ heroku config:add WEBROCKET_BACKEND_URL={backend endpoint URL}
    $ heroku config:add WEBROCKET_WEBSOCKET_URL={websocket endpoint URL}
    $ git push heroku master
    $ heroku scale worker=1 web=1
    
Now go to the website, and enjoy! 

## Testing

To run acceptance tests run:
  
    $ rake run
   
RSpec unit tests are available under:

    $ rake test

Invoking rake without arguments will cause run of all the tests together:

    $ rake

## Authors

Krzysztof Kowalik <chris@nu7hat.ch>:: 
    The ruby backend and integration with Kosmonaut.

Nicolas Barrera <drummerhead@gmail.com>::
    Awesome responsive layout with HTML5 and CSS3 sugar!
    
Sebastian Heit <sebastian@cuboxsa.com>::
    Jedi fight vectors and footer's parallax.

## Sponsors

This project has been done in a free time at Cubox - an awesome dev shop
from Uruguay <http://cuboxsa.com>.

## Copyright

Copyright (C) 2011 by folks at Cubox <dev@cuboxsa.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
