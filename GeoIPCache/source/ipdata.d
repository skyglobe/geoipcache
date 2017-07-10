import std.conv;

public class IPData {

private:
    string ips = "";
    int ipn = -1;
    string country_code = "";

public:
    this(string ip) {
        import std.regex;
        auto ipRegex = ctRegex!(`([0-2]?[0-9]?[0-9])\.([0-2]?[0-9]?[0-9])\.([0-2]?[0-9]?[0-9])\.([0-2]?[0-9]?[0-9])`);
        auto captured = matchFirst(ip, ipRegex);
        if (captured.empty)
            throw new Exception("Invalid IP");
        this.ips = captured.front;
        captured.popFront();
        this.ipn = 0;
        while (!captured.empty) {
            auto s = captured.front;
            int v = to!int(s);
            if (v > 255)
                throw new Exception("Invalid IP");
            this.ipn = this.ipn << 8;
            this.ipn += v;
            captured.popFront();
        }
    }

    @property
    string IPstring() { return this.ips; }

    @property
    int IPnum() { return this.ipn; }

    @property
    string CountryCode() { return this.country_code; }

    @property
    string CountryCode(string value) { return this.country_code = value; }

}
