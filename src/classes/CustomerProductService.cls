/**
 * Created by Jayakumar Mogenahall on 21/03/2023.
 */

public with sharing class CustomerProductService {

    @AuraEnabled(Cacheable=true)
    public static List<CustomerProductWrapper> getMaterialsForAccount(String accountId, String searchToken, String draftName){
        System.debug('#accountId:'+ accountId);
        String token = '' +searchToken +'%';
        System.debug('#token:'+ token);
        List<CustomerProduct__c> customerProducts;
        Map<Id,DraftOrder__c> draftOrderMap = new Map<Id,DraftOrder__c>();
        if(String.isNotBlank(draftName)){
            List<DraftOrder__c> draftOrders = [SELECT CustomerProduct__c, OrderQty__c FROM DraftOrder__c WHERE Description__c =: draftName];
            Set<Id> customerProductIds = new Set<Id>();
            for(DraftOrder__c d : draftOrders){
                draftOrderMap.put(d.CustomerProduct__c,d);
                customerProductIds.add(d.CustomerProduct__c);
            }
            customerProducts = [SELECT Id,UnitPrice__c,MaterialCode__c
            FROM CustomerProduct__c
            WHERE Id IN : customerProductIds];
        }else{
            customerProducts = [SELECT Id,UnitPrice__c,MaterialCode__c
            FROM CustomerProduct__c
            WHERE AccountId__c =: accountId];
        }

        System.debug('customerProducts:'+customerProducts);

        Set<String> materialCodeSet = new Set<String>();

        for(CustomerProduct__c c : customerProducts){
            materialCodeSet.add(c.MaterialCode__c);
        }
        System.debug('#materialCodeSet:'+materialCodeSet);
        List<Material__c> materials2 =  MaterialService.getMaterials(materialCodeSet);
        Map<String,Material__c> materialMap = new Map<String,Material__c>();
        for(Material__c m : materials2){
            materialMap.put(m.MaterialCode__c, m);
        }

        List<CustomerProductWrapper> wrappers = new List<CustomerProductWrapper>();
        Map<String,Decimal> materialPriceMap = new Map<String,Decimal>();
        for(CustomerProduct__c cp : customerProducts){
            CustomerProductWrapper wrapper = new CustomerProductWrapper();
            wrapper.ProductName = materialMap.get(cp.MaterialCode__c).MaterialDescription__c;
            wrapper.UnitPrice = cp.UnitPrice__c;
            wrapper.Id = cp.Id;
            wrapper.OrderQty = draftOrderMap.get(cp.Id)?.OrderQty__c;
            wrapper.MaterialCode = cp.MaterialCode__c;
            wrappers.add(wrapper);
        }
        System.debug('#wrappers:'+wrappers);

        //List<Material__c>  materials =  MaterialService.getMaterials();

        //for(Material__c mItem : materials){
         //   Decimal unitPrice = materialPriceMap.get(mItem.MaterialDescription__c);
//            if(unitPrice != null){
//
//            }
    //    }
        return wrappers;
    }

    @AuraEnabled
    public static Boolean create(String jsonInput, String accountId, String draftDesc, Decimal totalAmount) {
        System.debug('#jsonInput: ' + jsonInput);
        System.debug('#accountId:' + accountId + ' draftDesc:' + draftDesc + ' totalAmount:' + totalAmount);
        Database.SaveResult[] results;
        List<draftOrderWrapper> wrappers = (List<draftOrderWrapper>) JSON.deserialize(jsonInput, List<draftOrderWrapper>.class);
        System.debug('#wrappers:' + wrappers);

        Map<Id, draftOrderWrapper> customerProductMap = new Map<Id, draftOrderWrapper>();
        for (draftOrderWrapper wrapper : wrappers) {
            customerProductMap.put(wrapper.Id, wrapper);
        }
        System.debug('#customerProductMap:' + customerProductMap);
        List<CustomerProduct__c> customerProductList = [SELECT Id,UnitPrice__c, MaterialCode__c FROM CustomerProduct__c WHERE Id IN :customerProductMap.keySet()];
        System.debug('#customerProductList:' + customerProductList);
        Map<String, CustomerProduct__c> customerProductMap3 = new Map<String, CustomerProduct__c>();
        for (CustomerProduct__c cp : customerProductList) {
            customerProductMap3.put(cp.MaterialCode__c, cp);
        }
        System.debug('#customerProductMap3:' + customerProductMap3);
        List<Material__c> materials = [SELECT Id, Name, MaterialDescription__c, MaterialCode__c FROM Material__c WHERE MaterialCode__c IN :customerProductMap3.keySet()];
        System.debug('#materials:' + materials);
        Map<String, Material__c> materialMap = new  Map<String, Material__c>();
        for(Material__c m: materials){
            materialMap.put(m.MaterialCode__c,m);
        }
        System.debug('#materialMap:'+materialMap);
        Map<String, CustomerProduct__c> customerProductMap2 = new Map<String, CustomerProduct__c>();
        for (CustomerProduct__c cp : customerProductList) {
            customerProductMap2.put(cp.Id, cp);
        }
System.debug('#customerProductMap2:'+customerProductMap2);
        Set<DraftOrder__c> draftList = new Set<DraftOrder__c>();
        try {
            for (draftOrderWrapper w : wrappers) {
                DraftOrder__c draft = new DraftOrder__c();
                draft.OrderQty__c = Decimal.valueOf(w.OrderQty);
                draft.UnitPrice__c = customerProductMap2.get(w.Id).UnitPrice__c;
                draft.ProductName__c = materialMap.get(customerProductMap2.get(w.Id).MaterialCode__c).MaterialDescription__c;
                draft.Family__c = null;
                draft.AccountId__c = accountId;
                draft.Description__c = draftDesc;
                draft.Value__c = totalAmount;
                draft.Description__c = draftDesc;
                draft.CustomerProduct__c = w.Id;
                draftList.add(draft);
            }
System.debug('#draftList:'+draftList);
            if(draftList.size() > 0){
                List<DraftOrder__c> draftOrders = new List<DraftOrder__c>();
                for(DraftOrder__c d : draftList){
                    draftOrders.add(d);
                }

                results = Database.insert(draftOrders);
            }
System.debug('#draftList:'+draftList);
    } catch  (AuraHandledException ex){
            System.debug('Error: ' + ex.getMessage() + ' ->  Stack:' + ex.getStackTraceString());
        }

            return true;

    }

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


    public class CustomerProductWrapper{
        @AuraEnabled
        public String ProductName;
        @AuraEnabled
        public Decimal UnitPrice;
        @AuraEnabled
        public String Id;
        @AuraEnabled
        public Decimal OrderQty;
        @AuraEnabled
        public String MaterialCode;

    }
    public class draftOrderWrapper
    {
        public String OrderQty;
        public String Id;
    }

    public class ProductResultWrapper
    {
        ProductResultWrapper(){
            productsTemps = new List<ProductsTemp>();
        }

        public List<ProductsTemp> productsTemps {get;set;}
    }

}