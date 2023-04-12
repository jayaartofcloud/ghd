/**
 * Created by Jayakumar Mogenahall on 14/02/2023.
 */

public  class ProductsTemp {

    @AuraEnabled
    public String ProductName {get;set;}
    @AuraEnabled
    public Decimal UnitPrice{get;set;}
    @AuraEnabled
    public Integer OrderQty{get;set;}
    @AuraEnabled
    public Integer FreeQty{get;set;}
    @AuraEnabled
    public Integer PromotionOrderQty{get;set;}
    @AuraEnabled
    public Integer PromotionFreeQty{get;set;}
    @AuraEnabled
    public String Family{get;set;}
    @AuraEnabled
    public Integer AvailableStock {get;set;}
    @AuraEnabled
    public String Id {get;set;}

    public static List<ProductsTemp> parse(String json) {
        return (List<ProductsTemp>) System.JSON.deserialize(json, List<ProductsTemp>.class);

    }
}