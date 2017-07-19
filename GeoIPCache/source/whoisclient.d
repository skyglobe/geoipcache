import vibe.vibe;
import ipdata;
import std.exception;
import std.regex;
import std.concurrency;
import core.thread;
import core.time;

private string IANA_WHOIS = "whois.iana.org";
private string ARIN_WHOIS = "whois.arin.net";

void whoisLoop(string redisHost, ushort redisPort)
{
    import dbconn;
    auto conn = new DBConnection(redisHost, redisPort);
    while (true) {
        auto query = receiveOnly!string();
        auto data = whoisIPQuery(query);
        //Save data into Redis
        if (data.CountryCode != "")
            conn.setCIDRCountryCode(data.CIDR, data.CountryCode);
        //Suspend for grace period of 10 seconds.
        Thread.sleep(dur!("seconds")(10));
    }
}

IPData whoisIPQuery(string ipquery, string host = IANA_WHOIS)
{
    enforce(IPData.isValid(ipquery), new HTTPStatusException(400, "Invalid IPv4 address"));
    IPData result = new IPData(ipquery);
    try {
        if (host == ARIN_WHOIS)
            ipquery = "n + " ~ ipquery;
        auto conn = connectTCP(host, 43);
        scope(exit) conn.close();
        conn.write(ipquery ~ "\r\n");
        conn.flush();
        bool dataAvailable = conn.waitForData(seconds(5));
        if (dataAvailable) {
            auto data = conn.readAllUTF8(true);
            if (host == IANA_WHOIS) {
                auto referRegex = ctRegex!(`refer:\s*(\w+.*)$`,"m");
                auto captured = matchFirst(data, referRegex);
                if (!captured.empty) {
                    result = whoisIPQuery(ipquery, captured[1]);
                } else {
                    logInfo("No WHOIS refer available");
                    string myCIDR = "";
                    if (findCIDR(data, myCIDR))
                        result.CIDR = myCIDR;
                }
            } else {
                auto countryRegex = ctRegex!(`country:\s*(\w+)`, "mi");
                auto captured = matchFirst(data, countryRegex);
                if (!captured.empty)
                    result.CountryCode = captured[1];
                string myCIDR = "";
                if (findCIDR(data, myCIDR))
                    result.CIDR = myCIDR;
            }
        } else {
            logInfo("No WHOIS data available");
        }
    } catch(Exception ex) {
        logInfo("WHOIS error: %s", ex.msg);
        throw new HTTPStatusException(503, "Service Unavailable");
    }
    return result;
}

private bool findCIDR(string input, out string output)
{
    auto cidrRegex = ctRegex!(`[0-2]?[0-9]?[0-9]\.[0-2]?[0-9]?[0-9]\.[0-2]?[0-9]?[0-9]\.[0-2]?[0-9]?[0-9]/[0-9][0-9]?`,"m");
    auto cidrMinMaxRegex = ctRegex!(`([0-2]?[0-9]?[0-9]\.[0-2]?[0-9]?[0-9]\.[0-2]?[0-9]?[0-9]\.[0-2]?[0-9]?[0-9])\s*-\s*([0-2]?[0-9]?[0-9]\.[0-2]?[0-9]?[0-9]\.[0-2]?[0-9]?[0-9]\.[0-2]?[0-9]?[0-9])`,"m");

    bool result = false;
    output = "";

    auto captured = matchFirst(input, cidrRegex);
    if (!captured.empty) {
        output = captured[0];
        result = true;
    } else {
        captured = matchFirst(input, cidrMinMaxRegex);
        if (!captured.empty) {
            string parsedCIDR = "";
            if (IPData.MinMaxToIPrange(captured[1], captured[2], parsedCIDR)) {
                output = parsedCIDR;
                result = true;
            }
        }
    }

    return result;
}
