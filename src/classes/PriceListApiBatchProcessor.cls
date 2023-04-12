/**
 * Created by Jayakumar Mogenahall on 11/04/2023.
 */

public  class PriceListApiBatchProcessor implements Database.Batchable<sObject>{

    public void execute(Database.BatchableContext bc, List<Account> accounts) {
        System.debug('##account size for batch:' + accounts.size());
        for(Account acc : accounts){
            PriceListAPIProcessQueueable processQueueable = new PriceListAPIProcessQueueable(acc.CustomerId__c);
            System.enqueueJob(processQueueable,1);
        }
    }

    public void finish(Database.BatchableContext bc) {
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {

        String query = 'SELECT Id, CustomerId__c, Name FROM Account WHERE CustomerId__c != null';
        return Database.getQueryLocator(query);
    }
}