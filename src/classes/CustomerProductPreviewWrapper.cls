/**
 * Created by Jayakumar Mogenahall on 16/02/2023.
 */

public with sharing class CustomerProductPreviewWrapper {

    public CustomerProductPreviewWrapper(){}
    public Decimal Free_Qty {get;set;}
    public Decimal Order_Qty {get;set;}
    public Decimal Promotion_Order_Qty {get;set;}
    public Decimal Promotion_Free_Qty {get;set;}
    public Decimal Unit_Price {get;set;}
    public String Family {get;set;}
    public String Account_Id {get;set;}
}