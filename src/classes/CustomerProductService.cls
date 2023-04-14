/**
 * Created by Jayakumar Mogenahall on 21/03/2023.
 */

public with sharing class CustomerProductService {

    @AuraEnabled(Cacheable=true)
    public static List<CustomerProductWrapper> getMaterialsForAccount(String accountId, String searchToken, String draftName){
        System.debug('#accountId:'+ accountId + ' draftName:' + draftName);
        String token = '' +searchToken +'%';
        System.debug('#token:'+ token);
        List<CustomerProduct__c> customerProducts;
        Map<Id,DraftOrder__c> draftOrderMap = new Map<Id,DraftOrder__c>();
        System.debug('#1');
        if(String.isNotBlank(draftName)){
            System.debug('#2');
            List<DraftOrder__c> draftOrders = [SELECT CustomerProduct__c, OrderQty__c FROM DraftOrder__c WHERE Description__c =: draftName];
            System.debug('#3');
            Set<Id> customerProductIds = new Set<Id>();
            for(DraftOrder__c d : draftOrders){
                draftOrderMap.put(d.CustomerProduct__c,d);
                customerProductIds.add(d.CustomerProduct__c);
            }
            System.debug('#4');
            customerProducts = [SELECT Id,UnitPrice__c,MaterialCode__c
            FROM CustomerProduct__c
            WHERE Id IN : customerProductIds];
        }else{
            System.debug('#5');
            customerProducts = [SELECT Id,UnitPrice__c,MaterialCode__c
            FROM CustomerProduct__c
            WHERE AccountId__c =: accountId];
            System.debug('#6 : '+customerProducts);
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

}