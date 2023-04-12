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
        OrderStatus orderStatusWrapper = (OrderStatus)JSON.deserialize(req.requestBody.toString(), UpdateOrderStatusWrapper.class);
        System.debug('orderStatusWrapper:'+orderStatusWrapper);
    }

    public class UpdateOrderStatusWrapper
    {
        UpdateOrderStatusWrapper(){
            orderStatus = new OrderStatus();
        }
        public String customerCode;
        public String fulfilmentSystemOrderCode;
        public OrderStatus orderStatus;
    }
    public class OrderStatus
    {
        public String statusCode;
        public String statusDescription;
    }

}