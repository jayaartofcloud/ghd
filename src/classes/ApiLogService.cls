/**
 * Created by Jayakumar Mogenahall on 23/03/2023.
 */

public with sharing class ApiLogService {
//    public static void publishLogMessage(String message,String status,String customerId){
//        ApiLog__e apiLog = new ApiLog__e();
//        apiLog.Message__c = JSON.serialize(message);
//        apiLog.API_Name__c = 'CustomerUpdate';
//        apiLog.HttpStatus__c = status;
//        apiLog.CustomerId__c = customerId;
//        EventBus.publish(apiLog);
//    }
    public static void ApiLog(String customerId, String status, List<RestResponseWrapper> message, String apiName){
        Map<String,Object> inputs = new Map<String,Object>();
        inputs.put('customerId', customerId);
        inputs.put('HttpStatus',status);
        inputs.put('ApiName', apiName);
        inputs.put('Message', JSON.serialize(message));
        System.debug('#inputs:'+ inputs);
        Flow.Interview.createInterview('Api_Request_Log_New',inputs).start();

    }

    public static void ApiLog(String customerId, String status, String message, String apiName){
        Map<String,Object> inputs = new Map<String,Object>();
        inputs.put('customerId', customerId);
        inputs.put('HttpStatus',status);
        inputs.put('ApiName', apiName);
        inputs.put('Message', message);
        System.debug('#inputs:'+ inputs);
        Flow.Interview.createInterview('Api_Request_Log_New',inputs).start();

    }
}