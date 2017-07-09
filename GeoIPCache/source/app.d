import vibe.vibe;
import std.conv;

void main()
{
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
    settings.port = 8080;
    settings.bindAddresses = ["0.0.0.0"];
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
    res.writeBody("Hello, World!\n");
}


void getIPv4Info(HTTPServerRequest req, HTTPServerResponse res)
{
    string myInput = req.params["ip"];
    if (isValidIPv4(myInput)) {
        res.writeBody("Valid IP: " ~ myInput ~ "\n");
    } else {
        res.writeBody("Invalid IP: " ~ myInput ~ "\n");
    }

}

bool isValidIPv4(string input) {
    import std.regex;
    bool result = false;
    auto ipRegex = ctRegex!(`([0-2]?[0-9]?[0-9])\.([0-2]?[0-9]?[0-9])\.([0-2]?[0-9]?[0-9])\.([0-2]?[0-9]?[0-9])`);
    auto captured = matchFirst(input, ipRegex);
    if (!captured.empty) {
        captured.popFront();
        while(!captured.empty) {
            result = (to!int(captured.front) < 256);
            if (!result) break;
            captured.popFront();
        }
    }
    return result;
}
