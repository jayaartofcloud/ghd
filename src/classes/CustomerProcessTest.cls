/**
 * Created by Jayakumar Mogenahall on 01/02/2023.
 */

@IsTest
public with sharing class CustomerProcessTest{
/*
    @TestSetup
    static void Setup(){
        Account account = new Account();
        account.Customer_Id__c = '12345678';
        account.First_Name__c = 'John';
        account.Last_Name__c = 'Doe';
        account.Phone = '02023002343';
        account.Name = account.First_Name__c +' ' + account.Last_Name__c;
        insert account;
    }
    @IsTest
    static void updatingAccount(){

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer';  //Request URL
        req.httpMethod = 'POST';//HTTP Request Type
        req.addHeader('Content-Type', 'application/json');
        String jsonStr = '{"customerId":"12345678","customerType":"Salon","firstName":"John1","lastName":"Doe 5","phone":"1234567","origin": {"originApplication":"testOriginApp","originIdentifier":"1234","countryCode":"GB"}, "additionalInfo": {"info1":"testInfo1"}}';
        req.requestBody = Blob.valueOf(jsonStr);

        Test.startTest();
        RestContext.request = req;
        RestContext.response= res;
         CustomerProcess.doPost();
        Test.stopTest();
        System.debug(res);

        List<Account> accounts = [SELECT Id,First_Name__c FROM Account WHERE Customer_Id__c =: '12345678'];
        System.assert(res.statusCode == 200);
        System.assert(accounts != null);

    }

    @IsTest
    static void updatingAccountWithoutLastNameCauseError(){
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer';  //Request URL
        req.httpMethod = 'POST';//HTTP Request Type
        req.addHeader('Content-Type', 'application/json');
        String jsonStr = '{"customerId":"12345678","customerType":"Salon","firstName":"John1","phone":"1234567","origin": {"originApplication":"testOriginApp","originIdentifier":"1234","countryCode":"GB"}, "additionalInfo": {"info1":"testInfo1"}}';
        req.requestBody = Blob.valueOf(jsonStr);

        Test.startTest();
        RestContext.request = req;
        RestContext.response= res;
        CustomerProcess.doPost();
        Test.stopTest();
        System.debug(res);
        System.assert(res.statusCode == 400);
    }


    @IsTest
    static void updateCustomerWhoIsNotExistsInTheSystem(){
        List<Account> accounts = [SELECT Id,First_Name__c FROM Account WHERE Customer_Id__c =: '12345678'];
        accounts[0].Customer_Id__c = '93939393';
        update accounts;

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/customer';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        String jsonStr = '{"customerId":"12345678","customerType":"Salon","firstName":"John1","phone":"1234567","origin": {"originApplication":"testOriginApp","originIdentifier":"1234","countryCode":"GB"}, "additionalInfo": {"info1":"testInfo1"}}';
        req.requestBody = Blob.valueOf(jsonStr);

        Test.startTest();
        RestContext.request = req;
        RestContext.response= res;
        CustomerProcess.doPost();
        Test.stopTest();
        System.debug(res);
        System.assert(res.statusCode == 401);
    }


 */

}