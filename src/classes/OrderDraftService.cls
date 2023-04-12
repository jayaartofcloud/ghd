/**
 * Created by Jayakumar Mogenahall on 21/02/2023.
 */

public class OrderDraftService {

    @AuraEnabled

    public static List<DraftViewWrapper> getDraftViewForCustomer(String customerId,String draftName) {
        Map<String,DraftViewWrapper> draftViewWrappers = new Map<String,DraftViewWrapper>();
        try {
            System.debug('#customerId:' + customerId + ' draftName:' + draftName);
            List<DraftOrder__c> draftOrders = [
                    SELECT Id,
                            Name,
                            OrderQty__c,
                            Family__c,
                            ProductName__c,
                            PromotionFreeQty__c,
                            PromotionOrderQty__c,
                            UnitPrice__c,
                            FreeQty__c,
                            LastModifiedBy.Name,
                            LastModifiedDate,
                            Description__c,
                            Value__c

                    FROM DraftOrder__c
                    WHERE AccountId__c = :customerId
                    ORDER BY Name
            ];

            System.debug('#draftOrders:' + draftOrders);
            Set<String> productNames = new Set<String>();

            Map<String, CustomerProduct__c> customerProductMap = new Map<String, CustomerProduct__c>();
            //    List<Material__c> materials = [SELECT Id, MaterialCode__c,MaterialDescription__c FROM Material__c WHERE Name IN : ]
            List<CustomerProduct__c> customerProducts = [SELECT Id, Name, UnitPrice__c FROM CustomerProduct__c];
            for (CustomerProduct__c item : customerProducts) {
                customerProductMap.put(item.Name, item);
            }


            for (DraftOrder__c draft : draftOrders) {
                DraftViewWrapper d = new DraftViewWrapper();
                d.DraftRecordName = draft.Name;
                d.Description = draft.Description__c;
                d.ProductName = draft.ProductName__c;
                if (customerProductMap.get(draft.ProductName__c) != null) {
                    d.UnitPrice = customerProductMap.get(draft.ProductName__c)?.UnitPrice__c;
                }
                d.TotalAmount = draft.Value__c;
                d.LastModifiedBy = draft.LastModifiedBy.Name;
                d.LastModifiedDate = draft.LastModifiedDate.date();
                d.OrderQty = draft.OrderQty__c;
                d.Id = draft.Id;
                System.debug('#d' + d);
                draftViewWrappers.put(d.Description,d);
            }
            System.debug('#draftViewWrappers size:' + draftViewWrappers.size());
            System.debug('#draftViewWrappers:' + draftViewWrappers);

        }
        catch (Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
        return draftViewWrappers.values();
    }

    public class DraftViewWrapper
    {
        @AuraEnabled
        public String ProductName;
        @AuraEnabled
        public Decimal TotalAmount;
        @AuraEnabled
        public String LastModifiedBy;
        @AuraEnabled
        public Date LastModifiedDate;
        @AuraEnabled
        public Decimal UnitPrice;
        @AuraEnabled
        public String DraftRecordName;
        @AuraEnabled
        public String Description;
        @AuraEnabled
        public String Id;
        @AuraEnabled
        public Decimal OrderQty;



    }
}