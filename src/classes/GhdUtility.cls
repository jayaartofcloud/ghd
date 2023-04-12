/**
 * Created by Jayakumar Mogenahall on 24/03/2023.
 */

public with sharing class GhdUtility {

    public static String getRecordTypeNameById(String recordId){
        string recordTypeName = [SELECT Id,DeveloperName FROM RecordType WHERE Id =: recordId]?.DeveloperName;
        System.debug('##recordTypeName:'+recordTypeName);
        return recordTypeName;
    }
    public static RecordType getRecordType(String objectName, String developerName){
        RecordType recordtype = [SELECT Id, Name FROM RecordType WHERE SobjectType =: objectName and DeveloperName =: developerName LIMIT 1];
        return recordtype;
    }
}