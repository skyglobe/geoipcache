import std.conv;

public class IPData {

private:
    string ips = "";
    long ipn = -1;
    string country_code = "";
    double lon = 0.0;
    double lat = 0.0;

public:
    this(string ip)
    {
        this.ipn = stringToIP(ip);
        this.ips = ip;
    }

    @property
    string IPstring() { return this.ips; }

    @property
    long IPnum() { return this.ipn; }

    @property
    string CountryCode() { return this.country_code; }

    @property
    string CountryCode(string value) { return this.country_code = value; }

    @property
    string Coords() { return to!string(this.lon) ~ "," ~ to!string(this.lat); }

    //Converts a dotted decimal string into a integer value
    static long stringToIP(string ips)
    {
        import std.regex;
        long result = -1;
        auto ipRegex = ctRegex!(`([0-2]?[0-9]?[0-9])\.([0-2]?[0-9]?[0-9])\.([0-2]?[0-9]?[0-9])\.([0-2]?[0-9]?[0-9])`);
        auto captured = matchFirst(ips, ipRegex);
        if (captured.empty)
            throw new Exception("Invalid IP");
        captured.popFront();
        result = 0;
        while (!captured.empty) {
            auto s = captured.front;
            int v = to!int(s);
            if (v > 255)
                throw new Exception("Invalid IP");
            result = result << 8;
            result += v;
            captured.popFront();
        }
        return result;
    }

    static bool isValid(string ip)
    {
        import std.regex;
        bool result = false;
        auto ipRegex = ctRegex!(`([0-2]?[0-9]?[0-9])\.([0-2]?[0-9]?[0-9])\.([0-2]?[0-9]?[0-9])\.([0-2]?[0-9]?[0-9])`);
        auto captured = matchFirst(ip, ipRegex);
        if (!captured.empty) {
            captured.popFront();
            while (!captured.empty) {
                auto v = to!int(captured.front);
                if (v > 255)
                    return false;
                captured.popFront();
            }
            result = true;
        }
        return result;
    }
}
