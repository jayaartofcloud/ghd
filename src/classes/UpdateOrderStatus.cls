/**
 * Created by Jayakumar Mogenahall on 21/03/2023.
 */

@RestResource(UrlMapping='/UpdateOrderStatus/*')
global with sharing class UpdateOrderStatus {

    @HttpPost
    global static void doPost(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        System.debug(req.requestBody.toString());

        res.statusCode = 200;
        res.responseBody = Blob.valueOf(JSON.serialize(req.requestBody.toString()) + ' Message received' );
    }

}