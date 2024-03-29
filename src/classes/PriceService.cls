/**
 * Created by Jayakumar Mogenahall on 21/02/2023.
 */

public with sharing class PriceService {

    public static void getPriceForCustomer(String customerId) {

        HttpRequest req = new HttpRequest();

        //GhdApiAccessTokenRequestService.AccessTokenWrapper accessTokenService = GhdApiAccessTokenRequestService.getGhdApiAccessToken();
      //  System.debug('#accessTokenService:' + accessTokenService);
        //req.setEndpoint(' https://ghdcoredev.com/api/crm/getpricelist?customerAccount='+customerId);
        req.setEndpoint('https://ghdcoretest.com/api/crm/json/getpricelist');
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        String jsonBody = '{"customerAccount":"' + customerId + '",' + '"countryCode":' + '"GB"}';
        system.debug('#json:' + jsonBody);

        //PriceList api can be accessible from UserTest, hence token is from UserTest
        string access_token = 'eyJraWQiOiJkZWZhdWx0IiwidHlwIjoiSldUIiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiJTRkRDVGVzdCIsImF1ZCI6IlNGRENUZXN0IiwiZG9tYWluIjoiMjVkODY1YmQtNDQ4Mi00NmFmLTk4NjUtYmQ0NDgyNzZhZjVhIiwiaXNzIjoiaHR0cHM6XC9cL2FtLWdhdGV3YXkuZ2hkY29yZXRlc3QuY29tXC9naGRjb3JldGVzdGRvbWFpblwvb2lkYyIsImV4cCI6MTY4MTQ2NjY0NSwiaWF0IjoxNjgxNDU5NDQ1LCJqdGkiOiIzWDR5WVpIRUdIQ3VJcE1pazk5MUNfd00tYmtZTkdBVnkzVXdiUGtoeXVNIn0.zhHnj2IxgUxhLnK84XCPO6yVXJmV-N8RyKFj78ERNsaiuDge1W5MWOpLzAZC4TEEwfN6V-cBUbshm94qT7dJg4vPWqrg0b706XjzS7bNa9d3PC92r_0CdlpA80yUGzaEKXXDJcW9xH10qdPSfM3qmPGZkl-7PRjsN522_zKSdGCsBO6wbyPFydYbBqAoQQwkChx46IrsfTFEET5vs5El1wo-w93dwUtLbBBCfUba-Znjq7DvGZPAVmJ_bh782R5kKvpBRip8FHNUI58_a7CCFRYoLqRzYiUpJt9o9MVmRtraAMsgmrV1FF_lkMbELW1_Y9gX1merUrS7UMzEEtg-mg';
        req.setHeader('Authorization', 'bearer ' + access_token);
        req.setBody(jsonBody);

        System.debug('#req:' + req);
        Http http = new Http();
        HttpResponse response = http.send(req);

        PriceListResultWrapper priceList = new PriceListResultWrapper();
        List<CustomerProduct__c> existingCp;
        System.debug('#response.getBody():' + response.getBody());
        List<CustomerProduct__c> customerProducts = new List<CustomerProduct__c>();
        if (response.getStatusCode() == 200) {

            PriceListResultWrapper priceListWrapper = PriceListResultWrapper.parse(response.getBody());
            Set<String> materialCode = new Set<String>();
            Map<String, PriceListResultWrapper.Price> priceMap = new Map<String, PriceListResultWrapper.Price>();
            for (PriceListResultWrapper.Price s : priceListWrapper.response.data.prices.price) {
                materialCode.add(s.materialCode);
                priceMap.put(s.materialCode, s);
            }
            Account account = [SELECT Id FROM Account WHERE CustomerId__c = :priceListWrapper.response.data.customerAccount];
            existingCp = [
                    SELECT Id, UnitPrice__c, Currency__c, PriceType__c, MaterialCode__c
                    FROM CustomerProduct__c
                    WHERE AccountId__c = :account.Id AND MaterialCode__c IN :materialCode
            ];
            System.debug('#existingCp:' + existingCp);
           Set<String> materialCodeSet = new Set<String>();
            for (PriceListResultWrapper.Price d : priceListWrapper.response.data.prices.price) {
                materialCodeSet.add(d.materialCode);
            }

            List<Material__c> materials = [SELECT Id,MaterialCode__c,MaterialDescription__c FROM Material__c WHERE MaterialCode__c IN : materialCodeSet];
            Map<String, Material__c> materialMap = new Map<String,Material__c>();
            for(Material__c material : materials){
                materialMap.put(material.MaterialCode__c,material);
            }

            if (existingCp.isEmpty()) {
                for (PriceListResultWrapper.Price d : priceListWrapper.response.data.prices.price) {
                    CustomerProduct__c cp = new CustomerProduct__c();
                    cp.MaterialCode__c = d.materialCode;
                    cp.UnitPrice__c = d.unitPrice;
                    cp.AccountId__c = account.Id;
                    cp.PriceType__c = d.priceType;
                    cp.Material__c = materialMap.get(d.materialCode).Id;
                    customerProducts.add(cp);

                }
            } else {

                for (CustomerProduct__c cp : existingCp) {
                    PriceListResultWrapper.Price price = priceMap.get(cp.MaterialCode__c);
                    cp.UnitPrice__c = price.unitPrice;
                    cp.Material__r = materialMap.get(cp.MaterialCode__c);
                    cp.PriceType__c = price.priceType;
                    customerProducts.add(cp);
                }
            }
            List<Database.UpsertResult> saveResults;
            String error;
            if (customerProducts.size() > 0) {
                try{
                  saveResults = Database.upsert(customerProducts);
                    System.debug('saveResults:' + saveResults);
                }
                catch (DmlException dmlException){
                    for(Database.UpsertResult sr : saveResults)
                        if(sr.getErrors() != null){
                            error += sr.getErrors()+'/n/r';
                        }
                    ApiLogService.ApiLog(customerId,'500',error,'PriceList');
                }
            }
        }
    }

}