import std.exception;
import vibe.vibe;
import ipdata;

public class IPNotFoundException : Exception
{
    public this()
    {
        super("IP not found in database.");
    }
}

public class DBConnection
{
    private:
        RedisDatabase db;

    public:
        this(string host, ushort port)
        {
            auto redisClient = new RedisClient(host, port);
            this.db = redisClient.getDatabase(0);
        }

        IPData getIPData(string query)
        {
            import std.array;
            IPData result = new IPData(query);
            //Split the IP on the dots
            auto nums = split(query,'.');
            if (this.db.exists(nums[0])) {
                auto v = this.db.get(nums[0]);
                if (IPData.isValidCIDR(v)) {
                    //Convert IP to num
                    auto ipN = IPData.stringToIP(query);
                    //Get CIDR min and max values
                    long cidrMin, cidrMax;
                    auto convResult = IPData.IPrangeToMinMax(v, cidrMin, cidrMax);
                    if (convResult && (ipN > cidrMin) && (ipN < cidrMax)) {
                        result.CountryCode = this.db.get(v);
                    } else {
                        this.db.set(nums[0], "");
                        return this.getIPData(query);
                    }
                } else {
                    //Multiple CIDRs
                    int i = 0;
                    do {
                        ++i;
                        string cidrQuery = join(nums[0..i], ".");
                        v = this.db.get(cidrQuery);
                    }
                    while ((i < 3) && (!IPData.isValidCIDR(v)));
                    if (IPData.isValidCIDR(v)) {
                        auto cc = this.db.get(v);
                        result.CountryCode = cc;
                    } else {
                        throw new IPNotFoundException();
                    }
                }
            } else {
                throw new IPNotFoundException();
            }
            return result;
        }

        void setCIDRCountryCode(string cidr, string cc, uint prefixCount=cast(uint)1u)
        {
            import std.array;
            import std.regex;
            enforce(IPData.isValidCIDR(cidr), new Exception("Invalid CIDR: " ~ cidr));
            enforce(cc.length == 2, new Exception("Invalid ISO Country Code: " ~ cc)); //TODO: make sure the code is correct
            auto splitCIDR = ctRegex!(`^([0-2]?[0-9]?[0-9]).([0-2]?[0-9]?[0-9]).([0-2]?[0-9]?[0-9]).([0-2]?[0-9]?[0-9])/([0-9][0-9]?)$`);
            auto captured = matchFirst(cidr, splitCIDR);
            if (captured.empty)
                throw new Exception("Second regex fail."); //This should never happen
            string key = "";
            int i = 0;
            while (i < prefixCount) {
                if (i > 0)
                    key = join([ key, captured[i+1] ], '.');
                else
                    key = captured[1];
                ++i;
            }
            logInfo("key = %s", key);
            logInfo("key exists = %d", this.db.exists(key));
            if (!this.db.exists(key)) {
                //Create a new entry
                logInfo("Create a new entry");
                this.db.set(key, cidr);
                this.db.set(cidr, cc);
            } else {
                //Void the old key
                logInfo("Void the old key");
                this.db.set(key, "");
                ++prefixCount;
                if (prefixCount < 4) {
                    setCIDRCountryCode(cidr, cc, prefixCount);
                } else {
                    import std.format;
                    string msg = format!"Recursion error: setCIDRCountryCode(%s, %s, %d)"(cidr, cc, prefixCount);
                    throw new Exception(msg);
                }
            }
        }
}
