/**
 * Created by Jayakumar Mogenahall on 13/03/2023.
 */

@RestResource(UrlMapping='/Order/*')
global class OrderProcess {
    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        RestResponse res1 = RestContext.response;

        List<Order> orders = new List<Order>();
        Set<Id> accountIds = new Set<Id>();
        Set<String> material = new Set<String>();
        OrderRequestWrapper orw = OrderRequestWrapper.parse(req.requestBody.toString());


        Decimal vat = [SELECT Vat__c FROM VAT__mdt WHERE VATCountry__r.BillingCountry__c = 'United Kingdom']?.VAT__c;

        Account account = [SELECT Id, CustomerId__c,Type,FirstName__c,LastName__c,Primary_Email__c,
                BillingCity, BillingCountry, BillingState, BillingStreet,BillingPostalCode,Phone,
                NationalNumber__c,Etage__c,Codeporte__c,Origin__r.CountryCode__c FROM Account WHERE Id =: orw.accountId];
        Origin__c origin = [SELECT Id,Identifier__c,Application__c,CountryCode__c,eCommStore__c FROM Origin__c WHERE Account__c =: account.Id];
        AdditionalInfo__c additionalInfo = [SELECT Id,Info1__c,Info2__c,Info3__c,Info4__c,Info5__c FROM AdditionalInfo__c WHERE Account__c =: account.Id];

        Savepoint sp = Database.setSavepoint();
        try {

                GhdOrder__c order = new GhdOrder__c();
                order.OrderDate__c = Date.valueOf(orw.orderDate);
                order.CountryCode__c = orw.countryCode;
                order.OrderType__c = orw.orderType;
                order.POReference__c = orw.poReference;
                order.CurrencyCode__c = orw.currencyCode;
                order.CountryCode__c = orw.countryCode;
                order.ReturnReason__c ='';
                order.ReturnedToCustomer__c = null;
                order.PaymentTermsB2B__c = '';
                order.paymentMethodB2B__c = '';
//
//                order.DeliveryCustomer__c = null; //customer
//                order.OrderingCustomer__c = null; //customer
                order.DeliveryInfo__r = null; // deliveryInfo
                order.Payment__r = null; //payment
                order.CollectInfo__r = null; //collectInfo;


                order.VAT__c = vat;
                order.DeliveryInfo__r.DeliveryDate__c = Date.today();
                order.DeliveryInfo__r.DeliveryMethod__c = '';
                order.DeliveryInfo__r.DeliveryInstructions__c = '';
                order.CollectInfo__r.CollectStoreId__c = '';
                order.Origin__r.Application__c = origin.Application__c;
                order.Origin__r.Identifier__c = origin.Identifier__c;
                order.Origin__r.eCommStore__c = origin.eCommStore__c;
                order.Origin__r.CountryCode__c = origin.CountryCode__c;
                order.AdditionalInfo__r.Info1__c = additionalInfo.Info1__c;
                order.AdditionalInfo__r.Info2__c = additionalInfo.Info2__c;
                order.AdditionalInfo__r.Info3__c = additionalInfo.Info3__c;
                order.AdditionalInfo__r.Info4__c = additionalInfo.Info4__c;
                order.AdditionalInfo__r.Info5__c = additionalInfo.Info5__c;

                for(OrderLineModel olm : orw.orderlines){
                    OrderItem oi =   new OrderItem(); 
                    oi.ProductName__c = olm.productName;
                    oi.UnitPrice = olm.unitPrice;
                    oi.TaxRate__c = olm.taxRate;
                    oi.UnitTax__c = olm.unitTax;
                    oi.Quantity = olm.quantity;
                }



        }catch (DmlException  ex){
            Database.rollback(sp);
        }

    }

}