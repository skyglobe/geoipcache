import std.concurrency;
import std.conv;
import std.regex;
import vibe.vibe;
import dbconn;
import ipdata;
import whoisclient;

private DBConnection conn;
private Tid worker;

private string listeningAddress;
private ushort listeningPort;
private string redisHost;
private ushort redisPort;

void main(string[] args)
{
    //Command line arguments parsing
    if (!readOption!string("address|a", &listeningAddress, "Listening address (default: 0.0.0.0).")) {
        listeningAddress = "0.0.0.0";
    }
    if (!readOption!ushort("port|p", &listeningPort, "Listening port (default: 8080).")) {
        listeningPort = cast(ushort)8080u;
    }
    if (!readOption!string("redishost", &redisHost, "Redis host (default: redis).")) {
        redisHost = "redis";
    }
    if (!readOption!ushort("redisport", &redisPort, "Redis port (default: 6379).")) {
        redisPort = cast(ushort)6379u;
    }
    if (!finalizeCommandLineOptions())
        return;
    conn = new DBConnection(redisHost, redisPort);
    worker = spawn(&whoisLoop, redisHost, redisPort);
    auto router = new URLRouter;
    router.get("/", staticTemplate!"index.dt");
    router.get("/ipv4/:ip", &getIPv4Info);

    //Favicon
    auto faviconSettings = new HTTPFileServerSettings;
    faviconSettings.serverPathPrefix = "/";
    faviconSettings.options = HTTPFileServerOption.failIfNotFound;
    faviconSettings.preWriteCallback = (req, res, ref path) {
        res.headers["Content-Type"] = "image/vnd.microsoft.icon";
    };
    router.get("/favicon.ico", serveStaticFiles("public/", faviconSettings));

    //Other static files
    auto staticFilesSettings = new HTTPFileServerSettings;
    staticFilesSettings .serverPathPrefix = "/static/";
    staticFilesSettings.options = HTTPFileServerOption.failIfNotFound;
    router.get("*", serveStaticFiles("public/", staticFilesSettings));

    auto settings = new HTTPServerSettings;
    settings.port = listeningPort;
    settings.bindAddresses = [listeningAddress];
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

void getIPv4Info(HTTPServerRequest req, HTTPServerResponse res)
{
    string myInput = req.params["ip"];
    enforce(IPData.isValid(myInput), new HTTPStatusException(400, "Invalid IPv4 address"));
    IPData ipdata;
    try {
        ipdata = conn.getIPData(myInput);
    } catch(IPNotFoundException) {
        ipdata = whoisIPQuery(myInput);
        //Send message to worker
        std.concurrency.send(worker, myInput);
    }
    auto retval = [ "IP" : ipdata.IPstring, "CIDR" : ipdata.CIDR, "Country" : ipdata.CountryCode, "Coords" : ipdata.Coords];
    auto retvalJSON = serializeToJson(retval);
    res.headers["Content-Type"] = "application/json";
    res.writeBody(retvalJSON.toString());
}
