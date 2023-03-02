/**
 * Created by Jayakumar Mogenahall on 07/02/2023.
 */

public class MaterialRequestWrapper {

        static MaterialRequestListWrapper listWrapper;
        MaterialRequestWrapper(){
                dimensions = new ApiObjectWrapper.Dimension();
                codes = new ApiObjectWrapper.Codes();
                region = new ApiObjectWrapper.Region();
                additionalInfo = new ApiObjectWrapper.AdditionalInfoWrapper();
                origin = new ApiObjectWrapper.OriginWrapper();
                startDate = Date.today();
                kitDate = Date.today();
        }
        public String Id;
        public String material;
        public String materialDescription;
        public String productType;
        public String active;
        public String tntEnabled;
        public String bundle;
        public String uom;
        public String category;
        public String owner;
        public String serialisedProduct;
        public Boolean dangerousGoodsFlag;
        public String dangerousGoodsClassification;
        public String dangerousGoodsPackingGroup;
        public String dangerousGoodsUNCode;
        public String dangerousGoodsShippingName;
        public String customsDescription;
        public Integer units=0;
        public String minimumReplacementQuantity;
        public String replacementCode;
        public String inventory;
        public String carrierBag;
        public String wetStock;
        public Date startDate;
        public Date kitDate;
         public ApiObjectWrapper.Dimension dimensions;
         public ApiObjectWrapper.Codes codes;
         public ApiObjectWrapper.Region region;
         public ApiObjectWrapper.AdditionalInfoWrapper additionalInfo;
         public ApiObjectWrapper.OriginWrapper origin;


    public static MaterialRequestListWrapper parse(String json){
            listWrapper = new MaterialRequestListWrapper();
            System.debug('#json before parse:'+json);
            List<MaterialRequestWrapper> wrappers = (List<MaterialRequestWrapper>)System.JSON.deserialize(json, List<MaterialRequestWrapper>.class);
            System.debug('#wrappers:'+ wrappers);
            listWrapper.wrappers = wrappers;
            System.debug('#listWrapper.wrappers:'+listWrapper.wrappers.size());
            return listWrapper;

    }
}