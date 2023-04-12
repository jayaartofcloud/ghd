/**
 * Created by Jayakumar Mogenahall on 20/03/2023.
 */

public class OrderCalloutQueueable implements Queueable, Database.AllowsCallouts{

    OrderRequestWrapper wrapper;
    public OrderCalloutQueueable(OrderRequestWrapper requestWrapper){
        this.wrapper = requestWrapper;
    }
    public void execute(QueueableContext param1) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        GhdApiAccessTokenRequestService.AccessTokenWrapper accessTokenService = GhdApiAccessTokenRequestService.getGhdApiAccessToken();
        GHD_meta_values__mdt  orderUrl = GHD_meta_values__mdt.getInstance('OrderCreationURL');
        System.debug('#orderUrl:'+orderUrl.Value__c);
        req.setEndpoint('https://ghdcoredev.com/api/soc-b2b');
        req.setMethod('POST');
        req.setHeader('Authorization','bearer' + ' ' + accessTokenService.access_token);


        String jsonRequestInput =   JSON.serialize(this.wrapper);
        System.debug('jsonRequestInput:'+jsonRequestInput);
        req.setBody(jsonRequestInput);
        HttpResponse response = http.send(req);
        System.debug('#response1:'+response.getBody());
    }
}