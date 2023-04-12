/**
 * Created by Jayakumar Mogenahall on 16/03/2023.
 */

public with sharing class PriceListResultWrapper {

    public class Response {
        public String result;
        public String serviceName;
        public String responseSent;
        public Data data;
    }

    public class Prices {
        public List<Price> price;
    }

    public Response response;

    public class Price {
        public String materialCode;
        public Double unitPrice;
        public String countryCurrency;
        public String priceType;
    }

    public class Data {
        public String customerAccount;
        public Prices prices;
        public String countryCode;
    }

    public static PriceListResultWrapper parse(String json) {
        return (PriceListResultWrapper) System.JSON.deserialize(json, PriceListResultWrapper.class);
    }
}