/**
 * Created by Jayakumar Mogenahall on 15/03/2023.
 */

public with sharing class PaymentModel {
    public String paymentType;
    public String cardType;
    public String cardholder;
    public String authorisationCode;
    public Double authorisedAmount;
    public String merchantID;
    public String paymentInfo;
    public String paymentTerms;
    public String authorisationExpiry;
}