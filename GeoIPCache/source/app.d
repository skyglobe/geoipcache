import vibe.vibe;
import std.conv;
import std.regex;
import ipdata;
import whoisclient;

private struct APIopt {
    string listeningAddress = "0.0.0.0";
    ushort listeningPort = cast(ushort)8080u;
    string redisHost = "redis";
    ushort redisPort = cast(ushort)6379u;
}

void main()
{
    auto myOpts = new APIopt();
    auto redisClient = new RedisClient(myOpts.redisHost, cast(ushort)myOpts.redisPort);
    auto router = new URLRouter;
    router.get("/", &hello);
    router.get("/ipv4/:ip", &getIPv4Info);

    //Favicon
    auto faviconSettings = new HTTPFileServerSettings;
    faviconSettings.serverPathPrefix = "/";
    faviconSettings.options = HTTPFileServerOption.failIfNotFound;
    faviconSettings.preWriteCallback = (req, res, ref path) {
        res.headers["Content-Type"] = "image/vnd.microsoft.icon";
    };
    router.get("/favicon.ico", serveStaticFiles("public/", faviconSettings));

    auto settings = new HTTPServerSettings;
    settings.port = myOpts.listeningPort;
    settings.bindAddresses = [myOpts.listeningAddress];
    settings.errorPageHandler = toDelegate(&errorPage);
    listenHTTP(settings, router);

    runApplication();
}

void errorPage(HTTPServerRequest req, HTTPServerResponse res, HTTPServerErrorInfo error)
{
    auto retvalArray = [ "error_code" : to!string(error.code) , "message" : to!string(error.message) ] ;
    auto retvalJSON = serializeToJson(retvalArray);
    res.headers["Content-Type"] = "application/json";
    res.writeBody(retvalJSON.toString());
}

void hello(HTTPServerRequest req, HTTPServerResponse res)
{
    //TODO: write the endpoints here
    res.writeBody("Hello, World!\n");
}


void getIPv4Info(HTTPServerRequest req, HTTPServerResponse res)
{
    string myInput = req.params["ip"];
    auto ipdata = whoisIPQuery(myInput);
    auto retval = [ "IP" : ipdata.IPstring, "CIDR" : ipdata.CIDR, "Country" : ipdata.CountryCode, "Coords" : ipdata.Coords];
    auto retvalJSON = serializeToJson(retval);
    res.headers["Content-Type"] = "application/json";
    res.writeBody(retvalJSON.toString());
}
