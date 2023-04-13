/**
 * Created by Jayakumar Mogenahall on 10/03/2023.
 */

public with sharing class OrderService {

    @AuraEnabled
    public static void createOrder(String jsonInput) {
        System.debug('#jsonInput:'+jsonInput);
        Savepoint savepoint;
        Database.SaveResult[] oliSaveResult;
        Database.SaveResult[]  orderLineSaveResult;

        try {

            savepoint = Database.setSavepoint();
System.debug('---1---');
            OrderCreateWrapper orderWrapper = OrderCreateWrapper.parse(jsonInput);
            System.debug('---2---');
            System.debug('#orderWrapper:'+orderWrapper);

            if(String.isNotBlank(orderWrapper.poReference)){
                Boolean isPoRefFound = [SELECT Id, POReference__c FROM GhdOrder__c WHERE POReference__c =: orderWrapper.poReference] != null;
                if(isPoRefFound){
                    AuraHandledException e = new  AuraHandledException('');
                    e.setMessage('PO Reference is already exists, please use different reference.');
                    throw e;
                }
            }

            for(OrderLineModel model : orderWrapper.products){
                if(String.isEmpty(model.materialNumber)){
                    AuraHandledException e = new  AuraHandledException('');
                    e.setMessage('Please make sure the order line item  contains materialCode.');
                    throw e;
                }
            }
            System.debug('#orderWrapper:'+orderWrapper);
            String accountCustomerId = [SELECT Id, CustomerId__c FROM Account WHERE Id =: orderWrapper.accountId].CustomerId__c;
            Account account = [SELECT Id, FirstName__c, LastName__c,Type,Phone,CustomerId__c,Primary_Email__c,NationalNumber__c,CommercialName__c,CountryCurrency__c, DeliveryFirstName__c, DeliveryLastName__c,DeliveryPhone__c,DeliveryEmail__c,
                    BillingStreet, BillingState,BillingCity,BillingCountry, BillingPostalCode,ShippingStreet,ShippingState,ShippingCity,ShippingCountry,ShippingPostalCode
            FROM Account WHERE CustomerId__c =: accountCustomerId];
            System.debug('#Account:'+ account);
            List<Origin__c> origin1 = [SELECT CountryCode__c,Identifier__c,Application__c,eCommStore__c FROM Origin__c WHERE Account__c =: account.Id];
            System.debug('#origin1:' + origin1);
            Origin__c origin = [SELECT CountryCode__c,Identifier__c,Application__c,eCommStore__c FROM Origin__c WHERE  Account__c =: account.Id];
            System.debug('#Origin:' + origin);
            System.debug('--1');
            GhdOrder__c order = new GhdOrder__c();
            order.POReference__c = orderWrapper.PoReference;
            order.OrderDate__c = orderWrapper.estimatedDeliveryDate;
            order.CountryCode__c = origin.CountryCode__c;
            order.AccountId__c = account.Id;

            System.debug('--2');
            Database.SaveResult  orderSaveResult = Database.insert(order);
            System.debug('Order Created:' +orderSaveResult.getId());
            System.debug('orderSaveResult.getId():'+orderSaveResult.getId());
            VAT__mdt vat = [SELECT Id, VAT__c FROM VAT__mdt WHERE VATCountry__r.Masterlabel =: 'United Kingdom'];
            GhdOrder__c createdOrder = [SELECT Id, POReference__c,AccountId__c, CountryCode__c  FROM GhdOrder__c where Id =: orderSaveResult.getId()];
            System.debug('createdOrder:'+createdOrder);

            OrderRequestWrapper requestWrapper = new OrderRequestWrapper();

            //Order Mandatory fields starts
            requestWrapper.clientOrderNumber = createdOrder.POReference__c;
            requestWrapper.countryCode = createdOrder.CountryCode__c;
            requestWrapper.orderType = '';
            requestWrapper.currencyCode = account.CountryCurrency__c;
            requestWrapper.subTotal =orderWrapper.totalExclVat;
            requestWrapper.tax = vat.VAT__c;
            requestWrapper.totalValue = orderWrapper.totalInclVat;
            requestWrapper.orderDate = String.valueOf(Date.today());
            List<OrderLineModel> orderLine = new  List<OrderLineModel>();
            //build orderLine for JSON
            for(OrderLineModel olm : orderWrapper.products){
                System.debug('#olm:'+olm);
                OrderLineModel ol = new OrderLineModel();
                ol.quantity = olm.quantity;
                ol.unitTax = olm.unitTax;
                ol.taxRate = olm.taxRate;
                ol.unitPrice = olm.unitPrice;
                ol.materialNumber = olm.materialNumber;
                ol.productCode = olm.productCode;
                ol.productName = olm.productName;
                orderLine.add(ol);
            }

            requestWrapper.orderlines = orderLine;
            System.debug('#OrderLineModel:'+ requestWrapper.orderlines);
            //insert order line
            List<OrderLineItem__c> orderItems = new List<OrderLineItem__c>();
            for(OrderLineModel ol :  requestWrapper.orderlines){
                OrderLineItem__c orderItem = new OrderLineItem__c();
                orderItem.ProductPrice__c = ol.unitPrice;
                orderItem.Quantity__c = ol.quantity;
                orderItem.UnitTax__c = ol.unitTax;
                orderItem.GhdOrder__c = orderSaveResult.getId();
                orderItems.add(orderItem);
            }
            if(orderItems.size() > 0){
                orderLineSaveResult = Database.insert(orderItems);
            }
            System.debug('#orderItems:'+orderItems);

            //Order Mandatory fields ends

            //customer mandatory fields starts
            requestWrapper.orderingCustomer.customerType = account.Type;
            requestWrapper.orderingCustomer.fullName = account.FirstName__c + ' '+ account.LastName__c;
            requestWrapper.orderingCustomer.firstName = account.FirstName__c;
            requestWrapper.orderingCustomer.telephoneNumber = account.Phone;
            requestWrapper.orderingCustomer.clientCustomerId = account.CustomerId__c;
//            //Customer mandatory fields ends
            requestWrapper.orderingCustomer.addressLine1 = account.BillingStreet;
            requestWrapper.orderingCustomer.addressLine2 = '';
            requestWrapper.orderingCustomer.addressLine3 = '';
            requestWrapper.orderingCustomer.town = account.BillingCity;
            requestWrapper.orderingCustomer.county = account.BillingState;
            requestWrapper.orderingCustomer.postcode =account.BillingPostalCode;
            requestWrapper.orderingCustomer.countryCode = account.BillingCountry;
            requestWrapper.orderingCustomer.emailAddress = account.Primary_Email__c;
            requestWrapper.orderingCustomer.nationalNumber = account.NationalNumber__c;
            requestWrapper.orderingCustomer.company = account.CommercialName__c;
            requestWrapper.orderingCustomer.etage = '';
            requestWrapper.orderingCustomer.codePorte = '';

            //Delivery Info mandatory fields starts
            //    System.debug('#requestWrapper:'+requestWrapper);
            requestWrapper.deliveryInfo.deliveryDate = String.valueOf(Date.today());
            requestWrapper.deliveryInfo.deliveryMethod = 'Standard';
            requestWrapper.deliveryInfo.deliveryInstructions = '';
//            Delivery Info mandatory fields ends

            //requestWrapper.deliveryInfo.deliveryMaterialNumber = '';
            requestWrapper.deliveryInfo.deliveryNet = 0;
            requestWrapper.deliveryInfo.deliveryTax = 0;
            requestWrapper.deliveryInfo.deliveryTaxRate = 0;
            requestWrapper.deliveryInfo.deliveryTotal = 0;

            //collectINfo required field start
            requestWrapper.collectInfo.collectStoreId = '';
            //collectINfo required field end

            requestWrapper.collectInfo.collectPhoneNumber = '';
            requestWrapper.collectInfo.collectEmail = '';

            //Origin required field start here
            requestWrapper.origin.originApplication = origin.Application__c;
            requestWrapper.origin.originIdentifier = origin.Identifier__c;
            requestWrapper.origin.countryCode = origin.CountryCode__c;
            requestWrapper.origin.eCommStore = origin.eCommStore__c;
            //Origin required field ends here

            //Payment mandatory fields start
            requestWrapper.payment.paymentType = '';
            //Payment mandatory fields end
            requestWrapper.payment.paymentInfo = '';
            requestWrapper.payment.paymentTerms = '';
            requestWrapper.payment.authorisationCode = '';
            requestWrapper.payment.authorisedAmount = 0.0;
            requestWrapper.payment.authorisationExpiry = '';

            //GiftCard mandatory fields start
            requestWrapper.giftCardPayment.isGiftUsed = '';
            requestWrapper.giftCardPayment.giftedCardValue = 0;
            //GiftCard mandatory fields end

            //Discount mandatory fields start
            requestWrapper.discount.code = '';
            requestWrapper.discount.value = '';
            //Discount mandatory fields end

            System.debug('requestWrapper:'+requestWrapper);
            System.enqueueJob(new OrderCalloutQueueable(requestWrapper));



        }
        catch (DmlException dmlException){
            System.debug('dmlException:'+dmlException);
            for(Database.SaveResult sr : oliSaveResult){
                if(!sr.isSuccess()){
                    System.debug('---------OrderCreate Error-----------');
                    for(Database.Error err : sr.getErrors()){
                        System.debug(err.getMessage() + ' -> ' + err.getFields());
                    }
                }
            }
            Database.rollback(savepoint);
            throw new AuraHandledException(dmlException.getMessage());
        }
        catch (Exception ex){
            System.debug('#Error:' + ex.getMessage() + ' -> '+ ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage() );
        }
    }
}