/**
 * Created by Jayakumar Mogenahall on 01/02/2023.
 */

public class CustomerRequestWrapper {

    public CustomerRequestWrapper(){
        Invoice = new CustomerRequestWrapper.Invoice();
        Delivery = new CustomerRequestWrapper.Delivery();
        customerData = new CustomerRequestWrapper.CustomerData();
        origin = new OriginModel();
        externalCode = new ExternalCode();


    }

    public CustomerRequestWrapper.CustomerData customerData {get;set;}
    public CustomerRequestWrapper.Invoice Invoice {get;set;}
    public CustomerRequestWrapper.Delivery Delivery {get;set;}
    public OriginModel origin {get;set;}
    public ExternalCode externalCode {get;set;}

    public class CustomerData{
        public String customerIdGuid {get;set;}
        public String erpCustomerId {get;set;}
        public String customerType {get;set;}
        public String firstName {get;set;}
        public String lastName {get;set;}
        public String customerName {get;set;}
        public String addressLine1 {get;set;}
        public String addressLine2 {get;set;}
        public String addressLine3 {get;set;}
        public String town {get;set;}
        public String country {get;set;}
        public String county {get;set;}
        public String postCode {get;set;}
        public String countryCode {get;set;}
        public String emailAddress {get;set;}
        public String phone {get;set;}
        public String nationalNumber {get;set;}
        public String etage {get;set;}
        public String codePorte {get;set;}
        public String accountStatus {get;set;}
        public String blockStatus {get;set;}
        public String companyChain {get;set;}
        public String customerGroup {get;set;}
        public String countryCurrency {get;set;}
        public String creditLimit {get;set;}
        public String creditLimitAvailable {get;set;}
        public String salesDistrict {get;set;}
        public String defaultStockLocation {get;set;}
        public String deliveryTerms {get;set;}
        public String priceGroup {get;set;}
        public String paymentTerms {get;set;}
        public String paymentMethod {get;set;}
        public String modeOfTransport {get;set;}
        public String customerComments {get;set;}
        public String reportingMarket {get;set;}
        public String taxNumber {get;set;}
        public String salesChannel {get;set;}
        public String salesSegment {get;set;}
        public String discountPriceGroupId {get;set;}
        public String primaryContactName {get;set;}
        public String localCustomerId {get;set;}
        public String salesTaxGroup {get;set;}
        public String commercialName {get;set;}
        public String parentCompany {get;set;}
        public String tierReference {get;set;}
        public String costCenter {get;set;}
        public String taxValue {get;set;}

    }
    public class Invoice
    {
        public String addressType {get;set;}
        public String fullAddress {get;set;}
        public String town {get;set;}
        public String country {get;set;}
        public String postcode {get;set;}
        public String county {get;set;}
        public String countryCode {get;set;}
        public String emailAddress {get;set;}
        public String telephoneNumber {get;set;}
    }

    public class Delivery{
        public String addressType {get;set;}
        public String fullAddress {get;set;}
        public String town {get;set;}
        public String country {get;set;}
        public String postcode {get;set;}
        public String county {get;set;}
        public String countryCode {get;set;}
        public String emailAddress {get;set;}
        public String telephoneNumber {get;set;}
    }

    public class ExternalCode{
        public String externalCodeId {get;set;}
    }
    public class customerCount{
        public String total {get;set;}
    }
    public class RecordType{
        public String SFDCRecordTypeId {get;set;}
    }





    public static List<CustomerRequestWrapper> parse(String json){
        return (List<CustomerRequestWrapper>)System.JSON.deserialize(json, List<CustomerRequestWrapper>.class);
    }





}