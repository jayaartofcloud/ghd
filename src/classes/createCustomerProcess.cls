/**
 * Created by Jayakumar Mogenahall on 23/03/2023.
 */
@RestResource(UrlMapping='/CreateCustomer/*')
global with sharing class createCustomerProcess {

    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        List<RestResponseWrapper> resList = new List<RestResponseWrapper>();
        RestResponseWrapper res;
        RestResponse response = RestContext.response;
        response.addHeader('Content-Type', 'application/json');

        Boolean hasErrors = false;
        String error = '';
        List<String> errorFields = new List<String>();
        res = new RestResponseWrapper ();
        List<createCustomerWrapper> customerWrappers = createCustomerWrapper.parse(req.requestBody.toString());

        for (createCustomerWrapper customerWrapper : customerWrappers) {
            if (String.isBlank(customerWrapper.localCustomerId)) {
                hasErrors = true;
                errorFields.add('localCustomerId');
            }
            if (String.isBlank(customerWrapper.customerName)) {
                hasErrors = true;
                errorFields.add('customerName');
            }
            if (String.isBlank(customerWrapper.telephoneNumber)) {
                hasErrors = true;
                errorFields.add('telephoneNumber');
            }
            if (String.isBlank(customerWrapper.emailAddress)) {
                hasErrors = true;
                errorFields.add('emailAddress');
            }
            if (String.isBlank(customerWrapper.countryCurrency)) {
                hasErrors = true;
                errorFields.add('countryCurrency');
            }
            if (customerWrapper.origin == null) {
                hasErrors = true;
                errorFields.add('origin');
            }else {
                if(String.isBlank(customerWrapper.origin.originApplication)){
                    hasErrors = true;
                    errorFields.add('origin.originApplication');
                }
                if(String.isBlank(customerWrapper.origin.originIdentifier)){
                    hasErrors = true;
                    errorFields.add('origin.originIdentifier');
                }
                if(String.isBlank(customerWrapper.origin.countryCode)){
                    hasErrors = true;
                    errorFields.add('origin.countryCode');
                }
                if(String.isBlank(customerWrapper.origin.eCommStore)){
                    hasErrors = true;
                    errorFields.add('origin.eCommStore');
                }
            }


            if (hasErrors) {

                for (String f : errorFields) {
                    error += f + ',';
                }

                res.result = 'ERROR';
                RestResponseWrapper.ErrorWrapper errorWrapper = new RestResponseWrapper.ErrorWrapper();
                errorWrapper.errorId = 123;
                errorWrapper.errorText = error.removeEnd(',') + ' can\'t be blank';
                res.error = errorWrapper;
                resList.add(res);
                response.statusCode = 400;
                response.responseBody = Blob.valueOf(JSON.serialize(resList));
                return;
            }

        }
        Database.SaveResult[] saveResults;
        Database.SaveResult[] childObjectSaveResults;
        if (!hasErrors) {
            System.debug('customerWrappers:'+customerWrappers);
            List<Account> accounts = new List<Account>();
            for (createCustomerWrapper wrapper : customerWrappers) {
              //  createCustomerWrapper wrapper = new createCustomerWrapper();
                Account account = new Account();
                account.LocalCustomerId__c = wrapper.localCustomerId;
                account.CustomerId__c =  wrapper.localCustomerId;
                account.Name = wrapper.customerName;
                account.CommercialName__c = wrapper.commercialName;
                account.DeliveryAddress__Street__s = wrapper.deliveryAddressLine1 + ',' + wrapper.deliveryAddressLine2 + ',' + wrapper.deliveryAddressLine3;
                account.DeliveryAddress__City__s = wrapper.deliveryTown;
                account.InvoiceAddress__StateCode__s = wrapper.deliveryCounty;
                account.DeliveryAddress__CountryCode__s = wrapper.deliveryCountryCode;
                account.DeliveryAddress__PostalCode__s = wrapper.deliveryPostCode;
                account.InvoiceAddress__Street__s = wrapper.invoiceAddressLine1 + ',' + wrapper.invoiceAddressLine2 + ',' + wrapper.invoiceAddressLine3;
                account.InvoiceAddress__City__s = wrapper.deliveryTown;
                account.InvoiceAddress__StateCode__s = wrapper.invoiceCounty;
                account.InvoiceAddress__CountryCode__s = wrapper.invoiceCountryCode;
                account.InvoiceAddress__PostalCode__s = wrapper.invoicePostcode;
                account.CountryCurrency__c = wrapper.countryCurrency;
                account.SalesSegment__c = wrapper.salesSegment;
                account.TaxNumber__c = wrapper.taxNumber;
                account.SalesTaxGroup__c = wrapper.salesTaxNumber;
                account.Status__c = wrapper.accountStatus;
                account.BlockStatus__c = (wrapper.blockStatus == 'N/a'|| wrapper.blockStatus == null) ? false : true;
                account.Etage__c = wrapper.etag;
                account.CodePorte__c = wrapper.codePorte;
                account.RecordTypeId = GhdUtility.getRecordType('Account','Customer').Id;
                accounts.add(account);
                System.debug('#accounts:'+accounts);
                if (customerWrappers.size() > 0) {
                    saveResults = Database.insert(accounts);
                }
            }
            Set<String> insertedAccIds = new Set<String>();
            if(saveResults != null){
                for(Database.SaveResult result : saveResults){
                    insertedAccIds.add(result.getId());
                }
            }
           if(insertedAccIds.size() > 0){
               List<SObject> insertObjects = new List<sObject>();
               List<Account> insertedAccounts = [SELECT Id,LocalCustomerId__c FROM Account WHERE Id IN : insertedAccIds];
               Map<String,Account> accountMap = new Map<String,Account>();
               for(Account acc : insertedAccounts){
                   accountMap.put(acc.LocalCustomerId__c, acc);
               }

               for (createCustomerWrapper customerWrapper : customerWrappers) {
                   Account account = accountMap.get(customerWrapper.localCustomerId);
                   AdditionalInfo__c additionalInfo = new AdditionalInfo__c();
                   additionalInfo.Info1__c = customerWrapper.additionalInfo.info1;
                   additionalInfo.Info2__c = customerWrapper.additionalInfo.info2;
                   additionalInfo.Info3__c = customerWrapper.additionalInfo.info3;
                   additionalInfo.Info4__c = customerWrapper.additionalInfo.info4;
                   additionalInfo.Info5__c = customerWrapper.additionalInfo.info5;
                   additionalInfo.Account__c = account.Id;
                   insertObjects.add(additionalInfo);

                   Origin__c origin = new Origin__c();
                   origin.Identifier__c = customerWrapper.origin.originIdentifier;
                   origin.Application__c = customerWrapper.origin.originApplication;
                   origin.CountryCode__c = customerWrapper.origin.countryCode;
                   origin.DataAreaId__c = customerWrapper.origin.dataAreaRead;
                   origin.Account__c = account.Id;
                   origin.eCommStore__c = customerWrapper.origin.eCommStore;
                   insertObjects.add(origin);
               }
            if(insertObjects.size() > 0){
                childObjectSaveResults = Database.insert(insertObjects);
            }

           }


            for (Database.SaveResult sr : saveResults) {
                System.debug('--2');
                if (!sr.isSuccess()) {
                    System.debug('--3');
                    res = new RestResponseWrapper ();
                    res.result = 'ERROR';
                    RestResponseWrapper.ErrorWrapper errorWrapper = new RestResponseWrapper.ErrorWrapper();
                    errorWrapper.errorId = 123;
                    errorWrapper.errorText = 'Bad Request, please verify the input data and try again.';
                    res.error = errorWrapper;
                    resList.add(res);
                    response.statusCode = 400;
                    response.responseBody = Blob.valueOf(JSON.serialize(resList));
                    ApiLogService.ApiLog('',String.valueOf(response.statusCode),JSON.serialize(resList), 'Customer');
                    return;
                } else {
                    System.debug('--4');
                    res = new RestResponseWrapper ();
                    res.result = 'OK';
                    RestResponseWrapper.Data data = new RestResponseWrapper.Data();
                    res.data.genericId += sr.getId() + ',';
                    resList.add(res);
                    response.statusCode = 200;
                    response.responseBody = Blob.valueOf(JSON.serialize(resList));
                    return ;
                }
            }

        }
    }
}