/**
 * Created by Jayakumar Mogenahall on 31/01/2023.
 *  //https://salesforce.stackexchange.com/questions/85664/oauth-implementation/85679#85679
 */

public with sharing class SecurityService {

    public static void getToken()
    {


        //String refreshToken = 'https://am-gateway.ghdcoredev.com/ghdcoredevdomain/oauth/token?grant_type=refresh_token';
        String endPoint = 'https://am-gateway.ghdcoredev.com/ghdcoredevdomain/oauth/token?grant_type=client_credentials';
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPoint);
        req.setMethod('POST');
        req.setHeader('Content-Type','application/x-www-form-urlencoded');
        req.setHeader('Authorization', 'basic '+ EncodingUtil.base64Encode(System.Blob.valueOf('SFDC_Dev:sSg1q9jKj6vLBmYc67g0')));
        HttpResponse res = h.send(req);
        HttpResponseWrapper wrapper = (HttpResponseWrapper)JSON.deserialize(res.getBody(),HttpResponseWrapper.class);
        //String refreshT = EncodingUtil.base64Encode(Blob.valueOf(wrapper.access_token));
       // req.setHeader('refresh_token',refreshT);
        System.debug('#wrapper:'+wrapper);
        System.debug('#res: '+ res);
        system.debug('#body:' + res.getBody());



    }

    public static void getTokenViaCallout(){
       Http h = new Http();
       HttpRequest req = new HttpRequest();
       req.setEndpoint('callout:GHD_Core_Token_Request'+'/ghdcoredevdomain/oauth/token?grant_type=client_credentials');
       req.setMethod('POST');
       HttpResponse res = h.send(req);
       System.debug('#res: '+ res);
       system.debug('#body:' + res.getBody());

    }

    public class HttpResponseWrapper
    {
        String access_token;
        String token_type;
        Integer expires_in;
    }
}