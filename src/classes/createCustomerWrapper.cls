/**
 * Created by Jayakumar Mogenahall on 23/03/2023.
 */

public with sharing class createCustomerWrapper {

    public createCustomerWrapper(){
        additionalInfo = new AdditionalInfoModel();
        origin = new OriginModel();
    }
    public String localCustomerId {get;set;}
    public String customerName {get;set;}
    public String commercialName {get;set;}
    public String deliveryAddressLine1 {get;set;}
    public String deliveryAddressLine2 {get;set;}
    public String deliveryAddressLine3 {get;set;}
    public String deliveryTown {get;set;}
    public String deliveryCounty {get;set;}
    public String deliveryPostCode {get;set;}
    public String deliveryCountryCode {get;set;}
    public String invoiceAddressLine1 {get;set;}
    public String invoiceAddressLine2 {get;set;}
    public String invoiceAddressLine3 {get;set;}
    public String invoiceCountryCode {get;set;}
    public String invoiceTown {get;set;}
    public String invoiceCounty {get;set;}
    public String invoicePostcode {get;set;}
    public String emailAddress {get;set;}
    public String telephoneNumber {get;set;}
    public String countryCurrency {get;set;}
    public String salesSegment {get;set;}
    public String taxNumber {get;set;}
    public String salesTaxNumber {get;set;}
    public String accountStatus {get;set;}
    public String blockStatus {get;set;}
    public String etag {get;set;}
    public String codePorte {get;set;}
    public AdditionalInfoModel additionalInfo{get;set;}
    public OriginModel origin {get;set;}

    public static List<createCustomerWrapper> parse(String json){
        return (List<createCustomerWrapper>)System.JSON.deserialize(json, List<createCustomerWrapper>.class);
    }
}