import std.conv;
import coords;
import std.regex;
import std.exception;

public class IPData {

private:
    string ips = "";
    string cidr = "";
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
    string CIDR() { return this.cidr; }

    @property
    string CIDR(string value)
    {
        auto cidrRegex = ctRegex!(`[0-2]?[0-9]?[0-9]\.[0-2]?[0-9]?[0-9]\.[0-2]?[0-9]?[0-9]\.[0-2]?[0-9]?[0-9]/[0-9]?[0-9]`);
        auto captured = matchFirst(value, cidrRegex);
        if (captured.empty)
            throw new Exception("Invalid CIDR");
        return this.cidr = value;
    }

    @property
    string CountryCode() { return this.country_code; }

    @property
    string CountryCode(string value)
    {
        country_coords ccVal = ccBinSearch(value);
        if (ccVal.code != "") {
            this.lon = ccVal.lon;
            this.lat = ccVal.lat;
            return this.country_code = value;
        } else {
            throw new Exception("Invalid country code.");
        }
    }

    @property
    string Coords() { return to!string(this.lat) ~ "," ~ to!string(this.lon); }

    //Converts a dotted decimal string into a integer value
    static long stringToIP(string ips)
    {
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

    static bool isValidCIDR(string input)
    {
        bool result = false;
        auto cidrRegex = ctRegex!(`([0-2]?[0-9]?[0-9])\.([0-2]?[0-9]?[0-9])\.([0-2]?[0-9]?[0-9])\.([0-2]?[0-9]?[0-9])/([0-9][0-9]?)`);
        auto captured = matchFirst(input, cidrRegex);
        if (!captured.empty) {
            for (ulong i = 1; i < 5; ++i) {
                auto v = to!int(captured[i]);
                if (v > 255)
                    return false;
            }
            auto bits = to!int(captured[5]);
            return (bits >= 0) && (bits <= 32);
        }
        return result;
    }

    static bool IPrangeToMinMax(string IPrange, out long min, out long max)
    {
        bool result = false;
        auto ipRRegex = ctRegex!(`([0-2]?[0-9]?[0-9])\.([0-2]?[0-9]?[0-9])\.([0-2]?[0-9]?[0-9])\.([0-2]?[0-9]?[0-9])/([0-9][0-9]?)`);
        min = -1L;
        max = -1L;
        auto captured = matchFirst(IPrange, ipRRegex);
        if (!captured.empty) {
            int bits;
            try {
                string ips = captured[1] ~ "." ~ captured[2] ~ "." ~ captured[3] ~ "." ~ captured[4];
                min = IPData.stringToIP(ips);
                bits = to!int(captured[5]);
            } catch(Exception) {
                min = -1L;
                max = -1L;
                return false;
            }
            if (bits == 32) {
                max = min;
                result = true;
            } else {
                if (bits > 32) {
                    min = -1L;
                    max = -1L;
                    return false;
                }
                long howMany = 2 ^^ (32 - bits);
                max = min + howMany;
                result = true;
            }
        }
        return result;
    }

    static bool MinMaxToIPrange(string minIP, string maxIP, out string IPrange)
    {
        import std.format;
        try {
            auto ipRegex = ctRegex!(`([0-2]?[0-9]?[0-9])\.([0-2]?[0-9]?[0-9])\.([0-2]?[0-9]?[0-9])\.([0-2]?[0-9]?[0-9])`);
            auto captured = matchFirst(minIP, ipRegex);
            enforce(!captured.empty, new Exception("Invalid IP."));
            captured = matchFirst(maxIP, ipRegex);
            enforce(!captured.empty, new Exception("Invalid IP."));
            auto min = IPData.stringToIP(minIP);
            auto max = IPData.stringToIP(maxIP);
            auto delta = max - min;
            auto bits = 32L - format("%b", delta).length;
            IPrange = format("%s/%s", minIP, bits);
            return true;
        } catch(Exception) {
            IPrange = "";
            return false;
        }
    }
}
