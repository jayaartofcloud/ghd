/**
 * Created by Jayakumar Mogenahall on 21/03/2023.
 */

public with sharing class MaterialService {
    public static List<Material__c> getMaterials(Set<String> code){
      return [ SELECT Id,Name, MaterialDescription__c, MaterialCode__c FROM Material__c WHERE MaterialCode__c IN : code];
    }
}