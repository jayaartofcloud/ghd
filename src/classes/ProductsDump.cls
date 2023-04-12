/**
 * Created by Jayakumar Mogenahall on 15/02/2023.
 */

public  class ProductsDump {

   public static Map<String,List<ProductsTemp>> productsTemps;

    @AuraEnabled(Cacheable=true)
    public static List<ProductsTemp> buildProductDump(String family,String searchToken,String description){
        System.debug('#searchToken:'+searchToken);
        System.debug('#family:'+family);
        System.debug('#description:'+description);
    List<ProductsTemp> productsTempsOutput = new List<ProductsTemp>();
    try {
        ProductsDump.ProductResultWrapper resultWrapper = new ProductsDump.ProductResultWrapper();

        List<DraftOrder__c> draftOrders = [SELECT Id,ProductName__c,OrderQty__c FROM DraftOrder__c WHERE Description__c = : description];
        Set<String> prodNames = new Set<String>();
        Map<String,DraftOrder__c> draftOrderMap = new Map<String,DraftOrder__c>();
        for(DraftOrder__c d : draftOrders){
            prodNames.add(d.ProductName__c);
            draftOrderMap.put(d.ProductName__c,d);
        }
        Map<String,ProductTemp__c> draftProductMap = new  Map<String,ProductTemp__c>() ;
        if(prodNames.size() > 0) {
            List<ProductTemp__c> draftProducts = [SELECT Id, Available_Stock__c, Family__c, Name, Order_Qty__c, Unit_Price__c, Free_Qty__c, Promotion_Free_Qty__c, Promotion_Order_Qty__c FROM ProductTemp__c WHERE Name IN :prodNames];

           for(ProductTemp__c draft : draftProducts){
               draftProductMap.put(draft.Name, draft);
           }
            System.debug('#draftProducts:'+draftProducts);
        }
            List<ProductTemp__c> productsTemps1 = [SELECT Id,Available_Stock__c, Family__c,Name,Order_Qty__c,Unit_Price__c,Free_Qty__c,Promotion_Free_Qty__c, Promotion_Order_Qty__c FROM ProductTemp__c];

        System.debug('productsTemps1:'+productsTemps1);

        Map<String, List<ProductsTemp>> productTempMap = new Map<String,List<ProductsTemp>>();
       // System.debug('#productsTemps1:'+productsTemps1);
        Integer num = 0;
        for(ProductTemp__c p : productsTemps1){
            if(!productTempMap.containsKey(p.Family__c)){
                ProductsTemp temp = new ProductsTemp();
                temp.ProductName = p.Name;
                DraftOrder__c dp = draftOrderMap?.get(p.Name);
                temp.OrderQty = dp != null? Integer.valueOf(dp.OrderQty__c) : Integer.valueOf(p.Order_Qty__c);
                temp.PromotionOrderQty = Integer.valueOf(p.Promotion_Order_Qty__c);
                temp.PromotionFreeQty = Integer.valueOf(p.Promotion_Free_Qty__c);
                temp.FreeQty = Integer.valueOf(p.Free_Qty__c);
                temp.AvailableStock = Integer.valueOf(p.Available_Stock__c);
                temp.Family = p.Family__c;
                temp.UnitPrice = Integer.valueOf(p.Unit_Price__c);
                temp.Id = '12345'+num;
                productTempMap.put(p.Family__c,new List<ProductsTemp>{temp});
                System.debug('#productTempMap1 :'+productTempMap);
            }else{
                ProductsTemp temp1 = new ProductsTemp();
                temp1.ProductName = p.Name;
                DraftOrder__c dp = draftOrderMap?.get(p.Name);
                System.debug('#dp:'+ dp);
                temp1.OrderQty = dp != null? Integer.valueOf(dp.OrderQty__c) :  Integer.valueOf(p.Order_Qty__c);
                temp1.PromotionOrderQty =  Integer.valueOf(p.Promotion_Order_Qty__c);
                temp1.PromotionFreeQty = Integer.valueOf(p.Promotion_Free_Qty__c);
                temp1.FreeQty = Integer.valueOf(p.Free_Qty__c);
                temp1.AvailableStock = Integer.valueOf(p.Available_Stock__c);
                temp1.Family = p.Family__c;
                temp1.UnitPrice = Integer.valueOf(p.Unit_Price__c);
                temp1.Id ='34334'+num;
                productTempMap.get(p.Family__c).add(temp1);
                System.debug('#productTempMap2 :'+productTempMap);
            }
            num++;
        }


        if (String.isNotBlank(family) && family != 'All' && description == null) {
            System.debug('--1');
            List<ProductsTemp> items = productTempMap.get(family);
            if (items != null) {
                System.debug('--2');
                resultWrapper.productsTemps.addAll(items);
            }

        } else {

            System.debug('--3');
            List<ProductsTemp> itemList = new List<ProductsTemp>();
                for (String key : productTempMap.keySet()) {
                    List<ProductsTemp> items = productTempMap.get(key);
                            itemList.addAll(items);
                }
             resultWrapper.productsTemps = itemList;
            System.debug('--4');
        }
        System.debug('#resultWrapper:'+resultWrapper);
        if (String.isNotBlank(searchToken)) {
            for (ProductsTemp item : resultWrapper.productsTemps) {
                if (item.ProductName.toLowerCase().contains(searchToken.toLowerCase())) {
                    productsTempsOutput.add(item);
                }
            }
        }else {
            productsTempsOutput.addAll(resultWrapper.productsTemps);
        }
    }
    catch (AuraHandledException ex){
        throw ex;
    }
        System.debug('#productsTempsOutput:'+productsTempsOutput);
        return productsTempsOutput;
    }

    @AuraEnabled
    public static List<ProductsTemp> getOrderDraftByDescription(String description, String accountId){
        List<DraftOrder__c> draftOrders = [SELECT Id,OrderQty__c, ProductName__c, AccountId__c,
                Value__c,Name, Description__c FROM DraftOrder__c WHERE Description__c =: description AND AccountId__c =: accountId];
        Map<String,DraftOrder__c> draftOrderMap = new Map<String,DraftOrder__c>();
        List<ProductsTemp> products = buildProductDump('','',null);
        Map<String,ProductsTemp> productsDumpMap = new Map<String,ProductsTemp>();
        for(ProductsTemp dump : products){
            productsDumpMap.put(dump.ProductName, dump);
        }


        ProductResultWrapper wrapper = new ProductResultWrapper();
        Map<String,OrderDraftService.DraftViewWrapper> draftViewWrappers = new Map<String,OrderDraftService.DraftViewWrapper>();
        for(DraftOrder__c draft :draftOrders){
            ProductsTemp temp = new ProductsTemp();
            temp.OrderQty = Integer.valueOf(draft.OrderQty__c);
            temp.ProductName = productsDumpMap.get(draft.ProductName__c).ProductName;
            wrapper.productsTemps.add(temp);
        }
        System.debug('#productsDumpMap.values():'+wrapper.productsTemps);

        return wrapper.productsTemps;
    }

    public class ProductResultWrapper
    {
        ProductResultWrapper(){
            productsTemps = new List<ProductsTemp>();
        }

        public List<ProductsTemp> productsTemps {get;set;}
    }
}