/**
 * Created by Jayakumar Mogenahall on 10/03/2023.
 */

public  class OrderRequestWrapper {

    public OrderRequestWrapper() {
        orderlines = new List<OrderlineModel>();
        deliveryCustomer = new DeliveryCustomer();
        orderingCustomer = new OrderingCustomer();
        deliveryInfo = new DeliveryInfoModel();
        origin = new OriginModel();
        payment = new PaymentModel();
        discount = new Discount();
        promotionCodes = new List<PromotionCodes>();
        collectInfo = new CollectInfoModel();
        giftCardPayment = new GiftCardPaymentModel();

    }

    public String clientOrderNumber;
    public String countryCode;
    public String orderType;
    public String orderDate;
    public String currencyCode;
    public String poReference;
    public Double subTotal;
    public Double tax;
    public Double totalValue;
    public String orderReason;
    public String manualIntervention;
    public String agentName;
    public String orderSource;
    public String returnInvoiceId;
    public String returnReason;
    public String returnReasonMethod;
    public String paymentTermsB2B;
    public String paymentMethodB2B;
    public List<OrderlineModel> orderlines;
    public DeliveryCustomer deliveryCustomer;
    public OrderingCustomer orderingCustomer;
    public DeliveryInfoModel deliveryInfo;
    public OriginModel origin;
    public PaymentModel payment;
    public List<PromotionCodes> promotionCodes;
    public CollectInfoModel collectInfo;
    public GiftCardPaymentModel giftCardPayment;
    public Discount discount;
    public String accountId;


    public class DeliveryCustomer {
        public String customerType;
        public String fullName;
        public String firstName;
        public String lastName;
        public String clientCustomerId; //what is this?
        public String addressLine1;
        public String addressLine2;
        public String town;
        public String county;
        public String postcode;
        public String countryCode;
        public String emailAddress;
        public String telephoneNumber;
        public String etage;
        public String codePorte;
    }

    public class OrderingCustomer {
        public String customerType;
        public String fullName;
        public String firstName;
        public String lastName;
        public String clientCustomerId;
        public String addressLine1;
        public String addressLine2;
        public String addressLine3;
        public String town;
        public String county;
        public String postcode;
        public String countryCode;
        public String emailAddress;
        public String telephoneNumber;
        public String nationalNumber;
        public String company;
        public String etage;
        public String codePorte;
    }

    public class LineDiscounts {
        public String code;
        public Double value;
    }

    public class Discount {
        public String code;
        public String value;
    }
    public class PromotionCodes {

    }

    public class CollectInfoModel
    {
        public String collectStoreId ;
        public String collectPhoneNumber;
        public String collectEmail;
    }

    public class GiftCardPaymentModel{
        public String isGiftUsed;
        public Decimal giftedCardValue;
    }

    public static OrderRequestWrapper parse(String json) {

        System.debug('#json before parse:' + json);
       OrderRequestWrapper orderWrappers = ( OrderRequestWrapper) System.JSON.deserialize(json, OrderRequestWrapper.class);
        System.debug('#orderWrappers:' + orderWrappers);
        return orderWrappers;
    }
}