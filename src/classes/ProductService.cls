/**
 * Created by Jayakumar Mogenahall on 15/02/2023.
 */

public with sharing class ProductService {

    static string removeChar(String source, Integer index) {
        return source.left(index) + source.right(source.length() - index - 1);
    }
    @AuraEnabled
   public static Boolean create(String jsonInput, String accountId, String draftDesc, Decimal totalAmount) {
        System.debug('#jsonInput: ' + jsonInput);
        System.debug('#accountId:' + accountId + ' draftDesc:' + draftDesc + ' totalAmount:' + totalAmount);
        Database.SaveResult[]  results;
        List<draftOrderWrapper> wrappers = (List<draftOrderWrapper>)JSON.deserialize(jsonInput,List<draftOrderWrapper>.class);
        System.debug('#wrappers:'+ wrappers);

       return true;
    }

 public class draftOrderWrapper
 {
     public String OrderQty;
     public String Id;
 }
}