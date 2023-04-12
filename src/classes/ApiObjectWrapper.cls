/**
 * Created by Jayakumar Mogenahall on 07/02/2023.
 */

public  class ApiObjectWrapper {
    public class Dimension{
        public String dimType;
        public String weight;
        public String height;
        public String width;
        public String volume;
        public String depth;
        public String totalCartonInPallet;
        public String totalUnitsInCarton;
        public String totalUnitsInPallet;
        public String totalUnitsInRetail;
    }
    public class Codes
    {
        public String eanCode;
        public String outerEAN;
        public String itfCode;
        public String taricCode;
    }

    public class Region{
        public String countryCode;
        public String regionalDescription;
    }
}