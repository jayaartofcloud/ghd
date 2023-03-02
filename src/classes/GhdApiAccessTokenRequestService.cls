/**
 * Created by Jayakumar Mogenahall on 20/02/2023.
 *
 * api call to
    https://am-gateway.ghdcoredev.com
    to get access token
    following setup element involved in this process
    App Manager
    Named Credential: GHD_Core_Token_Request
    External Credentials : GHD_Token_Request
    Permission Set: Basic_Auth_Permission_Set

 */

public with sharing class GhdApiAccessTokenRequestService {


    public static GhdApiAccessTokenRequestService.AccessTokenWrapper getGhdApiAccessToken(){
        Http http= new Http();
        AccessTokenWrapper wrapper = null;
        HttpRequest request = new HttpRequest();
        GHD_meta_values__mdt  partUrl = GHD_meta_values__mdt.getInstance('GHD_Access_token_Part_URL');
        request.setEndpoint('callout:GHD_Core_Token_Request'+partUrl.Value__c);
        request.setMethod('POST');
        HttpResponse response = http.send(request);
        if(response.getStatusCode() == 200){
            wrapper = (AccessTokenWrapper)JSON.deserialize(response.getBody(),AccessTokenWrapper.class);
        }
        System.debug('wrapper:'+wrapper);
        return wrapper;
    }

    public class AccessTokenWrapper
    {
        public String access_token;
        public String token_type;
        public Integer expires_in;
    }
}