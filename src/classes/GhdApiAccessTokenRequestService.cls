/**
 * Created by Jayakumar Mogenahall on 20/02/2023.
 *
 * api call to
    https://am-gateway.ghdcoredev.com
    to get access token
    following setup element involved in this process
    Named Credential: GHD_Core_Token_Request
    External Credentials : GHD_Token_Request
    Permission Set: Basic_Auth_Permission_Set

 */

public with sharing class GhdApiAccessTokenRequestService {


    public static GhdApiAccessTokenRequestService.AccessTokenWrapper getGhdApiAccessToken(){
        Http http= new Http();
        AccessTokenWrapper wrapper = null;
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:GHD_Core_Token_Request/ghdcoredevdomain/oauth/token?grant_type=client_credentials&Content-Type=application/x-www-form-urlencoded');
        request.setMethod('POST');
        HttpResponse response = http.send(request);
        if(response.getStatusCode() == 200){
            System.debug(response.getBody());
            wrapper = (AccessTokenWrapper)JSON.deserialize(response.getBody(),AccessTokenWrapper.class);
        }
        System.debug('#wrapper:' + wrapper);
        return wrapper;
    }

    public class AccessTokenWrapper
    {
        public String access_token;
        public String token_type;
        public Integer expires_in;
    }
}