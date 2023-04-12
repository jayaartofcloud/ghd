/**
 * Created by Jayakumar Mogenahall on 11/04/2023.
 */

public class PriceListAPIProcessQueueable implements System.Queueable, Database.AllowsCallouts{

    String customerId;
    public PriceListAPIProcessQueueable(){}
    public PriceListAPIProcessQueueable(String customerId) {
        this.customerId = customerId;
    }

    public void execute(QueueableContext param1) {

         Finalizer finalizer = new PriceListApiRetryFinalizerHandler();
        System.attachFinalizer(finalizer);

        HttpRequest req = new HttpRequest();

//        GhdApiAccessTokenRequestService.AccessTokenWrapper accessTokenService = GhdApiAccessTokenRequestService.getGhdApiAccessToken();
//        System.debug('#accessTokenService:' + accessTokenService);
        //req.setEndpoint(' https://ghdcoredev.com/api/crm/getpricelist?customerAccount='+customerId);
        req.setEndpoint('https://ghdcoretest.com/api/crm/json/getpricelist');
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        String jsonBody = '{"customerAccount":"' + customerId + '",' + '"countryCode":' + '"GB"}';
        system.debug('#json:' + jsonBody);

        //PriceList api can be accessible from UserTest, hence token is from UserTest
        string access_token = 'eyJraWQiOiJkZWZhdWx0IiwidHlwIjoiSldUIiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiJTRkRDVGVzdCIsImF1ZCI6IlNGRENUZXN0IiwiZG9tYWluIjoiMjVkODY1YmQtNDQ4Mi00NmFmLTk4NjUtYmQ0NDgyNzZhZjVhIiwiaXNzIjoiaHR0cHM6XC9cL2FtLWdhdGV3YXkuZ2hkY29yZXRlc3QuY29tXC9naGRjb3JldGVzdGRvbWFpblwvb2lkYyIsImV4cCI6MTY4MTI4NDAzOCwiaWF0IjoxNjgxMjc2ODM4LCJqdGkiOiIxUkNfczdNT1cwc001Xy1HazY4alZFUUpEWklpSTZYMEszaFNrMmJGLUVVIn0.iZQcko5emDTa0IoeKG8lOcdXauU6yMS18i84pAaeKrqUCWHsvSGbJxLs7x7r2I98Y_a9isZqh5krSx927EZlT1p7MqQG7ZH1fFjrdb2Ewwi9760vSQEoDFyw4FDITRdtCQ8IuQBsa_s6Ly5SCjlk4xWFT-p1sqL-NORiyI-2Tl0d-6onQY72JalSNTdCmLDJly1u8hdSbbAElIdRegBMssaLPitg8B2npsaxZjspdQyquc3DbKXokqIo_yJMMyBllajgRddfZkzmBz3vUYpyn5eD97q4oDprU5ykmsJFu3nB74OwNA_d_hOQajscbU-BZts2B4iBrws2N4D5qjGKyw';
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