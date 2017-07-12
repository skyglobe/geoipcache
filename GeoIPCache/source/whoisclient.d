import vibe.vibe;
import ipdata;
import std.exception;
import std.regex;

private string IANA_WHOIS = "whois.iana.org";
private string ARIN_WHOIS = "whois.arin.net";

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
            auto data = conn.readAllUTF8();
            if (host == IANA_WHOIS) {
                auto referRegex = ctRegex!(`refer:\s*(\w+.*)$`,"m");
                auto captured = matchFirst(data, referRegex);
                if (!captured.empty) {
                    result = whoisIPQuery(ipquery, captured[1]);
                } else {
                    logInfo("No WHOIS server available");
                }
            } else {
                logInfo("WHOIS Host: %s", host); //DEBUG
                logInfo("WHOIS Data: %s", data); //DEBUG
                auto countryRegex = ctRegex!(`country:\s*(\w+)`, "mi");
                auto captured = matchFirst(data, countryRegex);
                if (!captured.empty)
                    result.CountryCode = captured[1];
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
