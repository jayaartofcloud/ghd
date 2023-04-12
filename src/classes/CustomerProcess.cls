/**
 * Created by Jayakumar Mogenahall on 31/01/2023.
 */
@RestResource(UrlMapping='/Customer/*')
global with sharing class CustomerProcess {
  @HttpPost
    global static void doPost(){
      List<CustomerRequestWrapper> wrapper;
      Set<String> customerIds = new Set<String>();
      Map<String, CustomerRequestWrapper> customerRequestWrapperMap = new Map<String, CustomerRequestWrapper>();
      Boolean hasErrors = false;
      String error = '';
      RestRequest req;
      List<String> errorFields = new List<String>();
      List<RestResponseWrapper>  resList = new List<RestResponseWrapper>();
      RestResponseWrapper res;
      RestResponse response;
      List<Database.UpsertResult> upsertResult;
      List<Account> upsertRecords = new List<Account>();
      Database.UpsertResult[] upsertResults;
      try{
          req = RestContext.request;
          response = RestContext.response;
          response.addHeader('Content-Type', 'application/json');
          res = new RestResponseWrapper ();
          System.debug('v:'+req.requestBody.toString());

           wrapper =  CustomerRequestWrapper.parse(req.requestBody.toString());
          System.debug('#wrapper:'+wrapper);

      }
      catch(Exception ex){
          res = new RestResponseWrapper ();
          res.result = 'ERROR';
          RestResponseWrapper.ErrorWrapper errorWrapper = new RestResponseWrapper.ErrorWrapper();
          errorWrapper.errorId = 123;
          errorWrapper.errorText = ex.getMessage() + ' -> ' + ex.getStackTraceString();
          res.error = errorWrapper;
          resList.add(res);
          response.statusCode = 500;
          response.responseBody = Blob.valueOf(JSON.serialize(resList));
          ApiLogService.ApiLog(wrapper[0]?.customerData?.erpCustomerId,'500',resList,'UpdateCustomer');
          return;
      }


        for(CustomerRequestWrapper w : wrapper){
            customerIds.add(w.customerData.erpCustomerId);
            customerRequestWrapperMap.put(w.customerData.erpCustomerId,w);
            if(String.isBlank(w.customerData.customerGroup)){
                hasErrors = true;
                errorFields.add('Customer group');
            }
            if(String.isBlank(w.customerData.erpCustomerId)){
                hasErrors = true;
                errorFields.add('erpCustomerId');
            }
            if(w.origin != null){
                if(String.isBlank(w.origin.originApplication)){
                    hasErrors = true;
                    errorFields.add('origin.originApplication');
                }
                if(String.isBlank(w.origin.originIdentifier)){
                    hasErrors = true;
                    errorFields.add('origin.originIdentifier');
                }
                if(String.isBlank(w.origin.countryCode)){
                    hasErrors = true;
                    errorFields.add('origin.countryCode');
                }
            }

        }
          if(hasErrors){

              for(String f : errorFields){
                  error += f +',';
              }
              res.result = 'ERROR';
              RestResponseWrapper.ErrorWrapper errorWrapper = new RestResponseWrapper.ErrorWrapper();
              errorWrapper.errorId = 123;
              errorWrapper.errorText = error.removeEnd(',') +' can\'t be blank';
              res.error = errorWrapper;
              resList.add(res);
              response.statusCode = 400;
              response.responseBody = Blob.valueOf(JSON.serialize(resList));
              ApiLogService.ApiLog(wrapper[0]?.customerData?.erpCustomerId,'400',resList,'UpdateCustomer');
              return;
          }
      try{
          if(!hasErrors){
              List<Account> existingCustomer = [SELECT Id,CustomerId__c FROM Account WHERE CustomerId__c =: customerIds];
              Map<String,Account> foundAccountMap = new Map<String,Account>();
              if(existingCustomer != null && existingCustomer.size() > 0){
                  for(Account acc : existingCustomer){
                      foundAccountMap.put(acc.CustomerId__c,acc);
                  }
              }
             for(String key : customerRequestWrapperMap.keySet()){
                 Account acc = foundAccountMap.get(key);
                 CustomerRequestWrapper w = customerRequestWrapperMap.get(key);
                 if(acc !=null){
                     upsertRecords.add(buildAccount(w,acc));
                 }else{
                     upsertRecords.add(buildAccount(w,null));
                 }
             }
          }

          upsertResults = new List<Database.UpsertResult>();
          if(upsertRecords.size()>0){
              upsertResults = Database.upsert(upsertRecords);
          }


          Set<String> ids = new Set<String>();
          for(Database.UpsertResult sr : upsertResults){
              if(!sr.isSuccess()){

                  res = new RestResponseWrapper ();
                  res.result = 'ERROR';
                  RestResponseWrapper.ErrorWrapper errorWrapper = new RestResponseWrapper.ErrorWrapper();
                  errorWrapper.errorId = 123;
                  errorWrapper.errorText = 'Bad Request, please verify the input data and try again.';
                  res.error = errorWrapper;
                  resList.add(res);
                  response.statusCode = 400;
                  response.responseBody = Blob.valueOf(JSON.serialize(resList));
                  ApiLogService.ApiLog(wrapper[0]?.customerData?.erpCustomerId,'400',resList,'UpdateCustomer');
                  return;
              }else{
                  ids.add(sr.getId());
              }
          }

          if(ids.size() > 0){
              res = new RestResponseWrapper ();
              res.result = 'OK';
              RestResponseWrapper.Data data = new RestResponseWrapper.Data();
              String idList = '';
                for(String id: ids){
                    idList += id + ',';
                }

              res.data.genericId = idList.removeEnd(',');
              resList.add(res);
              response.statusCode = 200;
              response.responseBody = Blob.valueOf(JSON.serialize(resList));
              return ;
          }
      }

      catch (DmlException ex){

          System.debug('Customer Process DML Exception:' + ex.getMessage() + '->' + ex.getStackTraceString());
          res = new RestResponseWrapper ();
          res.result = 'ERROR';
          RestResponseWrapper.ErrorWrapper errorWrapper = new RestResponseWrapper.ErrorWrapper();
          errorWrapper.errorId = 123;
          String duplicateMsg ;
          if(ex.getMessage().contains('DUPLICATES_DETECTED')){
              duplicateMsg = 'Duplicate record found!';
              response.statusCode = 400;
          }elsE{
              response.statusCode = 500;
          }
          errorWrapper.errorText = String.isNotBlank( duplicateMsg) ? duplicateMsg :  ex.getMessage() + ' -> ' + ex.getStackTraceString();
          res.error = errorWrapper;
          resList.add(res);


          response.responseBody = Blob.valueOf(JSON.serialize(resList));
          ApiLogService.ApiLog(wrapper[0]?.customerData?.erpCustomerId,'500',resList,'UpdateCustomer');
          return;
      }
      catch (Exception ex){
          System.debug('Customer Process Exception:' + ex.getMessage() + '->' + ex.getStackTraceString());
      }
    }

//    static void ApiLog(String customerId, String status, Object message, String apiName){
//        Map<String,Object> inputs = new Map<String,Object>();
//        inputs.put('customerId', customerId);
//        inputs.put('HttpStatus',status);
//        inputs.put('ApiName', apiName);
//        inputs.put('Message', JSON.serialize(message));
//        System.debug('#inputs:'+ inputs);
//        Flow.Interview.createInterview('Api_Request_Log_New',inputs).start();
//
//    }

    public static Account buildAccount(CustomerRequestWrapper w, Account account){
        Account acc;

        if(account != null){
           acc = account;
        }else{
            acc = new Account();
        }

        acc.customerIdGuid__c = w.customerData?.customerIdGuid;
        acc.CustomerId__c = w.customerData?.erpCustomerId;
        acc.Type = w.customerData?.customerType;
        acc.Name = w.customerData?.customerName;
        acc.Primary_Email__c = w.customerData?.emailAddress;
        acc.Phone = w.customerData?.phone;
        acc.CustomerGroup__c = w.customerData?.customerGroup;
        acc.Status__c = w.customerData?.accountStatus == 'N/a' ? '--None--': w.customerData?.accountStatus;
        acc.BlockStatus__c = w.customerData?.blockStatus == 'No' ? false:true;
        acc.CompanyChain__c = w.customerData?.companyChain;
        acc.CreditLimit__c =Decimal.valueOf(w.customerData?.creditLimit);
        acc.CreditLimitAvailable__c = Decimal.valueOf(w.customerData?.creditLimitAvailable);
        acc.SalesDistrict__c = w.customerData?.salesDistrict;
        acc.DefaultStockLocation__c = w.customerData?.defaultStockLocation;
        acc.DeliveryTerms__c = w.customerData?.deliveryTerms;
        acc.PriceGroup__c = w.customerData?.priceGroup;
        acc.PaymentMethod__c = w.customerData?.paymentMethod;
        acc.Payment_Terms__c = w.customerData?.paymentTerms;
        acc.ModeOfTransport__c = w.customerData?.modeOfTransport;
        acc.CustomerComments__c = w.customerData?.customerComments;
        acc.ReportingMarket__c = w.customerData?.reportingMarket;
        acc.TaxNumber__c = w.customerData?.taxNumber;
        acc.SalesChannel__c = w.customerData?.salesChannel;
        acc.SalesSegment__c = w.customerData?.salesSegment;
        acc.CountryCurrency__c = w.customerData?.countryCurrency;
        acc.DiscountPriceGroup__c = w.customerData?.discountPriceGroupId;
        //acc.PrimaryContactName__c = w.customerData.primaryContactName;
        // acc.LocalCustomerId__c = w.customerData.localCustomerId;
        acc.SalesTaxGroup__c = w.customerData?.salesTaxGroup;
        acc.CommercialName__c = w.customerData?.commercialName;
        //acc.ParentId = w.customerData.parentCompany;
        acc.TierReference__c = w.customerData?.tierReference;
        acc.CostCenter__c = w.customerData?.costCenter;
        // acc.TaxValue__c = w.customerData.taxValue;
        acc.NationalNumber__c = w.customerData?.nationalNumber;
        acc.Etage__c = w.customerData?.etage;
        acc.CodePorte__c = w.customerData?.codePorte;
        //acc.ExternalCode__c = w.externalCode.externalCodeId;

        acc.ShippingStreet = w.Delivery?.fullAddress;
        acc.ShippingCity = w.Delivery?.town;
        acc.ShippingState = w.Delivery?.county;
        acc.ShippingCountry = w.Delivery?.countryCode;
        acc.ShippingPostalCode = w.Delivery?.postcode;
        acc.DeliveryEmail__c = w.Delivery?.emailAddress;
        acc.DeliveryPhone__c = w.Delivery?.telephoneNumber;

        acc.BillingStreet = w.Invoice?.fullAddress;
        acc.BillingCity = w.Invoice?.town;
        acc.BillingState = w.Invoice?.county;
        acc.BillingCountry = w.Invoice?.countryCode;
        acc.BillingCountry = w.Invoice?.postcode;
        acc.InvoiceEmail__c = w.Invoice?.emailAddress;
        acc.InvoicePhone__c = w.Invoice?.telephoneNumber;
        return acc;

    }


}