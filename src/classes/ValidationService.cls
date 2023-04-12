/**
 * Created by Jayakumar Mogenahall on 01/02/2023.
 */

public with sharing class ValidationService {


    public static void ValidateRequestPayload(String sObjName,String payLoadJson){
        List<Ghd_Api_Required_Fields__mdt> requiredFields = [SELECT Label, Field_Name__c,Enable__c, Data_type__c,relatedTo__c,sObject_Name__c,Required_Field_Length__c FROM Ghd_Api_Required_Fields__mdt WHERE sObject_Name__c =: sObjName];

        Map<String,List<Ghd_Api_Required_Fields__mdt>> requiredObjectMap = new Map<String,List<Ghd_Api_Required_Fields__mdt>>();
        for(Ghd_Api_Required_Fields__mdt  item : requiredFields){
            if(!requiredObjectMap.containsKey(item.sObject_Name__c)){
                if(item.Enable__c){
                    requiredObjectMap.put(item.sObject_Name__c,new List<Ghd_Api_Required_Fields__mdt>{item});
                }

            }else{
                if(item.Enable__c){
                    requiredObjectMap.get(item.sObject_Name__c).add(item);
                }

            }
        }
        switch on sObjName{
            when 'Account' {
                CustomerRequestWrapper customerRequestWrapper = (CustomerRequestWrapper)CustomerRequestWrapper.parse(payLoadJson);
                List<CustomerRequestWrapper> wrappers = new List<CustomerRequestWrapper>();
                wrappers.add(customerRequestWrapper);

                List<Ghd_Api_Required_Fields__mdt> reqFields = requiredObjectMap.get('Account');
                for(Ghd_Api_Required_Fields__mdt req : reqFields){

                   System.debug('###'+ customerRequestWrapper+'.'+'firstName');

                }
            }
        }
    }
    public static Boolean getRequiredFields(String selectedObject, String fieldName){
       Boolean isRequired = false;
        Map <String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.SObjectType sObjType = gd.get(selectedObject);
        Schema.DescribeSObjectResult r = sObjType.getDescribe();
        Map<String, Schema.SObjectField> MapOfField = r.fields.getMap();
            Schema.SObjectField field = MapOfField.get(fieldName);
            Schema.DescribeFieldResult F = field.getDescribe();
//            if(isRequired(field.getDescribe()) == true){
//                isRequired == true;
//            }
        return isRequired;
    }

    static Boolean isRequired(DescribeFieldResult describeFieldResult) {
        return describeFieldResult.isCreateable() && !describeFieldResult.isNillable() && describeFieldResult.getType() != DisplayType.BOOLEAN;
    }
/*
    public static void validateRequestPayload(Map<String,String> validationMap){
        System.debug('Start validationMap: '+validationMap);
        Map<String, String> errorMap = new Map<String,String>();
        List<Ghd_Api_Required_Fields__mdt> requiredFields = [SELECT Label, Field_Name__c, Data_type__c,relatedTo__c,sObject_Name__c,Required_Field_Length__c FROM Ghd_Api_Required_Fields__mdt ];
        Map<String,List<Ghd_Api_Required_Fields__mdt>> requiredObjectMap = new Map<String,List<Ghd_Api_Required_Fields__mdt>>();
        for(Ghd_Api_Required_Fields__mdt  item : requiredFields){
            if(!requiredObjectMap.containsKey(item.sObject_Name__c)){
                requiredObjectMap.put(item.sObject_Name__c,new List<Ghd_Api_Required_Fields__mdt>{item});
            }else{
                requiredObjectMap.get(item.sObject_Name__c).add(item);
            }
        }
        System.debug('requiredObjectMap:'+requiredObjectMap);
        List<String> requiredFieldList = new List<String>();
        for(String key : requiredObjectMap.keySet()){
            List<Ghd_Api_Required_Fields__mdt> fields = requiredObjectMap.get(key);
            for(Ghd_Api_Required_Fields__mdt field : fields){
                if(field.Enable__c){
                    requiredFieldList.add(field.Field_Name__c);
                }
            }
        }
        for(String key : validationMap.keySet()){
            String json = validationMap.get(key);
            switch on key{
                when 'Account' {
                    CustomerRequestWrapper CustomerRequestWrapper = (CustomerRequestWrapper)CustomerRequestWrapper.parse(json);
                    System.debug('CustomerRequestWrapper:'+CustomerRequestWrapper);
                    for(String field : requiredFieldList ){

                    }
                }
            }

        }




    }

 */
}