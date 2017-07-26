GeoIPCache: a simple Web API to access IP Geolocation data.
===========================================================

GeoIPCache is a simple web API to provide IP addresses geolocation data.
It can query [whois](https://en.wikipedia.org/wiki/WHOIS) servers to
populate a [Redis](https://redis.io) database.

License
-------

    Copyright (c) 2017 Gianfranco Gallizia
    
    Permission is hereby granted, free of charge, to any person
    obtaining a copy of this software and associated documentation
    files (the "Software"), to deal in the Software without
    restriction, including without limitation the rights to use,
    copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following
    conditions:
    
    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
    OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
    HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
    OTHER DEALINGS IN THE SOFTWARE.

Build instructions
------------------

To build GeoIPCache first you need to install a [D](https://dlang.org)
compiler (the reference implementation, `dmd`, is recommended) and then
install the [dub](https://code.dlang.org) package registry.

After that all you have to do is run the `dub run` command from within
the GeoIPCache directory to compile and run GeoIPCache.

Commandline options
-------------------

Other than the default vibe.d commandline options GeoIPCache also
accepts the following options:

- `-a $ADDRESS` or `--address=$ADDRESS`: binding address (default: 0.0.0.0)
- `-p $PORT` or `--port=$PORT`: binding port (default: 8080)
- `--redishost=$HOST`: Redis server hostname or IP address (default: redis)
- `--redisport=$PORT`: Redis server port (default: 6379)
